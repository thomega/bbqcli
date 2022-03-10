(* WLANThermo.ml -- WLANThermo API *)

open Printf
let separator = String.make 72 '='

let print_json s =
  try
    let j = Yojson.Basic.from_string s in
    printf "%s\n" (Yojson.Basic.pretty_to_string j)
  with
  | Yojson.Json_error msg ->
     printf "Invalid JSON:\n%s\n%s\n%s\n%s\n" msg separator s separator

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

open ThoCurl
let json = Yojson.Basic.from_string

let print_temperature ch =
  let data = get "data" |> json in
  begin match temperature_opt data ch with
  | None -> printf "channel #%d: disconneted\n" ch
  | Some t -> printf "channel #%d: %5.1f deg Celsius\n" ch t
  end

let print_temperatures () =
  let data = json (get "data") in
  List.iter
    (fun (ch, t) -> printf "channel #%d: %5.1f deg Celsius\n" ch t)
    (List.sort compare (temperatures data))


let print_battery () =
  let data = get "data" |> json in
  let open Yojson.Basic.Util in
  let system = member "system" data in
  let percentage = system |> member "soc" |> to_int
  and charging =  system |> member "charge" |> to_bool in
  printf
    "battery %3d%% %s\n"
    percentage
    (if charging then "(charging)" else "(not charging)")

