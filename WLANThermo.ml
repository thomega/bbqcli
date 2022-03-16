(* WLANThermo.ml -- WLANThermo API *)

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

module type Color =
  sig
    type t
    val to_string : t -> string
    val of_string : string -> t
  end

module Color : Color =
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

module type System =
  sig
    type t_unit
    type cloud
    type t = private
      { time : int;
        t_unit : t_unit;
        charge : int;
        charging : bool;
        rssi : int;
        cloud : cloud }
    val of_json : Yojson.Basic.t -> t
  end

module System : System =
  struct

    type t_unit =
      | Celsius
      | Fahrenheit

    let t_unit_to_string = function
      | Celsius -> "C"
      | Fahrenheit -> "F"

    let t_unit_of_string = function
      | "C" -> Celsius
      | "F" -> Fahrenheit
      | s -> invalid_arg ("WLANThermo.System.t_unit_of_string: " ^ s)

    type cloud =
      | Disconnected
      | Standby
      | Connected

    let cloud_to_int = function
      | Disconnected -> 0
      | Standby -> 1
      | Connected -> 2

    let cloud_of_int = function
      | 0 -> Disconnected
      | 1 -> Standby
      | 2 -> Connected
      | n -> invalid_arg ("WLANThermo.System.cloud_of_int: " ^ string_of_int n)

    let format_cloud = function
      | Disconnected -> "disc"
      | Standby -> "stby"
      | Connected -> "conn"

    type t =
      { time : int;
        t_unit : t_unit;
        charge : int;
        charging : bool;
        rssi : int;
        cloud : cloud }

    let of_json s =
      let open Yojson.Basic.Util in
      { time = s |> member "time" |> to_string |> int_of_string;
        t_unit = s |> member "unit" |> to_string |> t_unit_of_string;
        charge = s |> member "soc" |> to_int;
        charging = s |> member "charge" |> to_bool;
        rssi = s |> member "rssi" |> to_int;
        cloud = s |> member "online" |> to_int |> cloud_of_int }

  end

module type Temperature =
  sig
    type t = private
      | Inactive
      | Too_low of float
      | Too_high of float
      | In_range of float
    val of_float : float * float -> float -> t
  end

module Temperature : Temperature =
  struct

    type t =
      | Inactive
      | Too_low of float
      | Too_high of float
      | In_range of float

    let of_float (t_min, t_max) t =
      if t_min > t_max then
        invalid_arg
          (Printf.sprintf "WLANThermo.Temperature: inverted range %g > %g" t_min t_max)
      else if t >= 999.0 then
        Inactive
      else if t < t_min then
        Too_low t
      else if t > t_max then
        Too_high t
      else
        In_range t

  end

type switch = On | Off

let switch_to_string = function
  | On -> "on"
  | Off -> "off"

module type Channel =
  sig
    type t = private
      { number : int;
        name : string;
        typ: int;
        t : Temperature.t;
        t_min : float;
        t_max : float;
        alarm : Alarm.t;
        color : Color.t;
        fixed : bool;
        connected : bool }
    val of_json : Yojson.Basic.t -> t
    val is_active : t -> bool
    val member : int -> t list -> bool
    val find_opt : int -> t list -> t option
    val format : t -> string
    val update : ThoCurl.options -> ?all:bool -> int -> float * float -> t list -> unit
  end

