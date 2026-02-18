let () =
  let get_env_or name or_value = try Sys.getenv name with _ -> or_value in
  Lib.App.app
  |> Dream.run
       ~interface:(get_env_or "RUN_HOST" "0.0.0.0")
       ~port:(int_of_string (get_env_or "PORT" "5001"))
