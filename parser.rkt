#lang brag

;; A #lang brag program automagically converts a BNF grammar (below) into a function
;; that parses bytes from an input port into an S-expression that matches the grammar.
;; It provides this function under the name `parse`.

tabloid-program: statement+

@statement: print | variable-assign | function-def
            | conditional | block-scope | program-end

print: /"YOU WON'T WANT TO MISS" value-expression

variable-assign: /"EXPERTS CLAIM" IDENTIFIER /"TO BE" value-expression

value-expression: [value-expression ("PLUS" | "MINUS")]* (@value | product | function-apply)
product: [product ("TIMES" | "DIVIDED BY" | "MODULO")]* value-expression

@value: NUMBER | STRING | boolean | IDENTIFIER | /"(" value-expression /")"

function-apply: APPLY-FUNC-ID value-expression [/"," value-expression]* /END-ARGLIST

@boolean: true | false
true: /"TOTALLY RIGHT"
false: /"COMPLETELY WRONG"

conditional: /"WHAT IF" compare (statement | shocking-return)
             [/"LIES!" (statement | shocking-return)]

compare: value-expression ("IS ACTUALLY" | "BEATS" | "SMALLER THAN") value-expression

function-def: /"DISCOVER HOW TO" id-and-arguments block-scope

/id-and-arguments: IDENTIFIER /"WITH" [IDENTIFIER /","]* IDENTIFIER

block-scope: /"RUMOR HAS IT" [statement | shocking-return]+ /"END OF STORY"

shocking-return: /"SHOCKING DEVELOPMENT" value-expression

program-end: /"PLEASE LIKE AND SUBSCRIBE"