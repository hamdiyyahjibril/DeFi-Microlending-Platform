;; Microlending Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))

(define-data-var next-loan-id uint u1)

(define-map loans
  uint
  {
    borrower: principal,
    lender: (optional principal),
    amount: uint,
    interest-rate: uint,
    term: uint,
    start-block: uint,
    status: (string-ascii 20),
    repaid-amount: uint
  }
)

(define-map user-reputation
  principal
  {
    total-loans: uint,
    repaid-loans: uint,
    current-score: uint
  }
)

(define-public (request-loan (amount uint) (term uint))
  (let
    (
      (loan-id (var-get next-loan-id))
      (borrower-rep (default-to { total-loans: u0, repaid-loans: u0, current-score: u50 }
                               (map-get? user-reputation tx-sender)))
    )
    (map-set loans loan-id
      {
        borrower: tx-sender,
        lender: none,
        amount: amount,
        interest-rate: (calculate-interest-rate (get current-score borrower-rep)),
        term: term,
        start-block: u0,
        status: "REQUESTED",
        repaid-amount: u0
      }
    )
    (var-set next-loan-id (+ loan-id u1))
    (map-set user-reputation tx-sender
      (merge borrower-rep { total-loans: (+ (get total-loans borrower-rep) u1) }))
    (ok loan-id)
  )
)

(define-public (fund-loan (loan-id uint))
  (let
    (
      (loan (unwrap! (map-get? loans loan-id) err-not-found))
    )
    (asserts! (is-eq (get status loan) "REQUESTED") err-unauthorized)
    (asserts! (is-none (get lender loan)) err-unauthorized)
    (try! (stx-transfer? (get amount loan) tx-sender (get borrower loan)))
    (map-set loans loan-id
      (merge loan
        {
          lender: (some tx-sender),
          start-block: block-height,
          status: "ACTIVE"
        }
      )
    )
    (ok true)
  )
)

(define-public (repay-loan (loan-id uint) (repayment-amount uint))
  (let
    (
      (loan (unwrap! (map-get? loans loan-id) err-not-found))
      (lender (unwrap! (get lender loan) err-not-found))
    )
    (asserts! (is-eq (get borrower loan) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status loan) "ACTIVE") err-unauthorized)
    (try! (stx-transfer? repayment-amount tx-sender lender))
    (let
      (
        (new-repaid-amount (+ (get repaid-amount loan) repayment-amount))
        (total-due (calculate-total-due loan))
      )
      (map-set loans loan-id (merge loan { repaid-amount: new-repaid-amount }))
      (if (>= new-repaid-amount total-due)
        (begin
          (map-set loans loan-id (merge loan { status: "REPAID", repaid-amount: new-repaid-amount }))
          (update-reputation tx-sender true)
        )
        true
      )
    )
    (ok true)
  )
)

(define-private (calculate-interest-rate (credit-score uint))
  (if (< credit-score u20)
    u15  ;; 15% interest rate for very low credit scores
    (if (< credit-score u40)
      u12  ;; 12% interest rate for low credit scores
      (if (< credit-score u60)
        u9   ;; 9% interest rate for medium credit scores
        (if (< credit-score u80)
          u6   ;; 6% interest rate for good credit scores
          u3   ;; 3% interest rate for excellent credit scores
        )
      )
    )
  )
)

(define-private (calculate-total-due (loan { amount: uint, interest-rate: uint, term: uint, borrower: principal, lender: (optional principal), repaid-amount: uint, start-block: uint, status: (string-ascii 20) }))
  (let
    (
      (interest-amount (/ (* (get amount loan) (get interest-rate loan) (get term loan)) u100))
    )
    (+ (get amount loan) interest-amount)
  )
)

(define-private (update-reputation (user principal) (repaid bool))
  (let
    (
      (user-rep (default-to { total-loans: u0, repaid-loans: u0, current-score: u50 }
                           (map-get? user-reputation user)))
    )
    (if repaid
      (let
        (
          (new-repaid-loans (+ (get repaid-loans user-rep) u1))
          (new-score (if (> (+ (get current-score user-rep) u5) u100)
                         u100
                         (+ (get current-score user-rep) u5)))
        )
        (map-set user-reputation user
          (merge user-rep
            {
              repaid-loans: new-repaid-loans,
              current-score: new-score
            }
          )
        )
      )
      (let
        (
          (new-score (if (< (- (get current-score user-rep) u10) u0)
                         u0
                         (- (get current-score user-rep) u10)))
        )
        (map-set user-reputation user
          (merge user-rep { current-score: new-score })
        )
      )
    )
  )
)

(define-read-only (get-loan (loan-id uint))
  (ok (unwrap! (map-get? loans loan-id) err-not-found))
)

(define-read-only (get-user-reputation (user principal))
  (ok (default-to { total-loans: u0, repaid-loans: u0, current-score: u50 }
                 (map-get? user-reputation user)))
)

