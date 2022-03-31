(* ThoCurl.ml *) (** A simple interface to curl. *)

(** We don't use extensions to JSON. *)
module JSON = Yojson.Basic

(** Options for the connection to the server:
    whether to use SSL,
    the hostname of the server,
    the level of debugging info printed,
    the number of seconds to wait before giving up. *)
type options =
  { ssl : bool;
    host : string;
    verbosity : int;
    timeout : int option }

(** Select "Content-Type" for POST data. *)
type content =
  | JSON

(** [get server request] returns the response to the [request] on [server]
    as a string. *)
val get : options -> string -> string

(** [post server request ~content data] returns the response to the [request]
    with [data] on [server] as a string. *)
val post : options -> string -> ?content:content -> string -> string

(** [get_json server request] returns the response to the [request]
    on [server] as parsed JSON.  *)
val get_json : options -> string -> JSON.t

(** [post_json server request json] returns the response to the [request]
    with JSON [data] on [server] as parsed JSON. *)
val post_json : options -> string -> JSON.t -> JSON.t
