(* recipe_syntax.mli *) (** Abstract recipe file syntax. *)

exception Lexical_Error of string * Lexing.position * Lexing.position

type channel =
  | Number of int
  | Name of string

type value =
  | Int of int
  | Float of float
  | String of string
  | Channel of channel

type unary =
  | Exp
  | Tanh

type expr =
  | Value of value
  | Unary of unary * expr
  | Sum of expr * expr
  | Diff of expr * expr
  | Prod of expr * expr
  | Quot of expr * expr
  | Powr of expr * expr

type stmt =
  | Let of string * expr

type t = stmt list
