(* config_syntax.mli -- configuration file syntax. *)

type value =
  | String of string

type line = string * value

type t = line list
