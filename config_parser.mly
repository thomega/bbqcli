/* config_parser.mly -- */

%{
module C = Config_syntax
%}

%token < string > ID STRING
%token EQUALS
%token END

%start file
%type < Config_syntax.t > file

%%

file:
 | rev_file          { List.rev $1 }
;

/* maintain the good habit of using left recursion,
   even though the config files will be small in practice. */

rev_file:
 | rev_file line     { $2 :: $1 }
 | END               { [ ] }
;

line:
 | ID EQUALS ID      { ($1, String $3) }
 | ID EQUALS STRING  { ($1, String $3) }
;

