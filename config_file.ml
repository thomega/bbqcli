(* config_file.ml -- *)

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

type t = Config_syntax.t

let of_string text =
  try
    Config_parser.file
      Config_lexer.token
      (Config_lexer.init_position "" (Lexing.from_string text))
  with
  | Parsing.Parse_error ->
	 invalid_arg ("parse error: " ^ text)

let simple_test () =
  let open Config_syntax in
  let open Printf in
  List.iter
    (fun (k, v) ->
      match v with
      | String v -> eprintf "%s = \"%s\"\n" k v)
    (of_string "foo = bar\n bar = baz")

let simple_test () =
  ()
