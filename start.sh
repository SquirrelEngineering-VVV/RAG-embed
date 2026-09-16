#!/bin/bash

# Determine directory where start.sh lives
USB_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set Ollama storage path to USB
export OLLAMA_MODELS="$USB_DIR/data/models"

# Local executable paths
PYTHON_BIN="$USB_DIR/engine/python/bin/python3"
OLLAMA_BIN="$USB_DIR/engine/ollama/bin/ollama"

echo "============================================="
echo "  🚀 Starting Portable AI Stack from USB..."
echo "============================================="

# ---------------------------------------------------------
# Step 0: Extract Tarballs & Prepare Environment
# ---------------------------------------------------------

# Extract standalone CPython (cpython.tar.gz)
if [ ! -d "$USB_DIR/engine/python" ]; then
    if [ -f "$USB_DIR/cpython.tar.gz" ]; then
        echo "📦 Extracting CPython runtime (cpython.tar.gz)..."
        mkdir -p "$USB_DIR/engine/python"
        tar -xzf "$USB_DIR/cpython.tar.gz" -C "$USB_DIR/engine/python" --strip-components=1 2>/dev/null || \
        tar -xzf "$USB_DIR/cpython.tar.gz" -C "$USB_DIR/engine"
    fi
fi

# Extract Ollama binaries (ollama.tar.zst)
if [ ! -d "$USB_DIR/engine/ollama" ]; then
    if [ -f "$USB_DIR/ollama.tar.zst" ]; then
        echo "📦 Extracting Ollama binaries (ollama.tar.zst)..."
        mkdir -p "$USB_DIR/engine/ollama"
        
        # Try tar with native zstd support first, fall back to zstd pipe
        if tar --zstd -xf "$USB_DIR/ollama.tar.zst" -C "$USB_DIR/engine/ollama" --strip-components=1 2>/dev/null; then
            :
        elif command -v zstd >/dev/null 2>&1; then
            zstd -dc "$USB_DIR/ollama.tar.zst" | tar -xf - -C "$USB_DIR/engine/ollama" --strip-components=1 2>/dev/null || \
            zstd -dc "$USB_DIR/ollama.tar.zst" | tar -xf - -C "$USB_DIR/engine"
        else
            echo "❌ Error: 'zstd' utility is required to extract ollama.tar.zst."
            exit 1
        fi
    fi
fi

# Fallback check for Ollama binary layout
if [ ! -f "$OLLAMA_BIN" ] && [ -f "$USB_DIR/engine/ollama/ollama" ]; then
    OLLAMA_BIN="$USB_DIR/engine/ollama/ollama"
fi

# Verify runtime binaries
if [ ! -f "$PYTHON_BIN" ]; then
    echo "❌ Error: CPython binary not found at $PYTHON_BIN"
    exit 1
fi

if [ ! -f "$OLLAMA_BIN" ]; then
    echo "❌ Error: Ollama binary not found at $OLLAMA_BIN"
    exit 1
fi

# ---------------------------------------------------------
# Step 1: Install Python Dependencies into Portable Env
# ---------------------------------------------------------

# Check for both chromadb AND ollama Python modules
REQUIRED_PACKAGES=""

if ! $PYTHON_BIN -c "import chromadb" >/dev/null 2>&1; then
    REQUIRED_PACKAGES="$REQUIRED_PACKAGES chromadb"
fi

if ! $PYTHON_BIN -c "import ollama" >/dev/null 2>&1; then
    REQUIRED_PACKAGES="$REQUIRED_PACKAGES ollama"
fi

# Install missing packages into embedded CPython site-packages
if [ -n "$REQUIRED_PACKAGES" ]; then
    echo "📥 Installing missing Python packages ($REQUIRED_PACKAGES) into portable environment..."
    
    $PYTHON_BIN -m pip install --no-user $REQUIRED_PACKAGES
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install Python dependencies."
        exit 1
    fi
fi

# Create required data directories
mkdir -p "$USB_DIR/data/models"
mkdir -p "$USB_DIR/data/vector_db"
mkdir -p "$USB_DIR/data/raw_notes"

# ---------------------------------------------------------
# Step 2: Start local Ollama daemon
# ---------------------------------------------------------
$OLLAMA_BIN serve > /dev/null 2>&1 &
OLLAMA_PID=$!

# Wait briefly for Ollama server to register
sleep 3

# ---------------------------------------------------------
# Step 3: Run sync script & launch RAG Interface
# ---------------------------------------------------------
echo "🔄 Checking and indexing .md files..."
$PYTHON_BIN "$USB_DIR/setup_and_sync.py"

echo "🤖 Launching AI Interface..."
$PYTHON_BIN "$USB_DIR/run.py"

# Clean up background daemon on exit
kill $OLLAMA_PID 2>/dev/null
echo "👋 Session ended. Ollama server stopped."
