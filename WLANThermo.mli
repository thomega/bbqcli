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
module Alarm : Alarm

module type Color =
  sig
    type t
    val to_string : t -> string
    val of_string : string -> t
  end
module Color : Color

module type Temperature =
  sig
    type t = private
      | Inactive
      | Too_low of float
      | Too_high of float
      | In_range of float
    val of_float : float * float -> float -> t
  end
module Temperature : Temperature

type switch = On | Off
val switch_to_string : switch -> string

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
    val format : t -> string
    val set : ThoCurl.options -> int list -> (float * float) option ->
              switch option -> switch option -> unit
  end

module Channel : Channel

val info : ThoCurl.options -> string
val data : ThoCurl.options -> Yojson.Basic.t
val settings : ThoCurl.options -> Yojson.Basic.t
val format_battery : ThoCurl.options -> string

val print_temperature : ThoCurl.options -> int -> unit
val print_temperatures : ThoCurl.options -> unit

