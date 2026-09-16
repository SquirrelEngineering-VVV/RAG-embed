import os
import glob
import json
import chromadb
import ollama

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "data", "vector_db")
NOTES_DIR = os.path.join(BASE_DIR, "data", "raw_notes")
MODEL_DIR = os.path.join(BASE_DIR, "data", "models")
MANIFEST_PATH = os.path.join(BASE_DIR, "data", "sync_manifest.json")

# Ensure Ollama checks the USB drive for models
os.environ["OLLAMA_MODELS"] = MODEL_DIR

def pull_required_models():
    """Ensure required models are installed locally on USB."""
    required_models = ["nomic-embed-text", "llama3.2"]
    
    try:
        models_response = ollama.list()
        installed_models = []
        for m in models_response.get('models', []):
            name = m.get('model', m.get('name', ''))
            installed_models.append(name.split(':')[0])
    except Exception:
        installed_models = []
    
    for model in required_models:
        if model not in installed_models:
            print(f"📥 Model '{model}' not found on USB. Downloading now (one-time step)...")
            ollama.pull(model)
        else:
            print(f"✅ Model '{model}' detected on USB.")

def chunk_text(text, max_chars=800):
    """Split long text into chunks for vector indexing."""
    return [text[i:i+max_chars] for i in range(0, len(text), max_chars)]

def sync_notes_to_vector_db():
    """Index or update Markdown files in ChromaDB only if modified."""
    os.makedirs(NOTES_DIR, exist_ok=True)
    os.makedirs(DB_PATH, exist_ok=True)

    # 1. Load Sync Manifest (timestamps of last indexed files)
    manifest = {}
    if os.path.exists(MANIFEST_PATH):
        try:
            with open(MANIFEST_PATH, "r") as f:
                manifest = json.load(f)
        except Exception as e:
            print(f"⚠️ Warning: Could not read manifest, full sync will run. Error: {e}")

    client = chromadb.PersistentClient(path=DB_PATH)
    collection = client.get_or_create_collection(name="notes")

    md_files = glob.glob(os.path.join(NOTES_DIR, "**", "*.md"), recursive=True)
    if not md_files:
        print(f"⚠️ No .md files found in '{NOTES_DIR}'. Add notes there anytime!")
        return

    processed_count = 0
    skipped_count = 0

    print(f"📄 Checking {len(md_files)} markdown file(s)...")

    for file_path in md_files:
        rel_path = os.path.relpath(file_path, NOTES_DIR)
        mtime = os.path.getmtime(file_path)

        # 2. Skip file if timestamp hasn't changed
        if manifest.get(rel_path) == mtime:
            skipped_count += 1
            continue

        # 3. Process modified or new file
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        chunks = chunk_text(content)
        for idx, chunk in enumerate(chunks):
            chunk_id = f"{rel_path}_chunk_{idx}"
            embedding = ollama.embed(model="nomic-embed-text", input=chunk)["embeddings"][0]
            collection.upsert(
                ids=[chunk_id],
                embeddings=[embedding],
                documents=[chunk],
                metadatas=[{"source": rel_path}]
            )
        
        # Update timestamp in manifest
        manifest[rel_path] = mtime
        processed_count += 1

    # 4. Save updated manifest to disk
    with open(MANIFEST_PATH, "w") as f:
        json.dump(manifest, f, indent=4)

    print(f"✅ Sync complete. Processed: {processed_count}, Skipped: {skipped_count}.")

if __name__ == "__main__":
    pull_required_models()
    sync_notes_to_vector_db()
