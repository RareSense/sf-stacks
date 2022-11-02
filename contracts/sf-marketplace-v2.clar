;; sf-marketplace-v2

(use-trait nft-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; bids map
;; if nft-id is `none`, the bid is a collection bid
;;    and can be accepted by anyone holding a token from
;;    that collection.

(define-map bids
  {
    collection: principal, 
    nft-id: uint,
  }
  {  
    bid-amount: uint, 
    buyer: principal, 
    seller: (optional principal), 
    expiration-block: uint, 
    action-event-index: uint,
    memo: (optional (string-ascii 256))
  }
)

(define-constant contract-address (as-contract tx-sender))
(define-constant contract-owner tx-sender)
(define-constant blocks-per-day u144)
(define-constant err-contract-not-authorized u101)
(define-constant err-placing-bids-disabled u102)
(define-constant err-accepting-bids-disabled u103)
(define-constant err-withdrawing-bids-disabled u104)
(define-constant err-user-not-authorized u105)
(define-constant err-no-bid-found u106)
(define-constant err-bid-expired u107)
(define-constant err-wrong-collection u108)
(define-constant err-wrong-nft-id u109)
(define-constant err-not-enough-bid-expiry u110)
(define-constant err-not-enough-bid-amount u111)

(define-data-var placing-bids-enabled bool true)
(define-data-var accepting-bids-enabled bool true)
(define-data-var withdrawing-bids-enabled bool true)
(define-data-var commission uint u200)
(define-data-var id uint u0)

;; #[allow(unchecked_data)]
(define-public (place-bid (collection <nft-trait>) (nft-id uint) (amount uint) (expiration uint) (memo (optional (string-ascii 256))))
  (let ((block block-height)
        ;; (next-bid-id (var-get id))
        (nft-owner (get-owner collection nft-id))  
        (nft { bid-amount: amount, buyer: tx-sender, seller: nft-owner, action-event-index: u0, memo: memo, expiration-block: (+ expiration block)})
        )
    
    (asserts! (var-get placing-bids-enabled) (err err-placing-bids-disabled))
    (asserts! (>= expiration (* blocks-per-day u2)) (err err-not-enough-bid-expiry))
    
    ;; (asserts! (contract-call? .nft-oracle-v2 is-trusted (contract-of collection))
    ;;           (err err-contract-not-authorized))


    (match (map-get? bids {collection: (contract-of collection), nft-id: nft-id})
        bid (begin
                (asserts! (>= amount (+ (get bid-amount bid) u1000000)) (err err-not-enough-bid-amount))
                
                ;; Review for social engineering attack
                (map-delete bids {collection: (contract-of collection), nft-id: nft-id})
                (try! (as-contract (stx-transfer? (get bid-amount bid) contract-address (unwrap-panic (get seller bid)))))
                (print {
                    message: "Deleted previous bid"
                })
                (unwrap-panic (private-place-bid collection nft-id nft))
                ;; (ok true)
            )
            (begin
                (asserts! (>= amount u1000000)
                          (err err-not-enough-bid-amount))
                (unwrap-panic (private-place-bid collection nft-id nft))
                ;; (ok true)
            )
            
    )
    
    
    ;; (var-set id (+ next-bid-id u1))

    ;; (print { 
    ;;   action: "place-bid",
    ;;   payload: {
    ;;     ;; bid_id: next-bid-id,
    ;;     action_event_index: (get action-event-index nft),
    ;;     collection_id: collection,
    ;;     ;; asset_id: asset-id',
    ;;     token_id: nft-id,
    ;;     bidder_address: tx-sender,
    ;;     seller_address: nft-owner,
    ;;     bid_amount: amount, 
    ;;     expiration_block: (get expiration-block nft),
    ;;     memo: memo
    ;;   }
    ;; })

    (ok "Bid placed")
  )
)

(define-private (private-place-bid (collection <nft-trait>) (nft-id uint)
    (nft (tuple
         (bid-amount uint) (buyer principal) (expiration-block uint) (seller (optional principal)) 
         (action-event-index uint) (memo (optional (string-ascii 256)))
    ))
)
    (begin
        (map-set bids {collection: (contract-of collection), nft-id: nft-id} nft)
        (try! (stx-transfer? (get bid-amount nft) tx-sender contract-address))
        (print { 
            action: "place-bid",
            payload: {
                ;; bid_id: next-bid-id,
                action_event_index: (get action-event-index nft),
                collection_id: (contract-of collection),
                ;; asset_id: asset-id',
                token_id: nft-id,
                bidder_address: tx-sender,
                seller_address: (get seller nft),
                bid_amount: (get bid-amount nft), 
                expiration_block: (get expiration-block nft),
                memo: (get memo nft)
            }
        })
    (ok true)
    )
)

;; #[allow(unchecked_data)]
;; (define-public (withdraw-bid (collection <nft-trait>) (nft-id uint))
;;   (let ((previous-bid (get-bid collection nft-id))
;;         (previous-bidder (get buyer previous-bid))
;;         (previous-bid-action-event-index (get action-event-index previous-bid))
;;         (previous-bid-amount (get bid-amount previous-bid)))
;;     (asserts! (var-get withdrawing-bids-enabled) 
;;               (err err-withdrawing-bids-disabled))
;;     (asserts! (> previous-bid-amount u0) (err err-no-bid-found))
;;     (asserts! (or (is-eq previous-bidder tx-sender) (is-eq contract-owner tx-sender))
;;               (err err-user-not-authorized))

;;     (map-delete bids {collection: (contract-of collection), nft-id: nft-id})

;;     (print {
;;       action: "withdraw-bid",
;;       payload: {
;;         action_event_index: (+ u1 previous-bid-action-event-index),
;;         collection_id: (contract-of collection), ;; Verify if 
;;         token_id: nft-id,
;;         bidder_address: previous-bidder,
;;         seller_address: (get seller previous-bid),
;;         bid_amount: previous-bid-amount,
;;         expiration_block: (get expiration-block previous-bid) 
;;       }
;;     })

;;     (as-contract (stx-transfer? previous-bid-amount contract-address previous-bidder))
;;   )
;; )

;; #[allow(unchecked_data)]
(define-public (accept-bid (bid-id uint) (collection <nft-trait>) (nft-id uint))
  (let ((bid (get-bid collection nft-id))
        (bid-nft-id nft-id)
        (bid-collection (contract-of collection))
        (bidder (get buyer bid))
        (bid-amount (get bid-amount bid))
        (bid-action-event-index (get action-event-index bid))
        (expiration-block (get expiration-block bid))
        (nft-owner (unwrap! (get-owner collection nft-id) (err err-user-not-authorized)))
        (royalty (get-royalty (contract-of collection)))
        (royalty-address (get address royalty))
        (commission-amount (/ (* bid-amount (var-get commission)) u10000))
        (royalty-amount (/ (* bid-amount (get percent royalty)) u10000))
        (to-owner-amount (- (- bid-amount commission-amount) royalty-amount))
        (block block-height))
    (asserts! (var-get accepting-bids-enabled) 
              (err err-accepting-bids-disabled))
    ;; (asserts! (contract-call? .nft-oracle-v2 is-trusted (contract-of collection))
    ;;           (err err-contract-not-authorized))
    (asserts! (> bid-amount u0) (err err-no-bid-found))
    (asserts! (is-eq (contract-of collection) bid-collection) (err err-wrong-collection))
    ;; (asserts! (or 
    ;;             (is-none bid-nft-id) 
    ;;             (and (is-some bid-nft-id) (is-eq (unwrap-panic bid-nft-id) nft-id))) 
    ;;           (err err-wrong-nft-id))
    (asserts! (is-eq tx-sender nft-owner) (err err-user-not-authorized))
    (asserts! (> expiration-block block) (err err-bid-expired))

    (map-delete bids {collection: (contract-of collection), nft-id: nft-id})
    (try! (contract-call? collection transfer nft-id tx-sender bidder))
    (and (> to-owner-amount u0)
        (try! (as-contract (stx-transfer? to-owner-amount contract-address nft-owner))))
    (and (> commission-amount u0)
        (try! (as-contract (stx-transfer? commission-amount contract-address contract-owner))))
    (and (> royalty-amount u0)
        (try! (as-contract (stx-transfer? royalty-amount contract-address royalty-address))))

    (print { 
      action: "accept-bid",
      payload: {
        ;; bid_id: bid-id,
        action_event_index: (+ u1 bid-action-event-index),
        collection_id: (contract-of collection),
        token_id: nft-id,
        bidder_address: bidder,
        seller_address: nft-owner,
        bid_amount: bid-amount, 
        expiration_block: expiration-block,
        royalty: {
          recipient_address: royalty-address,
          percent: (get percent royalty),
        }
      }
    })

    (ok true)
  )
)

;; #[allow(unchecked_data)]
;; (define-public (change-bid-amount-and-expiration (collection <nft-trait>) (nft-id uint) (new-amount uint) (new-expiration uint))
;;   (let ((bid (get-bid collection nft-id))
;;         (bidder (get buyer bid))
;;         (bid-amount (get bid-amount bid))
;;         (bid-collection (contract-of collection))
;;         (bid-nft-id nft-id)
;;         (bid-action-event-index (get action-event-index bid))
;;         (seller (get seller bid))
;;         (block block-height)
;;         (new-bid (merge bid {bid-amount: new-amount, expiration-block: (+ new-expiration block), action-event-index: (+ u1 bid-action-event-index), memo: (some "default memo")})))
;;     (asserts! (var-get accepting-bids-enabled) 
;;               (err err-accepting-bids-disabled))
;;     (asserts! (> bid-amount u0) (err err-no-bid-found))
;;     (asserts! (is-eq tx-sender bidder) (err err-user-not-authorized))

;;     (if (is-eq bid-amount new-amount)
;;       true
;;       (if (< new-amount bid-amount)
;;         (try! (as-contract (stx-transfer? (- bid-amount new-amount) contract-address bidder)))
;;         (try! (stx-transfer? (- new-amount bid-amount) tx-sender contract-address))
;;       )
;;     )

;;     (map-set bids {collection: (contract-of collection), nft-id: nft-id} new-bid)

;;     (print { 
;;       action: "change-bid-amount-and-expiration",
;;       payload: {
;;         action_event_index: (get action-event-index new-bid), 
;;         collection_id: bid-collection,
;;         ;; asset_id: asset-id',
;;         token_id: bid-nft-id,
;;         bidder_address: bidder,
;;         seller_address: seller,
;;         bid_amount: (get bid-amount new-bid), 
;;         expiration_block: (get expiration-block new-bid),
;;       }
;;     })

;;     (ok true)
;;   )
;; )

;; #[allow(unchecked_data)]
(define-public (set-placing-bids-enabled (enabled bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) (err err-user-not-authorized))
        (ok (var-set placing-bids-enabled enabled))
    )
)

