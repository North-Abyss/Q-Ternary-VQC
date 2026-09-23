import os
import sys
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import time
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import accuracy_score, f1_score
from statsmodels.stats.contingency_tables import mcnemar

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))
from data.loader import load_wisconsin_breast_cancer, load_ckd_dataset, DataBundle
from data.feature_selector import FeatureSelector
from data.preprocessor import Preprocessor
from quantum.qutrit_model import QutritClassifier
from classical.baselines import get_all_baselines

def run_kfold_cv(n_splits=5, epochs=50, dataset_name='breast_cancer'):
    print("=" * 50)
    print(f"🚀 Starting {n_splits}-Fold Cross Validation 🚀")
    print(f"📊 Dataset: {dataset_name}")
    print(f"⚙️  Qutrit VQC Epochs per fold: {epochs}")
    print("=" * 50)

    if dataset_name == 'breast_cancer':
        bundle = load_wisconsin_breast_cancer()
    else:
        bundle = load_ckd_dataset("data/kidney_disease.csv")
        
    X_full = np.vstack((bundle.X_train, bundle.X_test))
    y_full = np.concatenate((bundle.y_train, bundle.y_test))

    print(f"\nTotal Samples: {len(y_full)}")
    print(f"Class 0: {sum(y_full == 0)}, Class 1: {sum(y_full == 1)}")

    skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=42)
    
    baselines = get_all_baselines()
    results = {model.name: {'acc': [], 'f1': []} for model in baselines}
    results['Qutrit_VQC'] = {'acc': [], 'f1': []}

    all_y_true = []
    all_pred_rf = []
    all_pred_vqc = []

    fold = 1
    start_time = time.time()

    # type: ignore
    for train_index, test_index in skf.split(X_full, y_full):
        print(f"\n--- 🔄 Fold {fold}/{n_splits} ---")
        X_train_fold, X_test_fold = X_full[train_index], X_full[test_index]
        y_train_fold, y_test_fold = y_full[train_index], y_full[test_index]
        
        all_y_true.extend(y_test_fold)

        bundle_fold = DataBundle(
            X_train=X_train_fold,
            X_test=X_test_fold,
            y_train=y_train_fold,
            y_test=y_test_fold,
            feature_names=bundle.feature_names,
            dataset_name=bundle.dataset_name
        )

        # 1. Feature Selection
        selector = FeatureSelector(method="mutual_info", n_features=12)
        bundle_selected = selector.fit_transform(bundle_fold)

        # 2. Preprocessing for Quantum
        preprocessor = Preprocessor()
        bundle_compressed = preprocessor.fit_transform(bundle_selected)

        # 3. Classical Baselines
        fold_rf_preds = None
        preds = []
        for model in baselines:
            model.fit(bundle_selected.X_train, bundle_selected.y_train)
            preds = model.predict(bundle_selected.X_test)
            acc = accuracy_score(bundle_selected.y_test, preds)
            f1 = f1_score(bundle_selected.y_test, preds)
            results[model.name]['acc'].append(acc)
            results[model.name]['f1'].append(f1)
            
            if "Random Forest" in model.name or "RF" in model.name.upper():
                fold_rf_preds = preds
                
        if fold_rf_preds is not None:
            all_pred_rf.extend(fold_rf_preds)
        elif len(preds) > 0:
            # Fallback if RF isn't in baselines
            all_pred_rf.extend(preds)

        # 4. Quantum VQC
        device = torch.device("cpu")
        n_wires = bundle_compressed.X_train.shape[1]
        quantum_model = QutritClassifier(n_wires=n_wires, n_layers=3).to(device)
        
        X_train_t = torch.tensor(bundle_compressed.X_train, dtype=torch.float32)
        y_train_t = torch.tensor(bundle_compressed.y_train, dtype=torch.float32)
        X_test_t = torch.tensor(bundle_compressed.X_test, dtype=torch.float32).to(device)
        
        dataset = TensorDataset(X_train_t, y_train_t)
        dataloader = DataLoader(dataset, batch_size=16, shuffle=True)
        
        criterion = nn.BCELoss()
        optimizer = optim.Adam(quantum_model.parameters(), lr=0.01)
        
        print("Training Qutrit VQC...", end="", flush=True)
        quantum_model.train()
        for epoch in range(epochs):
            for batch_X, batch_y in dataloader:
                batch_X = batch_X.to(device)
                batch_y = batch_y.to(device)
                optimizer.zero_grad()
                outputs = quantum_model(batch_X)
                loss = criterion(outputs.to(torch.float32), batch_y.to(torch.float32))
                loss.backward()
                optimizer.step()
        print(" Done!")
        
        quantum_model.eval()
        with torch.no_grad():
            outputs = quantum_model(X_test_t)
            vqc_preds = (outputs.cpu().numpy() > 0.5).astype(int)
            
        acc = accuracy_score(bundle_compressed.y_test, vqc_preds)
        f1 = f1_score(bundle_compressed.y_test, vqc_preds)
        results['Qutrit_VQC']['acc'].append(acc)
        results['Qutrit_VQC']['f1'].append(f1)
        all_pred_vqc.extend(vqc_preds)

        # Print the fold's Random Forest and VQC accuracy
        rf_name = [m.name for m in baselines if "Random Forest" in m.name or "RF" in m.name.upper()][0]
        print(f"✅ {rf_name} Accuracy: {results[rf_name]['acc'][-1]*100:.2f}%")
        print(f"✅ VQC Accuracy: {acc*100:.2f}% (F1: {f1:.4f})")
        
        fold += 1

    total_time = time.time() - start_time

    print("\n" + "=" * 50)
    print("📈 FINAL CROSS-VALIDATION RESULTS (Mean ± Std)")
    print("=" * 50)
    
    for model_name, metrics in results.items():
        mean_acc = np.mean(metrics['acc']) * 100
        std_acc = np.std(metrics['acc']) * 100
        mean_f1 = np.mean(metrics['f1'])
        std_f1 = np.std(metrics['f1'])
        print(f"{model_name:>15} | Acc: {mean_acc:.2f}% ± {std_acc:.2f}% | F1: {mean_f1:.4f} ± {std_f1:.4f}")

    print("\n" + "=" * 50)
    print("🧪 MCNEMAR'S STATISTICAL SIGNIFICANCE TEST")
    print("=" * 50)
    print("Comparing best classical (Random Forest) vs Qutrit VQC across all out-of-fold predictions:")
    
    y_true_np = np.array(all_y_true)
    rf_np = np.array(all_pred_rf)
    vqc_np = np.array(all_pred_vqc)
    
    rf_correct = (rf_np == y_true_np)
    vqc_correct = (vqc_np == y_true_np)
    
    both_correct = np.sum(rf_correct & vqc_correct)
    rf_only = np.sum(rf_correct & ~vqc_correct)
    vqc_only = np.sum(~rf_correct & vqc_correct)
    both_wrong = np.sum(~rf_correct & ~vqc_correct)
    
    table = [[both_correct, rf_only],
             [vqc_only, both_wrong]]
             
    print(f"Both Correct: {both_correct} | Both Wrong: {both_wrong}")
    print(f"RF Correct / VQC Wrong: {rf_only}")
    print(f"VQC Correct / RF Wrong: {vqc_only}")
    
    mc_result = mcnemar(table, exact=False, correction=True)
    print(f"\nMcNemar's Statistic: {mc_result.statistic:.4f}")
    print(f"p-value: {mc_result.pvalue:.4e}")
    
    if mc_result.pvalue < 0.05:
        print("➡️ Result is STATISTICALLY SIGNIFICANT (p < 0.05).")
        print("   The difference in performance between RF and VQC is unlikely to be by chance.")
    else:
        print("➡️ Result is NOT statistically significant (p >= 0.05).")
        print("   The Qutrit VQC performs comparably to the Random Forest.")

    print(f"\nTotal Run Time: {total_time:.2f}s")
    print("=" * 50)

if __name__ == "__main__":
    run_kfold_cv(n_splits=5, epochs=50)
