(* WLANThermo.ml -- WLANThermo API *)

type switch = On | Off

val get_data : ThoCurl.options -> Yojson.Basic.t
val get_info : ThoCurl.options -> string
val get_settings : ThoCurl.options -> Yojson.Basic.t

val format_battery : ThoCurl.options -> string

val format_channels : ?all:bool -> ThoCurl.options -> int list -> string list
val format_pitmasters : ThoCurl.options -> string list

val monitor_temperatures : ThoCurl.options -> int list -> int list -> int list

val update_channels :
  ThoCurl.options -> ?all:bool ->
  ?range:(float * float) -> ?min:float -> ?max:float ->
  ?push:switch -> ?beep:switch -> int list -> unit
