# Real-Time Payments Platform — Scale Estimation

> Inputs: 5M DAU, 2 payments/user/day, 1KB avg transaction payload, 3-year growth horizon.

## Traffic Estimation

| Metric | Calculation | Result |
|---|---|---|
| DAU (Year 0) | Given | 5,000,000 |
| Payments/day | 5M × 2 | 10,000,000 |
| Avg write QPS (payments) | 10M / 86,400 | ~116 QPS |
| Peak write QPS (3× factor) | 116 × 3 | ~350 QPS |
| History/balance reads per user/day | Assumed 5× | 25,000,000 reads/day |
| Avg read QPS | 25M / 86,400 | ~290 QPS |
| Peak read QPS (3×) | 290 × 3 | ~870 QPS |
| Notification events/day | 10M tx × 2 (sender + receiver) | 20,000,000 |
| Peak notification QPS | (20M / 86,400) × 3 | ~695 QPS |
| Year 1 DAU (30% YoY growth) | 5M × 1.3 | 6,500,000 |
| Year 2 DAU | 6.5M × 1.3 | 8,450,000 |
| Year 3 DAU | 8.45M × 1.3 | ~11,000,000 |
| Year 3 peak write QPS | (11M × 2 / 86,400) × 3 | ~764 QPS |
| Year 3 peak read QPS | (11M × 5 / 86,400) × 3 | ~1,910 QPS |

**Read:Write ratio: 5:1** (history + balance lookups dominate; read path must be independently scaled)

[ASSUMPTION] Peak factor is 3× because payments cluster between 11:00–13:00 and 18:00–21:00 local time; a single-timezone launch is assumed — multi-timezone flattens this curve slightly but regional peaks remain.

[ASSUMPTION] 30% YoY DAU growth for 3 years; compounding. Re-run if growth targets change.

---

## Storage Estimation

| Entity | Record size | Vol/day (Yr0) | 1-year cumulative | 3-year cumulative |
|---|---|---|---|---|
| Transaction records | 1 KB | 10M × 1KB = **10 GB** | **3.65 TB** | **14.6 TB** |
| Audit log entries | 1 KB | 10M tx × 2 events = **20 GB** | **7.3 TB** | **29.2 TB** |
| Notification records | 256 B | 20M × 256B = **5 GB** | **1.8 TB** | **7.3 TB** |
| User profiles (incl. KYC metadata) | 5 KB | — | — | 11M × 5KB = **55 GB** |
| **Raw total** | | **35 GB/day** | **12.8 TB** | **51.2 TB** |
| **With 3× replication** | | **105 GB/day** | **38.4 TB** | **~154 TB** |

[RISK: HIGH] Replicated dataset crosses **100TB at ~Year 2**. At that point: (1) partition transaction table by `created_at` month with automated archival to cold object storage (S3 Glacier / GCS Nearline); (2) maintain a hot tier of ≤13 months online per the 12-month history SLA; (3) retain cold tier for 7-year compliance window. Without tiering, Year 3 storage cost alone exceeds $3,500/mo.

[ASSUMPTION] Audit log is append-only and never deleted; it is immutable by design. Cold-tier cost is ~$0.004/GB/mo vs $0.023/GB/mo for hot.

---

## Bandwidth

| Direction | Peak QPS | Avg payload | GB/day |
|---|---|---|---|
| Inbound — payment write | 350 | 1 KB | 10 GB |
| Inbound — read requests (headers only) | 870 | 200 B | 5 GB |
| Outbound — history read responses | 870 | 5 KB (5-record page) | 125 GB |
| Outbound — notifications (FCM/APNs) | 695 | 256 B | 5 GB |
| Outbound — API error / status responses | 200 | 512 B | 1 GB |
| **Total** | | | **~146 GB/day** |
| Year 3 projected | | | **~320 GB/day** |

CDN offload applies only to static assets; API and ledger responses are dynamic — **0% CDN offload on the critical path.**

---

## Infra Sizing (Rough)

| Component | Count | Instance type | Cost/mo (est.) |
|---|---|---|---|
| Payment write service (stateless) | 3 | c5.xlarge (4 vCPU / 8 GB) | $450 |
| API / read service (stateless) | 4 | c5.xlarge | $600 |
| Fraud scoring service (inline, <200ms SLA) | 2 | c5.2xlarge (8 vCPU / 16 GB) | $400 |
| Notification service | 2 | t3.medium | $60 |
| PostgreSQL primary (strong consistency ledger) | 1 | r5.2xlarge (8 vCPU / 64 GB) | $400 |
| PostgreSQL read replicas | 2 | r5.xlarge (4 vCPU / 32 GB) | $400 |
| Redis cluster (balance cache, sessions) | 2 | cache.r6g.large | $200 |
| Kafka cluster (event stream, notifications) | 3 | m5.large (2 vCPU / 8 GB) | $300 |
| Application load balancers | 2 | ALB | $50 |
| Object storage — hot tier (13 months) | ~40 TB | S3 Standard | $920 |
| Object storage — cold tier (audit/archive) | ~60 TB | S3 Glacier | $240 |
| Monitoring / observability stack | — | managed (Datadog/Grafana Cloud) | $400 |
| FCM/APNs gateway (20M notif/day) | — | SNS or direct | $100 |
| **Total** | | | **~$4,520/mo** |

[ASSUMPTION] AWS us-east-1 on-demand pricing used as baseline; Reserved Instances (1-year) would reduce compute ~40%, bringing total to ~$3,200/mo.

[ASSUMPTION] Does not include: KYC vendor ($0.50–$2.00/verification), payment network fees (card rails, RTP network), or WAF/DDoS protection costs.

---

## Scale Triggers

| Metric | Current design limit | Action needed |
|---|---|---|
| Peak write QPS > 1,000 | ~350 at launch | Horizontally scale payment write service; consider sharding ledger by user_id range |
| DB write TPS > 3,000 sustained | PostgreSQL single primary ~5,000 TPS theoretical | Migrate ledger to distributed SQL (CockroachDB or Cloud Spanner) |
| Replicated storage > 100 TB | Hits ~Year 2 | Activate hot/cold tiering; partition by `created_at` |
| Notification queue depth > 10,000 messages | 2-node Kafka, 3-partition | Add Kafka partitions + scale notification consumer group |
| Cache hit rate < 90% | 2-node Redis | Expand Redis cluster; review eviction policy and TTL |
| Fraud scoring p99 > 150ms | 2× c5.2xlarge inline | Pre-compute risk scores async; serve from cache with TTL; add instances |
| DAU > 15M | Year 3 projected limit | Full architecture re-evaluation: multi-region active-active, global load balancing |
