# Adversarial Audit Report — Q-Ternary VQC Project

**Date:** 2026-09-23  
**Git Commit:** `d3ed56255c69a09bad7460aac3ad8d2bf342bb59`  
**Auditor:** Automated adversarial audit script + manual code review  
**Audit Script:** `/mnt/sda5/Projects/QT/audit_run.py`  
**Commands Run:**
```bash
source .venv/bin/activate && python3 audit_run.py 2>&1 | tee audit_output.txt
# VQC re-evaluation (separate run with sys.path fix for pickle):
source .venv/bin/activate && python3 -c "<inline VQC eval script>" 2>&1 | tee audit_vqc_output.txt
```

---

## 1. DATASET INTEGRITY

### 1a. Data Source
```
Source: sklearn.datasets.load_breast_cancer()
Full shape: (569, 30) — 569 rows, 30 columns
```

**This IS the well-known Wisconsin Breast Cancer Diagnostic benchmark from sklearn.**
It is NOT a novel or hard clinical dataset. It is a standard ML benchmark that virtually
every classifier can achieve >90% accuracy on with default hyperparameters. Any claims of
"medical AI breakthrough" on this dataset should be treated with extreme skepticism.

### 1b. First 5 Rows & Column Names

First 5 rows (truncated for readability):
```
   mean radius  mean texture  mean perimeter  mean area  mean smoothness ...
0        17.99         10.38          122.80     1001.0          0.11840
1        20.57         17.77          132.90     1326.0          0.08474
2        19.69         21.25          130.00     1203.0          0.10960
3        11.42         20.38           77.58      386.1          0.14250
4        20.29         14.34          135.10     1297.0          0.10030
```

Full feature list (30 features):
```
[ 0] mean radius              [10] radius error            [20] worst radius
[ 1] mean texture             [11] texture error           [21] worst texture
[ 2] mean perimeter           [12] perimeter error         [22] worst perimeter
[ 3] mean area                [13] area error              [23] worst area
[ 4] mean smoothness          [14] smoothness error        [24] worst smoothness
[ 5] mean compactness         [15] compactness error       [25] worst compactness
[ 6] mean concavity           [16] concavity error         [26] worst concavity
[ 7] mean concave points      [17] concave points error    [27] worst concave points
[ 8] mean symmetry            [18] symmetry error          [28] worst symmetry
[ 9] mean fractal dimension   [19] fractal dimension error [29] worst fractal dimension
```

### 1c. Class Balance
```
Class 0 (malignant): 212 samples (37.3%)
Class 1 (benign):    357 samples (62.7%)

A majority-class-only classifier would achieve: 62.7% accuracy
```

**This is critical context.** Any model that simply predicts "benign" for every sample
achieves 62.7%. The VQC's 63.16% accuracy (see Section 5c) is INDISTINGUISHABLE from
a majority-class-only dummy classifier.

### 1d. Duplicate Rows
```
Number of exact duplicate rows in full dataset: 0
```
No duplicates. ✅

### 1e. Missing Values
```
Total NaN values in raw data: 0
Note: sklearn's built-in dataset has no missing values.
The Preprocessor's SimpleImputer(strategy='median') is a no-op here.
```

### Section 1 Verdict: PASS
The dataset is correctly identified, honestly described, no duplicates, no missing values.
The dataset itself is real and legitimate — but it IS a toy benchmark, not a novel clinical challenge.

---

## 2. PREPROCESSING / COMPRESSION PIPELINE

### 2a. Transformation Chain (Verified Step-by-Step)

```
Step 0 (Split):    X_train=(455, 30), X_test=(114, 30)
Step 1 (Feature Selection): SelectKBest(mutual_info_classif, k=12)
                   X_train_sel=(455, 12), X_test_sel=(114, 12)
  Selected features: ['mean radius', 'mean perimeter', 'mean area',
    'mean compactness', 'mean concavity', 'mean concave points',
    'area error', 'worst radius', 'worst perimeter', 'worst area',
    'worst concavity', 'worst concave points']
Step 2 (Impute):   No-op (no missing values). Shape unchanged: (455, 12)
Step 3 (Scale):    StandardScaler. Mean≈0, Std≈1 (verified)
Step 4 (Binarize): Threshold = median of each scaled training feature
                   thresholds (first 3): [-0.2281, -0.2312, -0.3098]
                   Output: binary matrix {0, 1}, shape (455, 12)
Step 5 (Compress): 3-bits → 2-trits. Shape: (455, 12) → (455, 8)
                   Compression ratio: 66.7%
```

