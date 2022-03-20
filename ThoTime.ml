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

let seconds h m s =
  (h * 60 + m) * 60 + s

let normalize tm =
  snd (Unix.mktime tm)

let is_after now tm_hour tm_min tm_sec =
  let open Unix in
  if seconds tm_hour tm_min tm_sec > seconds now.tm_hour now.tm_min now.tm_sec then
    true
  else
    false

(* normalize is not strictly necessary,
   because we will call Unix.mktime later anyway. *)
let tm_of_hms tm_hour tm_min tm_sec =
  let open Unix in
  let now = localtime (time ()) in
  if is_after now tm_hour tm_min tm_sec then
    normalize { now with tm_hour; tm_min; tm_sec; tm_mday = pred now.tm_mday }
  else
    normalize { now with tm_hour; tm_min; tm_sec }

let unix_of_hms tm_hour tm_min tm_sec =
  fst (Unix.mktime (tm_of_hms tm_hour tm_min tm_sec))

let unix_of_string_time s =
  match String.split_on_char ':' s with
  | [] -> failwith "unix_of_string: unexpected"
  | [_] -> invalid_arg "unix_of_string: ambiguous"
  | [h; m] -> unix_of_hms (int_of_string h) (int_of_string m) 0
  | [h; m; s] -> unix_of_hms (int_of_string h) (int_of_string m) (int_of_string s)
  | _ -> invalid_arg "unix_of_string: too many components"

let unix_to_string_time t =
  let open Unix in
  let tm = localtime t in
  Printf.sprintf
    "%02d:%02d:%02d"
    tm.tm_hour tm.tm_min tm.tm_sec

let unix_to_string_date_time t =
  let open Unix in
  let tm = localtime t in
  Printf.sprintf
    "%4d-%02d-%02d %02d:%02d:%02d"
    (tm.tm_year + 1900) (succ tm.tm_mon) tm.tm_mday
    tm.tm_hour tm.tm_min tm.tm_sec
