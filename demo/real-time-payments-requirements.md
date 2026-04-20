# Real-Time Payments Platform — Requirements

## Functional Requirements

| Feature | Priority | Notes |
|---|---|---|
| User can register and authenticate with verified identity | Must | KYC/AML compliance gate before any transfers |
| User can link a funding source (bank account, debit card) | Must | Required to fund outgoing payments |
| User can send money instantly to another registered user | Must | Core value proposition |
| User can receive money instantly from another registered user | Must | Push notification on receipt |
| User can view paginated transaction history (sent + received) | Must | Min 12 months of history |
| User can search and filter transaction history | Should | By date range, amount, counterparty |
| User can receive push/email/SMS notification on incoming payment | Must | Real-time; not batched |
| User can cancel a pending payment before settlement | Should | Only applicable within settlement window |
| User can dispute a transaction | Should | Triggers support workflow |
| User can set a per-transaction spending limit | Could | Self-managed fraud control |
| User can request money from another user | Could | Payment request / invoice flow |
| Admin can freeze/flag a user account | Must | Fraud and compliance operations |
| Admin can view platform-wide transaction audit log | Must | Regulatory requirement |

---

## Non-Functional Requirements

| Dimension | Target | Justification |
|---|---|---|
| Payment initiation latency | p99 < 500ms end-to-end acknowledgement | "Instant" UX expectation |
| Settlement latency | < 10 seconds to recipient ledger credit | Defines "real-time" for compliance and UX |
| API availability | 99.95% monthly uptime (~22 min/month downtime) | Payment platforms: downtime = lost revenue + regulatory exposure |
| Notification delivery | p95 < 3 seconds from settlement event | Notification delay breaks trust in "instant" |
| Transaction throughput | 5,000 TPS sustained; 15,000 TPS burst | Assumes mid-tier consumer launch; revisit at scale |
| Read throughput (history) | 20,000 QPS | Read-heavy workload; separate from write path |
| Data durability | RPO = 0 (synchronous replication); RTO < 30 seconds | Financial data; zero loss tolerance |
| Consistency model | Strong consistency on ledger writes | Prevents double-spend and balance discrepancies |
| Transaction history retention | 7 years | Regulatory minimum (varies by jurisdiction) |
| Fraud detection latency | < 200ms inline scoring per transaction | Must not block the payment critical path |
| Encryption | AES-256 at rest; TLS 1.3 in transit | PCI-DSS and SOC 2 baseline |
| Audit log immutability | Append-only, tamper-evident log | Regulatory audit requirements |

---

## Out of Scope

1. International / cross-border transfers and currency conversion
2. Merchant payments, QR-code POS, or e-commerce checkout integration
3. Cryptocurrency or digital asset support
4. Scheduled / recurring payments (standing orders)
5. Business/multi-user accounts and team wallets
6. Physical card issuance

---

## Open Assumptions

[ASSUMPTION] Users are individuals (consumers), not businesses — merchant use cases are excluded.

[ASSUMPTION] Platform operates in a single regulatory jurisdiction; multi-jurisdiction compliance (e.g., EU PSD2 + US FinCEN simultaneously) is not in scope.

[ASSUMPTION] Funding sources are external (linked bank account or debit card); the platform holds a pooled ledger balance, not individual custodial bank accounts.

[ASSUMPTION] "Instant" means ledger credit is visible to recipient within 10 seconds; actual bank settlement (e.g., ACH) may be T+1 behind the scenes.

[ASSUMPTION] KYC/AML verification is delegated to a third-party provider (e.g., Persona, Alloy); this platform does not build identity verification in-house.

[ASSUMPTION] Push notifications target mobile (iOS/Android); web push and SMS are secondary delivery channels.

[ASSUMPTION] Fraud scoring is a synchronous inline call with a hard timeout fallback (allow/block default TBD) — not an async review queue.
