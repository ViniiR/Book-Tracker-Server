open Dream

let id = "id"

module Types = struct
  type book = { title : string; chapter : float; cover_image : int32 list }
  type routeHandler = request -> response promise

  module Errors = struct
    exception InvalidId of string
  end
end

let id_validator (req : request) : int =
  match int_of_string_opt @@ param req id with
  | Some n -> n
  | None -> raise @@ Types.Errors.InvalidId "Invalid Book Id"

(** Book HTTP::GET handler *)
let get : Types.routeHandler =
 fun _req ->
  try
    let id = id_validator _req in
    html @@ string_of_int id
  with
  | Types.Errors.InvalidId _msg -> respond ~status:`Bad_Request _msg
  | _ -> respond ~status:`Internal_Server_Error "Unknown Error"

let post (_req : request) : response promise = empty `No_Content
let put (_req : request) : response promise = empty `No_Content
let patch (_req : request) : response promise = empty `No_Content
let delete (_req : request) : response promise = empty `No_Content
