(* wlanthermo.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"

let my_name = Sys.argv.(0)

let separator = String.make 72 '='

let print_json s =
  try
    let j = Yojson.Basic.from_string s in
    Format.printf "%s\n" (Yojson.Basic.pretty_to_string j)
  with
  | Yojson.Json_error msg ->
     Format.printf "Invalid JSON:\n%s\n%s\n%s\n%s\n" msg separator s separator

let temperatures data =
  let open Yojson.Basic.Util in
  let channel_list = data |> member "channel" |> to_list in
  List.fold_left
    (fun acc channel ->
      let temp = member "temp" channel |> to_float in
      if temp < 999.0 then
        (member "number" channel |> to_int, temp) :: acc
      else
        acc)
    [] channel_list

let temperature_opt data channel =
  List.assoc_opt channel (temperatures data)

type mode =
  | Data
  | Info
  | Settings
  | Temp of int
  | Temps

let curl = ThoCurl.request
let json = Yojson.Basic.from_string

let _ =
  let open Printf in
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
        ("-t", Arg.Int (fun ch -> mode := Temp ch),
         "channel get the temperature");
        ("-T", Arg.Unit (fun () -> mode := Temps),
         "get the temperatures");
        ] in
  Arg.parse options (fun s -> raise (Arg.Bad ("invalid argument: " ^ s))) usage;
  match !mode with
  | Data -> print_json (curl "data")
  | Info -> print_endline (curl "info")
  | Settings -> print_json (curl "settings")
  | Temp ch ->
     let data = json (curl "data") in
     begin match temperature_opt data ch with
     | None -> printf "channel #%d: disconneted\n" ch
     | Some t -> printf "channel #%d: %5.1f deg Celsius\n" ch t
     end
  | Temps ->
     let data = json (curl "data") in
     List.iter
       (fun (ch, t) -> printf "channel #%d: %5.1f deg Celsius\n" ch t)
       (List.sort compare (temperatures data))
