open! Lib_types.Book

let create_book_of_json str : Lib_types.Book.create_book =
  let open! Yojson.Basic in
  let open! Yojson.Basic.Util in
  try
    let json = from_string str in
    let title =
      match member "title" json with
      | `String v -> v
      | _ -> raise (Errors.Incorrect_type "Expected JSON type String")
    in
    let chapter =
      match member "chapter" json with
      | `Float v -> v
      | _ -> raise (Errors.Incorrect_type "Expected JSON type Float")
    in
    let cover_image =
      match member "cover_image" json with
      | `String v -> v
      | _ -> raise (Errors.Incorrect_type "Expected JSON type String")
    in
    (title, chapter, cover_image)
  with
  | Yojson.Json_error e ->
      Printf.eprintf "%s" e;
      Stdlib.flush stderr;
      raise (Errors.Invalid_json "JSON is not valid")
  | Yojson.Basic.Util.Type_error (msg, _) (* _ will usually be null *) ->
      Printf.eprintf "\nError: %s\n" msg;
      Stdlib.flush stderr;
      raise (Errors.Invalid_json "JSON is not valid")

let patch_book_of_json str : Lib_types.Book.patch_book =
  let open! Yojson.Basic in
  let open! Yojson.Basic.Util in
  try
    let json = from_string str in
    let title_opt =
      match member "title" json with
      | `String v -> Some v
      | `Null -> None
      | _ -> raise (Errors.Incorrect_type "Expected JSON type String")
    in
    let chapter_opt =
      match member "chapter" json with
      | `Float v -> Some v
      | `Null -> None
      | _ -> raise (Errors.Incorrect_type "Expected JSON type Float")
    in
    let cover_image_opt =
      match member "cover_image" json with
      | `String v -> Some v
      | `Null -> None
      | _ -> raise (Errors.Incorrect_type "Expected JSON type String")
    in
    { title_opt; chapter_opt; cover_image_opt }
  with
  | Yojson.Json_error e ->
      Printf.eprintf "%s" e;
      Stdlib.flush stderr;
      raise (Errors.Invalid_json "JSON is not valid")
  | Yojson.Basic.Util.Type_error (msg, _) (* _ will usually be null *) ->
      Printf.eprintf "\nError: %s\n" msg;
      Stdlib.flush stderr;
      raise (Errors.Invalid_json "JSON is not valid")

let json_of_book (book : book) : Yojson.Safe.t =
  `Assoc
    [
      ("title", `String book.title);
      ("chapter", `Float book.chapter);
      ("cover_image", `String book.cover_image);
      ("id", `Int book.id);
      (* JSON does not support bigints(64 bit) *)
      ("last_modified", `String (Int64.to_string book.last_modified));
    ]

let json_of_book_list (list : book list) : Yojson.Safe.t =
  `List (List.map (fun book -> json_of_book book) list)

(* let input_book_of_json (json_str : string) : input_book = *)
(*   let open! Yojson.Basic in *)
(*   let open! Yojson.Basic.Util in *)
(*   try *)
(*     let json = Yojson.Basic.from_string json_str in *)
(*     { *)
(*       title_opt = *)
(*         (match member "title" json with *)
(*         | `Null -> None *)
(*         | `String v -> Some v *)
(*         | _ -> raise (Errors.Incorrect_type "Expected JSON type String")); *)
(*       chapter_opt = *)
(*         (match member "chapter" json with *)
(*         | `Null -> None *)
(*         | `Float v -> Some v *)
(*         | _ -> raise (Errors.Incorrect_type "Expected JSON type Float")); *)
(*       cover_image_opt = *)
(*         (match member "cover_image" json with *)
(*         | `Null -> None *)
(*         | `String v -> Some v *)
(*         | _ -> raise (Errors.Incorrect_type "Expected JSON type String")); *)
(*     } *)
(*   with *)
(*   | Yojson.Json_error e -> *)
(*       Printf.eprintf "%s" e; *)
(*       Stdlib.flush stderr; *)
(*       raise (Errors.Invalid_json "JSON is not valid") *)
(*   | Yojson.Basic.Util.Type_error (msg, _) (* _ will usually be null *) -> *)
(*       Printf.eprintf "\nError: %s\n" msg; *)
(*       Stdlib.flush stderr; *)
(*       raise (Errors.Invalid_json "JSON is not valid") *)
(**)
(* let book_of_input_book book id = *)
(*   Lib_types.Book. *)
(*     { *)
(*       title = *)
(*         (match book.title_opt with *)
(*         | Some v -> v *)
(*         | _ -> raise (Lib_types.Book.Errors.Missing_field "Missing field title")); *)
(*       chapter = *)
(*         (match book.chapter_opt with *)
(*         | Some v -> v *)
(*         | _ -> *)
(*             raise (Lib_types.Book.Errors.Missing_field "Missing field chapter")); *)
(*       cover_image = *)
(*         (match book.cover_image_opt with *)
(*         | Some v -> v *)
(*         | _ -> *)
(*             raise *)
(*               (Lib_types.Book.Errors.Missing_field "Missing field cover_image")); *)
(*       id (* Send mock id since it may not be used *); *)
(*       last_modified = Unix.time (); *)
(*     } *)
