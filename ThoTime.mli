(* ThoTime.mli -- lightweight time manipulations. *)

type unix = float
val unix_now : unit -> unix
val unix_of_string_time : string -> unix
val unix_to_string_time : unix -> string
val unix_to_string_date_time : unix -> string
