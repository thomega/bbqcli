/* config_parser.mly -- */

%{
module C = Config_syntax
%}

%token < string > ID
%token EQUALS
%token END

%start file
%type < Config_syntax.t > file

%%

file:
 | line END { [ $1 ] }
;

line:
 | ID EQUALS ID  { ($1, String $3) }
;

