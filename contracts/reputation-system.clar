;; Reputation System Contract

(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))

(define-map borrower-scores
  { borrower: principal }
  { score: uint }
)

(define-map loan-repayments
  { loan-id: uint }
  { on-time: bool }
)

(define-public (update-repayment-status (loan-id uint) (on-time bool))
  (ok (map-set loan-repayments { loan-id: loan-id } { on-time: on-time }))
)

(define-public (calculate-reputation (borrower principal))
  (let
    ((current-score (default-to { score: u500 } (map-get? borrower-scores { borrower: borrower })))
     (repayments (map-get? loan-repayments { loan-id: u0 }))
     (new-score (if (is-some repayments)
                    (if (get on-time (unwrap-panic repayments))
                        (if (>= (+ (get score current-score) u50) u1000) u1000 (+ (get score current-score) u50))
                        (if (<= (- (get score current-score) u50) u0) u0 (- (get score current-score) u50)))
                    (get score current-score))))
    (ok (map-set borrower-scores { borrower: borrower } { score: new-score }))
  )
)

(define-read-only (get-borrower-score (borrower principal))
  (ok (get score (default-to { score: u500 } (map-get? borrower-scores { borrower: borrower }))))
)

