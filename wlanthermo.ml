(* wlanthermo.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"

let my_name = Sys.argv.(0)

let separator = String.make 72 '='

let print_json s =
  try
    let json = Yojson.Safe.from_string s in
    Format.printf "%s\n" (Yojson.Safe.pretty_to_string json)
  with
  | Yojson.Json_error msg ->
     Format.printf "Invalid JSON:\n%s\n%s\n%s\n%s\n" msg separator s separator

type mode =
  | Data
  | Info
  | Settings

let _ =
  let mode = ref Settings in
  let usage =
    "usage: " ^ my_name ^ " ..." in
  let options =
    Arg.align
      [ ("-d", Arg.Unit (fun () -> mode := Data),
         " get the /data");
        ("-i", Arg.Unit (fun () -> mode := Info),
         " get the /info");
        ("-s", Arg.Unit (fun () -> mode := Settings),
         " get the /settings");
        ] in
  Arg.parse options (fun s -> raise (Arg.Bad ("invalid argument: " ^ s))) usage;
  match !mode with
  | Data -> print_json (ThoCurl.request "data")
  | Info -> print_json (ThoCurl.request "info")
  | Settings -> print_json (ThoCurl.request "settings")
