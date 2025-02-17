#lang sicp

(define (append! x y)
  (set-cdr! (last-pair x) y)
  x)

(define (last-pair x)
  (if (null? (cdr x)) x (last-pair (cdr x))))

(define x (list 'a 'b))
(define y (list 'c 'd))
(define z (append x y))
z
; '(a b c d)
(cdr x)
; '(b)

(define w (append! x y))
w
; '(a b c d)
(cdr x)
; '(b c d)