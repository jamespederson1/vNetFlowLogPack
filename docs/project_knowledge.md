# vNetFlowLogPack — Project Knowledge

## Overview

This project provides Cribl packs for Azure Virtual Network (vNet) Flow Log ingestion, parsing, deduplication, and visualization. It is an evolution of the original `Azure_vNet_FlowLogs` pack (v0.0.3) with significant enhancements including a 15-minute collection schedule, multiple deduplication strategies, and improved documentation.

**GitHub Repository:** https://github.com/jamespederson1/vNetFlowLogPack


## Architecture

- **Stream Pack** (`stream-pack/`): Cribl Stream pack for collecting, parsing, and deduplicating vNet Flow Logs
- **Search Pack** (`pack/`): Cribl Search pack for dashboards (scaffolded, not yet populated)
- **Build Output** (`dist/`): Compiled `.crbl` pack files (gitignored)
- **Documentation** (`docs/`): Project documentation
- **Scripts** (`scripts/`): Build automation


## Origin — Existing Pack (v0.0.3)

The project was initialized from the existing `Azure_vNet_FlowLogs_0_0_3.crbl` pack. That pack was extracted and imported into the `stream-pack/` directory as the baseline. The original pack included:

- EventBreaker ruleset for Azure vNet Flow Log JSON arrays
- A single hourly Azure Blob Storage collector job
- A PreProcessing pipeline that unrolls the nested flow log structure
- A Redis-based deduplication pipeline
- A route table
- Sample data files (the large 1.17MB sample was removed)


## Collector Sources (jobs.yml)

### 1. Azure_vNet_FlowLogs_Hourly_v2 (Original)

- **Cron:** `15 * * * *` — runs at minute :15 of every hour
- **Lookback:** `earliest: -75m`, `latest: @h`
- **Timing analysis:** At 1:15 UTC, `@h` snaps to 1:00 and `-75m` reaches back to 0:00, giving a clean 00:00–01:00 window. This collects exactly one complete hour's flow log files per MAC address with **no overlap and no duplicates**.
- **Event Breaker:** `Azure_vNet_FlowLogs`
- **Pipeline:** `Azure_vNet_FlowLogs_PreProcessing`
- **Status:** Disabled by default (requires Azure auth configuration)
- **Dedup needed:** No — the non-overlapping window means no duplicates are produced

### 2. Azure_vNet_FlowLogs_15m_Dedup (New in v0.1.0)

- **Cron:** `*/15 * * * *` — runs at :00, :15, :30, :45 every hour
- **Lookback:** `earliest: -16m`, `latest: now`
- **Timing analysis:** Each 15-minute collection window overlaps with the previous window by 1 minute. This produces a small number of duplicate flow log events in the overlap.
- **Event Breaker:** `Azure_vNet_FlowLogs`
- **Pipeline:** `Azure_vNet_FlowLogs_PreProcessing`
- **Status:** Disabled by default (requires Azure auth configuration)
- **Dedup needed:** Yes — the 1-minute overlap produces duplicates. Use one of the dedup routes.

Both collectors use the same Azure Blob Storage configuration:
- Container: `insights-logs-flowlogflowevent`
- Path: `flowLogResourceID=/${*}/${*}/${_time:y=%Y}/${_time:m=%m}/${_time:d=%d}/${_time:h=%H}`
- Auth: `clientSecret` with `Azure_vNet_Flowlogs_Secret`
- Collector type: `azure_blob` with recursive traversal


## EventBreaker (breakers.yml)

**Azure_vNet_FlowLogs** — Custom event breaker for Azure vNet Flow Log JSON:
- Breaks on `records` JSON array field
- Auto timestamp parsing with 150-char length
- Max event size: 512KB
- Both collector sources reference this breaker


## Pipelines

### Azure_vNet_FlowLogs_PreProcessing

The core processing pipeline used by both collector sources. It unrolls the nested Azure vNet Flow Log structure into individual flat events:

1. Remove `_raw`, `_time`, `source` (will be rebuilt)
2. Unroll `flowRecords.flows` → one event per flow
3. Promote `aclID` from the flow object
4. Unroll `flow.flowGroups` → one event per flowGroup
5. Remove temporary `flow` and `flowRecords` fields
6. Unroll `flowGroup.flowTuples` → one event per flowTuple string
7. Promote `rule` from flowGroup, clean up temporary fields
8. Serialize back to `_raw` as flat JSON with fields: aclID, category, flowLogGUID, flowLogResourceID, flowLogVersion, flowTuple, host, macAddress, operationName, rule, targetResourceID, time
9. Keep only `_raw`, remove all other fields

