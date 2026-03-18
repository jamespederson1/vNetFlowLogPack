#!/bin/bash
# Build Cribl Search pack
echo "Building Search pack..."
cd "$(dirname "$0")/../pack" || exit 1
tar czf ../dist/search/cribl-search-vnet-flow-log.crbl .
echo "Search pack built: dist/search/cribl-search-vnet-flow-log.crbl"

# Build Cribl Stream pack
echo "Building Stream pack..."
cd "$(dirname "$0")/../stream-pack" || exit 1
tar czf ../dist/stream/cribl-stream-vnet-flow-log.crbl .
echo "Stream pack built: dist/stream/cribl-stream-vnet-flow-log.crbl"

echo "Done."
