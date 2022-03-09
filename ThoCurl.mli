(* ThoCurl.ml -- simple interface to curl(1) *)

val get : ?ssl:bool -> ?host:string -> string -> string
val post : ?ssl:bool -> ?host:string -> string -> string -> string
val patch : ?ssl:bool -> ?host:string -> string -> string -> string
