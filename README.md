# Portable Offline AI & RAG Stack

A zero-dependency, fully self-contained Retrieval-Augmented Generation (RAG) and local LLM environment designed to run directly from a USB drive across diverse Linux systems.

This project packages an isolated CPython runtime, Ollama model engine, ChromaDB vector index, and local note synchronization scripts into a single plug-and-play workflow without modifying host system packages or requiring root privileges.

---

## 🛠 Project Structure

```text
.
├── asset/                 # Archives (cpython.tar.gz, ollama.tar.zst)
├── data/
│   ├── models/            # Local Ollama model weights
│   ├── raw_notes/         # Input Markdown files for indexing
│   └── vector_db/         # Persistent ChromaDB vector storage
├── engine/                # Extracted binaries (Python runtime & Ollama engine)
├── script/
│   ├── download-asset.sh  # Automated asset downloader
│   ├── setup_and_sync.py  # Markdown parsing & vector embedding sync
│   └── run.py             # RAG query interface
├── start.sh               # Main portable launcher
└── .gitignore

```

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone [https://github.com/SquirrelEngineering-VVV/RAG-embed.git](https://github.com/SquirrelEngineering-VVV/RAG-embed.git)
cd RAG-embed

```

### 2. Make the Launcher Executable

```bash
chmod +x start.sh script/download-asset.sh

```

### 3. Run the Stack

```bash
./start.sh

```

The launcher automatically handles environment setup:

1. Verifies local runtime archives in `asset/` (triggers `download-asset.sh` if missing).
2. Extracts standalone CPython and Ollama into `engine/`.
3. Prepares persistent data storage in `data/`.
4. Starts the local Ollama background server.
5. Syncs Markdown files in `data/raw_notes/` into ChromaDB.
6. Launches the interactive RAG query interface.

---

## ⚙️ How It Works

* **Isolated Execution:** Uses `python-build-standalone` (CPython 3.11) and raw Ollama binaries to ensure full portability across glibc-based Linux distributions without requiring system-level `apt`, `pip`, or `sudo`.
* **Portable Storage:** `OLLAMA_MODELS` and ChromaDB paths are pinned relative to the project root on the USB drive, keeping model weights and embeddings fully self-contained.
* **Auto-Downloader:** Missing binary archives are automatically fetched via `script/download-asset.sh` using `curl` directly from upstream GitHub releases.

---

## 📋 Requirements

* **Operating System:** x86_64 Linux (e.g., Ubuntu, Debian, Arch, Fedora)
* **System Utilities:** `tar`, `curl`, and `zstd` (for extracting compressed binary assets)
* **Hardware:** USB 3.0+ storage drive (Btrfs or ext4 recommended)

---

## 🔧 Maintenance & Manual Asset Management

If you prefer to download binary assets manually rather than running `download-asset.sh`, place the following files inside `asset/`:

* `asset/cpython.tar.gz` — Standalone CPython 3.11 build from `indygreg/python-build-standalone`
* `asset/ollama.tar.zst` — Ollama Linux x86_64 binary release archive

## 📄 License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0).

```text
Copyright (C) 2026 Nong Duc Thinh

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
