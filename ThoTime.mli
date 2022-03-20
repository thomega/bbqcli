(* ThoTime.mli -- lightweight time manipulations. *)

type t
val now : unit -> t
val of_string_time : string -> t
val to_string_time : ?since:t -> t -> string
val to_string_date_time : ?since:t -> t -> string
