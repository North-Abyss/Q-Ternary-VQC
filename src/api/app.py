"""
=============================================================================
Designed and Engineered by: Yuvanesh KS (Alias: North-Abyss)
GitHub: https://github.com/North-Abyss
License: CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike)
=============================================================================
"""
from flask import Flask, request, jsonify, render_template, send_from_directory, send_file
from flask_cors import CORS
import torch
import numpy as np
import traceback
import joblib
import pandas as pd
import os
import sys
import threading
import subprocess
import io

# Add parent dir to path so we can import our modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from quantum.qutrit_model import QutritClassifier

app = Flask(__name__, template_folder='templates', static_folder='static')
CORS(app)

HISTORY_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'models', 'history.json')

def load_history():
    if os.path.exists(HISTORY_FILE):
        try:
            import json
            with open(HISTORY_FILE, 'r') as f:
                return json.load(f)
        except:
            return []
    return []

def save_history(history):
    os.makedirs(os.path.dirname(HISTORY_FILE), exist_ok=True)
    import json
    with open(HISTORY_FILE, 'w') as f:
        json.dump(history, f, indent=2)

# Global variables to hold loaded pipeline
preprocessor = None
feature_selector = None
quantum_model = None
feature_names = []

# Background Training State
training_state = {
    "is_running": False,
    "logs": []
}
training_lock = threading.Lock()

def load_pipeline():
    global preprocessor, feature_selector, quantum_model, feature_names
    try:
        model_dir = "models/"
        if os.path.exists("models/latest/preprocessor.pkl"):
            model_dir = "models/latest/"
            
        if not os.path.exists(os.path.join(model_dir, 'preprocessor.pkl')):
            print(f"⚠️ Models directory ({model_dir}) empty. Please train the model first.")
            return

        preprocessor = joblib.load(os.path.join(model_dir, 'preprocessor.pkl'))
        feature_selector = joblib.load(os.path.join(model_dir, 'feature_selector.pkl'))
        feature_names = joblib.load(os.path.join(model_dir, 'feature_names.pkl'))
        
        n_features = len(feature_names)
        n_wires = (n_features // 3) * 2
        
        device = torch.device("cpu")
        state_dict = torch.load(os.path.join(model_dir, 'qutrit_vqc_weights.pt'), map_location=device, weights_only=True)
        # Determine n_layers from the saved shape (n_layers, n_wires, 3)
        n_layers = state_dict['q_weights'].shape[0]
        
        model = QutritClassifier(n_wires=n_wires, n_layers=n_layers).to(device)
        model.load_state_dict(state_dict)
        model.eval()
        quantum_model = model
        print(f"✅ Pipeline successfully loaded from {model_dir}. (VQC Layers: {n_layers})")
    except Exception as e:
        print(f"⚠️ Failed to load models: {e}")

load_pipeline()

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html', features=feature_names)

@app.route('/upload_dataset', methods=['POST'])
def upload_dataset():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
        
    os.makedirs('data', exist_ok=True)
    filename = str(file.filename) if file.filename else 'upload.csv'
    file_path = os.path.join('data', filename)
    file.save(file_path)
    return jsonify({"status": "success", "message": f"Saved as {file_path}", "filename": filename})

def _run_training_subprocess(epochs, layers, dataset):
    global training_state
    
    with training_lock:
        training_state["is_running"] = True
        training_state["logs"] = [f"Starting training job for dataset '{dataset}'..."]
        
    cmd = [sys.executable, "src/main.py", "--epochs", str(epochs), "--n-layers", str(layers)]
    # We append dataset arg if it's one of the recognized ones, or default to breast_cancer
    if dataset == "ckd":
        cmd.extend(["--dataset", "ckd"])
    
    # __file__ is src/api/app.py. dirname x3 gives the repo root (QT)
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=repo_root)
    
    if process.stdout:
        for line in iter(process.stdout.readline, ''):
            with training_lock:
                training_state["logs"].append(line.strip())
        process.stdout.close()
    process.wait()
    
    with training_lock:
        training_state["logs"].append(f"Training finished with code {process.returncode}")
        training_state["is_running"] = False
        
        # Extract F1 score from logs
        f1_score = "N/A"
        for line in training_state["logs"]:
            if "Quantum Model Accuracy:" in line and "F1:" in line:
                try:
                    f1_score = line.split("F1:")[1].strip()
                except IndexError:
                    pass
                    
        # Save to history
        import datetime
        history = load_history()
        history.append({
            "timestamp": datetime.datetime.now().isoformat(),
            "epochs": epochs,
            "layers": layers,
            "dataset": dataset,
            "f1_score": f1_score,
            "logs": training_state["logs"].copy(),
            "success": process.returncode == 0
        })
        save_history(history)
        
    # Reload pipeline after training
    load_pipeline()

@app.route('/train', methods=['POST'])
def train():
    global training_state
    
    with training_lock:
        if training_state["is_running"]:
            return jsonify({"error": "A training job is already running."}), 400
            
    config = request.json or {}
    epochs = int(config.get("epochs", 50))
    layers = int(config.get("layers", 3))
    dataset = config.get("dataset", "breast_cancer")
    
    thread = threading.Thread(target=_run_training_subprocess, args=(epochs, layers, dataset))
    thread.daemon = True
    thread.start()
    
    return jsonify({"status": "success", "message": "Training job started in background."})

@app.route('/train_status', methods=['GET'])
def train_status():
    with training_lock:
        return jsonify({
            "is_running": training_state["is_running"],
            "logs": training_state["logs"]
        })

@app.route('/download_model', methods=['GET'])
def download_model():
    filename = request.args.get('filename')
    models_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'models')
    if not filename or not os.path.exists(os.path.join(models_dir, filename)):
        return jsonify({"error": "File not found."}), 404
        
    return send_from_directory(models_dir, filename, as_attachment=True)

