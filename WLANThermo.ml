(* WLANThermo.ml -- WLANThermo API *)

module JSON = Yojson.Basic

module Info =
  struct

    type t = string

    let get options =
      ThoCurl.get options "info"

  end


module Sensor =
  struct

    type t =
      { typ : int;
        name : string;
        fixed : bool }

    let of_json sensor =
      let open JSON.Util in
      { typ = sensor |> member "type" |> to_int;
        name = sensor |> member "name" |> to_string;
        fixed = sensor |> member "fixed" |> to_bool }

    let name_opt sensors n =
      List.find_opt (fun p -> p.typ = n) sensors

  end        


module Settings =
  struct

    type t =
      { device : unit; (* TODO! *)
        system : unit; (* TODO! *)
        hardware : unit; (* TODO! *)
        api : unit; (* TODO! *)
        sensors : Sensor.t list;
        features : unit; (* TODO! *)
        pid : unit; (* TODO! *)
        aktor : unit; (* TODO! *)
        display : unit; (* TODO! *)
        iot : unit; (* TODO! *) }

    let get_json options =
      ThoCurl.get_json options "settings"

    let sensors_of_json settings =
      let open JSON.Util in
      settings |> member "sensors" |> to_list |> List.map Sensor.of_json

    let of_json settings =
      { device = (); (* TODO! *)
        system = (); (* TODO! *)
        hardware = (); (* TODO! *)
        api = (); (* TODO! *)
        sensors = sensors_of_json settings;
        features = (); (* TODO! *)
        pid = (); (* TODO! *)
        aktor = (); (* TODO! *)
        display = (); (* TODO! *)
        iot = () (* TODO! *) }
      
  end


module type Alarm =
  sig
    type t
    val none : t
    val push : t
    val beep : t
    val all : t
    val to_int : t -> int
    val of_int : int -> t
    val is_on : t -> t -> bool
    val switch_on : t -> t -> t
    val switch_off : t -> t -> t
    val format : t -> string
  end

module Alarm : Alarm =
  struct

    type t = int
    let none = 0
    let push = 1
    let beep = 2
    let all = push lor beep

    let to_int a = a

    let of_int n =
      if 0 <= n && n <= 3 then
        n
      else
        invalid_arg ("WLANThermo.Alarm.of_int: " ^ string_of_int n)

    let is_on which a =
      (a land which) <> 0

    let switch_on which a =
      a lor which

    let switch_off which a =
      a land (lnot which)

    let format a =
      match is_on push a, is_on beep a with
      | false, false -> "off"
      | true,  false -> "push"
      | false, true  -> "beep"
      | true,  true  -> "push+beep"

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
    val of_json : JSON.t -> t
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
      let open JSON.Util in
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
      | Inverted of float * (float * float)
    val of_float : float * float -> float -> t
  end

module Temperature : Temperature =
  struct

    type t =
      | Inactive
      | Too_low of float
      | Too_high of float
      | In_range of float
      | Inverted of float * (float * float)

    let of_float (t_min, t_max as t_range) t =
      if t_min > t_max then
        Inverted (t, t_range)
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
    val of_json : JSON.t -> t
    val is_active : t -> bool
    val member : int -> t list -> bool
    val find_opt : t list -> int -> t option
    val format : Settings.t -> t -> string list
    val format_header : string list
    val format_unavailable : int -> string list
    val update :
      ThoCurl.options -> ?all:bool ->
      ?range:(float * float) -> ?min:float -> ?max:float ->
      ?push:switch -> ?beep:switch -> t list -> int -> unit
  end

