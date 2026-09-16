#!/bin/bash

# Determine directory where start.sh lives
USB_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set Ollama storage path to USB
export OLLAMA_MODELS="$USB_DIR/data/models"

# Local executable paths
PYTHON_BIN="$USB_DIR/engine/python/bin/python3"
OLLAMA_BIN="$USB_DIR/engine/ollama/bin/ollama"

# Fallback: Check if ollama binary is directly under engine/ollama/
if [ ! -f "$OLLAMA_BIN" ]; then
    OLLAMA_BIN="$USB_DIR/engine/ollama/ollama"
fi

echo "============================================="
echo "  🚀 Starting Portable AI Stack from USB..."
echo "============================================="

# 1. Start local Ollama daemon
$OLLAMA_BIN serve > /dev/null 2>&1 &
OLLAMA_PID=$!

# Wait briefly for Ollama server to register
sleep 3

# 2. Run sync script to process Markdown files into Vector DB
echo "🔄 Checking and indexing .md files..."
$PYTHON_BIN "$USB_DIR/setup_and_sync.py"

# 3. Launch RAG Chat Interface
echo "🤖 Launching AI Interface..."
$PYTHON_BIN "$USB_DIR/run.py"

# Clean up background server on exit
#kill $OLLAMA_PID
# Silence error if process already exited
kill $OLLAMA_PID 2>/dev/null
echo "👋 Session ended. Ollama server stopped."
