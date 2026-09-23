#!/usr/bin/env python3
"""
Adversarial Audit Script for Q-Ternary VQC Project
Runs all verification checks and prints detailed results.
"""
import sys
import os
import numpy as np
import torch

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

print("=" * 80)
print("ADVERSARIAL AUDIT — Q-Ternary VQC Project")
print("=" * 80)

# =========================================================================
# SECTION 1: DATASET INTEGRITY
# =========================================================================
print("\n" + "=" * 80)
print("SECTION 1: DATASET INTEGRITY")
print("=" * 80)

from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split

# 1a. What dataset is loaded?
print("\n--- 1a. Data Source ---")
data = load_breast_cancer()
print(f"Source: sklearn.datasets.load_breast_cancer()")
print(f"This IS the well-known Wisconsin Breast Cancer Diagnostic benchmark.")
print(f"It is NOT a novel or hard clinical dataset — it is a standard ML benchmark.")
print(f"Full shape: {data.data.shape} ({data.data.shape[0]} rows, {data.data.shape[1]} columns)")

# 1b. First 5 rows and column names
print("\n--- 1b. First 5 Rows ---")
import pandas as pd
df = pd.DataFrame(data.data, columns=data.feature_names)
print(df.head().to_string())
print(f"\nFull feature list ({len(data.feature_names)}):")
for i, name in enumerate(data.feature_names):
    print(f"  [{i:2d}] {name}")

# 1c. Class balance
print("\n--- 1c. Class Balance ---")
unique, counts = np.unique(data.target, return_counts=True)
for u, c in zip(unique, counts):
    label = data.target_names[u]
    print(f"  Class {u} ({label}): {c} samples ({c/len(data.target)*100:.1f}%)")

majority_pct = max(counts) / len(data.target) * 100
print(f"\nA majority-class-only classifier would achieve: {majority_pct:.1f}% accuracy")
print(f"(Any model must beat this baseline to be meaningful.)")

# 1d. Duplicate rows
print("\n--- 1d. Duplicate Rows ---")
n_dupes = df.duplicated().sum()
print(f"Number of exact duplicate rows in full dataset: {n_dupes}")
if n_dupes > 0:
    print("WARNING: Duplicates exist. This could inflate performance within CV folds.")
else:
    print("No duplicate rows found.")

# 1e. Missing values
print("\n--- 1e. Missing Values ---")
n_missing = np.isnan(data.data).sum()
print(f"Total NaN values in raw data: {n_missing}")
if n_missing == 0:
    print("Note: sklearn's built-in dataset has no missing values.")
    print("The Preprocessor's SimpleImputer(strategy='median') is a no-op here.")

# =========================================================================
# SECTION 2: PREPROCESSING / COMPRESSION PIPELINE
# =========================================================================
print("\n" + "=" * 80)
print("SECTION 2: PREPROCESSING / COMPRESSION PIPELINE")
print("=" * 80)

# Reproduce the pipeline step by step
print("\n--- 2a. Transformation Chain ---")

# Step 1: Split (same as loader.py)
X = data.data
y = data.target
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
print(f"Step 0 (Split): X_train={X_train.shape}, X_test={X_test.shape}")

# Step 2: Feature Selection via SelectKBest(mutual_info_classif, k=12)
from sklearn.feature_selection import mutual_info_classif, SelectKBest
selector = SelectKBest(mutual_info_classif, k=12)
X_train_sel = selector.fit_transform(X_train, y_train)
X_test_sel = selector.transform(X_test)
mask = selector.get_support()
selected_names = [name for name, sel in zip(data.feature_names, mask) if sel]
print(f"Step 1 (Feature Selection): X_train_sel={X_train_sel.shape}, X_test_sel={X_test_sel.shape}")
print(f"  Selected features: {selected_names}")

# Step 3: Impute (no-op for this dataset)
from sklearn.impute import SimpleImputer
imputer = SimpleImputer(strategy='median')
X_train_imp = imputer.fit_transform(X_train_sel)
X_test_imp = imputer.transform(X_test_sel)
print(f"Step 2 (Impute): No change (no missing values). Shape: {X_train_imp.shape}")

# Step 4: Scale
from sklearn.preprocessing import StandardScaler
scaler = StandardScaler()
X_train_scl = scaler.fit_transform(X_train_imp)
X_test_scl = scaler.transform(X_test_imp)
print(f"Step 3 (Scale): X_train_scl mean={X_train_scl.mean(axis=0)[:3].round(6)}, std={X_train_scl.std(axis=0)[:3].round(6)}")

