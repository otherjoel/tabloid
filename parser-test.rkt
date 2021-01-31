#lang racket/base

(require brag/support
         rackunit
         tabloid/parser
         tabloid/tokenizer)

(define (string-parse str)
  (parse-to-datum (apply-tokenizer-maker make-tabloid-tokenizer str)))

(check-equal? (string-parse "EXPERTS CLAIM result TO BE 7")
              '(tabloid-program
                (variable-assign result
                                 (value-expression (product 7)))))

(check-equal? (string-parse "EXPERTS CLAIM z TO BE func OF 7 PLUS 2 TIMES 3 MINUS 1")
              '(tabloid-program
                (variable-assign z
                                 (value-expression
                                  (function-apply
                                   func
                                   (value-expression
                                    (value-expression (value-expression (product 7))
                                                      "PLUS"
                                                      (product (product 2) "TIMES" 3))
                                    "MINUS"
                                    (product 1)))))))
