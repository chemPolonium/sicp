#lang sicp

; PARTS

(define (half-adder a b s c)
  (let ([d (make-wire)] [e (make-wire)])
    (or-gate a b d)
    (and-gate a b c)
    (inverter c e)
    (and-gate d e s)
    'ok))

(define (full-adder a b c-in sum c-out)
  (let ([s (make-wire)] [c1 (make-wire)] [c2 (make-wire)])
    (half-adder b c-in s c1)
    (half-adder a s sum c2)
    (or-gate c1 c2 c-out)
    'ok))

(define (inverter input output)
  (define (invert-input)
    (let ([new-value (logical-not (get-signal input))])
      (after-delay inverter-delay
                   (lambda ()
                     (newline)
                     (display "inverter triggered at time ")
                     (display (current-time the-agenda))
                     (display ", new value: ")
                     (display new-value)
                     (newline)
                     (set-signal! output new-value)))))
  (add-action! input invert-input) 'ok)

(define (logical-not s)
  (cond [(= s 0) 1]
        [(= s 1) 0]
        [else (error "Invalid signal" s)]))

(define (and-gate a1 a2 output)
  (define (and-action-procedure)
    (let ([new-value
           (logical-and (get-signal a1) (get-signal a2))])
      (after-delay and-gate-delay
                   (lambda ()
                     (newline)
                     (display "and-gate triggered at time ")
                     (display (current-time the-agenda))
                     (display ", new value: ")
                     (display new-value)
                     (newline)
                     (set-signal! output new-value)))))
  (add-action! a1 and-action-procedure)
  (add-action! a2 and-action-procedure)
  'ok)

(define (logical-and s1 s2)
  (cond [(and (= s1 1) (= s2 1)) 1]
        [(and (= s1 0) (= s2 0)) 0]
        [(and (= s1 1) (= s2 0)) 0]
        [(and (= s1 0) (= s2 1)) 0]
        [else (error "Invalid signal" s1 s2)]))

(define (or-gate a1 a2 output)
  (define (or-action-procedure)
    (let ([new-value
           (logical-or (get-signal a1) (get-signal a2))])
      (after-delay or-gate-delay
                   (lambda ()
                     (newline)
                     (display "or-gate triggered at time ")
                     (display (current-time the-agenda))
                     (display ", new value: ")
                     (display new-value)
                     (newline)
                     (set-signal! output new-value)))))
  (add-action! a1 or-action-procedure)
  (add-action! a2 or-action-procedure)
  'ok)

(define (logical-or s1 s2)
  (cond [(and (= s1 1) (= s2 1)) 1]
        [(and (= s1 0) (= s2 0)) 0]
        [(and (= s1 1) (= s2 0)) 1]
        [(and (= s1 0) (= s2 1)) 1]
        [else (error "Invalid signal" s1 s2)]))

(define (make-wire)
  (let ([signal-value 0]
        [action-procedures '()])
    (define (set-my-signal! new-value)
      (if (not (= signal-value new-value))
          (begin (set! signal-value new-value)
                 (call-each action-procedures))
          'done))
    (define (accept-action-procedure! proc)
      (set! action-procedures
            (cons proc action-procedures))
      (proc)
      )
    (define (dispatch m)
      (cond [(eq? m 'get-signal) signal-value]
            [(eq? m 'set-signal!) set-my-signal!]
            [(eq? m 'add-action!) accept-action-procedure!]
            [else (error "Unknown operation: WIRE" m)]))
    dispatch))

(define (call-each procedures)
  (if (null? procedures)
      'done
      (begin ((car procedures))
             (call-each (cdr procedures)))))

(define (get-signal wire) (wire 'get-signal))

(define (set-signal! wire new-value)
  ((wire 'set-signal!) new-value))

(define (add-action! wire action-procedure)
  ((wire 'add-action!) action-procedure))

(define (after-delay delay action)
  (add-to-agenda! (+ delay (current-time the-agenda))
                  action
                  the-agenda))

(define (propagate)
  (if (empty-agenda? the-agenda)
      'done
      (let ([first-item (first-agenda-item the-agenda)])
        (first-item)
        (remove-first-agenda-item! the-agenda)
        (propagate))))

(define (probe name wire)
  (add-action! wire
               (lambda ()
                 (newline)
                 (display name) (display " ")
                 (display (current-time the-agenda))
                 (display "  New-value = ")
                 (display (get-signal wire))
                 (newline))))

; AGENDA DEFINITION

(define (make-time-segment time queue)
  (cons time queue))

(define (segment-time s) (car s))

(define (segment-queue s) (cdr s))

(define (make-agenda) (list 0))

(define (current-time agenda) (car agenda))

(define (set-current-time! agenda time)
  (set-car! agenda time))

(define (segments agenda) (cdr agenda))

(define (set-segments! agenda segments)
  (set-cdr! agenda segments))

(define (first-segment agenda) (car (segments agenda)))

(define (rest-segments agenda) (cdr (segments agenda)))

(define (empty-agenda? agenda) (null? (segments agenda)))

(define (add-to-agenda! time action agenda)
  (define (belongs-before? segments)
    (or (null? segments)
        (< time (segment-time (car segments)))))
  (define (make-new-time-segment time action)
    (let ([q (make-queue)])
      (insert-queue! q action)
      (make-time-segment time q)))
  (define (add-to-segments! segments)
    (if (= (segment-time (car segments)) time)
        (insert-queue! (segment-queue (car segments))
                       action)
        (let ([rest (cdr segments)])
          (if (belongs-before? rest)
              (set-cdr!
               segments
               (cons (make-new-time-segment time action)
                     (cdr segments)))
              (add-to-segments! rest)))))
  (let ([segments (segments agenda)])
    (if (belongs-before? segments)
        (set-segments!
         agenda
         (cons (make-new-time-segment time action)
               segments))
        (add-to-segments! segments))))

(define (remove-first-agenda-item! agenda)
  (let ([q (segment-queue (first-segment agenda))])
    (delete-queue! q)
    (if (empty-queue? q)
        (set-segments! agenda (rest-segments agenda)))))

(define (first-agenda-item agenda)
  (if (empty-agenda? agenda)
      (error "Agenda is empty: FIRST-AGENDA-ITEM")
      (let ([first-seg (first-segment agenda)])
        (set-current-time! agenda
                           (segment-time first-seg))
        (front-queue (segment-queue first-seg)))))

; QUEUE DEFINITION

(define (make-queue) (cons '() '()))

(define (empty-queue? queue)
  (null? (front-ptr queue)))

(define (front-ptr queue) (car queue))

(define (rear-ptr queue) (cdr queue))

(define (set-front-ptr! queue item)
  (set-car! queue item))

(define (set-rear-ptr! queue item)
  (set-cdr! queue item))

(define (front-queue queue)
  (if (empty-queue? queue)
      (error "FRONT called with an empty queue" queue)
      (car (front-ptr queue))))

(define (insert-queue! queue item)
  (let ([new-pair (cons item '())])
    (cond [(empty-queue? queue)
           (set-front-ptr! queue new-pair)
           (set-rear-ptr! queue new-pair)
           queue]
          [else
           (set-cdr! (rear-ptr queue) new-pair)
           (set-rear-ptr! queue new-pair)
           queue])))

(define (delete-queue! queue)
  (cond [(empty-queue? queue)
         (error "DELETE! called with an empty queue" queue)]
        [else
         (set-front-ptr! queue (cdr (front-ptr queue)))
         queue]))

; TIME DEFINITION

(define inverter-delay 2)
(define and-gate-delay 3)
(define or-gate-delay 5)

; SIMULATION

(define the-agenda (make-agenda))

(define input-1 (make-wire))
(define input-2 (make-wire))
(define sum (make-wire))
(define carry (make-wire))

(probe 'sum sum)
; sum 0 New-value = 0
(probe 'carry carry)
; carry 0 New-value = 0
(half-adder input-1 input-2 sum carry)
; ok
(set-signal! input-1 1)
; done
(propagate)
; sum 8 New-value = 1
; done
(set-signal! input-2 1)
; done
(propagate)
; carry 11 New-value = 1
; sum 16 New-value = 0
; done
(current-time the-agenda)

;;; CORRRECT

; TIME INPUT-1 INPUT-2 D E SUM CARRY
; 0    0       0       0 0 0   0
; WILL SET D TO 0 AT 5 BY OR-GATE
; WILL SET C TO 0 AT 3 BY AND-GATE-1
; WILL SET E TO 1 AT 2 BY INVERTER
; WILL SET S TO 0 AT 3 BY AND-GATE-2

; SET INPUT-1 TO 1
; 0    1       0       0 0 0   0
; WILL SET D TO 1 AT 5 BY OR-GATE

; INVERTER TRIGGERED, E CHANGED TO 1
; 2    1       0       0 1 0   0
; WILL SET S TO 0 AT 5 BY AND-GATE-2

; AND-GATE-1 TRIGGERED, C NOT CHANGED
; 3    1       0       0 1 0   0

; AND-GATE-2 TRIGGERED, S NOT CHANGED
; 3    1       0       0 1 0   0

; OR-GATE TRIGGERED, D NOT CHANGED
; 5    1       0       0 1 0   0

; OR-GATE TRIGGERED, D SET TO 1
; 5    1       0       1 1 0   0
; WILL SET S TO 1 AT 8 BY AND-GATE-2

; AND-GATE-2 TRIGGERED, S NOT CHANGED
; 5    1       0       1 1 0   0

; AND-GATE TRIGGERED, S SET TO 1
; 8    1       0       1 1 1   0

; SET INPUT-2 TO 1
; 8    1       1       1 1 1   0
; WILL SET D TO 1 AT 13 BY OR-GATE
; WILL SET C TO 1 AT 11 BY AND-GATE-1

; AND-GATE-1 TRIGGERED, C SET TO 1
; 11   1       1       1 1 1   1
; WILL SET E TO 0 AT 13 BY INVERTER

; OR-GATE TRIGGERED, D NOT CHANGED
; 13   1       1       1 1 1   1

; INVERTER TRIGGERED, E CHANGED TO 0
; 13   1       1       1 0 1   1
; WILL SET S TO 0 AT 16 BY AND-GATE-2

; AND-GATE-2 TRIGGERED, S SET TO 0
; 16   1       1       1 0 0   1

;;; WRONG

; TIME INPUT-1 INPUT-2 D E SUM CARRY
; 0    0       0       0 0 0   0

; SET INPUT-1 TO 1
; 0    1       0       0 0 0   0
; WILL SET D TO 1 AT 5 BY OR-GATE
; WILL SET C TO 0 AT 3 BY AND-GATE-1

; AND-GATE-1 TRIGGERED, C NOT CHANGED
; 3    1       0       0 0 0   0

; OR-GATE TRIGGERED, D CHANGED TO 1
; 5    1       0       1 0 0   0
; WILL SET S TO 0 AT 8 BY AND-GATE-2

; AND-GATE-2 TRIGGERED, S NOT CHANGED
; 8    1       0       1 0 0   0

; SET INPUT-2 TO 1
; 8    1       1       1 0 0   0
; WILL SET D TO 1 AT 13 BY OR-GATE
; WILL SET C TO 1 AT 11 BY AND-GATE-1

; AND-GATE TRIGGERED, C CHANGED TO 1
; 11   1       1       1 0 0   1
; WILL SET E TO 0 AT 13 BY INVERTER

; OR-GATE TRIGGERED, D NOT CHANGED
; 13   1       1       1 0 0   1

; INVERTER TRIGGERED, E NOT CHANGED
; 13   1       1       1 0 0   1