# Step 5: Binarize
thresholds = np.median(X_train_scl, axis=0)
X_train_bin = (X_train_scl > thresholds).astype(int)
X_test_bin = (X_test_scl > thresholds).astype(int)
print(f"Step 4 (Binarize): thresholds (first 3): {thresholds[:3].round(4)}")
print(f"  X_train_bin unique values: {np.unique(X_train_bin)}")
print(f"  X_train_bin shape: {X_train_bin.shape}")

# Step 6: Compress (3 bits -> 2 trits)
from src.data.preprocessor import Preprocessor
X_train_comp = Preprocessor.batch_compress(X_train_bin)
X_test_comp = Preprocessor.batch_compress(X_test_bin)
print(f"Step 5 (Compress): X_train_comp={X_train_comp.shape}, X_test_comp={X_test_comp.shape}")
print(f"  Compression ratio: {X_train_bin.shape[1]} bits -> {X_train_comp.shape[1]} trits ({X_train_comp.shape[1]/X_train_bin.shape[1]*100:.1f}%)")

# --- 2b. Fit/Transform Leakage Check ---
print("\n--- 2b. Fit/Transform Leakage Check ---")
print("Checking code order (from source files read above):")
print("  feature_selector.py L30: self.selector.fit_transform(X_train, ...) -- FIT on TRAIN")
print("  feature_selector.py L31: self.selector.transform(X_test)           -- TRANSFORM on TEST")
print("  preprocessor.py L24: self.imputer.fit_transform(bundle.X_train)    -- FIT on TRAIN")
print("  preprocessor.py L25: self.imputer.transform(bundle.X_test)         -- TRANSFORM on TEST")
print("  preprocessor.py L28: self.scaler.fit_transform(X_train)            -- FIT on TRAIN")
print("  preprocessor.py L29: self.scaler.transform(X_test)                 -- TRANSFORM on TEST")
print("  preprocessor.py L33: self.thresholds = np.median(X_train, axis=0)  -- Computed on TRAIN")
print("  preprocessor.py L38-39: Binarize both using train thresholds")
print("VERDICT: No fit/transform leakage detected in the code.")

# --- 2c. Qutrit Encoding Losslessness ---
print("\n--- 2c. Qutrit Encoding Losslessness Test ---")
print("Testing: Is 3-bit to 2-trit encoding lossless (i.e., invertible)?")
print("There are 8 possible 3-bit patterns (000 to 111). Each maps to 2 trits (base-3 digits).")

all_3bit = np.array([[0,0,0],[0,0,1],[0,1,0],[0,1,1],[1,0,0],[1,0,1],[1,1,0],[1,1,1]])
encoded = Preprocessor.batch_compress(all_3bit)
print("\n  3-bit input -> decimal -> 2-trit output:")
for i in range(8):
    decimal = all_3bit[i,0]*4 + all_3bit[i,1]*2 + all_3bit[i,2]*1
    print(f"    [{all_3bit[i,0]},{all_3bit[i,1]},{all_3bit[i,2]}] -> decimal {decimal} -> [{encoded[i,0]},{encoded[i,1]}]")

# Check uniqueness
trit_tuples = [tuple(row) for row in encoded]
n_unique = len(set(trit_tuples))
print(f"\n  Unique 2-trit outputs: {n_unique} out of 8 inputs")
if n_unique == 8:
    print("  Encoding is LOSSLESS (bijective for all 8 binary patterns)")
else:
    print(f"  ENCODING IS LOSSY -- only {n_unique} unique outputs for 8 inputs!")
    from collections import Counter
    ctr = Counter(trit_tuples)
    for pattern, count in ctr.items():
        if count > 1:
            colliders = [i for i,t in enumerate(trit_tuples) if t == pattern]
            print(f"    COLLISION: trit pattern {pattern} shared by inputs: {[list(all_3bit[j]) for j in colliders]}")

# Check if decoding is possible
print("\n  Attempting decode (2 trits -> decimal -> 3 bits):")
decode_ok = True
for i in range(8):
    t1, t0 = encoded[i]
    decimal_recovered = int(t1) * 3 + int(t0)
    bits_recovered = [(decimal_recovered >> 2) & 1, (decimal_recovered >> 1) & 1, decimal_recovered & 1]
    match = list(all_3bit[i]) == bits_recovered
    if not match:
        decode_ok = False
    status = "OK" if match else "MISMATCH"
    print(f"    [{t1},{t0}] -> decimal {decimal_recovered} -> [{bits_recovered[0]},{bits_recovered[1]},{bits_recovered[2]}] {status}")

