(* ThoCurl.ml -- simple interface to curl(1) *)

type options =
  { ssl : bool;
    host : string;
    verbosity : int;
    timeout : int option }

type content =
  | JSON

val get : options -> string -> string
val post : options -> string -> ?content:content -> string -> string

val get_json : options -> string -> Yojson.Basic.t
val post_json : options -> string -> Yojson.Basic.t -> Yojson.Basic.t
