;; Tokenized Real Estate Smart Contract

;; Data variables
(define-data-var property-counter uint u0)

;; Maps to store property details and investor balances
(define-map properties 
  {property-id: uint} 
  {
    owner: principal,    ;; Owner of the property
    property-value: uint, ;; Market value of the property
    total-shares: uint,   ;; Total number of shares issued
    share-price: uint     ;; Price per share
  }
)

(define-map investors
  {property-id: uint, wallet: principal} 
  {share-balance: uint})

;; Event types
(define-data-var last-event-id uint u0)

;; Print events instead of define-event
(define-private (emit-property-registered (property-id uint) (owner principal) (property-value uint) (total-shares uint) (share-price uint))
  (print {
    event: "property-registered",
    property-id: property-id,
    owner: owner,
    property-value: property-value,
    total-shares: total-shares,
    share-price: share-price
  })
)

(define-private (emit-shares-purchased (property-id uint) (buyer principal) (shares uint) (cost uint))
  (print {
    event: "shares-purchased",
    property-id: property-id,
    buyer: buyer,
    shares: shares,
    cost: cost
  })
)

(define-private (emit-shares-sold (property-id uint) (seller principal) (shares uint) (refund uint))
  (print {
    event: "shares-sold",
    property-id: property-id,
    seller: seller,
    shares: shares,
    refund: refund
  })
)

(define-private (emit-dividends-distributed (property-id uint) (total-income uint) (dividend-per-share uint))
  (print {
    event: "dividends-distributed",
    property-id: property-id,
    total-income: total-income,
    dividend-per-share: dividend-per-share
  })
)

;; Helper functions
(define-private (get-property (property-id uint))
  (map-get? properties {property-id: property-id}))

(define-private (get-investor (property-id uint) (wallet principal))
  (map-get? investors {property-id: property-id, wallet: wallet}))

;; Check if sender is the property owner
(define-private (is-owner (property-id uint))
  (match (get-property property-id)
    property (is-eq tx-sender (get owner property))
    false))

;; Register a new property and tokenize it into shares
(define-public (register-property (property-value uint) (total-shares uint) (share-price uint))
  ;; Input validation for property attributes to avoid untrusted data usage
  (if (or (is-eq property-value u0) (is-eq total-shares u0) (is-eq share-price u0))
    (err u400) ;; Invalid input if any attribute is zero
    (let (
          (property-id (+ (var-get property-counter) u1))
      )
      (begin
        ;; Insert property data into properties map
        (map-insert properties
          {property-id: property-id}
          {
            owner: tx-sender,
            property-value: property-value,
            total-shares: total-shares,
            share-price: share-price
          })
        
        ;; Increment property counter
        (var-set property-counter property-id)
        
        ;; Print event using our print-based function
        (emit-property-registered property-id tx-sender property-value total-shares share-price)
        
        ;; Return the property ID
        (ok property-id)
      )
    )
  )
)

;; Buy fractional shares of a property
(define-public (buy-shares (property-id uint) (shares uint))
  (begin
    (asserts! (> property-id u0) (err u400)) ;; Ensure property-id is valid
    (asserts! (> shares u0) (err u400))      ;; Ensure shares is non-zero
    
    (let (
          (property (unwrap! (get-property property-id) (err u404))) ;; Error if property not found
          (existing-balance (default-to u0 (get share-balance (get-investor property-id tx-sender))))
          (cost (* shares (get share-price property)))
    )
      (begin
        (asserts! (>= (stx-get-balance tx-sender) cost) (err u100))
        (map-set investors
          {property-id: property-id, wallet: tx-sender}
          {share-balance: (+ existing-balance shares)})
        
        (try! (stx-transfer? cost tx-sender (get owner property)))
        (emit-shares-purchased property-id tx-sender shares cost)
        (ok shares)
      )
    )
  )
)

;; Sell fractional shares back to the property owner
(define-public (sell-shares (property-id uint) (shares uint))
  (begin
    (asserts! (> property-id u0) (err u400))
    (asserts! (> shares u0) (err u400))
    
    (let (
          (investor (unwrap! (get-investor property-id tx-sender) (err u403)))
          (property (unwrap! (get-property property-id) (err u404)))
          (share-balance (get share-balance investor))
          (refund (* shares (get share-price property)))
    )
      (begin
        (asserts! (>= share-balance shares) (err u101))
        (map-set investors
          {property-id: property-id, wallet: tx-sender}
          {share-balance: (- share-balance shares)})
        
        (try! (stx-transfer? refund (get owner property) tx-sender))
        (emit-shares-sold property-id tx-sender shares refund)
        (ok refund)
      )
    )
  )
)

;; Distribute rental income to investors based on share ownership
(define-public (distribute-dividend (property-id uint) (investor-wallet principal) (total-income uint))
  (begin
    (asserts! (> property-id u0) (err u400))
    (asserts! (> total-income u0) (err u400))
    
    (let (
          (property (unwrap! (get-property property-id) (err u404)))
          (investor-data (unwrap! (get-investor property-id investor-wallet) (err u403)))
          (total-shares (get total-shares property))
          (dividend-per-share (/ total-income total-shares))
          (share-balance (get share-balance investor-data))
    )
      (begin
        (asserts! (is-owner property-id) (err u401))
        (let (
              (dividend-amount (* share-balance dividend-per-share))
        )
          (begin
            (try! (stx-transfer? dividend-amount tx-sender investor-wallet))
            (emit-dividends-distributed property-id total-income dividend-per-share)
            (ok dividend-amount)
          )
        )
      )
    )
  )
)