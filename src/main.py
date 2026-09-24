"""
=============================================================================
Designed and Engineered by: Yuvanesh KS (Alias: North-Abyss)
GitHub: https://github.com/North-Abyss
License: CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike)

Core Innovation: Q-Ternary (2³ → 3²) Medical Data Compression & VQC Entanglement
=============================================================================
"""
import argparse
import os
import joblib
import torch
import torch.nn as nn
import torch.optim as optim
import time
from tqdm import tqdm
from data.loader import load_wisconsin_breast_cancer, load_ckd_dataset
from data.preprocessor import Preprocessor
from data.feature_selector import FeatureSelector
from quantum.qutrit_model import QutritClassifier
from classical.baselines import get_all_baselines
from evaluation.metrics import calculate_metrics
from evaluation.visualizer import Visualizer
from explainability.xai_engine import XAIEngine
from api import app

def _main_impl():
    parser = argparse.ArgumentParser(description="Hybrid Quantum ML Engine for MedTech")
    parser.add_argument("--dataset", type=str, default="breast_cancer", choices=["breast_cancer", "ckd", "heart_disease", "parkinsons"])
    parser.add_argument("--n-features", type=int, default=12, help="Number of features after PCA/MI (must be multiple of 3)")
    parser.add_argument("--n-layers", type=int, default=3, help="Number of layers in Quantum Neural Network")
    parser.add_argument("--epochs", type=int, default=50, help="Training epochs for QNN")
    parser.add_argument("--classical-only", action="store_true", help="Skip quantum training, run classical only")
    parser.add_argument("--start-api", action="store_true", help="Start the Flask API after training")
    parser.add_argument("--max-ram", type=float, default=6.0, help="Maximum RAM limit in GB before halting training")
    
    args = parser.parse_args()
    
    print("===============================================")
    print("🚀 Starting QMLPlatform 🚀")
    print(f"📊 Dataset: {args.dataset}")
    print(f"🎯 Target Features: {args.n_features}")
    print("===============================================\n")

    # 1. Load Data
    print("--- 📥 1. Loading Data ---")
    if args.dataset == "breast_cancer":
        bundle = load_wisconsin_breast_cancer()
    elif args.dataset == "ckd":
        bundle = load_ckd_dataset("data/kidney_disease.csv")
    elif args.dataset == "heart_disease":
        from data.loader import load_heart_disease
        bundle = load_heart_disease()
    elif args.dataset == "parkinsons":
        from data.loader import load_parkinsons
        bundle = load_parkinsons()
    
    print(f"✅ Loaded {bundle.dataset_name}: {bundle.X_train.shape[0]} train, {bundle.X_test.shape[0]} test samples.")

    # 2. Feature Selection
    print("\n--- 🔍 2. Feature Selection (Mutual Information) ---")
    selector = FeatureSelector(method='mutual_info', n_features=args.n_features)
    bundle_selected = selector.fit_transform(bundle)
    print(f"✅ Selected features: {bundle_selected.X_train.shape[1]}")

    # 3. Preprocessing (Impute, Scale, Binarize, Compress)
    print("\n--- ⚛️ 3. Preprocessing & Q-Ternary Compression ---")
    preprocessor = Preprocessor()
    bundle_compressed = preprocessor.fit_transform(bundle_selected)
    print(f"📉 Original dimension: {bundle_selected.X_train.shape[1]} bits")
    print(f"📉 Compressed dimension: {bundle_compressed.X_train.shape[1]} trits")

    # 4. Train Classical Baselines
    print("\n--- 🖥️ 4. Training Classical Baselines ---")
    baselines = get_all_baselines()
    classical_results = {}
    classical_models_trained = {}
    for model in baselines:
        start_time = time.time()
        model.fit(bundle_selected.X_train, bundle_selected.y_train)
        y_pred = model.predict(bundle_selected.X_test)
        y_prob = model.predict_proba(bundle_selected.X_test)[:, 1] if hasattr(model, 'predict_proba') else None
        
        metrics = calculate_metrics(bundle_selected.y_test, y_pred, y_prob)
        classical_results[model.name] = {"metrics": metrics, "y_prob": y_prob}
        classical_models_trained[model.name] = model
        print(f"✅ {model.name} Accuracy: {metrics['Accuracy']:.2%} | F1: {metrics['F1']:.2%} | Time: {time.time()-start_time:.2f}s")

    quantum_model_trained = None
    if not args.classical_only:
        # 5. Train Quantum Engine
        print("\n--- ⚛️ 5. Training Quantum Engine (VQC) ---")
        n_wires = bundle_compressed.X_train.shape[1]
        
        # Pre-computation validation for NaNs
        import numpy as np
        if np.isnan(bundle_compressed.X_train).any() or np.isnan(bundle_compressed.y_train).any():
            raise ValueError("Input dataset contains NaN values, which will crash the quantum simulator.")
            
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        print(f"⚙️ Using device: {device}")
        
        model = QutritClassifier(n_wires=n_wires, n_layers=args.n_layers).to(device)
        criterion = nn.BCELoss()
        optimizer = optim.Adam(model.parameters(), lr=0.01)
        scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=5)
        
        import psutil
        import gc
        import os
        from torch.utils.data import DataLoader, TensorDataset
        
        X_train_t = torch.tensor(bundle_compressed.X_train, dtype=torch.float32)
        y_train_t = torch.tensor(bundle_compressed.y_train, dtype=torch.float32)
        X_test_t = torch.tensor(bundle_compressed.X_test, dtype=torch.float32).to(device)
        
        dataset = TensorDataset(X_train_t, y_train_t)
        dataloader = DataLoader(dataset, batch_size=16, shuffle=True)
        
        process = psutil.Process(os.getpid())
        MAX_MEM_GB = args.max_ram
        OVERLOAD_MEM_GB = args.max_ram + 1.0
        
        losses = []
        epoch_iterator = tqdm(range(args.epochs), desc="⚛️ Training Q-Ternary VQC", unit="epoch", dynamic_ncols=True)
        for epoch in epoch_iterator:
            model.train()
            epoch_loss = 0.0
            for batch_X, batch_y in dataloader:
                batch_X = batch_X.to(device)
                batch_y = batch_y.to(device)
                
                optimizer.zero_grad()
                outputs = model(batch_X)
                loss = criterion(outputs.to(torch.float32), batch_y.to(torch.float32))
                loss.backward()
                optimizer.step()
                epoch_loss += loss.item() * batch_X.size(0)
                
            avg_loss = epoch_loss / len(dataset)
            losses.append(avg_loss)
            
            # Memory Profiling & GC
            del outputs, loss, batch_X, batch_y
            gc.collect()
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                
            mem_gb = process.memory_info().rss / (1024 ** 3)
            
            if mem_gb > OVERLOAD_MEM_GB:
                epoch_iterator.write(f"🚨 CRITICAL WARNING: Memory overloaded at {mem_gb:.2f} GB. Halting training safely.")
                break
            elif mem_gb > MAX_MEM_GB:
                epoch_iterator.write(f"⚠️ WARNING: Memory usage high ({mem_gb:.2f} GB). Close to limit.")
                
            # Update progress bar postfix with current loss and memory
            current_lr = optimizer.param_groups[0]['lr']
            epoch_iterator.set_postfix({"Loss": f"{avg_loss:.4f}", "LR": f"{current_lr:.5f}", "RAM(GB)": f"{mem_gb:.2f}"})
            
            # Step the LR scheduler
            scheduler.step(avg_loss)
                
            if (epoch + 1) % 10 == 0 or epoch == 0:
                epoch_iterator.write(f"\n🔄 Epoch {epoch+1}/{args.epochs} | Loss: {avg_loss:.4f} | LR: {current_lr:.5f} | Mem: {mem_gb:.2f} GB\n")
                
        # Evaluate Quantum
        model.eval()
        with torch.no_grad():
            q_probs = model(X_test_t).cpu().numpy()
            q_preds = (q_probs >= 0.5).astype(int)
            
        q_metrics = calculate_metrics(bundle_compressed.y_test, q_preds, q_probs)
        print(f"\n✅ Quantum Model Accuracy: {q_metrics['Accuracy']:.2%} | F1: {q_metrics['F1']:.2%}")
        quantum_model_trained = model

        # 6. Evaluation & Visualization
        print("\n--- 📈 6. Generating Visualizations ---")
        viz = Visualizer()
        viz.plot_training_loss(losses)
        viz.plot_compression_ratio(bundle_selected.X_train.shape[1], n_wires)
        
        # Combine probabilities for ROC
        roc_dict = {name: res["y_prob"] for name, res in classical_results.items()}
        roc_dict["Qutrit VQC"] = q_probs
        viz.plot_roc_curves(roc_dict, bundle_compressed.y_test)
        
        # Confusion Matrices
        viz.plot_confusion_matrix(bundle_compressed.y_test, q_preds, "Qutrit VQC")
        best_classical = baselines[0] # Just plot the first one (SVM) as representative
        c_preds = best_classical.predict(bundle_selected.X_test)
        viz.plot_confusion_matrix(bundle_selected.y_test, c_preds, best_classical.name)
        
        print("🖼️ Visualizations saved to outputs/ directory.")

        # 7. XAI (Explainability)
        print("\n--- 🧠 7. Generating SHAP Explanations ---")
        # Explain classical SVM as it's faster
        xai = XAIEngine(baselines[0], bundle_selected.X_train, bundle_selected.feature_names)
        xai.explain_dataset(bundle_selected.X_test, n_samples=30)
        print("🖼️ SHAP plots saved to outputs/ directory.")

        # 8. Save Trained Models
        print("\n--- 💾 8. Saving Trained Models to Disk ---")
        import datetime
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        run_dir = f"models/run_{timestamp}"
        os.makedirs(run_dir, exist_ok=True)
        
        # Save Quantum Model Weights
        torch.save(quantum_model_trained.state_dict(), f"{run_dir}/qutrit_vqc_weights.pt")
        print(f"✅ Saved Quantum VQC weights to {run_dir}/qutrit_vqc_weights.pt")
        
        # Save Classical Baselines
        for c_model_name, c_model_obj in classical_models_trained.items():
            # Clean filename by replacing spaces with underscores
            safe_name = c_model_name.replace(" ", "_").lower()
            joblib.dump(c_model_obj.model, f"{run_dir}/{safe_name}_baseline.pkl")
            print(f"✅ Saved Classical {c_model_name} to {run_dir}/{safe_name}_baseline.pkl")
            
        # Save Preprocessor and Feature Selector
        joblib.dump(preprocessor, f"{run_dir}/preprocessor.pkl")
        joblib.dump(selector, f"{run_dir}/feature_selector.pkl")
        joblib.dump(bundle_selected.feature_names, f"{run_dir}/feature_names.pkl")
        print(f"✅ Saved Preprocessor and Feature Selector to {run_dir}/")
        
        # Update latest symlink
        try:
            if os.path.exists("models/latest") or os.path.islink("models/latest"):
                os.remove("models/latest")
            os.symlink(f"run_{timestamp}", "models/latest")
        except Exception as e:
            print(f"⚠️ Could not create 'latest' symlink: {e}")

    # 9. API Startup
    if args.start_api:
        print("\n--- 🌐 9. Starting Flask API ---")
        app.preprocessor = preprocessor
        app.feature_selector = selector
        app.quantum_model = quantum_model_trained
        app.classical_baselines = classical_models_trained
        app.feature_names = bundle_selected.feature_names
        app.app.run(host='0.0.0.0', port=5000, debug=False)
        
    print("\n===============================================")
    print("🎉 Pipeline Execution Complete.")
    print("===============================================")

def main():
    try:
        _main_impl()
    except Exception as e:
        import json
        import traceback
        import sys
        error_info = {
            "error_type": type(e).__name__,
            "message": str(e),
            "traceback": traceback.format_exc()
        }
        print(f"\n[PIPELINE_ERROR] {json.dumps(error_info)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
