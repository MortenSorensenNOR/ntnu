%{
#include "vslc.h"

// The tokens defined in parser.y
#include "parser.h"

// parser.h contains some unused functions, ignore that
#pragma GCC diagnostic ignored "-Wunused-function"
%}

%option noyywrap
%option array
%option yylineno

WHITESPACE [ \t]
COMMENT \/\/[^\n]+
QUOTED \"([^\"\n]|\\\")*\"

%%
{WHITESPACE}+           { /* Eliminate whitespace */ }
{COMMENT}               { /* Eliminate comments */ }
{QUOTED}                { return STRING_TOKEN; }

/*
 * TODO:
 *
 * Add the rest of the translation rules here.
 * See the lexical structure definition of the modified VSL in PS2.
 * Also see the `%token` directives in parser.y for all symbolic names that can be returned - e.g. FUNC, IF, IDENTIFIER_TOKEN.
 *
 * Hint to get you started:
 * The WHITESPACE regex defined above is not quite finished. Finish it.
 * The scanner returns STRING_TOKEN when matching the QUOTED regex above.
 * When should the scanner return a NUMBER_TOKEN, IDENTIFIER_TOKEN, etc?
 * In which specific scenarios should the scanner return keyword tokens like FUNC or PRINT?
 *
 * For operators, which are all a single char or two chars, we let each char be a separate token.
 * This is achieved by using the "catch-all" rule at the very bottom of this file.
 */

  /* All other chars get returned as single char tokens */
.                       { return yytext[0]; }
%%
