
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_PERCENTAGE (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_NOT_FOUND (err u103))
(define-constant ERR_ALREADY_EXISTS (err u104))
(define-constant ERR_INVALID_PARAMS (err u105))
(define-constant ERR_CONSENSUS_REQUIRED (err u106))
(define-constant ERR_ALREADY_SIGNED (err u107))
(define-constant MAX_PARTICIPANTS u10)
(define-constant MAX_PERCENTAGE u10000)

(define-data-var contract-owner principal tx-sender)
(define-data-var next-contract-id uint u1)
(define-data-var total-distributed uint u0)
(define-data-var pending-updates uint u0)

(define-map revenue-contracts uint {
  name: (string-ascii 64),
  created-by: principal,
  total-participants: uint,
  total-revenue: uint,
  is-active: bool,
  last-distribution: uint,
  update-proposal: (optional uint)
})

(define-map contract-participants { contract-id: uint, participant: principal } {
  percentage: uint,
  total-earned: uint,
  is-active: bool,
  join-block: uint
})

(define-map participant-balances { contract-id: uint, participant: principal } uint)

(define-map update-proposals uint {
  contract-id: uint,
  proposed-by: principal,
  signatures-required: uint,
  signatures-count: uint,
  is-executed: bool,
  created-at: uint
})

(define-map proposal-signatures { proposal-id: uint, signer: principal } bool)

(define-map new-participant-data { proposal-id: uint, participant: principal } uint)

(define-public (create-revenue-contract (name (string-ascii 64)) (participants (list 10 { participant: principal, percentage: uint })))
  (let (
    (contract-id (var-get next-contract-id))
    (total-percentage (fold + (map get-percentage participants) u0))
  )
    (asserts! (is-eq (len participants) (len (get-unique-participants participants))) ERR_INVALID_PARAMS)
    (asserts! (is-eq total-percentage MAX_PERCENTAGE) ERR_INVALID_PERCENTAGE)
    (asserts! (> (len participants) u0) ERR_INVALID_PARAMS)
    (asserts! (<= (len participants) MAX_PARTICIPANTS) ERR_INVALID_PARAMS)
    
    (map-set revenue-contracts contract-id {
      name: name,
      created-by: tx-sender,
      total-participants: (len participants),
      total-revenue: u0,
      is-active: true,
      last-distribution: stacks-block-height,
      update-proposal: none
    })
    
    (fold add-participant-to-contract participants contract-id)
    (var-set next-contract-id (+ contract-id u1))
    (ok contract-id)
  )
)

(define-public (deposit-revenue (contract-id uint))
  (let (
    (contract-info (unwrap! (map-get? revenue-contracts contract-id) ERR_NOT_FOUND))
    (amount (stx-get-balance tx-sender))
  )
    (asserts! (get is-active contract-info) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_PARAMS)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set revenue-contracts contract-id
      (merge contract-info { total-revenue: (+ (get total-revenue contract-info) amount) })
    )
    
    (ok amount)
  )
)

(define-public (distribute-revenue (contract-id uint))
  (let (
    (contract-info (unwrap! (map-get? revenue-contracts contract-id) ERR_NOT_FOUND))
    (available-balance (as-contract (stx-get-balance tx-sender)))
  )
    (asserts! (get is-active contract-info) ERR_UNAUTHORIZED)
    (asserts! (> available-balance u0) ERR_INSUFFICIENT_BALANCE)
    
    (let (
      (distribution-result (distribute-to-participants contract-id available-balance))
    )
      (map-set revenue-contracts contract-id
        (merge contract-info { last-distribution: stacks-block-height })
      )
      (var-set total-distributed (+ (var-get total-distributed) available-balance))
      (ok available-balance)
    )
  )
)

(define-public (withdraw-earnings (contract-id uint))
  (let (
    (participant-balance (default-to u0 (map-get? participant-balances { contract-id: contract-id, participant: tx-sender })))
  )
    (asserts! (> participant-balance u0) ERR_INSUFFICIENT_BALANCE)
    
    (map-delete participant-balances { contract-id: contract-id, participant: tx-sender })
    
    (as-contract (stx-transfer? participant-balance tx-sender tx-sender))
  )
)

