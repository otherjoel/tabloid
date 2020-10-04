#lang racket/base

(require (for-syntax racket/base)
         racket/dict
         br/macro)

(provide tabloid-program
         print
         function-def
         function-apply
         conditional
         compare
         block-scope
         variable-assign
         value-expression
         true
         false)

(provide #%top #%app #%datum #%top-interaction)

(define-macro tabloid-program #'#%module-begin)

(define (print v)
  (define printable
    (cond
      [(string? v) (string-upcase v)]
      [(boolean? v) (if v "TOTALLY RIGHT" "COMPLETELY WRONG")]
      [else v]))
  (displayln (format "~a!" printable)))

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

;; TODO "TIMES" "DIVIDED BY" "MODULO"

(define-macro-cases conditional
  [(_ EVAL IF-TRUE) #'(cond [EVAL IF-TRUE])]
  [(_ EVAL IF-TRUE IF-FALSE) #'(cond [EVAL IF-TRUE] [else IF-FALSE])])

(define (compare left op right)
  (define vals (list left right))
  (case op
    [("IS ACTUALLY") (equal? left right)]
    [("BEATS") (coerce-compare 'bigger vals)]
    [("SMALLER THAN") (coerce-compare 'smaller vals)]))

(define (coerce-compare op vals)
  (define funcs `(((string . bigger) . ,string>?)
                  ((string . smaller) . ,string<?)
                  ((other . bigger) . ,>)
                  ((other . smaller). ,<)))
  (cond
    [(ormap string? vals) (apply (dict-ref funcs `(string . ,op)) (map ->str vals))]
    [else (apply (dict-ref funcs `(other . ,op)) (map ->number vals))]))

;; Tabloid functions can contain only one statement
(define-macro (function-def ID+ARGS EXPR)
  #'(define ID+ARGS EXPR))

(define-macro (block-scope EXPR ...)
  (with-syntax ([shocking-return (datum->syntax caller-stx 'shocking-return)])
    #'(let/cc shocking-return
        (begin EXPR ...))))

(define-macro (function-apply FUNC ARG ...)
  #'(apply FUNC (list ARG ...)))

(module+ test
  (require rackunit))
