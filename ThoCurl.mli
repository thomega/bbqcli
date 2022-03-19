(* ThoCurl.ml -- simple interface to curl(1) *)

module JSON = Yojson.Basic

type options =
  { ssl : bool;
    host : string;
    verbosity : int;
    timeout : int option }

type content =
  | JSON

val get : options -> string -> string
val post : options -> string -> ?content:content -> string -> string

val get_json : options -> string -> JSON.t
val post_json : options -> string -> JSON.t -> JSON.t
