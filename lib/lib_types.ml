open! Dream

module Book = struct
  type book = { title : string; chapter : float; cover_image : string }
  [@@deriving yojson]

  type id_book = {
    title : string;
    chapter : float;
    cover_image : string;
    id : int;
  }
  [@@deriving yojson]

  type routeHandler = request -> response promise

  module Errors = struct
    exception Invalid_id of string
    exception Invalid_json of string
    exception Incorrect_type of string
  end
end

module Db = struct
  let caqti_id_book : Book.id_book Caqti_type.t =
    let encode (book : Book.id_book) =
      Ok (book.title, book.chapter, book.cover_image, book.id)
    in
    let decode (title, chapter, cover_image, id) =
      Ok Book.{ title; chapter; cover_image; id }
    in
    Caqti_type.(custom ~encode ~decode (t4 string float string int))

  let caqti_book : Book.book Caqti_type.t =
    let encode (book : Book.book) =
      Ok (book.title, book.chapter, book.cover_image)
    in
    let decode (title, chapter, cover_image) =
      Ok Book.{ title; chapter; cover_image }
    in
    Caqti_type.(custom ~encode ~decode (t3 string float string))

  module Errors = struct
    exception Missing_env_variable of string
    exception Failed_database_connection of string
    exception Failed_to_fetch of string
    exception Failed_to_create of string
    exception Failed_to_change of string
    exception Failed_to_update of string
  end
end
