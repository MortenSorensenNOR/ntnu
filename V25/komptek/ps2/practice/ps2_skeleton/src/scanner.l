%{
#include "parser.h"
#include "tree.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

DIGIT      [0-9]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*
NUMBER     {DIGIT}+
STRING     \"([^\"\\]|\\.)*\"
WHITESPACE [ \t\n\r\v]+
COMMENT    \/\/.*

%%

{WHITESPACE}   { /* Ignore whitespace */ }
{COMMENT}      { /* Ignore comments */ }
{STRING}       { yylval.sval = strdup(yytext); return STRING_TOKEN; }
{NUMBER}       { yylval.ival = atoi(yytext); return NUMBER_TOKEN; }
{ID}           { yylval.sval = strdup(yytext); return IDENTIFIER_TOKEN; }

"func"        { return FUNC; }
"var"         { return VAR; }
"return"      { return RETURN; }
"print"       { return PRINT; }
"if"          { return IF; }
"then"        { return THEN; }
"else"        { return ELSE; }
"while"       { return WHILE; }
"do"          { return DO; }
"break"       { return BREAK; }

"="          { return '='; }
"+"          { return '+'; }
"-"          { return '-'; }
"*"          { return '*'; }
"/"          { return '/'; }
"=="         { return EQ; }
"!="         { return NE; }
"<"          { return '<'; }
"<="         { return LE; }
">"          { return '>'; }
">="         { return GE; }
"!"          { return '!'; }
"("          { return '('; }
")"          { return ')'; }
"{"          { return '{'; }
"}"          { return '}'; }
","          { return ','; }

%%

int yywrap() { return 1; }

node_t *node_create(node_type type, int num_children, ...) {
    node_t *node = malloc(sizeof(node_t));
    node->type = type;
    node->num_children = num_children;
    node->children = malloc(num_children * sizeof(node_t *));
    va_list args;
    va_start(args, num_children);
    for (int i = 0; i < num_children; i++) {
        node->children[i] = va_arg(args, node_t *);
    }
    va_end(args);
    return node;
}

void node_finalize(node_t *node) {
    if (node) {
        free(node->children);
        free(node);
    }
}

void destroy_subtree(node_t *node) {
    if (node) {
        for (int i = 0; i < node->num_children; i++) {
            destroy_subtree(node->children[i]);
        }
        node_finalize(node);
    }
}
