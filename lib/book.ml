open Dream
open! Lwt.Infix
open! Lwt.Syntax
open! Lib_types.Book

let id = "id"

let id_validator (req : request) =
  match int_of_string_opt @@ param req id with
  | Some n -> n
  | None -> raise (Errors.Invalid_id "Invalid Book Id")

let unwrap_or_raise result = match result with Ok v -> v | Error e -> raise e

(** Universal route Error handler *)
let route_error_handler (req : request) (route : routeHandler) :
    response promise =
  let module DbError = Lib_types.Db.Errors in
  let module BookError = Errors in
  try%lwt route req with
  | BookError.Invalid_id msg -> respond ~status:`Bad_Request msg
  | BookError.Invalid_json msg -> respond ~status:`Bad_Request msg
  | DbError.Failed_to_fetch msg -> respond ~status:`Bad_Request msg
  | DbError.Failed_to_create msg -> respond ~status:`Internal_Server_Error msg
  | DbError.Failed_database_connection msg ->
      respond ~status:`Internal_Server_Error msg
  | DbError.Missing_env_variable msg ->
      respond ~status:`Internal_Server_Error msg
(* Throw any unknown errors *)
(* | _ -> *)
(*     Printf.eprintf "%s\n" "Some damn error occurred"; *)
(*     Stdlib.flush stderr; *)
(*     respond ~status:`Internal_Server_Error "Internal Server Error" *)

let json_of_book (book : id_book) : Yojson.Safe.t =
  `Assoc
    [
      ("title", `String book.title);
      ("chapter", `Float book.chapter);
      ("cover_image", `String book.cover_image);
      ("id", `Int book.id);
    ]

let book_of_json (json_str : string) : book =
  try
    let open! Yojson.Basic in
    let open! Yojson.Basic.Util in
    let json = Yojson.Basic.from_string json_str in
    let book : book =
      {
        title = to_string @@ member "title" json;
        chapter = to_float @@ member "chapter" json;
        cover_image = to_string @@ member "cover_image" @@ json;
      }
    in
    book
  with
  | Yojson.Json_error e ->
      Printf.eprintf "%s" e;
      Stdlib.flush stderr;
      raise (Lib_types.Book.Errors.Invalid_json "JSON is not valid")
  | Yojson.Basic.Util.Type_error (msg, _) (* _ will usually be null *) ->
      Printf.eprintf "\nError: %s\n" msg;
      Stdlib.flush stderr;
      raise (Lib_types.Book.Errors.Invalid_json "JSON is not valid")

let json_of_book_list (list : id_book list) : Yojson.Safe.t =
  `List (List.map (fun book -> json_of_book book) list)

let get_all : routeHandler =
 fun _ ->
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.get_all_books connection
  in
  let json_string = Yojson.Safe.to_string @@ json_of_book_list result in
  json json_string

let get : routeHandler =
 fun req ->
  let id = id_validator req in
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.get_book connection id
  in
  let json_string = Yojson.Safe.to_string @@ json_of_book result in
  json json_string

(* TODO: database pool *)
let post : routeHandler =
 fun req ->
  let%lwt body = Dream.body req in
  let book = book_of_json body in
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.create_book connection book
  in
  if Result.is_ok result then empty `Created else empty `Internal_Server_Error

let put (req : request) : response promise = empty `No_Content
let patch (req : request) : response promise = empty `No_Content
let delete (req : request) : response promise = empty `No_Content
