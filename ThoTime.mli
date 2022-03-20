(* ThoTime.mli -- lightweight time manipulations. *)

type t
val use_local_time : unit -> unit
val now : unit -> t
val from_unix : float -> t
val sprint : string -> t -> string
   
type unix = float
val unix_of_string : string -> unix
val unix_now : unit -> unix
