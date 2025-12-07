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
    (Caqti_type.int ->! caqti_id_book) "SELECT * FROM books WHERE id = $1;"
  in
  let* res = Conn.find query id in
  match res with
  | Ok v -> Lwt.return v
  | Error e ->
      log_error e;
      raise (Errors.Failed_to_fetch "Book does not exist")

(** Get all books from the database *)
let get_all_books (conn : Caqti_lwt.connection) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let query = (Caqti_type.unit ->* caqti_id_book) "SELECT * FROM books;" in
  let* res = Conn.collect_list query () in
  match res with
  | Ok v ->
      if List.length v >= 1 then Lwt.return v
      else raise (Errors.Failed_to_fetch "No books to be found")
  | Error e ->
      log_error e;
      raise (Errors.Failed_to_fetch "No books to be found")

(** Create one book in the database *)
let create_book (conn : Caqti_lwt.connection) (book : Lib_types.Book.book) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let query =
    (caqti_book ->. Caqti_type.unit)
      "INSERT INTO books (title, chapter, image_link) VALUES ($1, $2, $3)"
  in
  let* res = Conn.exec query book in
  match res with
  | Ok _ -> Lwt.return_ok ()
  | Error e ->
      log_error e;
      raise (Errors.Failed_to_create "Could not create book")

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
