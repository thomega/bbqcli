(* ThoTime.mli *) (** Lightweight time manipulations for when [Calendar] is to heavy. *)

(** This will typically be [float] on a Unix system. *)
type t

(** The current time. *)
val now : unit -> t

(** Parse the string in the format {i MM:SS} or {i HH:MM:SS}. *)
val of_string_time : string -> t

type format =
  | Time (** {i HH:MM:SS } *)
  | Time_since of t
  | Date_Time (** {i YYYY-MM-DD HH:MM:SS } *)
  | Seconds
  | Seconds_since of t

(** Format the time as date and time, time of day (default) or elapsed,
    second of day or elapsed. *)
val to_string : ?format:format -> t -> string
