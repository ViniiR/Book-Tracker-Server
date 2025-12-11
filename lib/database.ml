open! Lwt.Infix
open! Lwt.Syntax
open! Caqti_lwt
open! Caqti_request.Infix
open! Lib_types.Db

let get_env name =
  try Sys.getenv name
  with _ -> raise (Errors.Missing_env_variable ("$" ^ name))

module Env : sig
  val conn_string : string
end = struct
  let conn_string = get_env "PGSQL_CONNECTION"
end

(*
    https://github.com/paurkedal/caqti-study/blob/main/study/hello-caqti-lwt/lib/repo/exec.ml

    Caqti infix operators

    ->! decodes a single row
    ->? decodes zero or one row
    ->* decodes many rows
    ->. expects no row
*)

let create_connection () =
  let uri = Uri.of_string Env.conn_string in
  let* result = Caqti_lwt_unix.connect uri in
  match result with
  | Ok m -> Lwt.return_ok m
  | Error _ ->
      raise (Errors.Failed_database_connection "Failed to connect to database")

let log_error error =
  Printf.eprintf "%s" @@ Caqti_error.show error;
  flush stderr;
  ()

(** Get a single book from the database *)
let get_book (conn : Caqti_lwt.connection) (id : int) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let query =
    (Caqti_type.int ->! caqti_book) "SELECT * FROM books WHERE id = $1;"
  in
  let* res = Conn.find query id in
  match res with
  | Ok v -> Lwt.return_ok v
  | Error e ->
      log_error e;
      Lwt.return_error (Errors.Failed_to_fetch "Book does not exist")

(** Get all books from the database *)
let get_all_books (conn : Caqti_lwt.connection) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let query = (Caqti_type.unit ->* caqti_book) "SELECT * FROM books;" in
  let* res = Conn.collect_list query () in
  match res with
  | Ok v ->
      if List.length v >= 1 then Lwt.return_ok v
      else Lwt.return_error (Errors.Failed_to_fetch "No books to be found")
  | Error e ->
      log_error e;
      Lwt.return_error (Errors.Failed_to_fetch "No books to be found")

(** Create one book in the database *)
let create_book (conn : Caqti_lwt.connection)
    (book : Lib_types.Book.create_book) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let timestamp = Int64.of_float @@ Unix.time () in
  let query =
    let open Caqti_type in
    (t4 string float string int64 ->. Caqti_type.unit)
      "INSERT INTO books (title, chapter, image_link, last_modified) VALUES \
       ($1, $2, $3, $4)"
  in
  let* res =
    let title, chapter, cover_image = book in
    Conn.exec query (title, chapter, cover_image, timestamp)
  in
  match res with
  | Ok _ -> Lwt.return_ok ()
  | Error e ->
      log_error e;
      Lwt.return_error (Errors.Failed_to_create "Could not create book")

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
let update_book (conn : Caqti_lwt.connection) (book : Lib_types.Book.patch_book)
    (id : int) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let query =
    Caqti_type.(
      t5 string float string int64 int
      ->? Caqti_type.int)
      (* TODO: chnage 404.404 to NULL *)
      (* syntax-sql *)
      {|
        -- BEGIN
        --   IF EXISTS(
        --       SELECT 1 FROM books
        --       WHERE id = $5
        --   ) THEN
            UPDATE books SET
              title = COALESCE(NULLIF ($1, ''), title),
              chapter = COALESCE(NULLIF ($2, 404.404), chapter),
              image_link = COALESCE(NULLIF ($3, ''), image_link),
              last_modified = $4
            WHERE id = $5 RETURNING id;
        --   ELSE
        --       RAISE EXCEPTION "book does not exist";
        --   END IF;
        -- END
      |}
      [@@ocamlformat "disable"]
  in
  let* res =
    let title = match book.title_opt with Some v -> v | None -> "" in
    let chapter = match book.chapter_opt with Some v -> v | None -> 404.404 in
    let cover_image =
      match book.cover_image_opt with Some v -> v | None -> ""
    in
    let timestamp = Int64.of_float @@ Unix.time () in

    Conn.find_opt query (title, chapter, cover_image, timestamp, id)
  in
  match res with
  | Ok opt -> (
      match opt with
      | Some v ->
          if v == id then Lwt.return_ok ()
          else
            Lwt.return_error
              (Errors.Update_on_incorrect "Query on incorrect id")
      | None ->
          Lwt.return_error
            (Errors.Update_on_nonexistent "Query on non existent id"))
  | Error e ->
      log_error e;
      Lwt.return_error (Errors.Failed_to_update "Could not update book")

(** Delete a book from the database *)
let delete_book (conn : Caqti_lwt.connection) (id : int) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let query =
    Caqti_type.(int ->. Caqti_type.unit) "DELETE FROM books WHERE id = $1;"
  in
  let* res = Conn.exec query id in
  match res with
  | Ok _ -> Lwt.return_ok ()
  | Error e ->
      log_error e;
      Lwt.return_error (Errors.Failed_to_delete "Could not delete book")

(* type pool = { *)
(*   connections : Caqti_lwt.connection Queue.t; *)
(*   mutex : Lwt_mutex.t; *)
(*   max_size : int; *)
(*   uri : Uri.t; *)
(* } *)
(**)
(* let create_pool = *)
(*   let pool_config = { *)
(*         connections *)
(*     } in *)
(*   Caqti_lwt_unix.connect_pool *)
