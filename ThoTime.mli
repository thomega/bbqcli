(* ThoTime.mli -- lightweight time manipulations. *)

type t
val diff : t -> t -> t
val now : unit -> t
val of_string_time : string -> t
val to_string_time : t -> string
val to_string_date_time : t -> string
