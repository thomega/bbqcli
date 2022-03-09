(* ThoCurl.ml -- simple interface to curl(1) *)

val curl : ?ssl:bool -> ?host:string -> ?data:string -> string -> string
