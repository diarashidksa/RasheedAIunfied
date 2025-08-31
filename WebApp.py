# ====== IMPORTS ======
from dotenv import load_dotenv
import os
import datetime
import uuid
import pickle
import faiss
import pandas as pd
import io
import time
import threading
from flask import Flask, render_template, request, jsonify, session, redirect, url_for, send_file
from flask_session import Session
from sentence_transformers import SentenceTransformer
from PyPDF2 import PdfReader
from docx import Document
from openai import OpenAI
from pymongo import MongoClient

# ====== LOAD ENV VARIABLES ======
load_dotenv()
MONGO_URI = os.getenv("MONGO_URI")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# ====== CONFIG ======
DATA_FOLDER = "data"
INDEX_FILE = "faiss_index.index"
MAPPING_FILE = "doc_mapping.pkl"
MODEL_NAME = "all-MiniLM-L6-v2"
TIMESTAMP_FILE = "last_training_timestamp.txt"
INDEX_REQUEST_FILE = "start_indexing.txt"
SYSTEM_PROMPT_FILE = "system_prompt.txt"
# Use environment variables for host and port
HOST = '0.0.0.0'
PORT = int(os.environ.get('PORT', 5000))

# ====== MONGODB CONFIG ======
client = MongoClient(MONGO_URI)
db = client["unifiedapp_db"]
chatlogs_collection = db["chatlogs"]

# ====== APP INIT ======
app = Flask(__name__)
app.config['SESSION_TYPE'] = 'filesystem'
Session(app)

# ====== OPENAI CLIENT ======
client_openai = OpenAI(api_key=OPENAI_API_KEY)

# ====== GLOBALS ======
index = None
documents_list = []
doc_mapping = {}
embedder = SentenceTransformer(MODEL_NAME)
system_prompt = "You are a helpful assistant."

# ====== UTILITIES FOR LOCAL INDEXING ======
def load_index_and_docs():
    """Loads FAISS index and document mapping from local files."""
    global index, documents_list, doc_mapping
    try:
        if not os.path.exists(INDEX_FILE) or not os.path.exists(MAPPING_FILE):
            raise FileNotFoundError
        index = faiss.read_index(INDEX_FILE)
        with open(MAPPING_FILE, "rb") as f:
            doc_mapping = pickle.load(f)
        documents_list = [item['content'] for item in doc_mapping.values()]
        print("FAISS index and documents loaded from local files.")
    except Exception as e:
        print(f"Error loading index from local files: {e}")
        index, documents_list, doc_mapping = None, [], {}

def load_system_prompt():
    """Loads the system prompt from a local file."""
    global system_prompt
    try:
        with open(SYSTEM_PROMPT_FILE, "r", encoding="utf-8") as f:
            system_prompt = f.read().strip() or system_prompt
    except Exception:
        pass

def load_txt(path):
    """Loads content from a .txt file."""
    return open(path, "r", encoding="utf-8", errors="ignore").read().strip()

def load_pdf(path):
    """Loads content from a .pdf file."""
    try:
        reader = PdfReader(path)
        parts = []
        for p in reader.pages:
            txt = p.extract_text() or ""
            if txt.strip():
                parts.append(txt)
        return "\n".join(parts)
    except Exception:
        return ""

def load_docx(path):
    """Loads content from a .docx file."""
    try:
        doc = Document(path)
        return "\n".join([p.text for p in doc.paragraphs if p.text.strip()])
    except Exception:
        return ""

def get_file_status():
    """Checks for new, updated, and deleted files in the data folder."""
    os.makedirs(DATA_FOLDER, exist_ok=True)
    current_files = {f for f in os.listdir(DATA_FOLDER) if os.path.isfile(os.path.join(DATA_FOLDER, f))}
    known_files = set(doc_mapping.keys())
    new_files = current_files - known_files
    deleted_files = known_files - current_files
    updated_files = {f for f in (known_files & current_files)
                     if os.path.getmtime(os.path.join(DATA_FOLDER, f)) > doc_mapping[f]['mtime']}
    return new_files, updated_files, deleted_files

