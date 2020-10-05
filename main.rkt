#lang br

(require brag/support
         racket/match
         "parser.rkt") ; Provides the `parse` function

(define debug-mode? (make-parameter #f))

;; This file includes the tokenizer and the reader. The reader passes the token stream to the
;; parser (see parser.rkt). The parser converts the tokens into an S-expression whose bindings are
;; provided by the expander (see expander.rkt)

(define-lex-abbrev reserved-phrases
  (:or "YOU WON'T WANT TO MISS"
       "EXPERTS CLAIM"
       "TO BE"
       "WHAT IF" "LIES!"
       "RUMOR HAS IT" "END OF STORY"
       "DISCOVER HOW TO" "WITH"
       "SHOCKING DEVELOPMENT"
       "PLEASE LIKE AND SUBSCRIBE"))

;; These are in a separate group because they are allowed to appear in expressions that
;; are passed as arguments to functions (see below)
(define-lex-abbrev values-and-ops
  (:or "PLUS" "MINUS" "TIMES" "DIVIDED BY" "MODULO"
       "AND" "OR"
       "IS ACTUALLY"
       "TOTALLY RIGHT"
       "COMPLETELY WRONG"
       "BEATS"
       "SMALLER THAN"))

(define-lex-abbrev matching-single-quotes (from/to "'" "'"))

;; Identifiers can contain letters, numbers, and punctuation
(define-lex-abbrev identifier-chars (:+ (:- (:or alphabetic punctuation numeric) (:or "(" ")" ","))))

;; The hardest part of this project (so far) was getting the precedence right in the case where
;; binary operations are used as in the last argument of a function application, e.g.:
;;
;;      YOU WON'T WANT TO MISS n TIMES function OF n PLUS 1
;;
;; This should be interpreted as (n TIMES (function OF n PLUS 1)) but I had a very difficult time
;; getting the parser to do that instead of ((n TIMES (function OF n)) PLUS 1) and still hang on to
;; operator precedence of TIMES over PLUS.
;;   My solution is to use the tokenizer to insert a special token marking the end of an argument
;; list, which in turn gives the parser a mechanism for being “greedy” with tokens in that context.
;; The tokenizer can only return one token at a time, so when it’s in the middle of an argument list
;; and the lexer encounters something that implicitly means the end of an argument list has been
;; reached, it stores that thing in a parameter (`held-token`) and returns the END-ARGLIST token
;; instead. The next time the tokenizer is called it will return (and clear out) the held token.

(define in-arg-list? (make-parameter #f)) ; Keep track of whether we’re in an argument list
(define held-token (make-parameter #f)) 

(define (end-argument-list lex)
  (cond [(in-arg-list?)
         (held-token lex)
         (in-arg-list? #f)
         (token 'END-ARGLIST)]
        [else lex]))

;; Returns a function that spits out tokens one at a time.
(define (make-tabloid-tokenizer port)
  (port-count-lines! port) ; Turn on source location tracking
  (lexer-file-path port)   ; Set location for error reporting
  
  (define (next-token)
    (define tabloid-lexer
      (lexer-srcloc
       [whitespace (next-token)] ; “In Tabloid, newlines are not significant.”
       [(eof) (end-argument-list lexeme)]
       [reserved-phrases (end-argument-list lexeme)]
       [values-and-ops lexeme]
       [(:or "(" ")" ",") lexeme]

       ;; Datum literals
       [matching-single-quotes (token 'STRING (trim-ends "'" lexeme "'"))]
       [(:: (:? "-") (:+ (char-set ".01234567890"))) (token 'NUMBER (string->number lexeme))]

       ;; Function application
       [(:: identifier-chars (:+ whitespace) "OF")
        (begin (in-arg-list? #t)
               (token 'APPLY-FUNC-ID (string->symbol (regexp-replace #rx"[ ]+OF" lexeme ""))))]

       ;; Identifiers in any other context
       [(:: identifier-chars)
        (token 'IDENTIFIER (string->symbol lexeme))]))
    (match (held-token)
      [#f (tabloid-lexer port)]
      [(var tok) (held-token #f) tok])) ; If we’re holding a token, return it and clear it out
  next-token)

;; read-syntax is called by Racket itself as the first step in interpreting a #lang tabloid program
;; See https://beautifulracket.com/appendix/master-recipe.html#the-reader
(define (read-syntax src in-port)
  ;; The “parse” function comes from parser.rkt
  (define parsed-tree (parse src (make-tabloid-tokenizer in-port)))
  (define program
    (cond
      [(debug-mode?) parsed-tree]
      [(not (equal? '(program-end) (last (syntax->datum parsed-tree))))
       (raise-user-error "A Tabloid program MUST end with PLEASE LIKE AND SUBSCRIBE")]
      [else (datum->syntax #f (drop-right (syntax->datum parsed-tree) 1))]))
  
  (strip-bindings
   (with-syntax ([PROGRAM-EXPRS program])
     #'(module tabloid-mod tabloid/expander
         PROGRAM-EXPRS))))

(module+ reader
  (provide read-syntax))