module Channel : Channel =
  struct

    type t =
      { number : int;
        name : string;
        typ: int (* see "sensors" in /settings/ *) ;
        t : Temperature.t;
        t_min : float;
        t_max : float;
        alarm : Alarm.t;
        color : Color.t;
        fixed : bool; (* sensor type fixed by hardware *)
        connected : bool (* wireless sensor connection status *) }

    let is_active ch =
      let open Temperature in
      match ch.t with
      | Inactive -> false
      | Too_low _ | Too_high _ | In_range _ | Inverted _ -> true

    let member n channels =
      List.exists (fun ch -> ch.number = n) channels

    let find_opt channels n =
      List.find_opt (fun ch -> ch.number = n) channels

    let of_json ch =
      let open JSON.Util in
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

    let format_header =
      [ "Ch#";
        "Name";
        "Temperature";
        "<>";
        "Range";
        "Alarm";
        "Sensor" ]

    (* TODO: handle Celsius/Fahrenheit. *)
    let format settings ch =
      let open Printf in
      let sensor =
        match Sensor.name_opt settings.Settings.sensors ch.typ with
        | None -> sprintf "?%3d" ch.typ
        | Some s -> s.name in
      List.concat
        [ [ sprintf "%3d" ch.number;
            "\"" ^ ch.name ^ "\"" ];
          begin match ch.t with
          | Inactive -> ["inactive"; ""]
          | Inverted (t, _) -> [sprintf "%5.1f deg" t; "inverted"]
          | Too_low t ->  [sprintf "%5.1f deg" t; "below"]
          | Too_high t -> [sprintf "%5.1f deg" t; "above"]
          | In_range t -> [sprintf "%5.1f deg" t; "in"]
          end;
          [ sprintf "[%5.1f,%5.1f]" ch.t_min ch.t_max;
            Alarm.format ch.alarm;
            sensor ] ]

    let format_unavailable ch =
      [ Printf.sprintf "%3d" ch; "[unavailable]" ]

    type mod_t  =
      { mod_number : int;
        mod_name : string option;
        (* typ : integer option; *)
        (* at the moment it's always 0 for channel 1-8 and 15 for channel 9 *)
        mod_t_min : float option;
        mod_t_max : float option;
        mod_alarm : Alarm.t;
        mod_color : Color.t option }

    let unchanged channel =
      { mod_number = channel.number;
        mod_name = None;
        mod_t_min = None;
        mod_t_max = None;
        mod_alarm = channel.alarm;
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
      `Assoc (List.concat
                [ int_to_json "number" ch.mod_number;
                  string_option_to_json "name" ch.mod_name;
                  float_option_to_json "min" ch.mod_t_min;
                  float_option_to_json "max" ch.mod_t_max;
                  alarm_to_json "alarm" ch.mod_alarm;
                  color_option_to_json "color" ch.mod_color ])

    let apply_range ?range mod_channel =
      match range with
      | None -> mod_channel
      | Some (min, max) ->
         if min <= max then
           { mod_channel with mod_t_min = Some min; mod_t_max = Some max }
         else begin
             Printf.eprintf
               "ignoring request for inverted limits (%.1f > %.1f) in channel %d!\n"
               min max mod_channel.mod_number;
             mod_channel
           end

    let apply_min current ?min mod_channel =
      match min with
      | None -> mod_channel
      | Some min ->
         if min <= current.t_max then
           { mod_channel with mod_t_min = Some min }
         else begin
             Printf.eprintf
               "ignoring request for inverted limits (%.1f > %.1f) in channel %d!\n"
               min current.t_max mod_channel.mod_number;
             mod_channel
           end

    let apply_max current ?max mod_channel =
      match max with
      | None -> mod_channel
      | Some max ->
         if current.t_min <= max then
           { mod_channel with mod_t_max = Some max }
         else begin
             Printf.eprintf
               "ignoring request for inverted limits (%.1f > %.1f) in channel %d!\n"
               current.t_min max mod_channel.mod_number;
             mod_channel
           end

    let apply_alarm alarm ch = function
      | On -> { ch with mod_alarm = Alarm.switch_on alarm ch.mod_alarm }
      | Off -> { ch with mod_alarm = Alarm.switch_off alarm ch.mod_alarm }

    let apply_push ?push ch =
      match push with
      | None -> ch
      | Some on_off -> apply_alarm Alarm.push ch on_off

    let apply_beep ?beep ch =
      match beep with
      | None -> ch
      | Some on_off -> apply_alarm Alarm.beep ch on_off

    let update options ?(all=false) ?range ?min ?max ?push ?beep available ch =
      match find_opt available ch with
      | None -> ()
      | Some channel ->
         if all || is_active channel then
           let command =
             unchanged channel
             |> apply_range ?range
             |> apply_min channel ?min
             |> apply_max channel ?max
             |> apply_push ?push
             |> apply_beep ?beep
             |> mod_to_json in
           let open JSON.Util in
           match ThoCurl.post_json options "setchannels" command with
           | `Bool true -> ()
           | `Bool false -> failwith "response: false"
           | response ->
              failwith ("unexpected: " ^ JSON.to_string response)
         else
           ()

  end

module type Pitmaster =
  sig
    type mode = private
      | Off
      | Manual
      | Auto
    type pm = private
      { id : int;
        channel : int;
        pid : int;
        value : int;
        target : float;
        mode : mode;
        mode_last : mode;
        target_color : Color.t;
        value_color : Color.t }
    type t = pm list
    val of_json : JSON.t -> t
    val is_active : pm -> bool
    val format : pm -> string list
    val format_header : string list
  end

module Pitmaster : Pitmaster =
  struct

    type mode =
      | Off
      | Manual
      | Auto

    let mode_to_string = function
      | Off -> "off"
      | Manual -> "manual"
      | Auto -> "auto"

    let mode_of_string = function
      | "off" -> Off
      | "manual" -> Manual
      | "auto" -> Auto
      | s -> invalid_arg ("WLANThermo.Pitmaster.mode_of_string: " ^ s)

    type pm =
      { id : int;
        channel : int;
        pid : int;
        value : int;
        target : float;
        mode : mode;
        mode_last : mode;
        target_color : Color.t;
        value_color : Color.t }

    let pm_of_json pm =
      let open JSON.Util in
      { id = pm |> member "id" |> to_int;
        channel = pm |> member "channel" |> to_int;
        pid = pm |> member "pid" |> to_int;
        value = pm |> member "value" |> to_int;
        target = pm |> member "set" |> to_float;
        mode = pm |> member "typ" |> to_string |> mode_of_string;
        mode_last = pm |> member "typ_last" |> to_string |> mode_of_string;
        target_color = pm |> member "set_color" |> to_string |> Color.of_string;
        value_color = pm |> member "value_color" |> to_string |> Color.of_string }

    let is_active pm =
      match pm.mode with
      | Off -> false
      | Manual | Auto -> true

    let format_mode pm =
      match pm.mode with
      | Off -> "off"
      | Manual -> Printf.sprintf "%3d%% (manual)" pm.value
      | Auto -> Printf.sprintf "%3d%% target %3f deg" pm.value pm.target

    let format_header =
      [ "PM#";
        "Mode";
        "Channel";
        "PID" ]

    (* TODO: translate PID using "pid" in /settings *)
    let format pm =
      [ Printf.sprintf "%2d" pm.id;
        (format_mode pm);
        Printf.sprintf "%2d" pm.channel;
        Printf.sprintf "%2d" pm.pid ]

    (* We ignore the entry "type": [ "off", "manual", "auto" ],
       which never changes. *)
    type t = pm list

    let of_json pitmaster =
      let open JSON.Util in
      pitmaster |> member "pm" |> to_list |> List.map pm_of_json

    let to_json _ =
      failwith "WLANThermo.Pitmaster.to_json: not implemented yet"

  end


module type Data =
  sig
    type t = private
      { system : System.t;
        channels : Channel.t list;
        pitmasters : Pitmaster.t }
    val get_json : ThoCurl.options -> JSON.t
    val of_json : JSON.t -> t
    val only_active : t -> t
    val format_temperatures : ?width:int -> ?prev:(int list * int list) ->
                              t -> (int list * int list) * string list
    val system_of_json : JSON.t -> System.t
    val channels_of_json : JSON.t -> Channel.t list
    val pitmasters_of_json : JSON.t -> Pitmaster.t
  end

module Data : Data =
  struct

    type t =
      { system : System.t;
        channels : Channel.t list;
        pitmasters : Pitmaster.t }

    let sort_channels channels =
      let open Channel in
      List.sort (fun ch1 ch2 -> compare ch1.number ch2.number) channels

    let system_of_json data =
      let open JSON.Util in
      data |> member "system" |> System.of_json

    let channels_of_json data =
      let open JSON.Util in
      data |> member "channel" |> to_list |> List.map Channel.of_json |> sort_channels

    let pitmasters_of_json data =
      let open JSON.Util in
      data |> member "pitmaster" |> Pitmaster.of_json

    let of_json data =
      let open JSON.Util in
      { system = system_of_json data;
        channels = channels_of_json data;
        pitmasters = pitmasters_of_json data }

    let only_active data =
      { data with
        channels = List.filter Channel.is_active data.channels;
        pitmasters = List.filter Pitmaster.is_active data.pitmasters }

    let get_json options =
      ThoCurl.get_json options "data"


    let format_temperatures_header width (channels, pitmasters) =
      let columns = List.length channels + 2 * (List.length pitmasters) in
      let separator =
        "#" ^ String.make ((width + 1) * columns - 1) '-' in
      [ separator;
        "#" ^ String.concat " "
                (List.map
                   (Printf.sprintf " Ch%*d" (width - 3))
                   channels
                 @ List.map
                   (fun pm -> Printf.sprintf " PM%*d%*s" (width - 3) pm width "")
                   pitmasters);
        separator ]

    let format_temperature width t =
      let open Temperature in
      match t with
      | Inactive -> failwith "unexpected inactive channel"
      | Inverted (t, _) | Too_low t | Too_high t
      | In_range t -> Printf.sprintf "%*.1f" width t

    let format_pitmaster width pm =
      match pm.Pitmaster.mode with
      | Pitmaster.Off -> (* should not happen! *)
         Printf.sprintf "%*s" (2 * width + 1) "[off]"
      | Pitmaster.Manual ->
         Printf.sprintf
           "%*s %*d%%"
           width "manual" (width - 1) pm.Pitmaster.value
      | Pitmaster.Auto ->
         Printf.sprintf
           "%*.1f %*d%%"
           width pm.Pitmaster.target (width - 1) pm.Pitmaster.value

    (* TODO: add active pitmasters *)
    (* TODO: add time stamps *)
    let format_temperatures ?(width=6) ?(prev=([],[])) data =
      let line =
        [ " " ^ String.concat " "
                  (List.map
                     (fun ch -> format_temperature width ch.Channel.t)
                     data.channels
                   @ List.map
                     (fun pm -> format_pitmaster width pm)
                     data.pitmasters) ] in
      let numbers =
        (List.map (fun ch -> ch.Channel.number) data.channels,
         List.map (fun pm -> pm.Pitmaster.channel) data.pitmasters) in
      if numbers <> prev  then
        (numbers, format_temperatures_header width numbers @ line)
      else
        (numbers, line)

  end


let get_data = Data.get_json
let get_info = Info.get
let get_settings = Settings.get_json

(* TODO: filter the channels *)
let monitor_temperatures options channels prev =
  ignore channels;
  let active = get_data options |> Data.of_json |> Data.only_active in
  let numbers, lines = Data.format_temperatures ~prev active in
  List.iter print_endline lines;
  flush stdout;
  numbers

let format_pitmasters options =
  let open JSON.Util in
  let unaligned =
    get_data options |> Data.pitmasters_of_json |> List.map Pitmaster.format in
  ThoString.align_string_lists " " (Pitmaster.format_header :: unaligned)

let format_battery options =
  let system = get_data options |> Data.system_of_json in
  Printf.sprintf
    "battery %3d%% %s"
    system.charge
    (if system.charging then "(charging)" else "(not charging)")

let format_all_channels ?(all=false) settings available =
  let channels =
    if all then
      available
    else
      List.filter Channel.is_active available in
  List.map (Channel.format settings) channels

let format_channel settings available ch =
  match Channel.find_opt available ch with
  | None -> Channel.format_unavailable ch
  | Some channel -> (Channel.format settings) channel

let format_channels ?(all=false) options channels =
  let available = get_data options |> Data.channels_of_json
  and settings = get_settings options |> Settings.of_json in
  let unaligned =
    match channels with
    | [] -> format_all_channels ~all settings available
    | ch_list -> List.map (format_channel settings available) ch_list in
  ThoString.align_string_lists " " (Channel.format_header :: unaligned)

let update_channels common ?all ?range ?min ?max ?push ?beep channels =
  let available = get_data common |> Data.channels_of_json in
  let all_channels =
    match channels with
    | [] -> List.map (fun ch -> ch.Channel.number) available
    | ch_list -> ch_list in
  List.iter (Channel.update common ?all ?range ?min ?max ?push ?beep available) all_channels

