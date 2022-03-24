(* config_file.mli -- *)

type t = Config_syntax.t

val of_string : string -> t

val simple_test : unit -> unit
