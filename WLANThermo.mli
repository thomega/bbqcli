(* WLANThermo.ml -- WLANThermo API *)

type switch = On | Off

val data : ThoCurl.options -> Yojson.Basic.t
val info : ThoCurl.options -> string
val settings : ThoCurl.options -> Yojson.Basic.t

val format_battery : ThoCurl.options -> string

val format_channels : ?all:bool -> ThoCurl.options -> int list -> string list
val format_pitmasters : ThoCurl.options -> string list

val update_channels :
  ThoCurl.options -> ?all:bool ->
  (float * float) option -> switch option -> switch option ->
  int list -> unit