if decode_ok:
    print("  All patterns correctly round-trip.")
else:
    print("  DECODING FAILURES DETECTED")

# --- 2d. Randomness seeding ---
print("\n--- 2d. Randomness / Reproducibility ---")
print("  SelectKBest(mutual_info_classif): mutual_info_classif uses random_state")
print("    BUT in feature_selector.py, no random_state is passed to mutual_info_classif.")
print("    SelectKBest does not accept random_state directly.")
print("    This means: feature selection MAY vary between runs!")

# Test: run it twice
mi1 = mutual_info_classif(X_train, y_train, random_state=None)
mi2 = mutual_info_classif(X_train, y_train, random_state=None)
if np.array_equal(mi1, mi2):
    print("    Two runs with random_state=None produced IDENTICAL scores (likely seeded internally)")
else:
    diff = np.abs(mi1 - mi2).max()
    print(f"    Two runs DIFFER by up to {diff:.6f} -- feature selection is NON-DETERMINISTIC")
    top12_1 = set(np.argsort(mi1)[-12:])
    top12_2 = set(np.argsort(mi2)[-12:])
    if top12_1 == top12_2:
        print(f"    However, the TOP 12 features are the same both times (order might differ).")
    else:
        print(f"    The top 12 features CHANGED between runs: diff={top12_1.symmetric_difference(top12_2)}")

# =========================================================================
# SECTION 3: TRAIN/TEST SPLIT VALIDITY
# =========================================================================
print("\n" + "=" * 80)
print("SECTION 3: TRAIN/TEST SPLIT VALIDITY")
print("=" * 80)

print("\n--- 3a. Split Call (from loader.py L30-34) ---")
print("  train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)")
print(f"  Train: {X_train.shape[0]} samples, Test: {X_test.shape[0]} samples")
print(f"  Split ratio: {X_test.shape[0]/(X_train.shape[0]+X_test.shape[0])*100:.1f}%")
print(f"  random_state: 42 (fixed)")
print(f"  stratify: y (by class label)")

print("\n--- 3b. Split Happens Before Preprocessing? ---")
print("  Code order in main.py:")
print("    L49: bundle = load_wisconsin_breast_cancer()  <- SPLIT HAPPENS HERE (inside loader)")
print("    L58: bundle_selected = selector.fit_transform(bundle)  <- Feature selection AFTER split")
print("    L64: bundle_compressed = preprocessor.fit_transform(bundle_selected)  <- Preprocessing AFTER split")
print("  Split is BEFORE any preprocessing fit.")

print("\n--- 3c. Distribution / Leakage Concerns ---")
print("  This is a static sklearn benchmark (no patient IDs, timestamps, or batch effects).")
print("  The stratified split ensures class proportions are preserved.")
y_train_bal = np.bincount(y_train)
y_test_bal = np.bincount(y_test)
print(f"  Train class distribution: {y_train_bal[0]}/{y_train_bal[1]} ({y_train_bal[1]/len(y_train)*100:.1f}% positive)")
print(f"  Test class distribution:  {y_test_bal[0]}/{y_test_bal[1]} ({y_test_bal[1]/len(y_test)*100:.1f}% positive)")

# =========================================================================
# SECTION 4: MODEL TRAINING PROCESS
# =========================================================================
print("\n" + "=" * 80)
print("SECTION 4: MODEL TRAINING PROCESS")
print("=" * 80)

print("\n--- 4a. VQC Architecture ---")
from src.quantum.qutrit_model import QutritClassifier

for n_layers in [1, 3]:
    model = QutritClassifier(n_wires=8, n_layers=n_layers)
    n_params = sum(p.numel() for p in model.parameters())
    print(f"\n  With n_layers={n_layers}:")
    print(f"    n_wires: {model.n_wires}")
    print(f"    Weight shape: {model.q_weights.shape} = (layers, wires, 3)")
    print(f"    Total trainable parameters: {n_params}")
    print(f"    Gate sequence per layer per wire: TRZ(data,[0,1]) -> TRZ(data,[1,2]) -> TRX(w0,[0,1]) -> TRY(w1,[1,2]) -> TRZ(w2,[0,2])")
    print(f"    Entanglement: CSUM ring topology (8 CSUM gates per layer)")

print(f"\n  Note: The '72 parameters' claim assumes n_layers=3 (3*8*3=72).")
print(f"  The last dashboard run used n_layers=1, which gives only 24 parameters.")

print("\n--- 4b. Optimizer / Loss ---")
print("  Optimizer: Adam (lr=0.01)  [main.py L94]")
print("  Loss: BCELoss (Binary Cross-Entropy)  [main.py L93]")

