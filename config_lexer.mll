(* config_lexer.mll -- *)
{
open Lexing
open Config_parser

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
    white             { token lexbuf }     (* skip blanks *)
  | '#' not_crlf*     { token lexbuf }     (* skip comments *)
  | crlf              { new_line lexbuf; token lexbuf }
  | '='        	      { EQUALS }
  | char word* as s   { ID s }
  | _ as c            { raise (Config_syntax.Lexical_Error
                                 ("invalid character `" ^ string_of_char c ^ "'",
                                  lexbuf.lex_start_p, lexbuf.lex_curr_p)) }
  | eof               { END }


