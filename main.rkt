#lang br

(require brag/support
         "parser.rkt")

(define debug-mode? (make-parameter #f))

;; This file includes the tokenizer/lexer and the reader.

;; 
(define-lex-abbrev reserved-phrases
  (:or "YOU WON'T WANT TO MISS"
       "EXPERTS CLAIM"
       "TO BE"
       "WHAT IF" "LIES!"
       "RUMOR HAS IT" "END OF STORY"
       "DISCOVER HOW TO" "WITH"
       "SHOCKING DEVELOPMENT"
       "IS ACTUALLY"
       "OF"
       "PLUS" "MINUS" "TIMES" "DIVIDED BY" "MODULO"
       "AND" "OR"
       "TOTALLY RIGHT"
       "COMPLETELY WRONG"
       "BEATS"
       "SMALLER THAN"
       "SHOCKING DEVELOPMENT"
       "PLEASE LIKE AND SUBSCRIBE"))

(define-lex-abbrev matching-single-quotes (from/to "'" "'"))

(define (make-tokenizer port)
  (port-count-lines! port) ; Turn on source location tracking
  (lexer-file-path port)   ; Set location for error reporting
  
  (define (next-token)
    (define tabloid-lexer
      (lexer-srcloc
       [whitespace (next-token)] ; “In Tabloid, newlines are not significant.”
       [reserved-phrases lexeme]
       [(:or "(" ")" ",") lexeme]

       ;; Datum literals
       [matching-single-quotes (token 'STRING (trim-ends "'" lexeme "'"))]
       [(:: (:? "-") (:+ (char-set ".01234567890"))) (token 'NUMBER (string->number lexeme))]

       ;; Identifiers can contain letters, numbers, and punctuation))
       [(:: (:+ (:- (:or alphabetic punctuation numeric) (:or "(" ")" ","))))
        (token 'IDENTIFIER (string->symbol lexeme))]))
    
    (tabloid-lexer port))
  next-token)

(define (read-syntax src in-port)
  (define parsed-tree (parse src (make-tokenizer in-port)))
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
