(* ThoTime.ml -- lightweight time manipulations. *)

open CalendarLib

type t = Calendar.t

let use_local_time () =
  Time_Zone.change Time_Zone.Local

let now () =
  Calendar.now ()

let from_unix t =
  Calendar.from_unixfloat t

let sprint format t =
  Printer.Calendar.sprint format t

type unix = float

(* TODO: the time zone is always UTC! *)
let unix_of_string s =
  Calendar.to_unixfloat (Printer.Calendar.from_string s)

let unix_now () =
  Unix.time ()
