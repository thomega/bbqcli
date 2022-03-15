(* WLANThermo.ml -- WLANThermo API *)

open Printf

module type Alarm =
  sig
    type t
    val none : t
    val push : t
    val buzzer : t
    val all : t
    val to_int : t -> int
    val of_int : int -> t
    val is_on : t -> t -> bool
    val switch_on : t -> t -> t
    val format : t -> string
  end

module Alarm : Alarm =
  struct

    type t = int
    let none = 0
    let push = 1
    let buzzer = 2
    let all = push lor buzzer

    let to_int a = a

    let of_int n =
      if 0 <= n && n <= 3 then
        n
      else
        invalid_arg ("WLANThermo.alarm_of_int: " ^ string_of_int n)

    let is_on which a =
      (a land which) <> 0

    let switch_on which a =
      a lor which

    let switch_off which a =
      a land (lnot which)

    (* A bit artificial, but always 4 characters. *)
    let format a =
      match is_on push a, is_on buzzer a with
      | false, false -> "none"
      | true, false -> "push"
      | false, true -> "buzz"
      | true, true -> "both"

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

    let of_string s =
      Scanf.sscanf s "#%02X%02X%02X" (fun red green blue -> { red; green; blue })

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

module Channel =
  struct

    type t =
      { channel : int;
        name : string;
        typ: int;
        t : float option;
        t_min : float;
        t_max : float;
        alarm : Alarm.t;
        color : Color.t;
        fixed : bool;
        connected : bool }

    let of_json ch =
      let open Yojson.Basic.Util in
      let t =
        let temp = ch |> member "temp" |> to_float in
        if temp < 999.0 then
          Some temp
        else
          None in
      { channel = ch |> member "number" |> to_int;
        name =  ch |> member "name" |> to_string;
        typ = ch |> member "typ" |> to_int;
        t;
        t_min = ch |> member "min" |> to_float;
        t_max = ch |> member "max" |> to_float;
        alarm = ch |> member "alarm" |> to_int |> Alarm.of_int;
        color = ch |> member "color" |> to_string |> Color.of_string;
        fixed = ch |> member "fixed" |> to_bool;
        connected = ch |> member "connected" |> to_bool }

    let format ch =
      let interval = sprintf "[%5.1f,%5.1f]" ch.t_min ch.t_max in
      match ch.t with
      | None -> sprintf "channel #%d: inactive  %s" ch.channel interval
      | Some t ->
         let value =
           sprintf "channel #%d: %5.1f deg" ch.channel t in
         if ch.t_max < ch.t_min then
           value ^ " ?? " ^ interval ^ " is inverted!"
         else if t < ch.t_min then
           value ^ " << " ^ interval
         else if t > ch.t_max then
           value ^ " >> " ^ interval
         else
           value ^ " in " ^ interval

  end

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