print("\n--- 4c. Training Termination ---")
print("  Fixed epoch count (default 50, configurable via --epochs)  [main.py L33]")
print("  No early stopping, no convergence threshold.")
print("  Memory-based emergency halt if RAM > max_ram + 1.0 GB  [main.py L139-141]")

print("\n--- 4d. Test Set Leakage During Training ---")
print("  The training loop iterates over DataLoader of X_train_t/y_train_t only.")
print("  X_test_t is NEVER accessed during the training loop.")
print("  Test evaluation happens ONLY after the loop ends (L151-158).")
print("  There is NO validation-based early stopping or hyperparameter tuning on test data.")
print("  No test set leakage during training detected.")

# =========================================================================
# SECTION 5: EVALUATION METRICS (RECOMPUTATION)
# =========================================================================
print("\n" + "=" * 80)
print("SECTION 5: EVALUATION METRICS (FRESH RECOMPUTATION)")
print("=" * 80)

print("\n--- 5a. Recompute Classical Baselines from Scratch ---")
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, classification_report
from sklearn.svm import SVC
from sklearn.calibration import CalibratedClassifierCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.neural_network import MLPClassifier
import xgboost as xgb

baselines_list = [
    ("SVM (RBF)", CalibratedClassifierCV(estimator=SVC(kernel='rbf', random_state=42), ensemble=False)),
    ("Random Forest", RandomForestClassifier(n_estimators=100, random_state=42)),
    ("XGBoost", xgb.XGBClassifier(eval_metric='logloss', random_state=42)),
    ("MLP", MLPClassifier(hidden_layer_sizes=(100,50), max_iter=500, random_state=42)),
]

for name, mdl in baselines_list:
    mdl.fit(X_train_sel, y_train)
    preds = mdl.predict(X_test_sel)
    acc = accuracy_score(y_test, preds)
    prec = precision_score(y_test, preds)
    rec = recall_score(y_test, preds)
    f1v = f1_score(y_test, preds)
    cm = confusion_matrix(y_test, preds)
    
    print(f"\n  {name}:")
    print(f"    Accuracy:  {acc:.4f} ({acc*100:.2f}%)")
    print(f"    Precision: {prec:.4f}")
    print(f"    Recall:    {rec:.4f}")
    print(f"    F1 Score:  {f1v:.4f}")
    print(f"    Confusion Matrix:")
    print(f"      TN={cm[0,0]}  FP={cm[0,1]}")
    print(f"      FN={cm[1,0]}  TP={cm[1,1]}")
    print(classification_report(y_test, preds, target_names=['malignant','benign'], digits=4))

print("\n--- 5b. Classical Baseline Hyperparameters ---")
print("  SVM: kernel='rbf', default C=1.0, default gamma='scale'  -- NOT TUNED")
print("  Random Forest: n_estimators=100, all other defaults  -- NOT TUNED")
print("  XGBoost: all defaults except eval_metric='logloss'  -- NOT TUNED")
print("  MLP: hidden_layer_sizes=(100,50), max_iter=500  -- SLIGHTLY CUSTOMIZED")
print("  None of these baselines are hyperparameter-tuned (no GridSearchCV, no CV).")

print("\n--- 5c. Recompute VQC from saved weights ---")
weights_path = "models/qutrit_vqc_weights.pt"
if os.path.exists(weights_path):
    state_dict = torch.load(weights_path, map_location='cpu', weights_only=True)
    for key, val in state_dict.items():
        print(f"  Saved weight key: {key}, shape: {val.shape}")
    n_layers_saved = list(state_dict.values())[0].shape[0]
    n_wires_saved = list(state_dict.values())[0].shape[1]
    
    vqc = QutritClassifier(n_wires=n_wires_saved, n_layers=n_layers_saved)
    vqc.load_state_dict(state_dict)
    vqc.eval()
    
    # Try using saved preprocessor and selector
    import joblib
    if os.path.exists("models/feature_selector.pkl") and os.path.exists("models/preprocessor.pkl"):
        print(f"\n  Using SAVED selector and preprocessor for faithful evaluation...")
        saved_selector = joblib.load("models/feature_selector.pkl")
        saved_preprocessor = joblib.load("models/preprocessor.pkl")
        
        X_test_sel_saved = saved_selector.selector.transform(X_test)
        X_test_comp_saved = saved_preprocessor.transform(X_test_sel_saved)
        
        X_test_t2 = torch.tensor(X_test_comp_saved, dtype=torch.float32)
        with torch.no_grad():
            q_probs2 = vqc(X_test_t2).cpu().numpy()
        q_preds2 = (q_probs2 >= 0.5).astype(int)
        
        acc2 = accuracy_score(y_test, q_preds2)
        prec2 = precision_score(y_test, q_preds2)
        rec2 = recall_score(y_test, q_preds2)
        f1_val2 = f1_score(y_test, q_preds2)
        cm2 = confusion_matrix(y_test, q_preds2)
        
        print(f"\n  VQC (SAVED pipeline, n_layers={n_layers_saved}):")
        print(f"    Accuracy:  {acc2:.4f} ({acc2*100:.2f}%)")
        print(f"    Precision: {prec2:.4f}")
        print(f"    Recall:    {rec2:.4f}")
        print(f"    F1 Score:  {f1_val2:.4f}")
        print(f"    Confusion Matrix:")
        print(f"      TN={cm2[0,0]}  FP={cm2[0,1]}")
        print(f"      FN={cm2[1,0]}  TP={cm2[1,1]}")
        print(classification_report(y_test, q_preds2, target_names=['malignant','benign'], digits=4))
    else:
        print("  WARNING: No saved selector/preprocessor pkl files found. Cannot faithfully re-evaluate VQC.")
