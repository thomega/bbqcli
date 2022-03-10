(* bbqcli.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"

let my_name = Sys.argv.(0)

type mode =
  | Data
  | Info
  | Settings
  | Temp of int
  | Temps
  | Battery

let _ =
  let mode = ref Settings in
  let usage = "usage: " ^ my_name ^ " ..." in
  let options =
    Arg.align
      [ ("-d", Arg.Unit (fun () -> mode := Data),     " get the /data");
        ("-i", Arg.Unit (fun () -> mode := Info),     " get the /info");
        ("-s", Arg.Unit (fun () -> mode := Settings), " get the /settings");
        ("-t", Arg.Int (fun ch -> mode := Temp ch),   "channel get the temperature");
        ("-T", Arg.Unit (fun () -> mode := Temps),    " get the temperatures");
        ("-b", Arg.Unit (fun () -> mode := Battery),  " get the battery status");
        ] in
  Arg.parse options (fun s -> raise (Arg.Bad ("invalid argument: " ^ s))) usage;
  let open ThoCurl in
  let open WLANThermo in
  match !mode with
  | Info -> get "info" |> print_endline
  | Data -> get "data" |> print_json
  | Settings -> get "settings" |> print_json
  | Temp ch -> print_temperature ch
  | Temps -> print_temperatures ()
  | Battery -> print_battery ()
