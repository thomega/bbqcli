(* bbqcli.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"

let my_name = Sys.argv.(0)

let separator = String.make 72 '='

let print_json j =
  Yojson.Basic.pretty_to_string j |> print_endline

type mode =
  | Data
  | Info
  | Settings
  | Temp of int
  | Temps
  | Battery
  | Range of string

let _ =
  let mode = ref Settings in
  let channel = ref 1 in
  let usage = "usage: " ^ my_name ^ " ..." in
  let options =
    Arg.align
      [ ("-c", Arg.Int (fun ch -> channel := ch),     "channel select channel");
        ("-d", Arg.Unit (fun () -> mode := Data),     " get the /data");
        ("-i", Arg.Unit (fun () -> mode := Info),     " get the /info");
        ("-r", Arg.String (fun r -> mode := Range r), "range set temperature range");
        ("-s", Arg.Unit (fun () -> mode := Settings), " get the /settings");
        ("-t", Arg.Int (fun ch -> mode := Temp ch),   "channel get the temperature");
        ("-T", Arg.Unit (fun () -> mode := Temps),    " get all temperatures");
        ("-b", Arg.Unit (fun () -> mode := Battery),  " get the battery status");
        ] in
  Arg.parse options (fun s -> raise (Arg.Bad ("invalid argument: " ^ s))) usage;
  let open ThoCurl in
  let open WLANThermo in
  try
    match !mode with
    | Info -> get "info" |> print_endline
    | Data -> get_json "data" |> print_json
    | Settings -> get_json "settings" |> print_json
    | Temp ch -> print_temperature ch
    | Temps -> print_temperatures ()
    | Battery -> print_battery ()
    | Range r -> set_channel_range !channel r
  with
  | ThoCurl.Invalid_JSON (msg, s) ->
     Printf.printf "Invalid JSON:\n%s\n%s\n%s\n%s\n" msg separator s separator

