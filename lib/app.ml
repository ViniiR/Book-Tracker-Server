open Dream

let authenticator handler req =
  let is_valid username password =
    let get_env name =
      try Sys.getenv name
      with _ -> raise (Lib_types.Db.Errors.Missing_env_variable ("$" ^ name))
    in
    let name = get_env "AUTH_USERNAME" in
    let pass = get_env "AUTH_PASSWORD" in
    username = name && password = pass
  in
  match Dream.header req "authorization" with
  | Some auth ->
      if String.starts_with ~prefix:"Basic " auth then
        let encoded = String.sub auth 6 (String.length auth - 6) in
        match Base64.decode encoded with
        | Ok credentials -> (
            match String.split_on_char ':' credentials with
            | [ username; password ] when is_valid username password ->
                handler req
            | _ -> respond ~status:`Unauthorized "Invalid credentials")
        | Error _ -> respond ~status:`Unauthorized "Invalid credentials"
      else respond ~status:`Unauthorized "Invalid authorization header encoding"
  | None -> respond ~status:`Unauthorized "No authorization provided"

(* INFO: No_Content does not deliver strings *)

(** Universal error handler *)
let error_handler handler req =
  let module DbError = Lib_types.Db.Errors in
  let module BookError = Lib_types.Book.Errors in
  try%lwt handler req with
  | BookError.Invalid_id msg -> respond ~status:`Bad_Request msg
  | BookError.Invalid_json msg -> respond ~status:`Bad_Request msg
  | BookError.Incorrect_type msg -> respond ~status:`Bad_Request msg
  | BookError.Missing_field msg -> respond ~status:`Bad_Request msg
  | BookError.No_fields msg -> respond ~status:`Bad_Request msg
  (* *)
  | DbError.Failed_database_connection msg ->
      respond ~status:`Internal_Server_Error msg
  | DbError.Failed_pool_creation msg ->
      respond ~status:`Internal_Server_Error msg
  | DbError.Failed_pool_connection msg ->
      respond ~status:`Internal_Server_Error msg
  | DbError.Missing_env_variable msg ->
      Printf.eprintf "Missing: %s\n" msg;
      Stdlib.flush stderr;
      respond ~status:`Internal_Server_Error
        ("Could not find environment variable" ^ msg)
  | DbError.Failed_to_fetch msg -> respond ~status:`Not_Found msg
  | DbError.Failed_to_create msg -> respond ~status:`Internal_Server_Error msg
  | DbError.Failed_to_update msg -> respond ~status:`Internal_Server_Error msg
  | DbError.Failed_to_delete msg -> respond ~status:`Internal_Server_Error msg
  | DbError.Update_on_incorrect msg -> respond ~status:`Bad_Request msg
  | DbError.Update_on_nonexistent msg -> respond ~status:`Bad_Request msg
  | DbError.Delete_on_incorrect msg -> respond ~status:`Bad_Request msg
  | DbError.Delete_on_nonexistent msg -> respond ~status:`Bad_Request msg

let with_pool pool =
 fun handler req ->
  Dream.set_field req Lib_types.Db.pool_field pool;
  handler req

let pool = Database.Pool.create

let app =
  error_handler @@ authenticator @@ with_pool pool @@ Dream.logger
  @@ Dream.router
       [
         (*
            NOTE: raising errors inside routes is intentional,
            they then should be handled by the error_handler.
            All of them, without exception.
         *)
         (* Book *)
         Dream.get "/books" (fun req -> Book.get_all req);
         Dream.get "/book/:id" (fun req -> Book.get req);
         Dream.post "/book" (fun req -> Book.post req);
         Dream.put "/book/:id" (fun _ -> Dream.empty `Method_Not_Allowed);
         Dream.patch "/book/:id" (fun req -> Book.patch req);
         Dream.delete "/book/:id" (fun req -> Book.delete req);
         (* Root *)
         Dream.get "/" (fun _ ->
             Root.render ~text:"We do not serve HTML ;)" |> Dream.html);
         Dream.any "/**" (fun _ ->
             Not_found.render |> Dream.html ~status:`Not_Found);
       ]
