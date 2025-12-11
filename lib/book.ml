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
  | BookError.Incorrect_type msg -> respond ~status:`Bad_Request msg
  | BookError.Missing_field msg -> respond ~status:`Bad_Request msg
  | BookError.No_fields msg -> respond ~status:`Bad_Request msg
  | DbError.Failed_database_connection msg ->
      respond ~status:`Internal_Server_Error msg
  | DbError.Missing_env_variable msg ->
      respond ~status:`Internal_Server_Error msg
  | DbError.Failed_to_fetch msg -> respond ~status:`Not_Found msg
  | DbError.Failed_to_create msg -> respond ~status:`Internal_Server_Error msg
  | DbError.Failed_to_update msg -> respond ~status:`Internal_Server_Error msg
  | DbError.Failed_to_delete msg -> respond ~status:`Internal_Server_Error msg
  | DbError.Update_on_incorrect msg -> respond ~status:`Bad_Request msg
  | DbError.Update_on_nonexistent msg -> respond ~status:`Bad_Request msg
(* Throw any unknown errors *)
(* | _ -> *)
(*     Printf.eprintf "%s\n" "Some damn error occurred"; *)
(*     Stdlib.flush stderr; *)
(*     respond ~status:`Internal_Server_Error "Internal Server Error" *)

let get_all : routeHandler =
 fun _ ->
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.get_all_books connection
  in
  if Result.is_ok result then
    let books = Result.get_ok result in
    let json_string =
      Yojson.Safe.to_string @@ Lib_parse.json_of_book_list books
    in
    json json_string
  else raise @@ Result.get_error result

let get : routeHandler =
 fun req ->
  let id = id_validator req in
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.get_book connection id
  in
  if Result.is_ok result then
    let book = Result.get_ok result in
    let json_string = Yojson.Safe.to_string @@ Lib_parse.json_of_book @@ book in
    json json_string
  else raise @@ Result.get_error result

(* TODO: database pool *)
let post : routeHandler =
 fun req ->
  let%lwt body = Dream.body req in
  let book : create_book = Lib_parse.create_book_of_json body in
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.create_book connection book
  in
  if Result.is_ok result then empty `Created
  else raise @@ Result.get_error result

(* NOTE: if id is sent via request.body it will be ignored *)
(** INFO: removed since you never really get to override all the data on the
    database *)
(* let put : routeHandler = *)
(*  fun req -> *)
(*   let id = id_validator req in *)
(*   let%lwt body = Dream.body req in *)
(*   let book = input_book_of_json body in *)
(*   let%lwt result = *)
(*     let%lwt connection = Database.create_connection () in *)
(*     let connection = unwrap_or_raise connection in *)
(*     Database.change_book connection book *)
(*   in *)
(*   if Result.is_ok result then empty `No_Content *)
(*   else empty `Internal_Server_Error *)

let patch : routeHandler =
 fun req ->
  let%lwt body = Dream.body req in
  let id = id_validator req in
  let book : patch_book = Lib_parse.patch_book_of_json body in
  if
    let open Option in
    is_none book.title_opt && is_none book.chapter_opt
    && is_none book.cover_image_opt
  then raise (Errors.No_fields "No fields have been sent");
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.update_book connection book id
  in
  if Result.is_ok result then empty `No_Content
  else raise @@ Result.get_error result

let delete : routeHandler =
 fun req ->
  let id = id_validator req in
  let%lwt result =
    let%lwt connection = Database.create_connection () in
    let connection = unwrap_or_raise connection in
    Database.delete_book connection id
  in
  if Result.is_ok result then empty `No_Content
  else raise @@ Result.get_error result
