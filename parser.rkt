#lang brag

tabloid-program: statement+

@statement: print | value-expression | variable-assign | program-end

print: /"YOU WON'T WANT TO MISS" value-expression

variable-assign: /"EXPERTS CLAIM" IDENTIFIER /"TO BE" value-expression

value-expression: [value-expression ("PLUS" | "MINUS")]* (@value | product)

product: [product ("TIMES" | "DIVIDED BY" | "MODULO")]+ @value

/value: NUMBER | STRING | @boolean | IDENTIFIER

/boolean: true | false
true: /"TOTALLY RIGHT"
false: /"COMPLETELY WRONG"

program-end: /"PLEASE LIKE AND SUBSCRIBE"