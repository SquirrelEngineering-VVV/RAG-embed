#!/usr/bin/env bash
set -euo pipefail

# Determine project root directory (one level up from script/) and asset target folder
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
ASSET_DIR="$ROOT_DIR/asset"

# Ensure root asset directory exists
mkdir -p "$ASSET_DIR"

# Define asset locations
CPYTHON_URL="https://github.com/indygreg/python-build-standalone/releases/download/20241016/cpython-3.11.10+20241016-x86_64-unknown-linux-gnu-install_only.tar.gz"
OLLAMA_URL="https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tar.zst"

echo "==> Project root detected at: $ROOT_DIR"
echo "==> Fetching CPython binary package into $ASSET_DIR..."
curl -L --progress-bar "$CPYTHON_URL" -o "$ASSET_DIR/cpython.tar.gz"

echo "==> Fetching Ollama engine into $ASSET_DIR..."
curl -L --progress-bar "$OLLAMA_URL" -o "$ASSET_DIR/ollama.tar.zst"

echo "==> Assets downloaded successfully:"
ls -lh "$ASSET_DIR/cpython.tar.gz" "$ASSET_DIR/ollama.tar.zst"
