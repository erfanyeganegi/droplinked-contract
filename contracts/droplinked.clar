
;; title: droplinked smart contract
;; version: 1.0.0
;; summary: droplinked is the decentralized commerce infrastructure protocol
;; description: droplinked is a commerce infrastructure network operating as a decentralized inventory management and sales tracking system for digital and physical goods. 

;; traits
(impl-trait .sft-trait.sft-trait)

;; token definitions
(define-fungible-token product)
(define-non-fungible-token sku uint)

;; constants
(define-constant err-producer-only (err u100))
(define-constant err-publisher-only (err u101))
(define-constant err-creator-only (err u102))
(define-constant err-publisher-producer-selfsame (err u103))
(define-constant err-unauthorized (err u104))

(define-constant err-publisher-chain-invalid (err u600))

(define-constant err-request-reduplicating (err u700))
(define-constant err-request-invalid (err u701))
(define-constant err-request-not-pending (err u702))
(define-constant err-request-exceeded-max-depth (err u703))

(define-constant err-insufficient-producer-supply (err u800))

(define-constant err-invalid-price (err u900))
(define-constant err-invalid-supply (err u901))
(define-constant err-invalid-commission (err u902))
(define-constant err-invalid-uri (err u902))
(define-constant err-invalid-amount (err u903))
(define-constant err-invalid-product-id (err u904))

(define-constant request-status-pending u0)
(define-constant request-status-accepted u1)

;; data vars
(define-data-var product-id-head uint u0)

;; data maps
(define-map holdings 
  {
    product-id: uint,
    owner: principal 
  }
  uint
)

(define-map prices uint uint)

(define-map commissions 
  { 
    product-id: uint,
    publisher: principal 
  } 
  uint
)

(define-map requests 
  {
    product-id: uint,
    publisher: principal,
    producer: principal
  }
  { 
    amount: uint,
    commission: uint,
    status: uint
  }  
)

(define-map publishers-chain
  {
    product-id: uint,
    publisher: principal
  }
  {
    previous: (optional principal),
    depth: uint
  }
)

(define-map supplies uint uint)

(define-map uris uint (string-ascii 256))

;; public functions

(define-public
  (transfer
    (product-id uint)
    (amount uint)
    (producer principal)
    (publisher principal)
  )
  (let 
    (
      (producer-balance (unwrap-panic (get-balance product-id producer)))
      (publisher-balance (unwrap-panic (get-balance product-id publisher)))
    )
    (asserts! (is-eq tx-sender (as-contract tx-sender)) err-unauthorized)
    (asserts! (<= amount producer-balance) err-insufficient-producer-supply)
    (map-set holdings { product-id: product-id, owner: producer } (- producer-balance amount))
    (map-set holdings { product-id: product-id, owner: publisher } (+ publisher-balance amount))
    (print 
      {
        type: "sft_transfer",
        token-id: product-id,
        amount: amount,
        sender: producer,
        recipient: publisher
      }
    )
    (ok true)
  )
)

(define-public
  (transfer-memo
    (product-id uint)
    (amount uint)
    (producer principal)
    (publisher principal)
    (memo (buff 34))
  )
  (begin 
    (asserts! (is-eq tx-sender (as-contract tx-sender)) err-unauthorized)
    (print memo)
    (ok (try! (as-contract (transfer product-id amount producer publisher))))
  )
)

(define-public
  (create-product
    (price uint) 
    (supply uint)
    (commission uint)
    (uri (string-ascii 256))
    (producer principal)
  )
  (let ((product-id (+ (var-get product-id-head) u1)))
    (asserts! (is-eq producer tx-sender) err-producer-only)
    (asserts! (>= price u1) err-invalid-price)
    (asserts! (>= supply u1) err-invalid-supply)
    (asserts! (and (>= commission u0) (<= commission u100)) err-invalid-commission)
    (asserts! (> (len uri) u0) err-invalid-uri)
    (try! (nft-mint? sku product-id (as-contract tx-sender)))
    (try! (ft-mint? product supply (as-contract tx-sender)))
    (map-insert holdings { product-id: product-id, owner: producer } supply)
    (map-insert supplies product-id supply)
    (map-insert prices product-id price)
    (map-insert uris product-id uri)
    (map-insert commissions { product-id: product-id, publisher: producer } commission)
    (map-insert publishers-chain
      { product-id: product-id, publisher: producer }
      { previous: none, depth: u0 }
    )
    (print 
      {
        type: "sft_mint",
        token-id: product-id,
        amount: supply,
        recipient: producer
      }
    )
    (print 
      {
        function: "create-product",
        product-id: product-id,
        supply: supply,
        producer: producer
      }
    )
    (var-set product-id-head product-id)
    (ok product-id)
  )
)

(define-public 
  (request-product
    (publisher principal)
    (producer principal)
    (product-id uint)
    (amount uint)
    (commission uint)
  )
  (let
    (
      (producer-commission (unwrap-panic (get-commission producer product-id)))
    ) 
    (asserts! (is-eq publisher tx-sender) err-publisher-only)
    (asserts! (not (is-eq publisher producer)) err-publisher-producer-selfsame)
    (asserts! (>= amount u1) err-invalid-amount)
    (asserts! (and (>= commission u1) (<= commission producer-commission)) err-invalid-commission)
    (asserts! (>= (unwrap-panic (get-balance product-id producer)) amount) err-insufficient-producer-supply)
    (asserts! (is-none (map-get? requests { product-id: product-id, publisher: publisher, producer: producer })) err-request-reduplicating)
    (ok (map-insert requests 
      {
        product-id: product-id,
        publisher: publisher,
        producer: producer
      }
      {
        amount: amount,
        commission: commission,
        status: request-status-pending
      }
    ))
  )
)

