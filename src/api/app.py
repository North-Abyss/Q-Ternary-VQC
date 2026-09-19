"""
=============================================================================
Designed and Engineered by: Yuvanesh KS (Alias: North-Abyss)
GitHub: https://github.com/North-Abyss
License: CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike)

Core Innovation: Q-Ternary (2³ → 3²) Medical Data Compression & VQC Entanglement
=============================================================================
"""
from flask import Flask, request, jsonify
import torch
import numpy as np
import traceback

app = Flask(__name__)

# Global variables to hold loaded pipeline
preprocessor = None
feature_selector = None
quantum_model = None
classical_baselines = {}
feature_names = []

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "online",
        "quantum_model_loaded": quantum_model is not None,
        "classical_models_loaded": len(classical_baselines) > 0
    })

@app.route('/predict', methods=['POST'])
def predict():
    """
    Expects JSON: {"features": [list of feature values matching the required dataset shape]}
    """
    if quantum_model is None:
        return jsonify({"error": "Model not loaded"}), 503
        
    try:
        data = request.json
        features = data.get('features')
        if not features:
            return jsonify({"error": "No features provided"}), 400
            
        # 1. Convert to numpy array
        X_raw = np.array([features])
        
        # 2. Impute and Scale (Using the preprocessor fitted on training data)
        # Note: Preprocessor expects DataBundle for fit_transform, 
        # but for single prediction we should refactor it to handle single inputs.
        # For this SIH demo, we'll do a simplified inference pass.
        
        # 3. Feature Selection
        if feature_selector:
            X_sel = feature_selector.selector.transform(X_raw)
        else:
            X_sel = X_raw
            
        # 4. Binarize and Compress
        X_bin = (X_sel > preprocessor.thresholds).astype(int)
        X_comp = preprocessor.batch_compress(X_bin)
        
        # 5. Quantum Prediction
        x_tensor = torch.tensor(X_comp, dtype=torch.float32)
        with torch.no_grad():
            prob = quantum_model(x_tensor).item()
            
        prediction = 1 if prob >= 0.5 else 0
        
        # 6. Classical Predictions for comparison
        classical_results = {}
        for name, model in classical_baselines.items():
            if hasattr(model, 'predict_proba'):
                c_prob = model.predict_proba(X_sel)[0, 1]
                classical_results[name] = {
                    "probability": float(c_prob),
                    "prediction": int(c_prob >= 0.5)
                }
        
        return jsonify({
            "quantum_prediction": int(prediction),
            "quantum_probability": float(prob),
            "classical_comparisons": classical_results
        })
        
    except Exception as e:
        return jsonify({"error": str(e), "trace": traceback.format_exc()}), 500

if __name__ == '__main__':
    # When running directly, we start the API
    # In practice, main.py would train the model and then start the API or pass the models
    app.run(host='0.0.0.0', port=5000, debug=True)
