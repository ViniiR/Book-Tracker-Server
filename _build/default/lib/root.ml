#1 "lib/root.eml.html"
let render ~text =

let ___eml_buffer = Buffer.create 4096 in
(Buffer.add_string ___eml_buffer "<!DOCTYPE html>\n<html lang=\"en\">\n\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Document</title>\n    <!-- <script defer src=\"./root.js\"></script> -->\n</head>\n\n<body>\n    <main>\n        ");
(Printf.bprintf ___eml_buffer "%s" (Dream.html_escape (
#15 "lib/root.eml.html"
            text 
)));
(Buffer.add_string ___eml_buffer "\n    </main>\n</body>\n\n</html>\n");
(Buffer.contents ___eml_buffer)
