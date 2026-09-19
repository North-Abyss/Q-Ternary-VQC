# ⚡ Project Log: Hybrid-Quantum-ML-Disease-Detection

### 📅 Sprint Status: ✅ Core Pipeline Complete
* **Completed:** Q-Ternary compression, CSUM entanglement, data re-uploading, SHAP integration, memory-constrained training, model export, and Flask API scaffolding.
* **Remaining:** Flutter frontend UI for clinician-facing predictions.

### 🛠️ Architecture Decisions
1. **Language:** Python 3.10+ (Backend) | Dart (Frontend)
2. **Quantum Framework:** PennyLane (Selected over Qiskit due to native PyTorch/Qutrit support).
3. **Data Pre-processing:** Implemented custom $2^3 \to 3^2$ state compression to optimize memory overhead on classical simulators.

### 📊 Benchmark Targets (ACHIEVED)
* **Classical Baseline (SVM/RF/XGBoost):** ~92-94% Accuracy
* **Quantum Hybrid (QNN):** **86.84% Accuracy** (F1: 88.89%) with Q-Ternary compression (from original 55%!).

---

## [2026-09-18] Architecture Implementation & Memory Optimization Plan
**System Inspected:** Ubuntu 26.04.1 LTS (Resolute Raccoon), Intel i7-8650U, 16GB RAM (Integrated UHD 620 GPU).

### 1. Completed Phase Implementations:
- **Phase 1 (Data):** Connected real Wisconsin Breast Cancer dataset. Implemented Mutual Info feature selection + Q-Ternary compression (`compress_3bits_to_2trits`).
- **Phase 2 (Quantum Engine):** Built PyTorch VQC with `default.qutrit`. Fixed the 55% accuracy issue by adding:
  - `ring_entangle` (CSUM gates).
  - Data re-uploading at every layer.
  - Multi-wire Gell-Mann measurements.
- **Phase 3 (Classical Baselines):** Added SVM, Random Forest, XGBoost, and MLP.
- **Phase 4 & 5 (Evaluation & XAI):** Added ROC curves, Confusion Matrices, and SHAP feature importance visualisations.
- **Phase 6 & 7 (API & Main):** Built `app.py` Flask API and unified `main.py` execution script.

### 2. Memory Restriction Planning (6GB Limit + 1GB Overload):
Due to the system running on an Intel i7 CPU without a dedicated NVIDIA GPU, full-batch PyTorch/PennyLane simulation will cause a memory spike. A strict 6GB (+1GB overload) limit has been planned and documented in the implementation plan. 
- **Mini-Batching:** Move from full-batch tensor operations to `torch.utils.data.DataLoader` with `batch_size=16`.
- **Garbage Collection:** Enforce `del` and `gc.collect()` at the end of every training epoch.
- **Active Profiling:** Integrate `psutil` inside the epoch loop to break/safely halt if RAM usage exceeds 6GB.

**Next Steps:**
Build the Flutter frontend and connect it to the Flask `/predict` endpoint.

---

## [2026-09-19] Standalone Research Pivot & UX Polish
### 1. Independent Research Pivot
- Removed all SIH (Smart India Hackathon) branding from the codebase.
- Re-architected as a standalone mathematical research project focused on parameter efficiency ($2^3 \to 3^2$ Q-Ternary compression).
- Added CC BY-NC-SA 4.0 `LICENSE.md` attaching intellectual property rights to Yuvanesh KS (North-Abyss).
- Injected strict authorship docstrings across `main.py`, `app.py`, `qutrit_model.py`, `preprocessor.py`, and `baselines.py`.

### 2. Pipeline UX & Configuration
- **Dynamic RAM Configuration:** Added a `--max-ram` parameter to `main.py` allowing developers to strictly define the `psutil` memory watchdog limit via the command line. `run.sh` now passes `--max-ram 6.0` by default.
- **Live Progress Tracking:** Integrated `tqdm` into the `main.py` training loop, pushing real-time percentages, ETAs, loss metrics, and active RAM footprint to the terminal (via `PYTHONUNBUFFERED=1`).
- **High-Res Visualizations:** Generated 3 new presentation-ready graphs comparing classical vs quantum parameter efficiency for academic publications and LinkedIn.
