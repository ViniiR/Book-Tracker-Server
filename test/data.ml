module Json = struct
  let valid_create =
    {|
      {
        "title": "test",
        "chapter": 2.5,
        "cover_image": "",
        "kind": "book",
        "on_hiatus": false,
        "is_finished": false
      }
    |}

  let invalid_create = {|
      {
        "title": "test"
      }
    |}

  let valid_patch =
    {|
      {
        "title": "patch_test",
        "chapter": 2.5
      }
    |}

  let invalid_patch = {|
      {}
    |}

  (* let wrong_type = *)
  (*   {| *)
  (*     { *)
  (*       "title": "test", *)
  (*       "chapter": "2.5", *)
  (*       "cover_image": ""  *)
  (*     } *)
  (*   |} *)
  (**)
  (* let missing_field = *)
  (*   {| *)
  (*     { *)
  (*       "title": "test", *)
  (*       "chapter": "2.5" *)
  (*     } *)
  (*   |} *)
  (**)
  (* let invalid_syntax = *)
  (*   {| *)
  (*     { *)
  (*       "title": "test" *)
  (*       "chapter": 2.5 *)
  (*       "chapter": "2.5", *)
  (*     } *)
  (*   |} *)
end

module Headers = struct
  let authorization =
    ("Authorization", "Basic " ^ Base64.encode_string "dev:developmentpassword")
end

module Book = struct
  let output =
    Lib.Lib_types.Book.
      {
        title = "test";
        chapter = 1.0;
        cover_image = "";
        id = 1;
        last_modified = Int64.of_int 1_000_000;
        kind = "book";
        on_hiatus = false;
        is_finished = false;
      }

  let create_book = Lib.Lib_types.Book.("test", 1.0, "", "book", false, false)

  let patch_book =
    Lib.Lib_types.Book.
      {
        title_opt = Some "test";
        chapter_opt = Some 2.0;
        cover_image_opt = None;
        kind_opt = Some "book";
        on_hiatus_opt = None;
        is_finished_opt = None;
      }
end