**Key detail:** After pre-processing, each event's `_raw` is a flat JSON containing all identifying fields. The `flowTuple` string itself contains the epoch timestamp, source/destination IPs, ports, protocol, and flow state — making it a reliable unique identifier when hashed.

### Azure_vNet_FlowLogs_Dedup_Redis (Original — Hourly)

Redis-based dedup for the hourly collector. Uses SHA-256 hash of `_raw` as Redis key:
- TTL: 7200 seconds (2 hours)
- Redis commands: `hsetnx` to check/set, `expire` for TTL, `hincrby` for counting
- Drops events where `hsetnx` returns 0 (key already exists)
- **Stateful:** State is shared across workers and persists in Redis

### Azure_vNet_FlowLogs_Dedup_15m (New in v0.1.0 — Redis)

Redis-based dedup optimized for the 15-minute collector:
- Same SHA-256 hash approach as the hourly dedup
- TTL: 1200 seconds (20 minutes) — shorter than hourly, optimized for the 15-minute window
- Smaller Redis memory footprint due to shorter TTL
- **Stateful:** State is shared across workers and persists in Redis

### Azure_vNet_FlowLogs_Dedup_Suppress (New in v0.2.0 — No Redis)

Stateless dedup using Cribl's built-in Suppress function. **No external dependencies.**

- Computes SHA-256 hash of `_raw` as the dedup key
- Suppress function maintains an in-memory cache
- Allows 1 event per unique hash within a 1200-second (20-minute) window
- Cleans up temporary `__dedup_key` field after suppression

**CRITICAL: This pipeline is NOT stateful.** The Suppress function's cache is:
- **Ephemeral:** Lost on worker restart (including Commit & Deploy)
- **Per-worker:** Not shared across workers in multi-worker deployments
- **Not persistent:** No disk-backed state

**When to use:**
- Single-worker deployments
- Worker affinity enabled on the collector job
- Dev/test environments
- Environments where occasional duplicates after restart are acceptable

**When NOT to use:**
- Multi-worker deployments without worker affinity
- Zero duplicate tolerance requirements
- High-frequency restart scenarios

**Performance vs Redis:**
- Latency: Microseconds (in-memory) vs 0.5–2ms (Redis network round-trips)
- The performance difference is negligible for vNet Flow Log volumes
- Choice should be driven by deployment architecture, not performance


## Route Table (route.yml)

Four routes, all dedup routes disabled by default:

1. **AzureFlowLogs 15m Dedup (Suppress - No Redis)** — Stateless dedup for 15-minute collector. Enable for simple single-worker deployments.
2. **AzureFlowLogs 15m Dedup (Redis)** — Stateful dedup for 15-minute collector. Enable for multi-worker deployments.
3. **AzureFlowLogs Dedup (Redis - Hourly)** — Stateful dedup for hourly collector. Typically not needed since the hourly schedule has no overlap.
4. **default** — Passthrough to main pipeline. Always enabled.

**Usage:** Enable exactly one dedup route matching your collector and deployment architecture. The default passthrough route handles events that don't match a dedup route.


## Build Process

The `scripts/build-pack.sh` script builds `.crbl` files with version numbers from `package.json`:

```bash
# From project root:
bash scripts/build-pack.sh
# Produces: dist/stream/cribl-stream-vnet-flow-log-{version}.crbl
```

Version numbers are embedded in the `.crbl` filename (e.g., `cribl-stream-vnet-flow-log-0.2.0.crbl`) to track which build contains which changes.

The `dist/` directory is gitignored — `.crbl` files are build artifacts that should be rebuilt from source.


## Version History

| Version | Description |
|---------|-------------|
| 0.0.3   | Original pack imported from Azure_vNet_FlowLogs_0_0_3.crbl |
| 0.1.0   | Added 15-minute collector source and Redis-based dedup pipeline for it |
| 0.1.1   | Removed large sample file (Azure_vNet_Unbroken.log, 1.17MB) |
| 0.2.0   | Added stateless Suppress-based dedup pipeline (no Redis required) |
| 0.2.1   | Updated Suppress pipeline docs to clarify stateless limitations |


## Development Notes

- Both collector sources MUST use the `Azure_vNet_FlowLogs` event breaker
- Both collector sources use the `Azure_vNet_FlowLogs_PreProcessing` pipeline
- All dedup pipelines expect pre-processed events (flowTuples already unrolled)
- Dedup pipelines use SHA-256 hash of `_raw` as the unique key
- Pack builds: `tar czf` from stream-pack source directory
- Follow Cribl pack conventions for `package.json`, `default/`, and `data/` structure
- Redis dedup pipelines currently reference `redis://10.198.32.64:6379` — update for your environment
- Azure auth fields (`clientId`, `tenantId`, `storageAccountName`) are placeholder values — update for your environment
