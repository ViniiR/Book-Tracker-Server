module Json = struct
  let valid =
    {|
      {
        "title": "test",
        "chapter": 2.5,
        "cover_image": ""
      }
    |}

  let valid_patch =
    {|
      {
        "title": "patch_test",
        "chapter": 2.5
      }
    |}

  let wrong_type =
    {|
      {
        "title": "test",
        "chapter": "2.5",
        "cover_image": "" 
      }
    |}

  let missing_field =
    {|
      {
        "title": "test",
        "chapter": "2.5"
      }
    |}

  let invalid_syntax =
    {|
      {
        "title": "test"
        "chapter": 2.5
        "chapter": "2.5",
      }
    |}
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
      }

  let create_book = Lib.Lib_types.Book.("test", 1.0, "")

  let patch_book =
    Lib.Lib_types.Book.
      {
        title_opt = Some "test";
        chapter_opt = Some 2.0;
        cover_image_opt = None;
      }
end
