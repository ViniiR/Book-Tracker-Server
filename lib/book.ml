open Dream
open! Lwt.Infix
open! Lwt.Syntax
open! Lib_types.Book

let id = "id"

let id_validator (req : request) =
  match int_of_string_opt @@ param req id with
  | Some n -> n
  | None -> raise (Errors.InvalidId "Invalid Book Id")

let unwrap_or_raise result = match result with Ok v -> v | Error e -> raise e

(** Universal route Error handler *)
let route_error_handler (req : request) (route : routeHandler) :
    response promise =
  let module DbError = Lib_types.Db.Errors in
  let module BookError = Errors in
  try%lwt route req with
  | BookError.InvalidId msg -> respond ~status:`Bad_Request msg
  | DbError.Failed_To_Fetch msg -> respond ~status:`Bad_Request msg
  | DbError.Failed_Database_Connection msg ->
      respond ~status:`Internal_Server_Error msg
  | DbError.Missing_Env_Variable msg ->
      respond ~status:`Internal_Server_Error msg
  | _ -> respond ~status:`Internal_Server_Error "Internal Server Error"

let book_to_json (book : book) : Yojson.Safe.t =
  `Assoc
    [
      ("title", `String book.title);
      ("chapter", `Float book.chapter);
      ("cover_image", `String book.cover_image);
      ("id", `Int book.id);
    ]

let book_list_to_json (list : book list) : Yojson.Safe.t =
  `List (List.map (fun book -> book_to_json book) list)

let get_all : routeHandler =
 fun _req ->
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.get_all_books connection
  in
  let json_string = Yojson.Safe.to_string @@ book_list_to_json result in
  json json_string

let get : routeHandler =
 fun req ->
  let id = id_validator req in
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.get_book connection id
  in
  let json_string = Yojson.Safe.to_string @@ book_to_json result in
  json json_string

let post : routeHandler = fun _req -> empty `Created
let put (_req : request) : response promise = empty `No_Content
let patch (_req : request) : response promise = empty `No_Content
let delete (_req : request) : response promise = empty `No_Content
