(* ThoTime.mli -- lightweight time manipulations. *)

type t
val now : unit -> t

val of_string_time : string -> t

type format =
  | Time
  | Time_since of t
  | Date_Time
  | Seconds
  | Seconds_since of t

val to_string : ?format:format -> t -> string
