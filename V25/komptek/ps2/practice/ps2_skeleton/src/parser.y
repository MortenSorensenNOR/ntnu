%{
#include "parser.h"
#include "tree.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%union {
    char *sval;
    int ival;
    node_t *node;
}

%token FUNC VAR RETURN PRINT IF THEN ELSE WHILE DO BREAK
%token <sval> IDENTIFIER_TOKEN STRING_TOKEN
%token <ival> NUMBER_TOKEN
%token '=' '+' '-' '*' '/' EQ NE '<' LE '>' GE '!'
%token '(' ')' '{' '}' ','

%type <node> program global_list global global_declaration function statement_list statement
%type <node> assignment_statement return_statement print_statement if_statement while_statement
%type <node> expression expression_list function_call argument_list identifier number string

%%

program: global_list { root = $1; }
;

global_list: global { $$ = node_create(GLOBAL_LIST, 1, $1); }
          | global_list global { $$ = append_to_list_node($1, $2); }
;

global: function { $$ = $1; }
      | global_declaration { $$ = $1; }
;

global_declaration: VAR identifier { $$ = node_create(GLOBAL_DECLARATION, 1, $2); }
;

function: FUNC identifier '(' argument_list ')' statement {
    $$ = node_create(FUNCTION, 3, $2, $4, $6);
}
;

statement_list: statement { $$ = node_create(STATEMENT_LIST, 1, $1); }
              | statement_list statement { $$ = append_to_list_node($1, $2); }
;

statement: assignment_statement
         | return_statement
         | print_statement
         | if_statement
         | while_statement
         | function_call
         | '{' statement_list '}' { $$ = $2; }
;

assignment_statement: identifier '=' expression { $$ = node_create(ASSIGNMENT, 2, $1, $3); }
;

return_statement: RETURN expression { $$ = node_create(RETURN_STATEMENT, 1, $2); }
;

print_statement: PRINT expression_list { $$ = node_create(PRINT_STATEMENT, 1, $2); }
;

if_statement: IF expression THEN statement ELSE statement { $$ = node_create(IF_STATEMENT, 3, $2, $4, $6); }
;

while_statement: WHILE expression DO statement { $$ = node_create(WHILE_STATEMENT, 2, $2, $4); }
;

expression_list: expression { $$ = node_create(EXPRESSION_LIST, 1, $1); }
              | expression_list ',' expression { $$ = append_to_list_node($1, $3); }
;

expression: expression '+' expression { $$ = node_create(ADD_OP, 2, $1, $3); }
          | expression '-' expression { $$ = node_create(SUB_OP, 2, $1, $3); }
          | expression '*' expression { $$ = node_create(MUL_OP, 2, $1, $3); }
          | expression '/' expression { $$ = node_create(DIV_OP, 2, $1, $3); }
          | '(' expression ')' { $$ = $2; }
          | number { $$ = $1; }
          | identifier { $$ = $1; }
          | function_call { $$ = $1; }
;

function_call: identifier '(' argument_list ')' { $$ = node_create(FUNCTION_CALL, 2, $1, $3); }
;

argument_list: expression_list { $$ = $1; }
            | /* empty */ { $$ = node_create(EXPRESSION_LIST, 0); }
;

identifier: IDENTIFIER_TOKEN { $$ = node_create(IDENTIFIER, 0); $$->data.identifier = strdup($1); }
;

number: NUMBER_TOKEN { $$ = node_create(NUMBER, 0); $$->data.number_literal = $1; }
;

string: STRING_TOKEN { $$ = node_create(STRING, 0); $$->data.string_literal = strdup($1); }
;

%%

int yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
    return 0;
}