### 2b. Fit/Transform Leakage Check

Checked the exact lines where `.fit()` and `.transform()` are called:

| Step | Fit on | Transform on | Source |
|------|--------|-------------|--------|
| SelectKBest | `X_train` (L30) | `X_test` (L31) | `feature_selector.py` |
| SimpleImputer | `bundle.X_train` (L24) | `bundle.X_test` (L25) | `preprocessor.py` |
| StandardScaler | `X_train` (L28) | `X_test` (L29) | `preprocessor.py` |
| Binarization thresholds | `np.median(X_train)` (L33) | Applied to both (L38-39) | `preprocessor.py` |

**No fit/transform leakage detected.** ✅

### 2c. Qutrit Encoding Losslessness Test

Tested all 8 possible 3-bit patterns:
```
[0,0,0] → decimal 0 → [0,0]    ✅ Round-trips correctly
[0,0,1] → decimal 1 → [0,1]    ✅ Round-trips correctly
[0,1,0] → decimal 2 → [0,2]    ✅ Round-trips correctly
[0,1,1] → decimal 3 → [1,0]    ✅ Round-trips correctly
[1,0,0] → decimal 4 → [1,1]    ✅ Round-trips correctly
[1,0,1] → decimal 5 → [1,2]    ✅ Round-trips correctly
[1,1,0] → decimal 6 → [2,0]    ✅ Round-trips correctly
[1,1,1] → decimal 7 → [2,1]    ✅ Round-trips correctly

Unique 2-trit outputs: 8 out of 8 inputs
```

**Encoding is LOSSLESS** (bijective). 2 trits can represent 9 values (0-8); 3 bits
produce only 8 (0-7), so the mapping is injective with one unused trit pair [2,2]. ✅

### 2d. Randomness / Reproducibility

```
SelectKBest(mutual_info_classif) with no explicit random_state:
  Two runs DIFFER by up to 0.016511 — feature selection is NON-DETERMINISTIC ⚠️
  However, the TOP 12 features are the same both times (order might differ).
```

**⚠️ WARNING:** `mutual_info_classif` uses internal randomization. The `FeatureSelector`
class (`feature_selector.py`) does NOT pass a `random_state` to `SelectKBest` or
`mutual_info_classif`. While the top-12 features appear stable for this dataset, this is
not guaranteed and makes exact reproducibility impossible across runs.

### Section 2 Verdict: PASS with WARNING
Pipeline logic is correct and leak-free. Encoding is proven lossless. But feature selection
is non-deterministic (no `random_state` seeding).

---

## 3. TRAIN/TEST SPLIT VALIDITY

### 3a. Split Parameters
```python
# From loader.py L30-34:
train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
```

| Parameter | Value | Assessment |
|-----------|-------|-----------|
| `test_size` | 0.2 (20%) | Standard |
| `random_state` | 42 (fixed) | Reproducible ✅ |
| `stratify` | `y` (class labels) | Preserves class balance ✅ |
| Train size | 455 samples | — |
| Test size | 114 samples | — |

### 3b. Split Ordering
```
Code order in main.py:
  L49: bundle = load_wisconsin_breast_cancer()     ← SPLIT HAPPENS HERE (inside loader)
  L58: bundle_selected = selector.fit_transform()  ← Feature selection AFTER split
  L64: bundle_compressed = preprocessor.fit_transform()  ← Preprocessing AFTER split
```
Split occurs BEFORE any preprocessing. ✅

### 3c. Class Distribution After Split
```
Train: 170 malignant / 285 benign (62.6% positive)
Test:   42 malignant /  72 benign (63.2% positive)
```
Proportions are preserved by stratification. ✅

### 3d. Leakage Concerns
This is a static sklearn benchmark with no patient IDs, timestamps, or batch effects.
No temporal or identity-based leakage is possible. ✅

### Section 3 Verdict: PASS

---

## 4. MODEL TRAINING PROCESS

### 4a. VQC Architecture

