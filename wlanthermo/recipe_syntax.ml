(* recipe_syntax.ml *) (** Abstract recipe file syntax. *)

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

let channel_to_string = function
  | Number n -> "@" ^ string_of_int n
  | Name s -> "@" ^ ThoString.quote_string_if_necessary s

let unary_to_string = function
  | Exp -> "exp"
  | Tanh -> "tanh"

let value_to_string = function
  | Int n -> string_of_int n
  | Float x -> string_of_float x
  | String s -> ThoString.quote_string_if_necessary s
  | Channel ch -> channel_to_string ch

let rec expr_to_string = function
  | Value v -> value_to_string v
  | Unary (f, e) -> unary_to_string f ^ "(" ^ expr_to_string e ^ ")"
  | Sum (e1, e2) -> binop_to_string " + " e1 e2
  | Diff (e1, e2) -> binop_to_string " / " e1 e2
  | Prod (e1, e2) -> binop_to_string " * " e1 e2
  | Quot (e1, e2) -> binop_to_string " / " e1 e2
  | Powr (e1, e2) -> binop_to_string "**" e1 e2
and binop_to_string op e1 e2 =
  "(" ^ expr_to_string e1 ^ ")" ^ op ^ "(" ^ expr_to_string e2 ^ ")"

let stmt_to_string = function
  | Let (name, e) -> name ^ " = " ^ expr_to_string e
