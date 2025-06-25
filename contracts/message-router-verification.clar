;; Message Router Verification Contract
;; Validates communication message routers and manages router registry

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ROUTER_NOT_FOUND (err u101))
(define-constant ERR_ROUTER_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_ROUTER (err u103))

;; Router data structure
(define-map routers
  { router-id: uint }
  {
    owner: principal,
    endpoint: (string-ascii 256),
    status: (string-ascii 20),
    reputation-score: uint,
    last-verified: uint
  }
)

(define-data-var next-router-id uint u1)

;; Register a new message router
(define-public (register-router (endpoint (string-ascii 256)))
  (let ((router-id (var-get next-router-id)))
    (asserts! (is-none (map-get? routers { router-id: router-id })) ERR_ROUTER_ALREADY_EXISTS)
    (map-set routers
      { router-id: router-id }
      {
        owner: tx-sender,
        endpoint: endpoint,
        status: "active",
        reputation-score: u100,
        last-verified: block-height
      }
    )
    (var-set next-router-id (+ router-id u1))
    (ok router-id)
  )
)

;; Verify router status
(define-public (verify-router (router-id uint))
  (match (map-get? routers { router-id: router-id })
    router-data
    (begin
      (map-set routers
        { router-id: router-id }
        (merge router-data { last-verified: block-height })
      )
      (ok true)
    )
    ERR_ROUTER_NOT_FOUND
  )
)

;; Update router reputation
(define-public (update-reputation (router-id uint) (new-score uint))
  (match (map-get? routers { router-id: router-id })
    router-data
    (begin
      (asserts! (is-eq (get owner router-data) tx-sender) ERR_UNAUTHORIZED)
      (map-set routers
        { router-id: router-id }
        (merge router-data { reputation-score: new-score })
      )
      (ok true)
    )
    ERR_ROUTER_NOT_FOUND
  )
)

;; Get router information
(define-read-only (get-router (router-id uint))
  (map-get? routers { router-id: router-id })
)

;; Check if router is active
(define-read-only (is-router-active (router-id uint))
  (match (map-get? routers { router-id: router-id })
    router-data
    (is-eq (get status router-data) "active")
    false
  )
)
