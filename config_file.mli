(* config_file.mli -- *)

(* Not yet convinced that this is a good idea.
   Environment variables should be enough and
   once we introduce a config file, we have to
   decide what takes precedence.  *)

type t = Config_syntax.t

val of_string : string -> t

val simple_test : unit -> unit