@app.route('/history', methods=['GET'])
def get_history():
    return jsonify({"status": "success", "history": load_history()})

@app.route('/feature_names', methods=['GET'])
def get_feature_names():
    if feature_names is None:
        return jsonify({"error": "Feature names not loaded."}), 503
    names_list = feature_names.tolist() if hasattr(feature_names, 'tolist') else list(feature_names)
    return jsonify({"status": "success", "feature_names": names_list})

@app.route('/cleanup', methods=['POST'])
def cleanup():
    import glob
    models_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'models')
    try:
        files = glob.glob(os.path.join(models_dir, '*'))
        for f in files:
            os.remove(f)
        
        # Also stop any running process? (Not implementing process kill here for safety, just files)
        global preprocessor, feature_selector, quantum_model
        preprocessor = None
        feature_selector = None
        quantum_model = None
        
        return jsonify({"status": "success", "message": "All models and history cleared."})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/download_sample', methods=['GET'])
def download_sample():
    dataset_name = request.args.get('dataset', 'breast_cancer')
    import io
    from flask import send_file
    
    # We will generate a small sample CSV using the backend's data loader
    sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from data.loader import load_wisconsin_breast_cancer
    
    # Only supporting breast_cancer for the demo payload
    bundle = load_wisconsin_breast_cancer()
    df = pd.DataFrame(bundle.X_train[:50], columns=bundle.feature_names)
    df['target'] = bundle.y_train[:50].tolist()
    
    csv_buffer = io.BytesIO()
    df.to_csv(csv_buffer, index=False)
    csv_buffer.seek(0)
    
    return send_file(csv_buffer, download_name=f'sample_{dataset_name}.csv', as_attachment=True, mimetype='text/csv')

@app.route('/predict_batch', methods=['POST'])
def predict_batch():
    if quantum_model is None or preprocessor is None:
        return jsonify({"error": "Quantum model not loaded properly."}), 503
        
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file uploaded"}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400
            
        df = pd.read_csv(file.stream)
        missing_cols = [col for col in feature_names if col not in df.columns]
        if missing_cols:
            return jsonify({"error": f"Missing columns in CSV: {missing_cols}"}), 400
            
        X_raw = df[feature_names].values
        
        # Process through pipeline
        X_comp = preprocessor.transform(X_raw)
        x_tensor = torch.tensor(X_comp, dtype=torch.float32)
        
        with torch.no_grad():
            probs = quantum_model(x_tensor).numpy()
            
        preds = (probs >= 0.5).astype(int)
        
        # Append predictions to the DataFrame
        df['Prediction'] = ['Malignant (0)' if p == 0 else 'Benign (1)' for p in preds]
        df['Confidence'] = [f"{float(p)*100:.2f}%" if p > 0.5 else f"{(1-float(p))*100:.2f}%" for p in probs]
        
        csv_buffer = io.BytesIO()
        df.to_csv(csv_buffer, index=False)
        csv_buffer.seek(0)
        
        return send_file(csv_buffer, download_name='batch_predictions.csv', as_attachment=True, mimetype='text/csv')
        
    except Exception as e:
        return jsonify({"error": str(e), "trace": traceback.format_exc()}), 500

@app.route('/model_info', methods=['GET'])
def get_model_info():
    history = load_history()
    if not history:
        return jsonify({"status": "idle", "message": "No model trained yet."})
        
    latest_run = history[-1]
    return jsonify({
        "status": "success",
        "epochs": latest_run.get("epochs"),
        "layers": latest_run.get("layers"),
        "dataset": latest_run.get("dataset"),
        "f1_score": latest_run.get("f1_score"),
        "timestamp": latest_run.get("timestamp")
    })

@app.route('/shap_images', methods=['GET'])
def get_shap_images():
    # Return the summary plot from the outputs directory
    outputs_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'outputs')
    filename = 'shap_summary.png'
    if not os.path.exists(os.path.join(outputs_dir, filename)):
        return jsonify({"error": "SHAP image not found."}), 404
        
    return send_from_directory(outputs_dir, filename)

@app.route('/predict', methods=['POST'])
def predict():
    if quantum_model is None or preprocessor is None:
        return jsonify({"error": "Quantum model not loaded properly."}), 503
        
    try:
        if 'file' in request.files:
            file = request.files['file']
            if file.filename == '':
                return jsonify({"error": "No file selected"}), 400
                
            df = pd.read_csv(file.stream)
            missing_cols = [col for col in feature_names if col not in df.columns]
            if missing_cols:
                return jsonify({"error": f"Missing columns in CSV: {missing_cols}"}), 400
                
            X_raw = df[feature_names].values
        elif request.is_json:
            data = request.json
            features = data.get('features')
            if not features or len(features) != len(feature_names):
                return jsonify({"error": f"Expected {len(feature_names)} features."}), 400
            X_raw = np.array([features])
        else:
            return jsonify({"error": "Invalid request format."}), 400

        # Process through the pipeline (impute, scale, binarize, compress)
        X_comp = preprocessor.transform(X_raw)
        
        x_tensor = torch.tensor(X_comp, dtype=torch.float32)
        with torch.no_grad():
            probs = quantum_model(x_tensor).numpy()
            
        preds = (probs >= 0.5).astype(int)
        
        results = []
        for i in range(len(preds)):
            results.append({
                "id": i,
                "quantum_prediction": int(preds[i]),
                "quantum_probability": float(probs[i])
            })
            
        return jsonify({"status": "success", "results": results})
        
    except Exception as e:
        return jsonify({"error": str(e), "trace": traceback.format_exc()}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