```
With n_layers=1 (LAST SAVED MODEL):
  n_wires: 8
  Weight shape: torch.Size([1, 8, 3])
  Total trainable parameters: 24
  Gate sequence per layer per wire:
    TRZ(data, [0,1]) → TRZ(data, [1,2]) → TRX(θ₀, [0,1]) → TRY(θ₁, [1,2]) → TRZ(θ₂, [0,2])
  Entanglement: CSUM ring topology (8 CSUM gates per layer)

With n_layers=3 (DEFAULT / CLAIMED):
  Total trainable parameters: 72
```

**⚠️ CRITICAL:** The saved model weights have shape `[1, 8, 3]` — that's **n_layers=1, 24 parameters**.
The frequently cited "72 parameters" corresponds to n_layers=3, which is the default but was NOT
used in the last training run visible on the dashboard (which used Epochs: 10, Layers: 1).

### 4b. Optimizer / Loss
```
Optimizer: Adam (lr=0.01)    [main.py L94]
Loss:      BCELoss            [main.py L93]
```
Standard and appropriate for binary classification.

### 4c. Training Termination
- Fixed epoch count (default 50, configurable)
- No early stopping
- No convergence threshold
- Emergency halt only if RAM exceeds `max_ram + 1.0 GB`

### 4d. Test Set Leakage During Training
- Training loop (`main.py` L114-149) uses ONLY `X_train_t` / `y_train_t` via DataLoader
- `X_test_t` is created at L103 but NEVER accessed during training
- Test evaluation occurs ONLY after the training loop ends (L151-158)
- No validation-based early stopping or hyperparameter tuning on test data

**No test set leakage detected.** ✅

### Section 4 Verdict: PASS with WARNING
Architecture and training loop are sound. No leakage. But the saved model was trained with
only 1 layer / 10 epochs — almost certainly undertrained.

---

## 5. EVALUATION METRICS (FRESH RECOMPUTATION)

### 5a. Classical Baselines (Recomputed from Scratch)

| Model | Accuracy | Precision | Recall | F1 | TN | FP | FN | TP |
|-------|----------|-----------|--------|----|----|----|----|----|
| SVM (RBF) | 91.23% | 0.9189 | 0.9444 | 0.9315 | 36 | 6 | 4 | 68 |
| Random Forest | 94.74% | 0.9459 | 0.9722 | 0.9589 | 38 | 4 | 2 | 70 |
| XGBoost | 94.74% | 0.9459 | 0.9722 | 0.9589 | 38 | 4 | 2 | 70 |
| MLP (Neural Net) | 92.11% | 0.9200 | 0.9583 | 0.9388 | 36 | 6 | 3 | 69 |

All baselines perform well on BOTH classes (malignant precision/recall >0.85). None are tuned.

### 5b. Baseline Hyperparameters
```
SVM:  kernel='rbf', C=1.0 (default), gamma='scale' (default)     — NOT TUNED
RF:   n_estimators=100, all other defaults                        — NOT TUNED
XGB:  all defaults except eval_metric='logloss'                   — NOT TUNED
MLP:  hidden_layers=(100,50), max_iter=500                        — SLIGHTLY CUSTOMIZED
```

No GridSearchCV or cross-validation tuning for any baseline. This is fair — but means
tuned baselines would likely score even higher, making the comparison harder for the VQC.

### 5c. VQC Recomputation (from Saved Weights — THE CRITICAL FINDING)

```
Saved weight key: q_weights, shape: torch.Size([1, 8, 3])
VQC config: n_layers=1, n_wires=8

VQC (SAVED pipeline, n_layers=1):
  Accuracy:  0.6316 (63.16%)
  Precision: 0.6316
  Recall:    1.0000
  F1 Score:  0.7742
  Confusion Matrix:
    TN=0   FP=42
    FN=0   TP=72

Probability distribution:
  min=0.6318, max=0.6318, mean=0.6318, std=0.0000
  Predicted class 0 (malignant): 0 samples
  Predicted class 1 (benign):   114 samples
  True class 0 (malignant):      42 samples
  True class 1 (benign):         72 samples
```

### 🚨 THIS IS THE SINGLE MOST IMPORTANT FINDING OF THE ENTIRE AUDIT 🚨

**The saved VQC model outputs the EXACT SAME probability (0.6318) for EVERY SINGLE input.**
It predicts "benign" for ALL 114 test samples. It has learned NOTHING. Its 63.16% accuracy
is EXACTLY the majority class rate (72/114 = 63.158%).