(define-public (propose-update (contract-id uint) (new-participants (list 10 { participant: principal, percentage: uint })))
  (let (
    (contract-info (unwrap! (map-get? revenue-contracts contract-id) ERR_NOT_FOUND))
    (participant-info (unwrap! (map-get? contract-participants { contract-id: contract-id, participant: tx-sender }) ERR_UNAUTHORIZED))
    (proposal-id (var-get pending-updates))
    (total-percentage (fold + (map get-percentage new-participants) u0))
  )
    (asserts! (get is-active contract-info) ERR_UNAUTHORIZED)
    (asserts! (get is-active participant-info) ERR_UNAUTHORIZED)
    (asserts! (is-none (get update-proposal contract-info)) ERR_ALREADY_EXISTS)
    (asserts! (is-eq total-percentage MAX_PERCENTAGE) ERR_INVALID_PERCENTAGE)
    
    (map-set update-proposals proposal-id {
      contract-id: contract-id,
      proposed-by: tx-sender,
      signatures-required: (get total-participants contract-info),
      signatures-count: u1,
      is-executed: false,
      created-at: stacks-block-height
    })
    
    (map-set proposal-signatures { proposal-id: proposal-id, signer: tx-sender } true)
    
    (fold store-new-participant-data new-participants proposal-id)
    
    (map-set revenue-contracts contract-id
      (merge contract-info { update-proposal: (some proposal-id) })
    )
    
    (var-set pending-updates (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (sign-update (proposal-id uint))
  (let (
    (proposal-info (unwrap! (map-get? update-proposals proposal-id) ERR_NOT_FOUND))
    (contract-id (get contract-id proposal-info))
    (participant-info (unwrap! (map-get? contract-participants { contract-id: contract-id, participant: tx-sender }) ERR_UNAUTHORIZED))
    (already-signed (default-to false (map-get? proposal-signatures { proposal-id: proposal-id, signer: tx-sender })))
  )
    (asserts! (get is-active participant-info) ERR_UNAUTHORIZED)
    (asserts! (not (get is-executed proposal-info)) ERR_UNAUTHORIZED)
    (asserts! (not already-signed) ERR_ALREADY_SIGNED)
    
    (let (
      (new-signature-count (+ (get signatures-count proposal-info) u1))
    )
      (map-set proposal-signatures { proposal-id: proposal-id, signer: tx-sender } true)
      (map-set update-proposals proposal-id
        (merge proposal-info { signatures-count: new-signature-count })
      )
      
      (if (>= new-signature-count (get signatures-required proposal-info))
        (execute-update proposal-id)
        (ok true)
      )
    )
  )
)

(define-public (deactivate-contract (contract-id uint))
  (let (
    (contract-info (unwrap! (map-get? revenue-contracts contract-id) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get created-by contract-info)) ERR_UNAUTHORIZED)
    (asserts! (get is-active contract-info) ERR_UNAUTHORIZED)
    
    (map-set revenue-contracts contract-id
      (merge contract-info { is-active: false })
    )
    (ok true)
  )
)

(define-read-only (get-contract-info (contract-id uint))
  (map-get? revenue-contracts contract-id)
)

(define-read-only (get-participant-info (contract-id uint) (participant principal))
  (map-get? contract-participants { contract-id: contract-id, participant: participant })
)

(define-read-only (get-participant-balance (contract-id uint) (participant principal))
  (default-to u0 (map-get? participant-balances { contract-id: contract-id, participant: participant }))
)

(define-read-only (get-proposal-info (proposal-id uint))
  (map-get? update-proposals proposal-id)
)

(define-read-only (has-signed-proposal (proposal-id uint) (signer principal))
  (default-to false (map-get? proposal-signatures { proposal-id: proposal-id, signer: signer }))
)

(define-read-only (get-contract-balance (contract-id uint))
  (as-contract (stx-get-balance tx-sender))
)

(define-read-only (get-total-contracts)
  (- (var-get next-contract-id) u1)
)

(define-private (get-percentage (participant-data { participant: principal, percentage: uint }))
  (get percentage participant-data)
)


(define-private (add-participant-to-contract (participant-data { participant: principal, percentage: uint }) (contract-id uint))
  (begin
    (map-set contract-participants 
      { contract-id: contract-id, participant: (get participant participant-data) }
      {
        percentage: (get percentage participant-data),
        total-earned: u0,
        is-active: true,
        join-block: stacks-block-height
      }
    )
    contract-id
  )
)

(define-private (get-unique-participants (participants (list 10 { participant: principal, percentage: uint })))
  (fold check-unique-participant participants (list))
)

(define-private (check-unique-participant (participant-data { participant: principal, percentage: uint }) (acc (list 10 principal)))
  (if (is-none (index-of acc (get participant participant-data)))
    (unwrap-panic (as-max-len? (append acc (get participant participant-data)) u10))
    acc
  )
)

(define-private (distribute-to-participants (contract-id uint) (total-amount uint))
  (ok true)
)

(define-private (store-new-participant-data (participant-data { participant: principal, percentage: uint }) (proposal-id uint))
  (begin
    (map-set new-participant-data 
      { proposal-id: proposal-id, participant: (get participant participant-data) }
      (get percentage participant-data)
    )
    proposal-id
  )
)

(define-private (execute-update (proposal-id uint))
  (let (
    (proposal-info (unwrap-panic (map-get? update-proposals proposal-id)))
    (contract-id (get contract-id proposal-info))
  )
    (map-set update-proposals proposal-id
      (merge proposal-info { is-executed: true })
    )
    (ok true)
  )
)
