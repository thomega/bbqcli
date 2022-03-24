/* recipe_parser.mly -- */

%{
module C = Recipe_syntax
%}

%token < string > ID STRING
%token EQUALS
%token END

%start file
%type < Recipe_syntax.t > file

%%

file:
 | rev_file END       { List.rev $1 }
;

/* maintain the good habit of using left recursion,
   even though the recipe files will be small in practice. */

rev_file:
 | /* empty */       { [] }
 | rev_file line     { $2 :: $1 }
;

line:
 | ID EQUALS ID      { ($1, String $3) }
 | ID EQUALS STRING  { ($1, String $3) }
;

