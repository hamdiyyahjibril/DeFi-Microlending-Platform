;; Risk Assessment Contract

(define-constant ERR_INVALID_AMOUNT (err u400))

(define-read-only (assess-risk (borrower principal) (loan-amount uint))
  (let
    ((base-rate u500)  ;; 5% base rate
     (loan-size-factor (/ (* loan-amount u100) u1000000))  ;; Assume 1M is the max loan size
     (risk-score (+ u500 loan-size-factor))  ;; Simple risk score based on loan size
     (interest-rate (+ base-rate (* risk-score u2))))
    (asserts! (> loan-amount u0) ERR_INVALID_AMOUNT)
    (ok {
      risk-score: risk-score,
      suggested-interest-rate: (if (> interest-rate u3000) u3000 interest-rate)  ;; Cap at 30%
    })
  )
)

