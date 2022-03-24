(* recipe_file.ml -- *)

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

type t = Recipe_syntax.t

let of_string text =
  try
    Recipe_parser.file
      Recipe_lexer.token
      (Recipe_lexer.init_position "" (Lexing.from_string text))
  with
  | Parsing.Parse_error ->
	 invalid_arg ("parse error: " ^ text)
