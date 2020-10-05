#lang racket/base

(require (for-syntax racket/base)
         racket/dict
         br/macro)

(provide tabloid-program
         program-end
         print
         function-def
         function-apply
         conditional
         compare
         block-scope
         variable-assign
         value-expression
         product
         true
         false)

;; Re-provide Racket’s default interposition points for use in #lang tabloid
;; See https://beautifulracket.com/explainer/interposition-points.html
(provide #%top #%app #%datum #%top-interaction)

(define-macro tabloid-program #'#%module-begin)

;; “Everything printed by Tabloid is automatically capitalized, and an exclamation point is added.”
(define (print v)
  (define printable
    (cond
      [(string? v) (string-upcase v)]
      [(boolean? v) (if v "TOTALLY RIGHT" "COMPLETELY WRONG")]
      [else v]))
  (displayln (format "~a!" printable)))

(define-macro (variable-assign ID VAL) #'(define ID VAL))

(define (program-end) (void)) ; Tabloid programs always evaluate to <void>

(define (true) #t)
(define (false) #f)

(define-macro-cases value-expression
  [(_ VAL) #'VAL]
  [(_ LEFT "PLUS" RIGHT) #'(plus-things LEFT RIGHT)]
  [(_ LEFT "MINUS" RIGHT) #'(minus-things LEFT RIGHT)])

(define-macro-cases product
  [(_ VAL) #'VAL]
  [(_ LEFT "TIMES" RIGHT) #'(multiply-things LEFT RIGHT)]
  [(_ LEFT "DIVIDED BY" RIGHT) #'(divide-things LEFT RIGHT)]
  [(_ LEFT "MODULO" RIGHT) #'(modulo-things LEFT RIGHT)])

;; Coerce values in a way that roughly mimics Javascript
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

;; If either operand is a string, treat both as strings and concatenate.
(define (plus-things a b)
  (cond
    [(ormap string? (list a b)) (apply string-append (map ->str (list a b)))]
    [else (apply + (map ->number (list a b)))]))

;; Build functions that perform binary operations on numbers only, returning NaN if either
;; operand cannot be coerced into a number.
(define (strict-math-op func)
  (lambda (left right)
    (define operands (map ->number (list left right)))
    (cond
      [(ormap NAN? operands) 'NAN]
      [else (apply func operands)])))
  
(define minus-things (strict-math-op -))
(define multiply-things (strict-math-op *))
(define divide-things (strict-math-op /))
(define modulo-things (strict-math-op modulo))

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

;; Tabloid functions can contain only one statement (but a block scope counts as one statement)
(define-macro (function-def ID+ARGS EXPR)
  #'(define ID+ARGS EXPR))

;; "SHOCKING DEVELOPMENT" is implemented as a continuation within a block scope
;; See https://beautifulracket.com/explainer/continuations.html
(define-macro (block-scope EXPR ...)
  (with-syntax ([shocking-return (datum->syntax caller-stx 'shocking-return)])
    #'(let/cc shocking-return
        (begin EXPR ...))))

(define-macro (function-apply FUNC ARG ...)
  #'(apply FUNC (list ARG ...)))

(module+ test
  (require rackunit))
