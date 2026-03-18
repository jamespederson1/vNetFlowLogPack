# Azure vNet Flow Log Pack for Cribl

Cribl packs for ingesting, parsing, and visualizing Azure Virtual Network (vNet) Flow Logs — a **Cribl Search** pack for dashboards and a **Cribl Stream** pack for data collection and processing.


## The Two Packs

### Cribl Search Pack — Dashboards
**Source:** `pack/` — **Build:** `dist/search/*.crbl`

Dashboards for analyzing Azure vNet Flow Log data through Cribl Search.

### Cribl Stream Pack — Collection & Processing
**Source:** `stream-pack/` — **Build:** `dist/stream/*.crbl`

Pipelines and routes for ingesting Azure vNet Flow Logs, parsing the nested JSON structure, flattening flow tuples, and routing to destinations.


## Repository Structure

```
vNetFlowLogPack/
├── pack/                         # Cribl Search pack source
│   ├── package.json
│   ├── README.md                 # Renders in Cribl Search UI
│   ├── default/                  # Pack settings, macros, saved queries
│   └── data/                     # Dashboards, lookups, uploads
│       ├── dashboards/
│       ├── lookups/
│       └── uploads/
├── stream-pack/                  # Cribl Stream pack source
│   ├── package.json
│   ├── README.md                 # Renders in Cribl Stream UI
│   └── default/                  # Pipelines, routes, breakers, vars
│       └── pipelines/
├── dist/                         # Built .crbl files (gitignored)
│   ├── search/
│   └── stream/
├── docs/                         # Documentation
│   ├── project_knowledge.md
│   └── dashboards/
├── api/                          # API docs and sample data
├── scripts/                      # Build and utility scripts
├── .gitignore
└── README.md
```


## Quick Start

### Search Pack

1. Build: `cd pack && tar czf ../dist/search/cribl-search-vnet-flow-log.crbl .`
2. Import in Cribl Search: **Packs → Import from File**

### Stream Pack

1. Build: `cd stream-pack && tar czf ../dist/stream/cribl-stream-vnet-flow-log.crbl .`
2. Import in Cribl Stream: **Processing → Packs → Import from File**
3. **Commit & Deploy**


## Prerequisites

- Azure subscription with vNet Flow Logs enabled
- Cribl Search (for dashboards)
- Cribl Stream (for data collection and processing)


## License

Apache 2.0
