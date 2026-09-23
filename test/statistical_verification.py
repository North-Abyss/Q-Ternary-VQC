import os
import sys
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from sklearn.model_selection import StratifiedKFold
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from statsmodels.stats.contingency_tables import mcnemar

# Local imports
from src.data.loader import load_wisconsin_breast_cancer
from src.data.preprocessor import Preprocessor
from src.data.feature_selector import FeatureSelector
from src.quantum.qutrit_model import QutritClassifier
from src.evaluation.metrics import calculate_metrics

def train_vqc(X_train, y_train, epochs=50, n_layers=3):
    n_wires = X_train.shape[1]
    device = torch.device("cpu")
    model = QutritClassifier(n_wires=n_wires, n_layers=n_layers).to(device)
    criterion = nn.BCELoss()
    optimizer = optim.Adam(model.parameters(), lr=0.01)
    
    X_train_t = torch.tensor(X_train, dtype=torch.float32)
    y_train_t = torch.tensor(y_train, dtype=torch.float32)
    
    dataset = TensorDataset(X_train_t, y_train_t)
    dataloader = DataLoader(dataset, batch_size=16, shuffle=True)
    
    for epoch in range(epochs):
        model.train()
        for batch_X, batch_y in dataloader:
            batch_X, batch_y = batch_X.to(device), batch_y.to(device)
            optimizer.zero_grad()
            outputs = model(batch_X)
            loss = criterion(outputs.to(torch.float32), batch_y.to(torch.float32))
            loss.backward()
            optimizer.step()
    return model

def eval_vqc(model, X_test, y_test):
    model.eval()
    X_test_t = torch.tensor(X_test, dtype=torch.float32)
    with torch.no_grad():
        probs = model(X_test_t).numpy()
    preds = (probs >= 0.5).astype(int)
    return preds, probs

