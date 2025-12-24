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
    let kind =
      match member "kind" json with
      | `String v -> v
      | _ -> raise (Errors.Incorrect_type "Expected JSON type String")
    in
    let on_hiatus =
      match member "on_hiatus" json with
      | `Bool v -> v
      | _ -> raise (Errors.Incorrect_type "Expected JSON type Bool")
    in
    let is_finished =
      match member "is_finished" json with
      | `Bool v -> v
      | _ -> raise (Errors.Incorrect_type "Expected JSON type Bool")
    in
    (title, chapter, cover_image, kind, on_hiatus, is_finished)
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
    let kind_opt =
      match member "kind" json with
      | `String v -> Some v
      | `Null -> None
      | _ -> raise (Errors.Incorrect_type "Expected JSON type String")
    in
    let on_hiatus_opt =
      match member "on_hiatus" json with
      | `Bool v -> Some v
      | `Null -> None
      | _ -> raise (Errors.Incorrect_type "Expected JSON type Bool")
    in
    let is_finished_opt =
      match member "is_finished" json with
      | `Bool v -> Some v
      | `Null -> None
      | _ -> raise (Errors.Incorrect_type "Expected JSON type Bool")
    in
    {
      title_opt;
      chapter_opt;
      cover_image_opt;
      kind_opt;
      on_hiatus_opt;
      is_finished_opt;
    }
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
      ("kind", `String book.kind);
      ("on_hiatus", `Bool book.on_hiatus);
      ("is_finished", `Bool book.is_finished);
    ]

let json_of_book_list (list : book list) : Yojson.Safe.t =
  `List (List.map (fun book -> json_of_book book) list)
