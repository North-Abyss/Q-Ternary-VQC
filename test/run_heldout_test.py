import os
import sys
import pandas as pd
import numpy as np
import torch
import joblib
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from quantum.qutrit_model import QutritClassifier
import data.feature_selector 
import data.preprocessor

def main():
    print("===============================================")
    print("🧪 HELDOUT TEST VALIDATION 🧪")
    print("===============================================")

    # Project root is one level up from the script's directory (assuming script is in test/)
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

    # 1. Load Data
    csv_path = os.path.join(project_root, "data/heldout_test_114.csv")
    if not os.path.exists(csv_path):
        print(f"❌ Error: {csv_path} not found.")
        return
        
    df = pd.read_csv(csv_path)
    X_raw = df.drop(columns=['target']).values
    y_true = df['target'].values
    print(f"✅ Loaded {csv_path}")
    print(f"   Shape: {X_raw.shape}")
    print(f"   Class split: {np.bincount(y_true)} (0: malignant, 1: benign)")

    # 2. Resolve Model Directory
    model_dir = os.path.join(project_root, "models/")
    latest_dir = os.path.join(project_root, "models/latest/")
    if os.path.exists(os.path.join(latest_dir, "preprocessor.pkl")):
        model_dir = latest_dir
    print(f"📂 Using models from: {model_dir}")

    # 3. Load Pipeline
    try:
        preprocessor = joblib.load(os.path.join(model_dir, 'preprocessor.pkl'))
        selector = joblib.load(os.path.join(model_dir, 'feature_selector.pkl'))
        feature_names = joblib.load(os.path.join(model_dir, 'feature_names.pkl'))
        
        device = torch.device("cpu")
        state_dict = torch.load(os.path.join(model_dir, 'qutrit_vqc_weights.pt'), map_location=device, weights_only=True)
        n_layers = state_dict['q_weights'].shape[0]
        n_wires = (len(feature_names) // 3) * 2
        
        vqc = QutritClassifier(n_wires=n_wires, n_layers=n_layers).to(device)
        vqc.load_state_dict(state_dict)
        vqc.eval()
        print(f"✅ Pipeline loaded successfully! VQC Layers: {n_layers}")
    except Exception as e:
        print(f"❌ Failed to load pipeline: {e}")
        return

    # 4. Process Data
    X_sel = selector.selector.transform(X_raw)
    X_comp = preprocessor.transform(X_sel)
    X_tensor = torch.tensor(X_comp, dtype=torch.float32)

    # 5. Make Predictions
    with torch.no_grad():
        q_probs = vqc(X_tensor).cpu().numpy()
        
    # Constant-output guard
    prob_std = q_probs.std()
    print("\n--- 🛡️ CONSTANT-OUTPUT GUARD ---")
    print(f"Probability StdDev: {prob_std:.6f}  (Must NOT be near 0.0)")
    print(f"First 10 Probs: {q_probs[:10].flatten()}")
    
    if prob_std < 1e-4:
        print("🚨 WARNING: Model is a constant function! It has learned nothing.")
    else:
        print("✅ Guard passed: Model outputs vary.")

    # 6. Evaluate
    q_preds = (q_probs >= 0.5).astype(int)
    
    acc = accuracy_score(y_true, q_preds)
    prec = precision_score(y_true, q_preds, zero_division=0)
    rec = recall_score(y_true, q_preds, zero_division=0)
    f1 = f1_score(y_true, q_preds, zero_division=0)
    cm = confusion_matrix(y_true, q_preds)

    print("\n--- 📊 EVALUATION METRICS ---")
    print(f"Accuracy:  {acc*100:.2f}%")
    print(f"Precision: {prec:.4f}")
    print(f"Recall:    {rec:.4f}")
    print(f"F1 Score:  {f1:.4f}")
    print("\nConfusion Matrix:")
    print(f"  TN(0): {cm[0,0]:2d}   FP(1): {cm[0,1]:2d}")
    print(f"  FN(0): {cm[1,0]:2d}   TP(1): {cm[1,1]:2d}")
    
    print("\n--- 🏁 CLASSICAL BASELINES FOR COMPARISON ---")
    print("SVM:          91.23%")
    print("Random Forest: 94.74%")
    print("XGBoost:      94.74%")
    
if __name__ == "__main__":
    main()
