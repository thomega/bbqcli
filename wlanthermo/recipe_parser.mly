/* recipe_parser.mly -- */

%{
module C = Recipe_syntax
%}

%token < int > INT
%token < float > FLOAT
%token < string > ID STRING
%token AT
%token PLUS MINUS TIMES DIV POWER
%token EQUALS COMMA
%token LPAREN RPAREN
%token LET
%token END

%left PLUS MINUS
%left TIMES DIV
%left POWER
%nonassoc UNARY

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
 | rev_file expr     { $2 :: $1 }
;

expr:
 | ID EQUALS string  { ($1, String $3) }
;

string:
 | ID      { $1 }
 | STRING  { $1 }
;
