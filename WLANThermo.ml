(* WLANThermo.ml -- WLANThermo API *)

let host_default = "wlanthermo"

open Printf

type temperature =
  { channel : int;
    t : float;
    t_min : float;
    t_max : float }

let temperatures data =
  let open Yojson.Basic.Util in
  let channel_list = data |> member "channel" |> to_list in
  List.fold_left
    (fun acc channel ->
      let t = channel |> member "temp" |> to_float in
      if t < 999.0 then
        { channel = channel |> member "number" |> to_int;
          t;
          t_min = channel |> member "min" |> to_float;
          t_max = channel |> member "max" |> to_float } :: acc
      else
        acc)
    [] channel_list

let temperature_opt data channel =
  List.find_opt (fun t -> t.channel = channel) (temperatures data)

let format_temperature t =
  let value = sprintf "channel #%d: %5.1f deg" t.channel t.t
  and interval = sprintf "[%5.1f,%5.1f]" t.t_min t.t_max in
  if t.t_max < t.t_min then
    value ^ " ?? " ^ interval ^ " is inverted!"
  else if t.t < t.t_min then
    value ^ " << " ^ interval
  else if t.t > t.t_max then
    value ^ " >> " ^ interval
  else
    value ^ " in " ^ interval

open ThoCurl

let print_temperature ?ssl ?host ch =
  let data = get_json ?ssl ?host "data" in
  begin match temperature_opt data ch with
  | None -> printf "channel #%d: disconnected\n" ch
  | Some t -> format_temperature t |> print_endline
  end

let print_temperatures ?ssl ?host () =
  let data = get_json ?ssl ?host "data" in
  List.iter
    (fun t -> format_temperature t |> print_endline)
    (List.sort (fun t1 t2 -> compare t1.channel t2.channel) (temperatures data))

let print_battery ?ssl ?host () =
  let data = get_json ?ssl ?host "data" in
  let open Yojson.Basic.Util in
  let system = data |> member "system" in
  let percentage = system |> member "soc" |> to_int
  and charging = system |> member "charge" |> to_bool in
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

let plain_channel ch =
  { number = ch;
    name = None;
    min = None;
    max = None;
    alarm = None;
    color = None }

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
           @ alarm_option_to_json "alarm" ch.alarm
           @ color_option_to_json "color" ch.color )

let channel_min_max ch min max =
  let channel = plain_channel ch in
  channel_to_json { channel with min = Some min; max = Some max }

let channel_min ch min =
  let channel = plain_channel ch in
  channel_to_json { channel with min = Some min }

let channel_max ch max =
  let channel = plain_channel ch in
  channel_to_json { channel with max = Some max }

(* "PATCH" doesn't appear to work, but "POST" works even with
   incomplete records. *)

let set_channel_range ?ssl ?host ch range =
  let command =
    begin match String.split_on_char '-' range with
    | [""; ""] -> invalid_arg ("set_channel_range: " ^ range)
    | [min; ""] -> channel_min ch (float_of_string min)
    | [""; max] -> channel_max ch (float_of_string max)
    | [min; max] -> channel_min_max ch (float_of_string min) (float_of_string max)
    | _ -> invalid_arg ("set_channel_range: " ^ range)
    end in
  let open Yojson.Basic.Util in
  match post_json ?ssl ?host "setchannels" command with
  | `Bool true -> ()
  | `Bool false -> failwith "response: false"
  | response ->
     failwith ("unexpected: " ^ Yojson.Basic.to_string response)
