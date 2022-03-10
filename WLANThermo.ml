(* WLANThermo.ml -- WLANThermo API *)

open Printf

let temperatures data =
  let open Yojson.Basic.Util in
  let channel_list = data |> member "channel" |> to_list in
  List.fold_left
    (fun acc channel ->
      let temp = channel |> member "temp" |> to_float in
      if temp < 999.0 then
        (channel |> member "number" |> to_int, temp) :: acc
      else
        acc)
    [] channel_list

let temperature_opt data channel =
  List.assoc_opt channel (temperatures data)

open ThoCurl
type json = Yojson.Basic.t
let json = Yojson.Basic.from_string

let print_temperature ch =
  let data = get_json "data" in
  begin match temperature_opt data ch with
  | None -> printf "channel #%d: disconneted\n" ch
  | Some t -> printf "channel #%d: %5.1f deg Celsius\n" ch t
  end

let print_temperatures () =
  let data = get_json "data" in
  List.iter
    (fun (ch, t) -> printf "channel #%d: %5.1f deg Celsius\n" ch t)
    (List.sort compare (temperatures data))

let print_battery () =
  let data = get_json "data" in
  let open Yojson.Basic.Util in
  let system = data |> member "system" in
  let percentage = system |> member "soc" |> to_int
  and charging =  system |> member "charge" |> to_bool in
  printf
    "battery %3d%% %s\n"
    percentage
    (if charging then "(charging)" else "(not charging)")

type alarm =
  | Silent
  | Push
  | Buzzer
  | Push_and_Buzzer

let alarm_to_int = function
  | Silent -> 0
  | Push -> 1
  | Buzzer -> 2
  | Push_and_Buzzer -> 3

type color =
  { red : int;
    green : int;
    blue : int }

let clamp_channel c =
  min (max c 0) 255

let color_to_string c =
  Printf.sprintf
    "#%02X%02X%02X"
    (clamp_channel c.red)
    (clamp_channel c.green)
    (clamp_channel c.blue)

type channel  =
  { number : int;
    name : string option;
    (* typ : integer option; *)
    (* at the moment it's always 0 for channel 1-8 and 15 for channel 9 *)
    min : float option;
    max : float option;
    alarm : alarm option;
    color : color option }

let int_to_json name n = [ name, `Int n ]
let float_to_json name x = [ name, `Float x ]
let string_to_json name s = [ name, `String s ]
let alarm_to_json name a = [ name, `Int (alarm_to_int a) ]
let color_to_json name c = [ name, `String (color_to_string c) ]

let option_to_json f name = function
  | None -> []
  | Some v -> f name v

let int_option_to_json = option_to_json int_to_json
let float_option_to_json = option_to_json float_to_json
let string_option_to_json = option_to_json string_to_json
let alarm_option_to_json = option_to_json alarm_to_json
let color_option_to_json = option_to_json color_to_json

let channel_to_json ch =
  `Assoc ( int_to_json "number" ch.number
           @ string_option_to_json "name" ch.name
           @ float_option_to_json "min" ch.min
           @ float_option_to_json "max" ch.max
           @ alarm_option_to_json "max" ch.alarm
           @ color_option_to_json "max" ch.color )

let channel_min_max ch min max : json =
  `Assoc [ "number", `Int ch;
           "min", `Float min;
           "max", `Float max ]

let channel_min ch min : json =
  `Assoc [ "number", `Int ch;
           "min", `Float min ]

let channel_max ch max : json =
  `Assoc [ "number", `Int ch;
           "max", `Float max ]

(* "PATCH" doesn't appear to work, but "POST" works even with
   incomplete records. *)

let set_channel_max ch max =
  let open Yojson.Basic.Util in
  match post_json "setchannels" (channel_max ch max) with
  | `Bool true -> ()
  | `Bool false -> failwith "response: false"
  | response ->
     failwith ("unexpected: " ^ Yojson.Basic.to_string response)
