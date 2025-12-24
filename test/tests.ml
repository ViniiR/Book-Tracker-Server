open Alcotest
open Dream
open Lwt.Syntax

module Integration = struct
  let testable_status =
    testable
      (fun fmt s -> Format.pp_print_string fmt (Dream.status_to_string s))
      ( = )

  let setup_database_for_test () =
    let open! Caqti_request.Infix in
    let _ =
      Caqti_lwt_unix.Pool.use
        (fun (module Db : Caqti_lwt.CONNECTION) ->
          let query =
            Caqti_type.(unit ->. unit)
              "TRUNCATE TABLE books RESTART IDENTITY CASCADE"
          in
          Db.exec query ())
        Lib.App.pool
    in
    ()

  let auth_req m u ?body () =
    let body = match body with Some v -> v | None -> "" in
    Dream.test Lib.App.app
      (Dream.request
         ~headers:[ Data.Headers.authorization ]
         ~target:u ~method_:m body)

  let test_get_all_books () =
    let res = auth_req `GET "/books" () in
    check testable_status "Get all books" `OK (Dream.status res)

  let test_get_book () =
    let res = auth_req `GET "/book/1" () in
    check testable_status "Get book" `OK (Dream.status res)

  let test_create_book () =
    let res = auth_req `POST "/book" ~body:Data.Json.valid_create () in
    check testable_status "Create book" `Created (Dream.status res)

  let test_patch_book () =
    let res = auth_req `PATCH "/book/1" ~body:Data.Json.valid_patch () in
    check testable_status "Patch book" `No_Content (Dream.status res)

  let test_delete_book () =
    let res = auth_req `DELETE "/book/1" () in
    check testable_status "Delete book" `No_Content (Dream.status res)

  (* // *)

  let test_unknown_route () =
    let res = auth_req `GET "/unknown" () in
    check testable_status "Unknown" `Not_Found (Dream.status res)

  (* // *)

  (* let bad_test_get_all_books () = *)
  (*   let res = auth_req `GET "/books" () in *)
  (*   check testable_status "Get all books" `OK (Dream.status res) *)

  let bad_test_get_book () =
    let res = auth_req `GET "/book/99" () in
    check testable_status "Get book" `Not_Found (Dream.status res)

  let bad_test_create_book () =
    let res = auth_req `POST "/book" ~body:Data.Json.invalid_create () in
    check testable_status "Create book" `Bad_Request (Dream.status res)

  let bad_test_patch_book () =
    let res = auth_req `PATCH "/book/1" ~body:Data.Json.invalid_patch () in
    check testable_status "Patch book" `Bad_Request (Dream.status res)

  let bad_test_delete_book () =
    let res = auth_req `DELETE "/book/99" () in
    check testable_status "Delete book" `Bad_Request (Dream.status res)
end

module Unit = struct
  open! Yojson.Basic
  open! Yojson.Basic.Util
  open! Yojson.Safe
  open! Yojson.Safe.Util

  let assert_book json () =
    let _title =
      match member "title" json with
      | `String _ -> ()
      | _ -> Alcotest.fail "Expected \"title\" String"
    in
    (match member "chapter" json with
    | `Float _ -> ()
    | _ -> Alcotest.fail "Expected \"chapter\" Float");
    (match member "cover_image" json with
    | `String _ -> ()
    | _ -> Alcotest.fail "Expected \"cover_image\" String");
    (match member "id" json with
    | `Int _ -> ()
    | _ -> Alcotest.fail "Expected \"id\" Int");
    (match member "last_modified" json with
    | `String _ -> ()
    | _ -> Alcotest.fail "Expected \"last_modified\" String (in json)");
    ()

  let test_json_of_book () =
    let json = Lib.Lib_parse.json_of_book Data.Book.output in
    assert_book json ();
    ()

  let test_json_of_book_list () =
    let books = [ Data.Book.output; Data.Book.output ] in
    let json =
      match Lib.Lib_parse.json_of_book_list books with
      | `List l -> l
      | _ -> Alcotest.fail "Expected JSON to be `List"
    in
    List.iter (fun book -> assert_book book ()) json;
    ()

  let test_create_book_of_json () =
    let open! Yojson.Safe in
    let open! Yojson.Safe.Util in
    let json =
      let title, chapter, cover_image, kind, on_hiatus, is_finished =
        Data.Book.create_book
      in
      Yojson.Safe.to_string
      @@ `Assoc
           [
             ("title", `String title);
             ("chapter", `Float chapter);
             ("cover_image", `String cover_image);
             ("kind", `String kind);
             ("on_hiatus", `Bool on_hiatus);
             ("is_finished", `Bool is_finished);
           ]
    in
    let book = Lib.Lib_parse.create_book_of_json json in
    if book = Data.Book.create_book then ()
    else Alcotest.fail "Expected create_book to be identical to input"

  let test_patch_book_of_json () =
    let book = Data.Book.patch_book in
    let json =
      let arr : (string * Yojson.Safe.t) array ref = ref [||] in
      if Option.is_some book.title_opt then
        arr :=
          Array.append !arr [| ("title", `String (Option.get book.title_opt)) |];
      if Option.is_some book.chapter_opt then
        arr :=
          Array.append !arr
            [| ("chapter", `Float (Option.get book.chapter_opt)) |];
      if Option.is_some book.cover_image_opt then
        arr :=
          Array.append !arr
            [| ("cover_image", `String (Option.get book.cover_image_opt)) |];
      if Option.is_some book.kind_opt then
        arr :=
          Array.append !arr [| ("kind", `String (Option.get book.kind_opt)) |];
      if Option.is_some book.on_hiatus_opt then
        arr :=
          Array.append !arr
            [| ("on_hiatus", `Bool (Option.get book.on_hiatus_opt)) |];
      if Option.is_some book.is_finished_opt then
        arr :=
          Array.append !arr
            [| ("is_finished", `Bool (Option.get book.is_finished_opt)) |];
      Yojson.Safe.to_string @@ `Assoc (Array.to_list !arr)
    in
    let book = Lib.Lib_parse.patch_book_of_json json in
    if book = Data.Book.patch_book then ()
    else Alcotest.fail "Expected patch_book to be identical to input"
end

let () =
  let open Integration in
  let open Unit in
  Alcotest.run "requests" (* TODO: add tests with db closed (optional) *)
    [
      ("setup", [ test_case "setup" `Slow setup_database_for_test ]);
      ( "unit",
        [
          test_case "json_of_book" `Quick test_json_of_book;
          test_case "json_of_book_list" `Quick test_json_of_book_list;
          test_case "create_book_of_json" `Quick test_create_book_of_json;
          test_case "patch_book_of_json" `Quick test_patch_book_of_json;
        ] );
      ( "integration",
        [
          (* Good routes *)
          test_case "post" `Slow test_create_book;
          test_case "get-all" `Slow test_get_all_books;
          test_case "get" `Slow test_get_book;
          test_case "patch" `Slow test_patch_book;
          test_case "delete" `Slow test_delete_book;
          (* Bad routes *)
          test_case "unknown" `Slow test_unknown_route;
          (* // *)
          test_case "post-err" `Slow bad_test_create_book;
          test_case "get-err" `Slow bad_test_get_book;
          test_case "patch-err" `Slow bad_test_patch_book;
          test_case "delete-err" `Slow bad_test_delete_book;
        ] );
    ]
