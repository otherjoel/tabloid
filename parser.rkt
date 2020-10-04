#lang brag

;; A #lang brag program automagically converts a BNF grammar (below) into a function
;; that parses bytes from an input port into an S-expression that matches the grammar.
;; It provides that function under the name `parse`.

tabloid-program: statement+

@statement: print | value-expression | variable-assign | function-def | program-end | shocking-return

print: /"YOU WON'T WANT TO MISS" value-expression

variable-assign: /"EXPERTS CLAIM" IDENTIFIER /"TO BE" value-expression

value-expression: [function-apply | value-expression ("PLUS" | "MINUS")]* (value | product | function-apply | conditional | block-scope | compare)

product: [product ("TIMES" | "DIVIDED BY" | "MODULO")]* value

@value: NUMBER | STRING | boolean | IDENTIFIER | /"(" value-expression /")"

compare: value-expression ("IS ACTUALLY" | "BEATS" | "SMALLER THAN") value-expression

@boolean: true | false
true: /"TOTALLY RIGHT"
false: /"COMPLETELY WRONG"

conditional: /"WHAT IF" value-expression statement [/"LIES!" statement]

function-def: /"DISCOVER HOW TO" id-and-arguments block-scope

/id-and-arguments: IDENTIFIER /"WITH" [IDENTIFIER /","]* IDENTIFIER

block-scope: /"RUMOR HAS IT" [statement | shocking-return]+ /"END OF STORY"

shocking-return: /"SHOCKING DEVELOPMENT" value-expression

function-apply: IDENTIFIER /"OF" argument-list

@argument-list: [value-expression /","]* value-expression

program-end: /"PLEASE LIKE AND SUBSCRIBE"