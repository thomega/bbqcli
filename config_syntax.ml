(* config_syntax.ml -- configuration file syntax. *)

type value =
  | String of string

type line = string * value

type t = line list
