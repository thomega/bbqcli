(* WLANThermo.ml -- WLANThermo API *)

val print_json : string -> unit
(* val temperatures : Yojson.Basic.t -> (int * float) list
   val temperature_opt : Yojson.Basic.t -> int -> float option
 *)
val print_temperature : int -> unit
val print_temperatures : unit -> unit
val print_battery : unit -> unit