#lang sicp

(define (lookup key table)
  (let ([record (assoc key (cdr table))])
    (and record (cdr record))))

(define (assoc key records)
  (cond [(null? records) false]
        [(equal? key (caar records)) (car records)]
        [else (assoc key (cdr records))]))

(define (insert! key value table)
  (let ([record (assoc key (cdr table))])
    (if record
        (set-cdr! record table)
        (set-cdr! table
                  (cons (cons key value)
                        (cdr table)))))
  'ok)

(define (make-table)
  (list '*table*))

(define (fib n)
  (cond [(= n 0) 0]
        [(= n 1) 1]
        [else (+ (fib (- n 1)) (fib (- n 2)))]))

(define (memoize f)
  (let ([table (make-table)])
    (lambda (x)
      (let ([previously-computed-result
             (lookup x table)])
        (or previously-computed-result
            (let ([result (f x)])
              (insert! x result table)
              result))))))

(define memo-fib
  (memoize
   (lambda (n)
     (cond [(= n 0) 0]
           [(= n 1) 1]
           [else (+ (memo-fib (- n 1))
                    (memo-fib (- n 2)))]))))

(memo-fib 10)