def run_indexing_process():
    """Rebuilds the FAISS index from files in the data folder."""
    global index, documents_list, doc_mapping

    print("Starting FAISS index build from local files...")

    new_files, updated_files, deleted_files = get_file_status()

    if deleted_files:
        for f in deleted_files:
            doc_mapping.pop(f, None)

    files_to_index = new_files | updated_files
    new_mapping = {}
    for f in files_to_index:
        path = os.path.join(DATA_FOLDER, f)
        ext = f.lower().split(".")[-1]
        try:
            if ext == "txt":
                content = load_txt(path)
            elif ext == "pdf":
                content = load_pdf(path)
            elif ext == "docx":
                content = load_docx(path)
            else:
                content = ""
            if content:
                new_mapping[f] = {"content": content, "mtime": os.path.getmtime(path)}
        except Exception as e:
            print(f"Error processing file {f}: {e}")
            pass

    doc_mapping.update(new_mapping)

    index = faiss.IndexFlatL2(embedder.get_sentence_embedding_dimension())
    all_docs = [item['content'] for item in doc_mapping.values()]
    if all_docs:
        embeddings = embedder.encode(all_docs, convert_to_numpy=True, normalize_embeddings=True)
        index.add(embeddings)

    faiss.write_index(index, INDEX_FILE)
    with open(MAPPING_FILE, "wb") as f:
        pickle.dump(doc_mapping, f)
    documents_list = all_docs

    with open(TIMESTAMP_FILE, "w") as f:
        f.write(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    if os.path.exists(INDEX_REQUEST_FILE):
        os.remove(INDEX_REQUEST_FILE)

    print("FAISS index built and saved to local files.")

def worker_thread():
    """A background thread to check for and trigger indexing."""
    while True:
        try:
            if os.path.exists(INDEX_REQUEST_FILE):
                run_indexing_process()
                load_index_and_docs()
        except Exception as e:
            print(f"Error in worker thread: {e}")
        time.sleep(5)

# Start the background indexing thread
threading.Thread(target=worker_thread, daemon=True).start()

# ====== MONGODB LOGGING UTILITIES (Unchanged) ======
def log_to_mongo(session_id, ip, user_msg, bot_resp):
    try:
        now = datetime.datetime.now()
        chatlogs_collection.insert_one({
            "session_id": session_id,
            "date": now.strftime("%Y-%m-%d"),
            "time": now.strftime("%H:%M:%S"),
            "ip_address": ip,
            "user_message": user_msg,
            "bot_response": bot_resp
        })
    except Exception as e:
        print(f"Error logging to MongoDB: {e}")

def search_docs(query, top_k=3):
    if index is None or index.ntotal == 0 or not documents_list:
        return ""
    query_vec = embedder.encode([query], convert_to_numpy=True, normalize_embeddings=True)
    D, I = index.search(query_vec, top_k)
    ctxs = []
    for i in I[0]:
        if 0 <= i < len(documents_list):
            ctxs.append(documents_list[i])
    return "\n\n---\n\n".join(ctxs)

# ====== SESSION HANDLER (Unchanged) ======
@app.before_request
def make_session_permanent():
    session.permanent = True
    if "session_id" not in session:
        session["session_id"] = str(uuid.uuid4())
    if "chat_history" not in session:
        session["chat_history"] = []

# ====== ROUTES ======

# This is the new root route that redirects to the chatbot page.
@app.route("/")
def index():
    return redirect(url_for("chatbot"))

@app.route("/chatbot")
def chatbot():
    return render_template("indexn.html", chat_history=session.get("chat_history", []))

@app.route("/chat", methods=["POST"])
def chat():
    try:
        user_message = (request.json or {}).get("message", "").strip()
        if not user_message:
            return jsonify({"reply": "الرسالة فارغة. من فضلك اكتب سؤالك."})

        session["chat_history"].append({"role": "user", "text": user_message})

        context = search_docs(user_message)
        prompt_user = f"Context:\n{context}\n\nQ: {user_message}\nA:" if context else user_message

        completion = client_openai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt_user}
            ],
            temperature=0.2,
        )
        bot_reply = (completion.choices[0].message.content or "").strip()

    except Exception as e:
        bot_reply = f"حدث خطأ أثناء توليد الرد: {e}"

    session["chat_history"].append({"role": "bot", "text": bot_reply})
    log_to_mongo(session["session_id"], request.remote_addr, user_message, bot_reply)
    return jsonify({"reply": bot_reply})

@app.route("/reset", methods=["POST"])
def reset():
    session["chat_history"] = []
    return jsonify({"status": "reset"})

@app.route("/training")
def training_dashboard():
    os.makedirs(DATA_FOLDER, exist_ok=True)
    files = []
    for f in os.listdir(DATA_FOLDER):
        path = os.path.join(DATA_FOLDER, f)
        if os.path.isfile(path):
            stat = os.stat(path)
            files.append({
                "name": f,
                "size": f"{stat.st_size/1024:.2f} KB",
                "date": datetime.datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S')
            })
    last_trained = open(TIMESTAMP_FILE).read().strip() if os.path.exists(TIMESTAMP_FILE) else "N/A"
    return render_template("training.html", files=files, last_trained=last_trained)

@app.route("/upload", methods=["POST"])
def upload():
    if "file" not in request.files or request.files["file"].filename == "":
        return redirect(url_for("training_dashboard"))
    file = request.files["file"]
    os.makedirs(DATA_FOLDER, exist_ok=True)
    file.save(os.path.join(DATA_FOLDER, file.filename))
    return redirect(url_for("training_dashboard"))

@app.route("/train")
def train():
    with open(INDEX_REQUEST_FILE, "w", encoding="utf-8") as f:
        f.write("start")
    return jsonify({"message": "Indexing started."})

@app.route("/dashboard")
def dashboard():
    return render_template("dashboard.html")

@app.route("/refresh_data")
def refresh_data():
    try:
        logs = list(chatlogs_collection.find({}, {"_id": 0}))
        num_conversations = len({log["session_id"] for log in logs})
        responses_per_conversation = {}
        for log in logs:
            responses_per_conversation[log["session_id"]] = responses_per_conversation.get(log["session_id"], 0) + 1
        return jsonify(success=True, data={
            "num_conversations": num_conversations,
            "responses_per_conversation": responses_per_conversation,
            "chat_logs": logs
        })
    except Exception as e:
        return jsonify(success=False, message=str(e))

@app.route("/export_excel")
def export_excel():
    try:
        logs = list(chatlogs_collection.find({}, {"_id": 0}))
        df = pd.DataFrame(logs)
        output = io.BytesIO()
        with pd.ExcelWriter(output, engine="xlsxwriter") as writer:
            df.to_excel(writer, index=False, sheet_name="ChatLogs")
        output.seek(0)
        return send_file(output,
                         mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                         as_attachment=True,
                         download_name="ChatLogs_Export.xlsx")
    except Exception as e:
        return jsonify(success=False, message=str(e))

# ====== MAIN ======
if __name__ == "__main__":
    os.makedirs(DATA_FOLDER, exist_ok=True)
    load_index_and_docs()
    load_system_prompt()
    app.run(host=HOST, port=PORT, debug=True, threaded=True)