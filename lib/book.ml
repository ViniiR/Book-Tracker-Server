open Dream
open! Lwt.Infix
open! Lwt.Syntax
open! Lib_types.Book

let id_validator (req : request) =
  match int_of_string_opt @@ param req "id" with
  | Some n when n > 0 -> n
  | None -> raise (Errors.Invalid_id "Invalid Book Id")
  | _ -> raise (Errors.Invalid_id "Id cannot be negative")

let get_pool req =
  let module DbErr = Lib_types.Db.Errors in
  match Dream.field req Lib_types.Db.pool_field with
  | Some c -> c
  | None -> raise (DbErr.Failed_pool_connection "Failed pool connection")

let get_all : routeHandler =
 fun req ->
  let pool = get_pool req in
  let* result = Database.get_all_books pool in
  match result with
  | Ok books ->
      let json_string =
        Yojson.Safe.to_string @@ Lib_parse.json_of_book_list books
      in
      json json_string
  | Error e -> raise e

let get : routeHandler =
 fun req ->
  let id = id_validator req in
  let pool = get_pool req in
  let* result = Database.get_book pool id in
  match result with
  | Ok book ->
      let json_string =
        Yojson.Safe.to_string @@ Lib_parse.json_of_book @@ book
      in
      json json_string
  | Error e -> raise e

let post : routeHandler =
 fun req ->
  let* body = Dream.body req in
  let pool = get_pool req in
  let book : create_book = Lib_parse.create_book_of_json body in
  let* result = Database.create_book pool book in
  match result with Ok _ -> empty `Created | Error e -> raise e

(* NOTE: if id is sent via request.body it will be ignored *)
(* INFO: removed since you never really get to override all the data on the database *)
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
  let validate_input_patch_book book () : bool =
    match book with
    | {
     title_opt = None;
     chapter_opt = None;
     cover_image_opt = None;
     kind_opt = None;
     on_hiatus_opt = None;
     is_finished_opt = None;
    } ->
        true
    | _ -> false
  in
  fun req ->
    let* body = Dream.body req in
    let id = id_validator req in
    let book : patch_book = Lib_parse.patch_book_of_json body in
    let pool = get_pool req in
    if validate_input_patch_book book () then
      raise (Errors.No_fields "No fields have been sent");
    let* result = Database.update_book pool book id in
    match result with Ok _ -> empty `No_Content | Error e -> raise e

let delete : routeHandler =
 fun req ->
  let id = id_validator req in
  let pool = get_pool req in
  let* result = Database.delete_book pool id in
  match result with Ok _ -> empty `No_Content | Error e -> raise e
