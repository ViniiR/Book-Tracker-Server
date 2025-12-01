#1 "lib/not_found.eml.html"
let render =

let ___eml_buffer = Buffer.create 4096 in
(Buffer.add_string ___eml_buffer "<!DOCTYPE html>\n<html lang=\"en\">\n\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Not Found</title>\n    <!-- <script defer src=\"./root.js\"></script> -->\n</head>\n\n<body>\n    make a good 404 page for once\n</body>\n\n</html>\n");
(Buffer.contents ___eml_buffer)
