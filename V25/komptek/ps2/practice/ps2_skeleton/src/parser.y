%{
#include "vslc.h"

// State variables from the flex generated scanner
extern int yylineno;  // The line currently being read
extern char yytext[]; // The text of the last consumed lexeme

// The main flex driver function used by the parser
int yylex(void);

// The function called by the parser when errors occur
int yyerror(const char *error)
{
  fprintf(stderr, "%s on line %d\n", error, yylineno);
  exit(EXIT_FAILURE);
}

// Feel free to define #define macros if you want to
%}

%token FUNC PRINT RETURN BREAK IF THEN ELSE WHILE DO VAR
%token NUMBER_TOKEN IDENTIFIER_TOKEN STRING_TOKEN

// Use operator precedence to ensure order of operations is correct
%left '=' '!'
%left '<' '>'
%left '+' '-'
%left '*' '/'
%right UNARY_OPERATORS

// Resolve the nested if-if-else ambiguity with precedence
%nonassoc IF THEN
%nonassoc ELSE

%%
program :
      global_list { root = $1; }
    ;
global_list :
      global { $$ = node_create(LIST, 1, $1); }
    | global_list global { $$ = append_to_list_node($1, $2); }
    ;
global :
      global_declaration { $$ = $1; }
    ;
global_declaration :
      VAR global_variable_list { $$ = node_create(GLOBAL_DECLARATION, 1, $2); }
    ;
global_variable_list :
      global_variable { $$ = node_create(LIST, 1, $1); }
    | global_variable_list ',' global_variable { $$ = append_to_list_node($1, $3); }
    ;
global_variable :
      identifier { $$ = $1; }
    ;
identifier :
      IDENTIFIER_TOKEN
      {
        // Create a node with 0 children to represent the identifier
        $$ = node_create(IDENTIFIER, 0);
        // Allocate a copy of yytext to keep in the syntax tree as data
        $$->data.identifier = strdup(yytext);
      }

/*
 * This file can currently only recognize global variable declarations, i.e,
 *
 * var myVar, anotherVar, third
 * var theLastOne
 *
 * TODO:
 * Include the remaining modified VSL grammar as specified in the task description.
 * This should be a pretty long file when you are done.
 */
%%
