#!/bin/bash
# Build Cribl packs with version numbers from package.json
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Build Cribl Search pack
if [ -f "$PROJECT_DIR/pack/package.json" ]; then
    SEARCH_VERSION=$(grep -o '"version":"[^"]*"' "$PROJECT_DIR/pack/package.json" | cut -d'"' -f4)
    echo "Building Search pack v${SEARCH_VERSION}..."
    mkdir -p "$PROJECT_DIR/dist/search"
    cd "$PROJECT_DIR/pack"
    tar czf "$PROJECT_DIR/dist/search/cribl-search-vnet-flow-log-${SEARCH_VERSION}.crbl" .
    echo "Search pack built: dist/search/cribl-search-vnet-flow-log-${SEARCH_VERSION}.crbl"
else
    echo "No Search pack found (pack/package.json missing), skipping."
fi

# Build Cribl Stream pack
if [ -f "$PROJECT_DIR/stream-pack/package.json" ]; then
    STREAM_VERSION=$(grep -o '"version":"[^"]*"' "$PROJECT_DIR/stream-pack/package.json" | cut -d'"' -f4)
    echo "Building Stream pack v${STREAM_VERSION}..."
    mkdir -p "$PROJECT_DIR/dist/stream"
    cd "$PROJECT_DIR/stream-pack"
    tar czf "$PROJECT_DIR/dist/stream/cribl-stream-vnet-flow-log-${STREAM_VERSION}.crbl" .
    echo "Stream pack built: dist/stream/cribl-stream-vnet-flow-log-${STREAM_VERSION}.crbl"
else
    echo "No Stream pack found (stream-pack/package.json missing), skipping."
fi

echo "Done."
