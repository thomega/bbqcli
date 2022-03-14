(* WLANThermo.ml -- WLANThermo API *)

open Printf

module Alarm =
  struct

    (* We could just as well have used bitarithmetic. *)

    type t =
      { push : bool;
        buzzer : bool }

    let to_int = function
      | { push = false; buzzer = false } -> 0
      | { push = true; buzzer = false } -> 1
      | { push = false; buzzer = true } -> 2
      | { push = true; buzzer = true } -> 3

    let format = function
      | { push = false; buzzer = false } -> "off"
      | { push = true; buzzer = false } -> "push"
      | { push = false; buzzer = true } -> "buzzer"
      | { push = true; buzzer = true } -> "push and buzzer"

    let of_int = function
      | 0 -> { push = false; buzzer = false }
      | 1 -> { push = true; buzzer = false }
      | 2 -> { push = false; buzzer = true }
      | 3 -> { push = true; buzzer = true }
      | n -> invalid_arg ("WLANThermo.alarm_of_int: " ^ string_of_int n)

    let on = { push = true; buzzer = true }
    let off = { push = false; buzzer = false }
    let push_on alarm = { alarm with push = true }
    let push_off alarm = { alarm with push = false }
    let buzzer_on alarm = { alarm with buzzer = true }
    let buzzer_off alarm = { alarm with buzzer = false }

  end

module Color =
  struct

    type t =
      { red : int;
        green : int;
        blue : int }

    let clamp_channel c =
      min (max c 0) 255

    let to_string c =
      Printf.sprintf
        "#%02X%02X%02X"
        (clamp_channel c.red)
        (clamp_channel c.green)
        (clamp_channel c.blue)
  end

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

let print_temperature ?ssl ~host ch =
  let data = get_json ?ssl ~host "data" in
  begin match temperature_opt data ch with
  | None -> printf "channel #%d: disconnected\n" ch
  | Some t -> format_temperature t |> print_endline
  end

let print_temperatures ?ssl ~host () =
  let data = get_json ?ssl ~host "data" in
  List.iter
    (fun t -> format_temperature t |> print_endline)
    (List.sort (fun t1 t2 -> compare t1.channel t2.channel) (temperatures data))

let print_battery ?ssl ~host () =
  let data = get_json ?ssl ~host "data" in
  let open Yojson.Basic.Util in
  let system = data |> member "system" in
  let percentage = system |> member "soc" |> to_int
  and charging = system |> member "charge" |> to_bool in
  printf
    "battery %3d%% %s\n"
    percentage
    (if charging then "(charging)" else "(not charging)")

module Channel_Mod =
  struct

    type t  =
      { number : int;
        name : string option;
        (* typ : integer option; *)
        (* at the moment it's always 0 for channel 1-8 and 15 for channel 9 *)
        min : float option;
        max : float option;
        alarm : Alarm.t option;
        color : Color.t option }

    let unchanged ch =
      { number = ch;
        name = None;
        min = None;
        max = None;
        alarm = None;
        color = None }

    let int_to_json name n = [ name, `Int n ]
    let float_to_json name x = [ name, `Float x ]
    let string_to_json name s = [ name, `String s ]
    let alarm_to_json name a = [ name, `Int (Alarm.to_int a) ]
    let color_to_json name c = [ name, `String (Color.to_string c) ]

    let option_to_json f name = function
      | None -> []
      | Some v -> f name v

    let int_option_to_json = option_to_json int_to_json
    let float_option_to_json = option_to_json float_to_json
    let string_option_to_json = option_to_json string_to_json
    let alarm_option_to_json = option_to_json alarm_to_json
    let color_option_to_json = option_to_json color_to_json

    let to_json ch =
      `Assoc ( int_to_json "number" ch.number
               @ string_option_to_json "name" ch.name
               @ float_option_to_json "min" ch.min
               @ float_option_to_json "max" ch.max
               @ alarm_option_to_json "alarm" ch.alarm
               @ color_option_to_json "color" ch.color )

    let min_max ch min max =
      let channel = unchanged ch in
      to_json { channel with min = Some min; max = Some max }

    let min ch min =
      let channel = unchanged ch in
      to_json { channel with min = Some min }

    let max ch max =
      let channel = unchanged ch in
      to_json { channel with max = Some max }

  end

(* "PATCH" doesn't appear to work, but "POST" works even with
   incomplete records. *)

let set_channel_range ?ssl ~host ch (min, max) =
  let command = Channel_Mod.min_max ch min max in
  let open Yojson.Basic.Util in
  match post_json ?ssl ~host "setchannels" command with
  | `Bool true -> ()
  | `Bool false -> failwith "response: false"
  | response ->
     failwith ("unexpected: " ^ Yojson.Basic.to_string response)
