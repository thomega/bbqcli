(* recipe_syntax.ml -- abstract recipe file syntax. *)

exception Lexical_Error of string * Lexing.position * Lexing.position

type value =
  | Int of int
  | Float of float
  | String of string

type expr =
  | Value of value

type stmt =
  | Let of string * expr

type t = stmt list