def main(epochs=50, folds=10):
    print("="*60)
    print("🔬 RIGOROUS STATISTICAL VERIFICATION")
    print("="*60)
    print(f"Note: Running VQC for {epochs} epochs per fold, for {folds} folds.")
    
    bundle_raw = load_wisconsin_breast_cancer(random_state=42)
    
    # We must do selection and preprocessing INSIDE the CV loop to prevent leakage!
    # The previous setup did it outside, but standard practice is inside.
    
    skf = StratifiedKFold(n_splits=folds, shuffle=True, random_state=42)
    
    lr_accs, lr_f1s = [], []
    rf_accs, rf_f1s = [], []
    vqc_accs, vqc_f1s = [], []
    
    fold = 1
    # Full dataset arrays for the loop
    X = np.vstack((bundle_raw.X_train, bundle_raw.X_test))
    y = np.concatenate((bundle_raw.y_train, bundle_raw.y_test))
    
    for train_index, test_index in skf.split(X, y):
        print(f"\n--- Fold {fold}/{folds} ---")
        X_tr, X_te = X[train_index], X[test_index]
        y_tr, y_te = y[train_index], y[test_index]
        
        # Fit Feature Selector on train only
        selector = FeatureSelector(method='mutual_info', n_features=12)
        # Mock bundle for selector
        class MockBundle:
            pass
        mb = MockBundle()
        mb.X_train, mb.X_test = X_tr, X_te
        mb.y_train, mb.y_test = y_tr, y_te
        mb.feature_names = bundle_raw.feature_names
        mb.dataset_name = ""
        
        sel_bundle = selector.fit_transform(mb)
        
        # Fit Preprocessor on train only
        prep = Preprocessor()
        comp_bundle = prep.fit_transform(sel_bundle)
        
        X_tr_comp, X_te_comp = comp_bundle.X_train, comp_bundle.X_test
        
        # 1. LR
        lr = LogisticRegression(max_iter=1000)
        lr.fit(X_tr_comp, y_tr)
        p_lr = lr.predict(X_te_comp)
        m_lr = calculate_metrics(y_te, p_lr, p_lr)
        lr_accs.append(m_lr['Accuracy'])
        lr_f1s.append(m_lr['F1'])
        
        # 2. RF
        rf = RandomForestClassifier(random_state=42)
        rf.fit(X_tr_comp, y_tr)
        p_rf = rf.predict(X_te_comp)
        m_rf = calculate_metrics(y_te, p_rf, p_rf)
        rf_accs.append(m_rf['Accuracy'])
        rf_f1s.append(m_rf['F1'])
        
        # 3. VQC
        vqc_model = train_vqc(X_tr_comp, y_tr, epochs=epochs)
        p_vqc, _ = eval_vqc(vqc_model, X_te_comp, y_te)
        m_vqc = calculate_metrics(y_te, p_vqc, p_vqc)
        vqc_accs.append(m_vqc['Accuracy'])
        vqc_f1s.append(m_vqc['F1'])
        
        print(f"LR Acc: {m_lr['Accuracy']:.4f} | RF Acc: {m_rf['Accuracy']:.4f} | VQC Acc: {m_vqc['Accuracy']:.4f}")
        fold += 1

    print("\n" + "="*60)
    print(f"📊 {folds}-FOLD CV RESULTS (Mean ± Std)")
    print("="*60)
    print(f"LR  - Accuracy: {np.mean(lr_accs):.4f} ± {np.std(lr_accs):.4f} | F1: {np.mean(lr_f1s):.4f} ± {np.std(lr_f1s):.4f}")
    print(f"RF  - Accuracy: {np.mean(rf_accs):.4f} ± {np.std(rf_accs):.4f} | F1: {np.mean(rf_f1s):.4f} ± {np.std(rf_f1s):.4f}")
    print(f"VQC - Accuracy: {np.mean(vqc_accs):.4f} ± {np.std(vqc_accs):.4f} | F1: {np.mean(vqc_f1s):.4f} ± {np.std(vqc_f1s):.4f}")

    # McNemar's Test on the last fold
    print("\n" + "="*60)
    print(f"🧪 MCNEMAR'S TEST (VQC vs RF on Fold {folds})")
    print("="*60)
    # Contingency table
    #           RF Correct | RF Wrong
    # VQC Corr |    a      |    b
    # VQC Wron |    c      |    d
    
    a = sum((p_vqc == y_te) & (p_rf == y_te))
    b = sum((p_vqc == y_te) & (p_rf != y_te))
    c = sum((p_vqc != y_te) & (p_rf == y_te))
    d = sum((p_vqc != y_te) & (p_rf != y_te))
    
    table = [[a, b], [c, d]]
    result = mcnemar(table, exact=True)
    print(f"Contingency Table: {table}")
    print(f"McNemar p-value: {result.pvalue:.4f}")
    if result.pvalue < 0.05:
        print("Result: Statistically significant difference between VQC and RF predictions.")
    else:
        print("Result: No statistically significant difference between VQC and RF predictions.")

    # 5 Random Seeds for VQC Initialization
    print("\n" + "="*60)
    print("🌱 MULTIPLE RANDOM SEED INITIALIZATIONS (Single Split)")
    print("="*60)
    
    X_tr_comp_single = comp_bundle.X_train
    y_tr_single = comp_bundle.y_train
    X_te_comp_single = comp_bundle.X_test
    y_te_single = comp_bundle.y_test
    
    seed_accs = []
    seeds = [42, 123, 999, 2026, 7]
    for s in seeds:
        torch.manual_seed(s)
        np.random.seed(s)
        model = train_vqc(X_tr_comp_single, y_tr_single, epochs=epochs)
        p, _ = eval_vqc(model, X_te_comp_single, y_te_single)
        acc = calculate_metrics(y_te_single, p, p)['Accuracy']
        seed_accs.append(acc)
        print(f"Seed {s}: Accuracy = {acc:.4f}")
        
    print(f"\nVQC Accuracy Range across 5 seeds: {min(seed_accs):.4f} - {max(seed_accs):.4f}")
    print(f"VQC Seed Mean: {np.mean(seed_accs):.4f} ± {np.std(seed_accs):.4f}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--epochs', type=int, default=50)
    parser.add_argument('--folds', type=int, default=10)
    args = parser.parse_args()
    main(epochs=args.epochs, folds=args.folds)
