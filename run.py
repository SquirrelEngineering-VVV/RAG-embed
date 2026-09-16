import os
import sys
import chromadb
import ollama

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "data", "vector_db")

def ask_ai(question: str):
    client = chromadb.PersistentClient(path=DB_PATH)
    try:
        collection = client.get_collection(name="notes")
    except Exception:
        print("❌ Vector DB is empty. Add .md files to 'data/raw_notes/' first!")
        return

    print(f"\n🔎 Searching vector DB for context...")
    
    # 1. Embed query using Ollama
    query_emb = ollama.embed(model="nomic-embed-text", input=question)["embeddings"][0]
    
    # 2. Retrieve top 3 matching note passages
    results = collection.query(query_embeddings=[query_emb], n_results=3)
    docs = results.get("documents", [[]])[0]
    
    if not docs:
        print("⚠️ No relevant note passages found.")
        retrieved_context = "No specific notes found for this question."
    else:
        retrieved_context = "\n\n".join(docs)

    # 3. Build RAG prompt
    prompt = f"""
You are an AI assistant searching my personal notes.
Answer the user's question using ONLY the provided context passages below.
If the context does not contain enough information, state that clearly.

--- CONTEXT FROM NOTES ---
{retrieved_context}
--------------------------

QUESTION: {question}
ANSWER:
"""

    print("🤖 Thinking...\n")
    response = ollama.generate(model="llama3.2", prompt=prompt, stream=True)
    
    for chunk in response:
        print(chunk["response"], end="", flush=True)
    print("\n\n" + "="*50 + "\n")

if __name__ == "__main__":
    print("\n💡 Type 'exit' or 'quit' to close the terminal session.\n")
    while True:
        try:
            user_input = input("Ask your USB stack a question: ").strip()
            if not user_input:
                continue
            if user_input.lower() in ["exit", "quit"]:
                break
            ask_ai(user_input)
        except (KeyboardInterrupt, EOFError):
            break
