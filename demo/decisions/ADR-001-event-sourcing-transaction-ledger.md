```yaml
title: "ADR-001: Event Sourcing for the Transaction Ledger"
status: Accepted
date: 2026-04-20
deciders:
  - Principal Architect
  - Staff Engineer (Payments)
  - Engineering Lead (Compliance)

context: |
  The transaction ledger must maintain an accurate, auditable record of all balance
  changes across 10K TPS peak with 7-year regulatory retention. Traditional CRUD
  models overwrite current state, creating a gap between what the system did and
  what it can prove it did — a direct compliance and auditability risk. Concurrent
  balance mutations under high TPS also produce inconsistency bugs that are
  notoriously hard to detect and reproduce in mutable state models.

decision: "We will use event sourcing for the transaction ledger, treating immutable
  domain events (MoneyDebited, MoneyCredited, PaymentFailed) as the primary source
  of truth, with derived read projections for current balance and transaction history."

rationale:
  - "Immutable event log satisfies the 7-year audit retention requirement by design —
    no separate audit table needed, eliminating the risk of audit records being missed
    in hotfix code paths."
  - "Balance is computed by replaying events, removing the class of concurrent-write
    inconsistency bugs that arise when multiple processes race to update a mutable
    balance column; CockroachDB serializable transactions enforce event append ordering."
  - "The event log is the natural persistence model for the Kafka integration already
    in the architecture — payment.completed events published to Kafka are structurally
    identical to ledger domain events, eliminating dual-write divergence."
  - "Temporal queries (what was user X's balance at time T?) are natively supported
    by replaying events up to a timestamp — a regulatory reporting requirement that
    requires a CDC pipeline or changelog table in the CRUD alternative."

consequences:
  positive:
    - "Complete, tamper-evident audit trail by construction — regulators can be given
      read access to the event store directly."
    - "Deterministic balance reconstruction: any balance figure can be independently
      verified by replaying the event sequence."
    - "Natural CQRS split: write model (event append) is decoupled from read model
      (balance projection, history projection), enabling independent scaling."
    - "Bug fixes can be applied by correcting projection logic and replaying events —
      no data migration required for historical records."
    - "Event schema is the canonical API contract between services consuming ledger
      state, reducing implicit coupling."

  negative:
    - "[RISK: HIGH] Event store grows unboundedly at 20GB/day raw — mitigation:
      write periodic snapshot checkpoints per account (every 1,000 events or 24h,
      whichever comes first); balance queries start from latest snapshot + tail replay,
      bounding replay cost to O(1,000) events maximum."
    - "[RISK: MED] Read projection staleness: eventual consistency between event store
      and read projections means history queries may lag by <1s — mitigation: for
      current balance specifically, use snapshot + synchronous tail replay on the
      write path; accept eventual consistency only for history display."
    - "[RISK: MED] Projection rebuild time during failure: if a projection store
      (PostgreSQL read replica) is lost, full replay from event store may take hours
      at scale — mitigation: snapshots reduce rebuild to minutes; maintain a warm
      standby projection at all times."
    - "[RISK: LOW] Event schema evolution requires an explicit versioning and upcasting
      strategy — mitigation: mandate a schema registry (Confluent Schema Registry or
      equivalent) for all event types from day one; never delete or rename event fields."

  neutral:
    - "Team must internalize event sourcing patterns: aggregate, event store, projection,
      snapshot. Plan 2–3 weeks of onboarding for engineers new to the pattern."
    - "ORM-based tooling (ActiveRecord, SQLAlchemy, GORM) does not apply to the event
      store layer; custom repository implementations are required per aggregate type."
    - "Idempotency of event handlers becomes a hard requirement — all projection
      consumers must handle duplicate event delivery (Kafka at-least-once) without
      corrupting state."

alternatives_considered:
  - option: "Traditional CRUD with a parallel audit log table"
    rejected_because: "Audit log is a second-class citizen — empirically skipped in
      hotfix and emergency code paths, creating compliance gaps. Concurrent balance
      updates under 10K TPS require application-level advisory locks or optimistic
      retry loops, adding latency and complexity. No native replay capability."

  - option: "Append-only double-entry ledger (no event sourcing semantics)"
    rejected_because: "Closer to event sourcing but treats the current-state projection
      as the source of truth rather than the event sequence. Temporal queries still
      require a separate changelog. Integration with Kafka requires explicit dual-write,
      risking divergence between the ledger and the event stream."

  - option: "Blockchain / distributed ledger (e.g., Hyperledger Fabric)"
    rejected_because: "100–1,000× latency overhead (block confirmation time) violates
      the 500ms p99 payment SLA. Operational complexity is disproportionate to the
      compliance requirement. Mature Go/Python client ecosystems do not exist. No
      regulatory mandate for blockchain in the target jurisdiction."
```