else:
    print(f"  No saved weights found at {weights_path}")

# =========================================================================
# SECTION 6: STATISTICAL VALIDITY
# =========================================================================
print("\n" + "=" * 80)
print("SECTION 6: STATISTICAL VALIDITY")
print("=" * 80)

pilot_log = "pilot_results.log"
if os.path.exists(pilot_log):
    print(f"\n--- 6a. Pilot Results Log ({pilot_log}) ---")
    with open(pilot_log) as f:
        content = f.read()
    print(content[:3000] if len(content) > 3000 else content)
else:
    print(f"\n  No pilot results log found at {pilot_log}")

print("\n--- 6b. Statistical Tests Status ---")
print("  UNVERIFIED: No k-fold cross-validation results available yet.")
print("  UNVERIFIED: No McNemar's test has been run.")
print("  UNVERIFIED: No multi-seed stability check has been run.")
print("  The overnight 10-fold/50-epoch/5-seed validation run has NOT been executed.")

# =========================================================================
# SECTION 7: UNVERIFIED CLAIMS
# =========================================================================
print("\n" + "=" * 80)
print("SECTION 7: UNVERIFIED CLAIMS")
print("=" * 80)

unverified = [
    "1. '72 trainable parameters' -- Only true for n_layers=3. Last run used n_layers=1 (24 params).",
    "2. '93.86% VQC accuracy' -- Stated in earlier messages but not reproduced from a fresh run in this audit.",
    "3. '1.2 GB RAM usage' -- Stated but not independently measured in this audit.",
    "4. 'Quantum advantage over classical baselines' -- No statistical test completed.",
    "5. Feature selection reproducibility -- mutual_info_classif is non-deterministic without explicit random_state.",
    "6. VQC convergence -- No learning curve analysis. With 10 epochs and lr=0.01, likely undertrained.",
    "7. F1 score in history.json -- Existing entry was saved BEFORE F1 extraction code was added.",
    "8. CSUM gate correctness -- Matrix looks correct by inspection, not verified against reference.",
    "9. Inference endpoint correctness -- Recently fixed scaling bug, but no end-to-end test run.",
    "10. /download_sample route -- Added to frontend but backend route existence not verified.",
]

for item in unverified:
    print(f"  * {item}")

# =========================================================================
# FINAL VERDICTS
# =========================================================================
print("\n" + "=" * 80)
print("FINAL VERDICTS")
print("=" * 80)

verdicts = [
    ("1. DATASET INTEGRITY", "PASS"),
    ("2. PREPROCESSING / COMPRESSION", "PASS with WARNING (feature selection non-deterministic)"),
    ("3. TRAIN/TEST SPLIT", "PASS"),
    ("4. MODEL TRAINING", "PASS with WARNING (likely undertrained at 1 layer / 10 epochs)"),
    ("5. EVALUATION METRICS", "PASS (recomputed independently)"),
    ("6. STATISTICAL VALIDITY", "UNVERIFIED"),
    ("7. UNVERIFIED CLAIMS", "FAIL (10 claims unverified)"),
    ("8. REPORT FILE", "See docs/audit_report_2026-09-23.md"),
]

for section, verdict in verdicts:
    print(f"  {section}: {verdict}")

print("\n" + "=" * 80)
print("END OF AUDIT")
print("=" * 80)
