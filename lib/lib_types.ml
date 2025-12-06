open! Dream

module Book = struct
  type book = {
    title : string;
    chapter : float;
    cover_image : string;
    id : int;
  }

  type routeHandler = request -> response promise

  module Errors = struct
    exception InvalidId of string
  end
end

module Db = struct
  module Errors = struct
    exception Missing_Env_Variable of string
    exception Failed_Database_Connection of string
    exception Failed_To_Fetch of string
  end
end