(define-public
  (cancel-request
    (request-key 
      { 
        product-id: uint,
        publisher: principal,
        producer: principal
      }
    )
  )
  (let ((request (unwrap! (map-get? requests request-key) err-request-invalid)))
    (asserts! (is-eq (get publisher request-key) tx-sender) err-publisher-only)
    (asserts! (is-eq (get status request) request-status-pending) err-request-not-pending)
    (ok (map-delete requests request-key))
  )
)

(define-public
  (reject-request
    (request-key 
      {
        product-id: uint,
        publisher: principal,
        producer: principal
      }
    )
  )
  (let ((request (unwrap! (map-get? requests request-key) err-request-invalid)))
    (asserts! (is-eq (get producer request-key) tx-sender) err-producer-only)
    (asserts! (is-eq (get status request) request-status-pending) err-request-not-pending)
    (ok (map-delete requests request-key))
  )
)

(define-public
  (accept-request 
    (request-key
      {
        product-id: uint,
        publisher: principal,
        producer: principal
      }
    )
  )
  (let 
    (
      (product-id (get product-id request-key))
      (publisher (get publisher request-key))
      (producer (get producer request-key))
      (request (unwrap! (map-get? requests request-key) err-request-invalid))
      (producer-chain (unwrap! (map-get? publishers-chain { product-id: product-id, publisher: producer }) err-publisher-chain-invalid))
      (depth (+ (get depth producer-chain) u1))
    )
    (asserts! (is-eq (get producer request-key) tx-sender) err-producer-only)
    (asserts! (<= depth u5) err-request-exceeded-max-depth)
    (try! (as-contract (transfer product-id (get amount request) producer publisher)))
    (map-insert commissions { product-id: product-id, publisher: publisher } (get commission request))
    (map-insert publishers-chain
      { product-id: product-id, publisher: publisher }
      { previous: (some producer), depth: depth }
    )
    (ok (map-set requests request-key (merge request { status: request-status-accepted })))
  )
)

(define-public 
  (purchase-product
    (purchaser principal)
    (product-id uint)
    (publisher principal)
    (price uint)
  )
  (let 
    (
      (product-price (unwrap! (map-get? prices product-id) (err u0)))
      (publisher-balance (unwrap-panic (get-balance product-id publisher)))
      (publisher-commission (unwrap-panic (get-commission publisher product-id)))
      (difference (- price product-price))
      (fee (/ product-price u100))
    )
    (asserts! (is-eq purchaser tx-sender) (err u0))
    (asserts! (>= publisher-balance u1) (err u0))
    (asserts! (>= price product-price) (err u0))
    (asserts! (>= (stx-get-balance purchaser) price) (err u0))
    (try! (stx-transfer? difference purchaser publisher))
    (try! (stx-transfer? fee purchaser (as-contract tx-sender)))
    (fold purchase-product-iter 0x000000000000
      (ok
        {
          publisher: (some publisher),
          product-id: product-id,
          price: (- product-price fee),
          previous-commission: u0
        }
      )
    )
  )
)

;; read only functions
(define-read-only
  (get-balance
    (id uint)
    (owner principal)
  )
  (ok (default-to u0 (map-get? holdings 
    {
      product-id: id,
      owner: owner
    }
  )))
)

(define-read-only
  (get-decimals
    (id uint)
  )
  (ok u0)  
)

(define-read-only
  (get-overall-balance
    (owner principal)
  ) 
  (ok (ft-get-balance product owner))
)

(define-read-only 
  (get-overall-supply)
  (ok (ft-get-supply product))
)

(define-read-only 
  (get-token-uri
    (id uint)
  ) 
  (ok (default-to none (some (map-get? uris id))))
)

(define-read-only
  (get-total-supply
    (id uint)
  ) 
  (ok (default-to u0 (map-get? supplies id)))
)

(define-read-only
  (get-commission
    (publisher principal)
    (product-id uint)
  ) 
  (ok (default-to u0 (map-get? commissions
    {
      product-id: product-id,
      publisher: publisher
    }
  )))
)

;; private functions

;; #[allow(unchecked_data)]
(define-private 
  (purchase-product-iter
    (index (buff 1))
    (data-response
      (response 
        {
          publisher: (optional principal),
          product-id: uint,
          price: uint,
          previous-commission: uint,
        }
        uint
      )
    )
  )
  (let 
    (
      (data (unwrap! data-response (ok { publisher: none, product-id: u0, price: u0, previous-commission: u0 })))
      (publisher (get publisher data))
      (product-id (get product-id data))
      (price (get price data))
    )
    (match publisher publisher-value 
      (let 
        (
          (previous-commission (get previous-commission data))
          (publisher-commission (unwrap-panic (get-commission publisher-value product-id)))
          (publisher-share (/ (* (- publisher-commission previous-commission) price) u100))
          (next-chain (map-get? publishers-chain { product-id: product-id, publisher: publisher-value }))
        )
        (print 
          {
            price: price,
            next-chain: next-chain,
            previous: (unwrap-panic (get previous next-chain))
          }
        )
        (match (unwrap-panic (get previous next-chain)) next-publisher
          (begin
            (try! (stx-transfer? publisher-share tx-sender publisher-value))
            (ok { publisher: (some next-publisher), product-id: product-id, price: (- price publisher-share), previous-commission: publisher-commission })
          )
          (begin
            (try! (stx-transfer? price tx-sender publisher-value))
            (ok { publisher: none, product-id: u0, price: u0, previous-commission: u0 })
          )
        )
      )
      (begin 
        (ok { publisher: none, product-id: u0, price: u0, previous-commission: u0 })
      )
    )
  )
)
