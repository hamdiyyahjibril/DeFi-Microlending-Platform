;; Loan Management Contract

(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))

(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    lender: principal,
    amount: uint,
    interest-rate: uint,
    term: uint,
    start-block: uint,
    status: (string-ascii 20)
  }
)

(define-data-var loan-nonce uint u0)

(define-public (create-loan (amount uint) (interest-rate uint) (term uint))
  (let
    ((loan-id (+ (var-get loan-nonce) u1))
     (loan {
       borrower: tx-sender,
       lender: tx-sender,
       amount: amount,
       interest-rate: interest-rate,
       term: term,
       start-block: block-height,
       status: "pending"
     }))
    (map-set loans { loan-id: loan-id } loan)
    (var-set loan-nonce loan-id)
    (ok loan-id)
  )
)

(define-public (fund-loan (loan-id uint))
  (let
    ((loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status loan) "pending") ERR_UNAUTHORIZED)
    (try! (stx-transfer? (get amount loan) tx-sender (get borrower loan)))
    (ok (map-set loans { loan-id: loan-id }
      (merge loan {
        lender: tx-sender,
        status: "active"
      })
    ))
  )
)

(define-read-only (calculate-repayment-amount (loan-id uint))
  (let
    ((loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR_NOT_FOUND)))
    (ok (+
      (get amount loan)
      (/
        (* (get amount loan) (get interest-rate loan) (get term loan))
        u10000
      )
    ))
  )
)

(define-public (repay-loan (loan-id uint))
  (let
    ((loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR_NOT_FOUND))
     (repayment-amount (unwrap! (calculate-repayment-amount loan-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status loan) "active") ERR_UNAUTHORIZED)
    (asserts! (is-eq (get borrower loan) tx-sender) ERR_UNAUTHORIZED)
    (try! (stx-transfer? repayment-amount tx-sender (get lender loan)))
    (ok (map-set loans { loan-id: loan-id }
      (merge loan { status: "repaid" })
    ))
  )
)

(define-read-only (get-loan (loan-id uint))
  (ok (unwrap! (map-get? loans { loan-id: loan-id }) ERR_NOT_FOUND))
)