;; #[allow(unchecked_data)]
(define-public (set-accepting-bids-enabled (enabled bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) (err err-user-not-authorized))
        (ok (var-set accepting-bids-enabled enabled))
    )
)

;; #[allow(unchecked_data)]
;; (define-public (set-withdrawing-bids-enabled (enabled bool))
;;     (begin
;;         (asserts! (is-eq tx-sender contract-owner) (err err-user-not-authorized))
;;         (ok (var-set withdrawing-bids-enabled enabled))
;;     )
;; )

;; #[allow(unchecked_data)]
(define-public (set-commission (comm uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-user-not-authorized))
    (ok (var-set commission comm))))

(define-read-only (get-bid (collection <nft-trait>) (nft-id uint))
  (default-to
    {buyer: contract-owner, seller: none, bid-amount: u0, expiration-block: block-height, action-event-index: u0}
    (map-get? bids {collection: (contract-of collection), nft-id: nft-id})
  )
)

(define-private (get-owner (nft <nft-trait>) (nft-id uint))
  (unwrap-panic (contract-call? nft get-owner nft-id))
)

(define-private (get-royalty (collection principal))
  ;; (default-to
    { address: contract-owner, percent: u0 }
    ;; (contract-call? .nft-oracle-v2 get-royalty-amount collection))
)

;; (define-public (set-bid (collection <nft-trait>) (nft-id uint) (amount uint))
;;     (begin
;;         (map-set bids 
;;             {collection: (contract-of collection), nft-id: nft-id} 
;;             {buyer: contract-owner, seller: none, bid-amount: amount, expiration-block: block-height, action-event-index: u0}
;;         )
;;         (ok "Bid placed")
;;     )
;; )



;; (define-private (pr-place-bid (collection <nft-trait>) (nft-id uint))
;;     (begin
;;         (map-delete bids {collection: (contract-of collection), nft-id: nft-id})
;;         (ok "Placing the new bid")
;;     )
;; )
;; (define-public (verify-bid (collection <nft-trait>) (nft-id uint))
;;     (match (map-get? bids {collection: (contract-of collection), nft-id: nft-id})
;;         bid (begin
;;                 (print bid)
;;                 (pr-place-bid collection u1)
;;             )
;;             (pr-place-bid collection u1)
;;     )
;; )
