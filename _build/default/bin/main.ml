open Lib

(* let error_handler (err : Dream.error) _debug_info (response : Dream.response) = *)
(*   let module DbErr = Database.Types.Errors in *)
(*   let module BookErr = Book.Types.Errors in *)
(*   let log (msg : string) = *)
(*     Printf.eprintf "Error: %s\n" msg; *)
(*     flush stderr *)
(*   in *)
(*   let message, (status : Dream.status) = *)
(*     match err.condition with *)
(*     | `Exn exn -> ( *)
(*         match exn with *)
(*         (* Database *) *)
(*         | DbErr.Failed_Database_Connection msg -> (msg, `Internal_Server_Error) *)
(*         | DbErr.Missing_Env_Variable msg -> (msg, `Internal_Server_Error) *)
(*         | DbErr.Failed_To_Fetch msg -> (msg, `Bad_Request) *)
(*         (* Book routes *) *)
(*         (* | BookErr.InvalidId msg -> (msg, `Bad_Request) *) *)
(*         (* Unhandled *) *)
(*         | _ -> ("Internal Exception", `Internal_Server_Error)) *)
(*     | _ -> ("Internal Error", `Internal_Server_Error) *)
(*   in *)
(*   log message; *)
(*   Dream.set_status response status; *)
(*   Dream.set_body response message; *)
(*   Lwt.return response *)

let () =
  Dream.logger
  @@ Dream.router
       [
         (* NOTE: raising errors inside the routes is intended.
            all errors should be handled by route_error_handler.
         *)
         (* Book *)
         Dream.get "/books" (fun _req ->
             Book.route_error_handler _req Book.get_all);
         Dream.get "/book/:id" (fun _req ->
             Book.route_error_handler _req Book.get);
         Dream.post "/book" (fun _req -> Book.post _req);
         Dream.put "/book/:id" (fun _req -> Book.put _req);
         Dream.patch "/book/:id" (fun _req -> Book.patch _req);
         Dream.delete "/book/:id" (fun _req -> Book.delete _req);
         (* Root *)
         Dream.get "/" (fun _req ->
             Root.render ~text:"We do not serve HTML ;)" |> Dream.html);
         Dream.any "/**" (fun _ -> Not_found.render |> Dream.html);
       ]
  |> Dream.run
       ~port:5001 (*~error_handler:(Dream.error_template error_handler)*)
