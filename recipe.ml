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

let pretty_print recipe =
  let open Recipe_syntax in
  let open Printf in
  List.iter
    (fun (k, v) ->
      match v with
      | String v -> eprintf "%s = \"%s\"\n" k v)
    recipe

