open! Dream

module Book = struct
  (* type used to store books in the database *)
  type book = {
    title : string; (* $1 *)
    chapter : float; (* $2 *)
    cover_image : string; (* $3 *)
    id : int; (* $4 *)
    last_modified : int64; (* $5 *)
    kind : string; (* book | manhwa |  manhua | manga *)
    on_hiatus : bool;
    is_finished : bool;
  }
  [@@deriving yojson]

  (* type used to create book from the client *)
  type create_book = string * float * string * string * bool * bool
  [@@deriving yojson]

  (* type used to patch book from the client *)
  (* id is sent separately via route parameter *)
  type patch_book = {
    title_opt : string option;
    chapter_opt : float option;
    cover_image_opt : string option;
    kind_opt : string option;
    on_hiatus_opt : bool option;
    is_finished_opt : bool option;
  }
  [@@deriving yojson]

  type pool = (Caqti_lwt.connection, Caqti_error.t) Caqti_lwt_unix.Pool.t
  type routeHandler = request -> response promise

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

  let pool_field :
      (Caqti_lwt.connection, Caqti_error.t) Caqti_lwt_unix.Pool.t Dream.field =
    Dream.new_field ()

  let caqti_book : Book.book Caqti_type.t =
    let encode (book : Book.book) =
      Ok
        ( book.title,
          book.chapter,
          book.cover_image,
          book.id,
          book.last_modified,
          book.kind,
          book.on_hiatus,
          book.is_finished )
    in
    let decode
        ( title,
          chapter,
          cover_image,
          id,
          last_modified,
          kind,
          on_hiatus,
          is_finished ) =
      Ok
        Book.
          {
            title;
            chapter;
            cover_image;
            id;
            last_modified;
            kind;
            on_hiatus;
            is_finished;
          }
    in
    Caqti_type.(
      custom ~encode ~decode (t8 string float string int int64 string bool bool))

  module Errors = struct
    exception Missing_env_variable of string

    (* NOTE: database connection is the actual Database connection *)
    exception Failed_database_connection of string

    (* NOTE: pool connection is a "result" of (Database connection, caqti error) *)
    exception Failed_pool_connection of string
    exception Failed_pool_creation of string
    exception Failed_to_fetch of string
    exception Failed_to_create of string
    exception Failed_to_update of string
    exception Failed_to_delete of string
    exception Update_on_incorrect of string
    exception Update_on_nonexistent of string
    exception Delete_on_incorrect of string
    exception Delete_on_nonexistent of string
    exception Internal_error of string
  end
end
