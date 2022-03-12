(* WLANThermo.ml -- WLANThermo API *)

(* val temperatures : Yojson.Basic.t -> (int * float) list
   val temperature_opt : Yojson.Basic.t -> int -> float option
 *)
val print_temperature : ?ssl:bool -> host:string -> int -> unit
val print_temperatures : ?ssl:bool -> host:string -> unit -> unit
val print_battery : ?ssl:bool -> host:string -> unit -> unit

val set_channel_range : ?ssl:bool -> host:string -> int -> string -> unit
