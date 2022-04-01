/* recipe_parser.mly -- */

%{
module R = Recipe_syntax
%}

%token < int > INT
%token < float > FLOAT
%token < string > ID STRING
%token < Recipe_syntax.unary > UNARY
%token AT
%token PLUS MINUS TIMES DIV POWER
%token EQUALS COMMA
%token LPAREN RPAREN
%token LET UNARY
%token END

%left PLUS MINUS
%left TIMES DIV
%left POWER
%nonassoc PREFIX

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
 | LET ID EQUALS expr    { R.Let ($2, $4) }
;

expr:
 | value                    { R.Value $1 }
 | UNARY LPAREN expr RPAREN { R.Unary ($1, $3) }
 | expr PLUS expr           { R.Sum ($1, $3) }
;

value:
 | INT                   { R.Int $1 }
 | FLOAT                 { R.Float $1 }
 | string                { R.String $1 }
 | channel               { R.Channel $1 }
;

channel:
 | AT INT                { R.Number $2 }
 | AT string             { R.Name $2 }
;

string:
 | ID                    { $1 }
 | STRING                { $1 }
;
