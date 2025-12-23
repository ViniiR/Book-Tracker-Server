open! Lwt.Infix
open! Lwt.Syntax
open! Caqti_lwt
open! Caqti_request.Infix
open! Lib_types.Db

let get_env name =
  try Sys.getenv name
  with _ -> raise (Errors.Missing_env_variable ("$" ^ name))

let log_error error =
  Printf.eprintf "%s" @@ Caqti_error.show error;
  flush stderr

module Env : sig
  val conn_string : string
end = struct
  let conn_string = get_env "PGSQL_CONNECTION"
end

module Pool = struct
  let config = Caqti_pool_config.create ~max_size:5 ()

  let create =
    let uri = Uri.of_string Env.conn_string in
    match Caqti_lwt_unix.connect_pool ~pool_config:config uri with
    | Ok pool -> pool
    | Error e ->
        log_error e;
        raise (Errors.Failed_pool_creation "Failed to create pool")
end

(*
    https://github.com/paurkedal/caqti-study/blob/main/study/hello-caqti-lwt/lib/repo/exec.ml

    Caqti infix operators

    ->! decodes a single row
    ->? decodes zero or one row
    ->* decodes many rows
    ->. expects no row
*)

let handle_caqti_error (e : Caqti_error.t) ~on_query_error =
  match e with
  | `Connect_failed _ | `Connect_rejected _ ->
      raise (Errors.Failed_pool_connection "Failed pool connection")
  | `Request_failed _ | `Response_failed _
  | `Response_rejected _ (* Response_rejected *) ->
      raise on_query_error
  | _ -> raise (Errors.Internal_error "Internal Error")

(** Get all books from the database *)
let get_all_books (pool : pool) =
  let* res =
    Caqti_lwt_unix.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        let query = Caqti_type.(unit ->* caqti_book) "SELECT * FROM books;" in
        Db.collect_list query ())
      pool
  in
  match res with
  | Ok v ->
      if List.length v >= 1 then Lwt_result.return v
      else Lwt_result.fail (Errors.Failed_to_fetch "No books to be found")
  | Error e ->
      log_error e;
      Lwt_result.fail
      @@ handle_caqti_error e
           ~on_query_error:(Errors.Failed_to_fetch "No books to be found")

(** Get a single book from the database *)
let get_book (pool : pool) (id : int) =
  let* res =
    Caqti_lwt_unix.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        let query =
          Caqti_type.(int ->! caqti_book) "SELECT * FROM books WHERE id = $1;"
        in
        Db.find query id)
      pool
  in
  match res with
  | Ok v -> Lwt_result.return v
  | Error e ->
      log_error e;
      Lwt_result.fail
      @@ handle_caqti_error e
           ~on_query_error:(Errors.Failed_to_fetch "books not found")

(** Create one book in the database *)
let create_book (pool : pool) (book : Lib_types.Book.create_book) =
  let* res =
    Caqti_lwt_unix.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        let timestamp = Int64.of_float @@ Unix.time () in
        let query =
          Caqti_type.(t4 string float string int64 ->. unit)
            "INSERT INTO books (title, chapter, image_link, last_modified) \
             VALUES ($1, $2, $3, $4)"
        in
        let title, chapter, cover_image = book in
        Db.exec query (title, chapter, cover_image, timestamp))
      pool
  in
  match res with
  | Ok _ -> Lwt_result.return ()
  | Error e ->
      log_error e;
      Lwt_result.fail @@ handle_caqti_error e
           ~on_query_error:(Errors.Failed_to_create "Could not create book")

(* Change one book in the database *)
(** INFO: removed since you never really get to override all the data on the
    database *)
(* let change_book (conn : Caqti_lwt.connection) (book : Lib_types.Book.input_book) *)
(*     = *)
(*   let module Conn = (val conn : Caqti_lwt.CONNECTION) in *)
(*   let book = book_of_input_book book book.id in *)
(*   let query = *)
(*     (query_book ->. Caqti_type.unit) *)
(*       "UPDATE books set title = $1, chapter = $2, image_link =$3 WHERE id = $4;" *)
(*   in *)
(*   let* res = Conn.exec query book in *)
(*   match res with *)
(*   | Ok _ -> Lwt.return_ok () *)
(*   | Error e -> *)
(*       log_error e; *)
(*       raise (Errors.Failed_to_change "Could not change book") *)

(** Update part of one book in the database *)
let update_book (pool : pool) (book : Lib_types.Book.patch_book) (id : int) =
  let* res =
    Caqti_lwt_unix.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        let query =
          Caqti_type.(
            t5 (option string) (option float) (option string) int64 int ->? int)
            (* syntax-sql *)
            {|
               UPDATE books SET
                 title = COALESCE($1, title),
                 chapter = COALESCE($2, chapter),
                 image_link = COALESCE($3, image_link),
                 last_modified = $4
               WHERE id = $5 RETURNING id;
            |}
            [@@ocamlformat "disable"]
        in
        let timestamp = Int64.of_float @@ Unix.time () in
        Db.find_opt query
          (book.title_opt, book.chapter_opt, book.cover_image_opt, timestamp, id))
      pool
  in
  match res with
  | Ok opt -> (
      match opt with
      | Some v ->
          if v = id then Lwt_result.return ()
          else
            Lwt_result.fail (Errors.Update_on_incorrect "Query on incorrect id")
      | None ->
          Lwt_result.fail
            (Errors.Update_on_nonexistent "Query on non existent id"))
  | Error e ->
      log_error e;
      Lwt_result.fail @@ handle_caqti_error e
           ~on_query_error:(Errors.Failed_to_update "Could not update book")

(** Delete a book from the database *)
let delete_book (pool : pool) (id : int) =
  let* res =
    Caqti_lwt_unix.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        let query =
          Caqti_type.(int ->? int)
            "DELETE FROM books WHERE id = $1 RETURNING id;"
        in
        Db.find_opt query id)
      pool
  in
  match res with
  | Ok opt -> (
      match opt with
      | Some v ->
          if v = id then Lwt_result.return ()
          else
            Lwt_result.fail (Errors.Update_on_incorrect "Query on incorrect id")
      | None ->
          Lwt_result.fail (Errors.Delete_on_nonexistent "Query on incorrect id")
      )
  | Error e ->
      log_error e;
      Lwt_result.fail @@ handle_caqti_error e
           ~on_query_error:(Errors.Failed_to_delete "Could not delete book")
