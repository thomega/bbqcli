(* ThoTime.ml -- lightweight time manipulations. *)

(* TODO: the time zone wrong sometimes! *)

type t = float

let subtract t1 t2 =
  t1 -. t2

let normalize tm =
  snd (Unix.mktime tm)

let now () =
  Unix.time ()

let seconds h m s =
  (h * 60 + m) * 60 + s

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

let of_hms tm_hour tm_min tm_sec =
  fst (Unix.mktime (tm_of_hms tm_hour tm_min tm_sec))

let of_string_time s =
  match String.split_on_char ':' s with
  | [] -> failwith "ThoTime.of_string: unexpected"
  | [_] -> invalid_arg "ThoTime.of_string: ambiguous"
  | [h; m] -> of_hms (int_of_string h) (int_of_string m) 0
  | [h; m; s] -> of_hms (int_of_string h) (int_of_string m) (int_of_string s)
  | _ -> invalid_arg "ThoTime.of_string: too many components"

let to_string_time t =
  let open Unix in
  let tm = localtime t in
  Printf.sprintf
    "%02d:%02d:%02d"
    tm.tm_hour tm.tm_min tm.tm_sec

let to_string_date_time t =
  let open Unix in
  let tm = localtime t in
  Printf.sprintf
    "%4d-%02d-%02d %02d:%02d:%02d"
    (tm.tm_year + 1900) (succ tm.tm_mon) tm.tm_mday
    tm.tm_hour tm.tm_min tm.tm_sec
