(* recipe_syntax.mli -- abstract recipe file syntax. *)

exception Lexical_Error of string * Lexing.position * Lexing.position

type value =
  | String of string

type line = string * value

type t = line list
