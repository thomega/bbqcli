(* ThoCurl.ml -- simple interface to curl(1) *)

val get : ?ssl:bool -> ?host:string -> string -> string
val post : ?ssl:bool -> ?host:string -> string -> string -> string
val request : ?ssl:bool -> ?host:string -> ?data:string -> string -> string