module Channel : Channel =
  struct

    type t =
      { number : int;
        name : string;
        typ: int;
        t : Temperature.t;
        t_min : float;
        t_max : float;
        alarm : Alarm.t;
        color : Color.t;
        fixed : bool;
        connected : bool }

    let is_active ch =
      let open Temperature in
      match ch.t with
      | Inactive -> false
      | Too_low _ | Too_high _ | In_range _ -> true

    let member n channels =
      List.exists (fun ch -> ch.number = n) channels

    let find_opt n channels =
      List.find_opt (fun ch -> ch.number = n) channels

    let of_json ch =
      let open Yojson.Basic.Util in
      let temp = ch |> member "temp" |> to_float
      and t_min = ch |> member "min" |> to_float
      and t_max = ch |> member "max" |> to_float in
      { number = ch |> member "number" |> to_int;
        name =  ch |> member "name" |> to_string;
        typ = ch |> member "typ" |> to_int;
        t = Temperature.of_float (t_min, t_max) temp;
        t_min;
        t_max;
        alarm = ch |> member "alarm" |> to_int |> Alarm.of_int;
        color = ch |> member "color" |> to_string |> Color.of_string;
        fixed = ch |> member "fixed" |> to_bool;
        connected = ch |> member "connected" |> to_bool }

    let format ch =
      let open Printf in
      let interval = sprintf "[%5.1f,%5.1f]" ch.t_min ch.t_max
      and temperature =
        match ch.t with
        | Inactive ->           "inactive    "
        | Too_low t ->  sprintf "%5.1f deg <<" t
        | Too_high t -> sprintf "%5.1f deg >>" t
        | In_range t -> sprintf "%5.1f deg in" t in
      sprintf "channel #%d: %s %s" ch.number temperature interval

    type mod_t  =
      { mod_number : int;
        mod_name : string option;
        (* typ : integer option; *)
        (* at the moment it's always 0 for channel 1-8 and 15 for channel 9 *)
        mod_t_min : float option;
        mod_t_max : float option;
        mod_alarm : Alarm.t option;
        mod_color : Color.t option }

    let unchanged ch =
      { mod_number = ch;
        mod_name = None;
        mod_t_min = None;
        mod_t_max = None;
        mod_alarm = None;
        mod_color = None }

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

    let mod_to_json ch =
      `Assoc ( int_to_json "number" ch.mod_number
               @ string_option_to_json "name" ch.mod_name
               @ float_option_to_json "min" ch.mod_t_min
               @ float_option_to_json "max" ch.mod_t_max
               @ alarm_option_to_json "alarm" ch.mod_alarm
               @ color_option_to_json "color" ch.mod_color )

    let min_max ch min max =
      let channel = unchanged ch in
      mod_to_json { channel with mod_t_min = Some min; mod_t_max = Some max }

    let min ch min =
      let channel = unchanged ch in
      mod_to_json { channel with mod_t_min = Some min }

    let max ch max =
      let channel = unchanged ch in
      mod_to_json { channel with mod_t_max = Some max }

    let diff _ch_old _ch_new =
      ()

    (* "PATCH" doesn't appear to work, but "POST" works even with
       incomplete records. *)
    let update options ?(all=false) ch (min, max) channels =
      match find_opt ch channels with
      | None -> ()
      | Some channel ->
         if all || is_active channel then
           let command = min_max ch min max in
           let open Yojson.Basic.Util in
           match ThoCurl.post_json options "setchannels" command with
           | `Bool true -> ()
           | `Bool false -> failwith "response: false"
           | response ->
              failwith ("unexpected: " ^ Yojson.Basic.to_string response)
         else
           ()

  end

module Pitmaster =
  struct

    type t = unit
    let of_json _ = ()
    let to_json _ =
      failwith "WLANThermo.Pitmaster.to_json: not implemented yet"

  end

module Data =
  struct

    type t =
      { system : System.t;
        channels : Channel.t list;
        pitmaster : Pitmaster.t }

    let sort_channels channels =
      let open Channel in
      List.sort (fun ch1 ch2 -> compare ch1.number ch2.number) channels

    let system_of_json data =
      let open Yojson.Basic.Util in
      data |> member "system" |> System.of_json

    let channels_of_json data =
      let open Yojson.Basic.Util in
      data |> member "channel" |> to_list |> List.map Channel.of_json |> sort_channels

    let pitmaster_of_json data =
      let open Yojson.Basic.Util in
      data |> member "pitmaster" |> Pitmaster.of_json

    let of_json data =
      let open Yojson.Basic.Util in
      { system = system_of_json data;
        channels = channels_of_json data;
        pitmaster = pitmaster_of_json data }

    let only_active data =
      { data with channels = List.filter Channel.is_active data.channels }

  end

let format_temperatures ?(all=false) options =
  let filter =
    if all then
      fun l -> l
    else
      List.filter Channel.is_active in
  ThoCurl.get_json options "data" |>
    Data.channels_of_json |> filter |> List.map Channel.format

let format_temperature options ch =
  let channels = ThoCurl.get_json options "data" |> Data.channels_of_json in
  begin match Channel.find_opt ch channels with
  | None -> Printf.sprintf "channel #%d: unavailable" ch
  | Some channel -> Channel.format channel
  end

let info options =
  ThoCurl.get options "info"

let data options =
  ThoCurl.get_json options "data"

let settings options =
  ThoCurl.get_json options "settings"

let format_battery options =
  let system = ThoCurl.get_json options "data" |> Data.system_of_json in
  Printf.sprintf
    "battery %3d%% %s"
    system.charge
    (if system.charging then "(charging)" else "(not charging)")

let update_channel common ?all channels temperature_range _push _beep =
  match temperature_range with
  | None -> ()
  | Some r ->
     let available = data common |> Data.channels_of_json in
     List.iter
       (fun ch -> Channel.update common ?all ch r available)
       channels

