(* ThoCurl.ml -- simple interface to curl(1) *)

type options =
  { ssl : bool;
    host : string;
    verbosity : int }

type content =
  | JSON

val get : options -> string -> string
val post : options -> string -> ?content:content -> string -> string

exception Invalid_JSON of string * string
val get_json : options -> string -> Yojson.Basic.t
val post_json : options -> string -> Yojson.Basic.t -> Yojson.Basic.t
