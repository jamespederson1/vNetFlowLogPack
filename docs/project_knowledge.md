# vNetFlowLogPack — Project Knowledge

## Overview

This project provides Cribl packs for Azure Virtual Network (vNet) Flow Log ingestion, parsing, and visualization.

## Architecture

- **Search Pack** (`pack/`): Cribl Search dashboards for analyzing vNet Flow Log data
- **Stream Pack** (`stream-pack/`): Cribl Stream pipelines for collecting and processing vNet Flow Logs
- **Build Output** (`dist/`): Compiled `.crbl` pack files (gitignored)

## Development Notes

- Pack builds: `tar czf` from pack source directories
- Follow Cribl pack conventions for `package.json`, `default/`, and `data/` structure
