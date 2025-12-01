open Lib

let () =
  Dream.logger
  @@ Dream.router
       [
         (* Book *)
         Dream.get "/book/:id" Book.get;
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
