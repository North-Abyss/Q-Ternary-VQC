# ⚡ Project Log: Hybrid-Quantum-ML-Disease-Detection

### 📅 Active Sprint 
* **Current Focus:** Mathematical mapping of classical binary vectors to ternary quantum states.
* **Blockers:** Ensuring PyTorch tensor gradients calculate correctly through the PennyLane `default.qutrit` device operations.

### 🛠️ Architecture Decisions
1. **Language:** Python 3.10+ (Backend) | Dart (Frontend)
2. **Quantum Framework:** PennyLane (Selected over Qiskit due to native PyTorch/Qutrit support).
3. **Data Pre-processing:** Implemented custom $2^3 \to 3^2$ state compression to optimize memory overhead on classical simulators.

### 📊 Benchmark Targets
* **Classical Baseline (SVM/RF):** ~85% Accuracy (Target)
* **Quantum Hybrid (QNN):** > 89% Accuracy with 33% reduced feature dimensionality.
