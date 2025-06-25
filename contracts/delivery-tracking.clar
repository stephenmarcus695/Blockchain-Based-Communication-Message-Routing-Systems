;; Delivery Tracking Contract
;; Tracks message delivery status and history

(define-constant ERR_MESSAGE_NOT_FOUND (err u300))
(define-constant ERR_INVALID_STATUS (err u301))
(define-constant ERR_UNAUTHORIZED_UPDATE (err u302))

;; Message tracking data
(define-map messages
  { message-id: uint }
  {
    sender: principal,
    recipient: principal,
    route-id: uint,
    status: (string-ascii 20),
    timestamp: uint,
    delivery-attempts: uint,
    last-hop: uint
  }
)

;; Delivery history
(define-map delivery-history
  { message-id: uint, hop-number: uint }
  {
    router-id: uint,
    timestamp: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-message-id uint u1)

;; Create new message tracking entry
(define-public (track-new-message (recipient principal) (route-id uint))
  (let ((message-id (var-get next-message-id)))
    (map-set messages
      { message-id: message-id }
      {
        sender: tx-sender,
        recipient: recipient,
        route-id: route-id,
        status: "pending",
        timestamp: block-height,
        delivery-attempts: u0,
        last-hop: u0
      }
    )
    (var-set next-message-id (+ message-id u1))
    (ok message-id)
  )
)

;; Update message status
(define-public (update-message-status (message-id uint) (new-status (string-ascii 20)) (router-id uint))
  (match (map-get? messages { message-id: message-id })
    message-data
    (let ((hop-number (+ (get last-hop message-data) u1)))
      (map-set messages
        { message-id: message-id }
        (merge message-data {
          status: new-status,
          last-hop: hop-number,
          delivery-attempts: (+ (get delivery-attempts message-data) u1)
        })
      )
      (map-set delivery-history
        { message-id: message-id, hop-number: hop-number }
        {
          router-id: router-id,
          timestamp: block-height,
          status: new-status
        }
      )
      (ok true)
    )
    ERR_MESSAGE_NOT_FOUND
  )
)

;; Mark message as delivered
(define-public (mark-delivered (message-id uint) (router-id uint))
  (update-message-status message-id "delivered" router-id)
)

;; Mark message as failed
(define-public (mark-failed (message-id uint) (router-id uint))
  (update-message-status message-id "failed" router-id)
)

;; Get message status
(define-read-only (get-message-status (message-id uint))
  (map-get? messages { message-id: message-id })
)

;; Get delivery history for a message
(define-read-only (get-delivery-hop (message-id uint) (hop-number uint))
  (map-get? delivery-history { message-id: message-id, hop-number: hop-number })
)

;; Check if message is delivered
(define-read-only (is-message-delivered (message-id uint))
  (match (map-get? messages { message-id: message-id })
    message-data
    (is-eq (get status message-data) "delivered")
    false
  )
)
