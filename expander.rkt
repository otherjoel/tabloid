#lang racket/base

(require (for-syntax racket/base)
         br/macro)

(provide tabloid-program
         print
         variable-assign
         value-expression
         true
         false)

(provide #%top #%app #%datum #%top-interaction)

(define-macro tabloid-program #'#%module-begin)

(define (print v)
  (displayln (format "~a!" (if (string? v) (string-upcase v) (->str v)))))

(define-macro (variable-assign ID VAL) #'(define ID VAL))

(define (true) #t)
(define (false) #f)

(define-macro-cases value-expression
  [(_ VAL) #'VAL]
  [(_ LEFT "PLUS" RIGHT) #'(plus-things LEFT RIGHT)]
  [(_ LEFT "MINUS" RIGHT) #'(minus-things LEFT RIGHT)])

(define (->str v)
  (cond
    [(string? v) v]
    [(boolean? v) (if v "TRUE" "FALSE")]
    [else (format "~a" v)]))

(define (->number v)
  (cond
    [(number? v) v]
    [(boolean? v) (if v 1 0)]
    [(string? v) (or (string->number v) 'NAN)]
    [else 'NAN]))

(define (NAN? v) (equal? 'NAN v))

(define (plus-things a b)
  (cond
    [(ormap string? (list a b)) (apply string-append (map ->str (list a b)))]
    [else (apply + (map ->number (list a b)))]))

(define (minus-things a b)
  (define operands (map ->number (list a b)))
  (cond
    [(ormap NAN? operands) 'NAN]
    [else (apply - operands)]))
  
(module+ test
  (require rackunit))
