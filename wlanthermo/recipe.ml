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

let value_to_string = function
  | R.String s -> "\"" ^ s ^ "\""
  | R.Int n -> string_of_int n
  | R.Float x -> string_of_float x

let expr_to_string = function
  | R.Value v -> value_to_string v

let stmt_to_string = function
  | R.Let (name, expr) -> name ^ " = " ^ expr_to_string expr

let pretty_print recipe =
  List.map stmt_to_string recipe |> List.iter print_endline

