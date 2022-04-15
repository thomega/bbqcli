(* recipe_lexer.mll -- *)
{
open Lexing
open Recipe_parser

let string_of_char c =
  String.make 1 c

let init_position fname lexbuf =
  let curr_p = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <-
    { curr_p with
      pos_fname = fname;
      pos_lnum = 1;
      pos_bol = curr_p.pos_cnum };
  lexbuf

}

let digit = ['0'-'9']
let upper = ['A'-'Z']
let lower = ['a'-'z']
let char = upper | lower
let word = char | digit | '_'
let white = [' ' '\t']
let esc = ['\'' '"' '\\']
let crlf = ['\r' '\n']
let not_crlf = [^'\r' '\n']

rule token = parse

    white             { token lexbuf }                  (* skip blanks *)
  | '#' not_crlf*     { token lexbuf }                  (* skip comments *)
  | crlf              { new_line lexbuf; token lexbuf } (* count lines *)

  | '('        	      { LPAREN }
  | ')'        	      { RPAREN }
  | ','        	      { COMMA }
  | '*' '*'    	      { POWER }
  | '*'        	      { TIMES }
  | '/'        	      { DIV }
  | '+'        	      { PLUS }
  | '-'        	      { MINUS }
  | '='        	      { EQUALS }
  | '@'        	      { AT }

  | "let"             { LET }

  | "exp"             { UNARY Recipe_syntax.Exp }
  | "tanh"            { UNARY Recipe_syntax.Tanh }

  | char word* as s   { ID s }

  | ( digit+ as i ) ( '.' '0'* )?
                      { INT (int_of_string i) }
  | ( digit | digit* '.' digit+
            | digit+ '.' digit* ) ( ['E''e'] '-'? digit+ )? as x
                      { FLOAT (float_of_string x) }

  | '\''              { let sbuf = Buffer.create 20 in
                        STRING (string1 sbuf lexbuf) }
  | '"'               { let sbuf = Buffer.create 20 in
                        STRING (string2 sbuf lexbuf) }

  | eof               { END }
  | _ as c            { raise (Recipe_syntax.Lexical_Error
                                 ("invalid character `" ^ string_of_char c ^ "'",
                                  lexbuf.lex_start_p, lexbuf.lex_curr_p)) }

(* complete a single quoted string *)
and string1 sbuf = parse
    '\''              { Buffer.contents sbuf }
  | '\\' (esc as c)   { Buffer.add_char sbuf c; string1 sbuf lexbuf }
  | eof               { raise End_of_file }
  | _ as c            { Buffer.add_char sbuf c; string1 sbuf lexbuf }

(* complete a double quoted string *)
and string2 sbuf = parse
    '"'               { Buffer.contents sbuf }
  | '\\' (esc as c)   { Buffer.add_char sbuf c; string2 sbuf lexbuf }
  | eof               { raise End_of_file }
  | _ as c            { Buffer.add_char sbuf c; string2 sbuf lexbuf }


