(* recipe_syntax.ml -- abstract recipe file syntax. *)

exception Lexical_Error of string * Lexing.position * Lexing.position

type value =
  | String of string

type expr = string * value

type t = expr list
