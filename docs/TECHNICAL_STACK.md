# Technical Stack & Methodology Guide

This document breaks down the exact software frameworks, AI models, and technical methodologies used to build the Q-Ternary VQC platform. It serves as a comprehensive reference for the technical implementation of the architecture.

---

## 1. Core Frameworks & Libraries

Our platform relies on a carefully curated, modern tech stack designed to bridge quantum physics, classical machine learning, and web infrastructure.

*   **PennyLane (`pennylane`):** The core quantum machine learning framework. We used its `default.qutrit` device simulator to build the 3-level quantum architecture and handle the Gell-Mann observable measurements.
*   **PyTorch (`torch`):** The classical deep learning backend. We integrated PennyLane into PyTorch so we could use the PyTorch `Adam` optimizer to calculate gradients and perform backpropagation to update the quantum rotation weights.
*   **Scikit-Learn (`sklearn`):** Used heavily for data preprocessing (StandardScaler), feature selection (Mutual Information, PCA), and providing standard classical algorithms for baseline comparison.
*   **SHAP (`shap`):** The Explainable AI (XAI) framework. It uses cooperative game theory (Shapley values) to break open the black-box models and output exactly which biological features contributed to a prediction.
*   **Flask:** The lightweight Python backend framework used to wrap the trained Quantum and Classical models into a REST API so they can be consumed by the frontend.
*   **Flutter (Upcoming):** The cross-platform UI framework that will serve as the doctor-facing application, allowing them to upload patient CSVs and view the Flask API's responses.

---

## 2. The 5 AI Models

To rigorously test our Quantum architecture, we benchmarked it against four industry-standard classical machine learning models. 

1.  **Qutrit VQC (The Q-Ternary Model):** Our novel hybrid quantum-classical model. It uses 8 Qutrit wires, 3 Layers, and CSUM entanglement, resulting in a highly efficient **72-parameter** architecture.
2.  **XGBoost:** The current industry gold-standard for tabular data. It builds an ensemble of decision trees. (Achieved 94.74% accuracy).
3.  **MLP (Classical Neural Network):** A standard Multi-Layer Perceptron using two hidden layers (100 neurons, 50 neurons) representing roughly **3,000+ parameters**.
4.  **Random Forest:** A classical ensemble learning method that constructs a multitude of decision trees at training time.
5.  **Support Vector Machine (SVM with RBF Kernel):** A classical algorithm that finds the optimal hyperplane in an N-dimensional space to separate the breast cancer classes.

---

## 3. Technical Methodology (What We Engineered)

This is the exact step-by-step methodology we executed to build the pipeline:

### A. Data Preprocessing & Binarization
We ingested the Wisconsin Breast Cancer dataset. We mathematically scaled all features, dropped noisy data, and selected the top 12 most critical features. Crucially, we converted these continuous features into a binary `0` or `1` format to prepare them for quantum encoding.

### B. Q-Ternary Compression ($2^3 \to 3^2$)
This is the core innovation. Rather than using 12 Qubits for 12 features (which would crash standard hospital computers), we clustered the binary features into groups of 3 (representing $2^3 = 8$ states). We then mathematically mapped these onto 2 Qutrits ($3^2 = 9$ states). This reduced our spatial circuit size by **33%**, allowing the simulation to run on constrained hardware.

### C. Hardware Optimization & Garbage Collection
Standard quantum simulation requires exponential RAM ($3^W$). To prevent the laptop from freezing:
*   We used **PyTorch DataLoaders** to enforce strict mini-batching (batch size = 16).
*   We injected `gc.collect()` and `del` commands directly into the training loop to instantly wipe the PyTorch computation graph from RAM after every backpropagation step.
*   We built a custom `psutil` watchdog to monitor system memory and gracefully halt the script if RAM exceeded safe limits (6GB).

### D. Model Training & Export
The models were trained for 50 epochs. After evaluating the ROC curves and F1-scores, the script isolates the perfectly tuned 72 quantum rotation weights and uses `torch.save()` to serialize them into a `models/qutrit_vqc_weights.pt` file. The classical models are similarly saved via `joblib.dump()`.

### E. API Instantiation
Once the `.pt` files are generated, the Flask API boots up. It holds the pre-trained weights in memory, exposing a `/predict` endpoint that can process new patient data in milliseconds without needing to retrain the quantum circuit.