This means:
1. The model is a **constant function** — it ignores its input entirely
2. The 63.16% accuracy is identical to a `return "benign"` one-liner
3. **Every accuracy number previously cited for the VQC is from a DIFFERENT training run** that
   no longer exists on disk. The only verifiable model is this one, and it's broken.
4. The user's complaint ("no matter what I change it shows the same answer") was NOT just an
   inference-endpoint bug — the model itself is degenerate.

**Root causes (likely):**
- Only 1 variational layer (24 parameters) — insufficient expressivity
- Only 10 training epochs — insufficient optimization
- The sigmoid(sum(expectations)) readout may have a vanishing gradient problem for qutrit circuits

### Section 5 Verdict: FAIL
Classical baselines recompute correctly. **The VQC is completely broken** — it is a constant
function equivalent to a majority-class classifier. No quantum advantage exists in the saved model.

---

## 6. STATISTICAL VALIDITY

### 6a. Pilot Results
**No pilot results log file exists.** The `pilot_results.log` file referenced in the user's
open editor does not exist on disk.

### 6b. Statistical Tests
- **K-fold cross-validation:** NEVER EXECUTED
- **McNemar's test:** NEVER EXECUTED
- **Multi-seed stability check:** NEVER EXECUTED
- **The overnight 10-fold/50-epoch/5-seed validation run was NEVER started.**

### Section 6 Verdict: UNVERIFIED
No statistical validation of any kind has been performed.

---

## 7. UNVERIFIED CLAIMS

The following specific claims made during this project have NOT been verified by actual
code execution in this audit:

1. **"72 trainable parameters"** — Only true for n_layers=3. The saved model uses n_layers=1
   (24 params). The claim was never pinned to a specific, verifiable run.

2. **"93.86% VQC accuracy"** / **"91.23% accuracy"** — These numbers were stated in earlier
   chat messages. The only verifiable saved model achieves 63.16% (majority-class constant).
   The training run that produced these numbers no longer exists on disk.

3. **"1.2 GB RAM usage"** — Stated but never independently measured in this audit.

4. **"Quantum advantage over classical baselines"** — The saved VQC is a constant function.
   No statistical test has been completed. No evidence of advantage exists.

5. **Feature selection reproducibility** — `mutual_info_classif` is non-deterministic without
   explicit `random_state`. Different runs may select different features.

6. **VQC convergence** — No learning curve analysis. The saved model (1 layer, 10 epochs)
   is definitively undertrained — it has not learned anything.

7. **F1 score in history.json** — The existing history entry was saved BEFORE the F1 extraction
   code was added; it contains no F1 data.

8. **CSUM gate correctness** — The matrix construction in `circuit_utils.py` looks correct by
   inspection (|a,b⟩ → |a,(a+b) mod 3⟩), but has not been verified against a reference
   implementation or academic paper.

9. **Inference endpoint correctness** — The `/predict` endpoint had a critical scaling bug
   (comparing raw inputs to scaled thresholds). It was patched with `preprocessor.transform()`,
   but the underlying model is constant, so the fix is moot.

10. **Download sample data endpoint** — Added to the frontend but the backend `/download_sample`
    route's existence and correctness were not verified.

---

## 8. REPORT FILE

This file: `docs/audit_report_2026-09-23.md`

---

## FINAL VERDICTS

| Section | Verdict | Detail |
|---------|---------|--------|
| 1. DATASET INTEGRITY | **PASS** | Standard sklearn benchmark, correctly identified, no duplicates |
| 2. PREPROCESSING / COMPRESSION | **PASS with WARNING** | Pipeline correct, encoding lossless, but feature selection is non-deterministic |
| 3. TRAIN/TEST SPLIT | **PASS** | Stratified, seeded, split before preprocessing |
| 4. MODEL TRAINING | **PASS with WARNING** | No leakage, but saved model severely undertrained (1 layer, 10 epochs) |
| 5. EVALUATION METRICS | **FAIL** | VQC is a constant function (63.16% = majority class). No quantum learning occurred. |
| 6. STATISTICAL VALIDITY | **UNVERIFIED** | No CV, no McNemar's test, no multi-seed run — nothing was executed |
| 7. UNVERIFIED CLAIMS | **FAIL** | 10 specific claims remain unverified; key accuracy numbers are not reproducible |
| 8. REPORT FILE | **PASS** | This file |
