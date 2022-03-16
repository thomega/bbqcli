(* WLANThermo.ml -- WLANThermo API *)

val print_temperature : ThoCurl.options -> int -> unit
val print_temperatures : ThoCurl.options -> unit -> unit
val print_battery : ThoCurl.options -> unit -> unit

val set_channel_range : ThoCurl.options -> int -> (float * float) -> unit
