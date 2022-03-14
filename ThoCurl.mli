(* ThoCurl.ml -- simple interface to curl(1) *)

type content =
  | JSON

val get : ?ssl:bool -> host:string -> string -> string
val post : ?ssl:bool -> host:string -> string -> ?content:content -> string -> string
(* val patch : ?ssl:bool -> host:string -> string -> string -> string *)

exception Invalid_JSON of string * string
val get_json : ?ssl:bool -> host:string -> string -> Yojson.Basic.t
val post_json : ?ssl:bool -> host:string -> string -> Yojson.Basic.t -> Yojson.Basic.t
(* val patch_json : ?ssl:bool -> host:string -> string -> Yojson.Basic.t -> Yojson.Basic.t *)
