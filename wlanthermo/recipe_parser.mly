/* recipe_parser.mly -- */

%{
module R = Recipe_syntax
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
 | rev_file END          { List.rev $1 }
;

/* maintain the good habit of using left recursion,
   even though the recipe files will be small in practice. */

rev_file:
 | /* empty */           { [] }
 | rev_file statement    { $2 :: $1 }
;

statement:
 | LET ID EQUALS value   { R.Let ($2, R.Value $4) }
;

value:
 | INT                   { Int $1 }
 | FLOAT                 { Float $1 }
 | string                { String $1 }
;

string:
 | ID      { $1 }
 | STRING  { $1 }
;
