open Lib

let () =
  (* let open Dream in *)
  Dream.logger
  @@ Dream.router
       [
         (* NOTE: raising errors inside routes is intentional,
            they then should be handled by route_error_handler.
         *)
         (* Book *)
         Dream.get "/books" (fun req ->
             Book.route_error_handler req Book.get_all);
         Dream.get "/book/:id" (fun req ->
             Book.route_error_handler req Book.get);
         Dream.post "/book" (fun req -> Book.route_error_handler req Book.post);
         (* Dream.put "/book/:id" (fun req -> Book.put req); *)
         (* Dream.patch "/book/:id" (fun req -> Book.patch req); *)
         (* Dream.delete "/book/:id" (fun req -> Book.delete req); *)
         (* Root *)
         Dream.get "/" (fun _ ->
             Root.render ~text:"We do not serve HTML ;)" |> Dream.html);
         Dream.any "/**" (fun _ -> Not_found.render |> Dream.html);
       ]
  |> Dream.run ~port:5001
