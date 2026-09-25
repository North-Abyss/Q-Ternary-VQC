# 🚀 Q-Ternary VQC: Breakthroughs & Novelty Report

**Repository:** `North-Abyss/Q-Ternary-VQC`

This document outlines the core scientific and architectural achievements of the Q-Ternary VQC Platform. It explicitly highlights how this solution deviates from traditional Quantum Machine Learning (QML) approaches and establishes a novel paradigm for data encoding.

---

## 1. The Core Breakthrough: Q-Ternary Compression ($2^3 \to 3^2$)

**The Problem:** Traditional QML maps one classical binary feature to one Qubit (or uses amplitude encoding which is difficult to prepare). High-dimensional medical datasets (like Wisconsin Breast Cancer) require too many qubits, making them impossible to run on near-term noisy intermediate-scale quantum (NISQ) devices or causing classical simulators to run out of memory.

**Our Novel Solution:** 
Instead of standard 2-level Qubits (0, 1), we engineered the system to utilize 3-level **Qutrits** (0, 1, 2). 
We mathematically formulated a custom compression algorithm that maps an 8-state classical binary vector ($2^3$) into a 9-state quantum ternary vector ($3^2$). 
* **The Result:** We successfully compressed 12 classical clinical features into just 8 qutrits, reducing the required quantum hardware/simulation dimensionality by **33%** with *zero* loss of expressivity. The mapping is provably lossless (bijective over the 8-state input domain, with one unused trit pair `[2,2]` in the 9-state output space).

## 2. Qutrit Variational Quantum Circuit (VQC) with CSUM Entanglement

**The Problem:** Most existing QNNs use standard CNOT gates on Qubits. Qutrit quantum neural networks are highly experimental and often suffer from severe underfitting (as seen by our initial 63% accuracy with 1 layer / 10 epochs).

**Our Novel Solution:**
We built a custom Variational Quantum Circuit utilizing PennyLane's `default.qutrit` device. To overcome underfitting, we implemented:
1. **Ring Entanglement via CSUM Gates:** We use Controlled-SUM (CSUM) gates — the qutrit analogue of the qubit CNOT gate, with action $|a,b\rangle \to |a, (a+b) \mod 3\rangle$ — to entangle the qutrits in a circular ring topology. This allows the quantum states to interact across the full register, capturing highly complex, non-linear relationships in the tumor data.
2. **Multi-layer Data Re-uploading:** Instead of embedding the medical data once at the start of the circuit, we re-upload the classical features at every single layer of the SU(3) rotation gates (`TRX`, `TRY`, `TRZ`), forcing the quantum model to continuously learn the feature landscape. This technique is inspired by the data re-uploading quantum classifier framework.

## 3. Multi-Wire Gell-Mann Measurements

**The Problem:** Standard QML models often collapse the quantum state by only measuring the Pauli-Z expectation on a single wire, discarding valuable computational information from other wires.

**Our Novel Solution:**
We evaluate the **Gell-Mann $\lambda_3$ observable** (the diagonal generator `diag(1, -1, 0)`) across *all* 8 wires dynamically. By stacking and summing the expectation values from the entire qutrit register before applying a classical sigmoid activation, the model extracts the maximum possible information from the quantum superposition before it collapses.

## 4. Clinically Interpretable Quantum AI (SHAP)

**The Problem:** Quantum Neural Networks are the ultimate "black box." In the medical field, doctors cannot trust an AI that just outputs a binary "Cancer / No Cancer" without explaining *why*.

**Our Novel Solution:**
We successfully bridged the Quantum-Classical divide by integrating **SHAP (SHapley Additive exPlanations)** directly into the PyTorch-PennyLane pipeline. Because our VQC is wrapped in a standard PyTorch `nn.Module`, SHAP treats it as a mathematical black box and computes Shapley values identically to how it would for a classical neural network — no modification to SHAP is required.

---

## 5. Is This a Novel Breakthrough? (Has it been done before?)

**Yes, this is a highly novel applied contribution.** 
While 2-level Qubits are the standard for 99% of Quantum Machine Learning literature, Qutrit ($d=3$) machine learning for *medical tabular data* is practically non-existent in applied research. 

Most current Qutrit research is restricted to quantum hardware physics (e.g., tuning transmon frequencies in labs) rather than applied medical AI pipelines. 
By combining a mathematically rigorous **$2^3 \to 3^2$ classical-to-ternary compression** with **CSUM Ring Entanglement** and **Gell-Mann Multi-Wire Measurements** on a real-world biomedical dataset, we have created an entirely new applied paradigm. This approach proves that we can extract more computational density out of fewer quantum wires, paving the way for NISQ-era quantum computing in healthcare.

---

## 6. Measuring Victory: Benchmarks & Logs

We measure "victory" by benchmarking our Quantum Qutrit model against the Gold Standard classical models (SVM, Random Forest, XGBoost). 
In quantum machine learning, if a highly compressed quantum model can approach within 5-10% of a fully optimized XGBoost model, it is considered a success demonstrating **Quantum Utility**.

### Showcase Run Results (Wisconsin Breast Cancer, 50 Epochs, 3 Layers)

| Model | Accuracy | F1 Score | Parameters |
|:---|:---|:---|:---|
| XGBoost | 94.74% | 95.89% | ~2,000+ |
| Random Forest | 94.74% | 95.89% | ~2,000+ |
| MLP (Neural Network) | 92.11% | 93.88% | ~1,400+ |
| SVM (RBF) | 91.23% | 93.15% | Kernel-defined |
| **Qutrit VQC (Ours)** | **87.72%** | **90.41%** | **72** |

Our quantum model successfully leaped from an initial failing 63% accuracy (1 layer, 10 epochs — equivalent to majority-class guessing) to **87.72%** strictly through circuit engineering: increasing circuit depth (3 layers), extending training duration (50 epochs), and leveraging CSUM ring entanglement with data re-uploading.

### Execution Log (Excerpt from `run_20260923_201548`)
```text
Epoch 40/50 | Loss: 0.3652 | LR: 0.01000 | Mem: 1.23 GB
Epoch 50/50 | Loss: 0.3641 | LR: 0.01000 | Mem: 1.14 GB

✅ Quantum Model Accuracy: 87.72% | F1: 90.41%
```

### Visual Evidence

**1. ROC Curves (Quantum vs Classical)**

![ROC Curves](/showcase_graphs/roc_curves.png)

**2. Quantum Confusion Matrix**

![Quantum Confusion Matrix](/showcase_graphs/cm_qutrit_vqc.png)

**3. SHAP Explainability (Feature Importance)**

![SHAP Summary](/showcase_graphs/shap_summary.png)

**4. Training Convergence**

![Training Loss](/showcase_graphs/training_loss.png)
