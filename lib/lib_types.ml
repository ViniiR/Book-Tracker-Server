open! Dream

module Book = struct
  (* type used to store books in the database *)
  type book = {
    title : string; (* $1 *)
    chapter : float; (* $2 *)
    cover_image : string; (* $3 *)
    id : int; (* $4 *)
    last_modified : int64; (* $5 *)
  }
  [@@deriving yojson]

  (* type used to create book from the client *)
  (* id is sent separately via route parameter *)
  type create_book = string * float * string [@@deriving yojson]

  (* type used to patch book from the client *)
  (* id is sent separately via route parameter *)
  type patch_book = {
    title_opt : string option;
    chapter_opt : float option;
    cover_image_opt : string option;
  }
  [@@deriving yojson]

  type pool = (Caqti_lwt.connection, Caqti_error.t) Caqti_lwt_unix.Pool.t
  type routeHandler = request -> pool -> response promise

  module Errors = struct
    exception Invalid_id of string
    exception Invalid_json of string
    exception Incorrect_type of string
    exception Missing_field of string
    exception No_fields of string
  end
end

module Db = struct
  type pool = Book.pool

  let caqti_book : Book.book Caqti_type.t =
    let encode (book : Book.book) =
      Ok
        (book.title, book.chapter, book.cover_image, book.id, book.last_modified)
    in
    let decode (title, chapter, cover_image, id, last_modified) =
      Ok Book.{ title; chapter; cover_image; id; last_modified }
    in
    Caqti_type.(custom ~encode ~decode (t5 string float string int int64))

  module Errors = struct
    exception Missing_env_variable of string
    exception Failed_database_connection of string
    exception Failed_to_fetch of string
    exception Failed_to_create of string
    exception Failed_to_update of string
    exception Failed_to_delete of string
    exception Update_on_incorrect of string
    exception Update_on_nonexistent of string
    exception Delete_on_incorrect of string
    exception Delete_on_nonexistent of string
  end
end
