(* recipe.ml -- *)

let error_in_string text start_pos end_pos =
  let i = max 0 start_pos.Lexing.pos_cnum in
  let j = min (String.length text) (max (i + 1) end_pos.Lexing.pos_cnum) in
  String.sub text i (j - i)

let error_in_file name start_pos end_pos =
  Printf.sprintf
    "%s:%d.%d-%d.%d"
    name
    start_pos.Lexing.pos_lnum
    (start_pos.Lexing.pos_cnum - start_pos.Lexing.pos_bol)
    end_pos.Lexing.pos_lnum
    (end_pos.Lexing.pos_cnum - end_pos.Lexing.pos_bol)

module R = Recipe_syntax

type t = R.t

let parse lexbuf =
  try
    Recipe_parser.file Recipe_lexer.token lexbuf
  with
  | Parsing.Parse_error -> invalid_arg ("parse error")

let lexbuf_of_string text =
  Lexing.from_string text |> Recipe_lexer.init_position ""

let lexbuf_of_channel filename ic =
  Lexing.from_channel ic |> Recipe_lexer.init_position filename

let of_string text =
  lexbuf_of_string text |> parse

let of_channel filename ic =
  lexbuf_of_channel filename ic |> parse

let of_file = function
  | "-" -> parse (lexbuf_of_channel "/dev/stdin" stdin)
  | filename ->
     let ic = open_in filename in
     let recipe = lexbuf_of_channel filename ic |> parse in
     close_in ic;
     recipe

let contains_any chars s =
  match List.find_opt (String.contains s) chars with
  | None -> false
  | Some _ -> true

(* Incomplete ... *)
let quote_string_if_necessary s =
  if contains_any [' '; '\t'; '\n'; '\r'] s then
    "\"" ^ s ^ "\""
  else
    s
    
let channel_to_string = function
  | R.Number n -> "@" ^ string_of_int n
  | R.Name s -> "@" ^ quote_string_if_necessary s

let unary_to_string = function
  | R.Exp -> "exp"
  | R.Tanh -> "tanh"

let value_to_string = function
  | R.Int n -> string_of_int n
  | R.Float x -> string_of_float x
  | R.String s -> quote_string_if_necessary s
  | R.Channel ch -> channel_to_string ch

let rec expr_to_string = function
  | R.Value v -> value_to_string v
  | R.Unary (f, e) -> unary_to_string f ^ "(" ^ expr_to_string e ^ ")"
  | R.Sum (e1, e2) -> binop_to_string " + " e1 e2
  | R.Diff (e1, e2) -> binop_to_string " / " e1 e2
  | R.Prod (e1, e2) -> binop_to_string " * " e1 e2
  | R.Quot (e1, e2) -> binop_to_string " / " e1 e2
  | R.Powr (e1, e2) -> binop_to_string "**" e1 e2
and binop_to_string op e1 e2 =
  "(" ^ expr_to_string e1 ^ ")" ^ op ^ "(" ^ expr_to_string e2 ^ ")"

let stmt_to_string = function
  | R.Let (name, e) -> name ^ " = " ^ expr_to_string e

let pretty_print recipe =
  List.map stmt_to_string recipe |> List.iter print_endline

