#lang racket/base

(require br/syntax
         racket/list
         "parser.rkt"
         "tokenizer.rkt")

;; This file includes the reader. The reader passes the token stream to the parser (see parser.rkt).
;; The parser converts the tokens into an S-expression whose bindings are provided by the expander
;; (see expander.rkt)

;; read-syntax is called by Racket itself as the first step in interpreting a #lang tabloid program
;; See https://beautifulracket.com/appendix/master-recipe.html#the-reader
(define (read-syntax src in-port)
  ;; The “parse” function comes from parser.rkt
  (define parsed-tree (parse src (make-tabloid-tokenizer in-port)))
  (define program
    (cond
      [(not (equal? '(program-end) (last (syntax->datum parsed-tree))))
       (raise-user-error "A Tabloid program MUST end with PLEASE LIKE AND SUBSCRIBE")]
      [else parsed-tree]))
  
  (strip-bindings
   (with-syntax ([PROGRAM-EXPRS program])
     #'(module tabloid-mod tabloid/expander
         PROGRAM-EXPRS))))

(module+ reader
  (provide read-syntax))
