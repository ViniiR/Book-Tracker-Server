open! Lwt.Infix
open! Lwt.Syntax
open! Caqti_lwt
open! Caqti_request.Infix
open! Lib_types.Db

let get_env name =
  try Sys.getenv name
  with _ -> raise (Errors.Missing_Env_Variable ("$" ^ name))

module Env : sig
  val conn_string : string
end = struct
  let conn_string = get_env "PGSQL_CONNECTION"
end

let create_connection () =
  let uri = Uri.of_string Env.conn_string in
  let* result = Caqti_lwt_unix.connect uri in
  match result with
  | Ok m -> Lwt.return_ok m
  | Error _ ->
      raise (Errors.Failed_Database_Connection "Failed to connect to database")

(** Caqti function to encode database type into ocaml record type Types.book *)
let encode (book : Lib_types.Book.book) =
  Ok (book.title, book.chapter, book.cover_image)

(** Caqti function to decode ocaml record type Types.book into database type *)
let decode (title, chapter, cover_image) =
  Ok Lib_types.Book.{ title; chapter; cover_image }

(** Get a single book from the database *)
let get_book (conn : Caqti_lwt.connection) (id : int) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let query =
    Caqti_type.(int ->! t3 string float string)
      "SELECT * FROM books WHERE id = $1;"
  in
  let* res = Conn.find query id in
  match res with
  | Ok v -> Lwt.return v
  | Error e ->
      Printf.eprintf "%s" @@ Caqti_error.show e;
      flush stderr;
      raise (Errors.Failed_To_Fetch "Book does not exist")

(** Get all books from the database *)
let get_all_books (conn : Caqti_lwt.connection) =
  let module Conn = (val conn : Caqti_lwt.CONNECTION) in
  let query_type : Lib_types.Book.book Caqti_type.t =
    Caqti_type.(custom ~encode ~decode (t3 string float string))
  in
  let query = (Caqti_type.unit ->* query_type) "SELECT * FROM books;" in
  let* res = Conn.collect_list query () in
  match res with
  | Ok v ->
      if List.length v >= 1 then Lwt.return v
      else raise (Errors.Failed_To_Fetch "No books to be found")
  | Error e ->
      Printf.eprintf "%s" @@ Caqti_error.show e;
      flush stderr;
      raise (Errors.Failed_To_Fetch "No books to be found")

(** Create one book in the database *)
let create_book (conn : Caqti_lwt.connection) = ()
