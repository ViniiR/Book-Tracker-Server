open Lib

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
  |> Dream.run ~port:5001
