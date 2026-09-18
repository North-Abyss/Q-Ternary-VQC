# Slide 1: TITLE PAGE
* **Problem Statement ID:** 26139
* **Problem Statement Title:** Hybrid Quantum Machine Learning Platform for Early Disease Detection
* **Theme:** MedTech / BioTech / HealthTech
* **PS Category:** Software
* **Team Name:** [Your Team Name]
* **Leader:** Yuvanesh KS (@North-Abyss)

---

# Slide 2: IDEA TITLE & PROPOSED SOLUTION
**Idea Title:** Q-Ternary: High-Dimensional Qutrit Compression for Disease Prediction
**Proposed Solution:**
* We are building a Hybrid Quantum-Classical ML platform designed to bypass the limitations of near-term quantum hardware memory (qubit scarcity).
* **The Innovation:** Instead of feeding standard binary data into qubits, our classical preprocessing engine compresses 3-bit binary clusters ($2^3 = 8$ states) into 2-trit quantum representations ($3^2 = 9$ states).
* **The Execution:** This compressed base-3 data is processed through a Variational Quantum Classifier built on PennyLane's `default.qutrit` simulator, drastically reducing computational overhead while maintaining high-dimensional feature mapping for complex genomics and MRI metadata.

---

# Slide 3: TECHNICAL APPROACH
* **Frontend (The Clinical Dashboard):** Flutter (Web/Desktop) for offline-first, responsive medical data ingestion.
* **Backend Controller:** Python / Flask (Handling API routes and data pipelines).
* **Classical ML Engine:** `scikit-learn` (PCA feature extraction, baseline classical SVM for benchmarking).
* **Quantum ML Engine:** `PennyLane` integrated with `PyTorch`. 
* **Data Flow:** CSV Upload -> Classical Feature Extraction -> Binary-to-Ternary Compression -> PennyLane Qutrit Simulator -> PyTorch Optimizer -> Explainable Output (JSON).

---

# Slide 4: FEASIBILITY AND VIABILITY
* **Hardware Feasibility:** By utilizing a classical-to-ternary compression algorithm, we reduce the required quantum circuitry size by roughly 33%. This makes the model executable on standard classical CPU simulators today, without needing access to a physical quantum mainframe.
* **Open Source Tools:** Relies entirely on stable, production-ready open-source libraries (PennyLane, PyTorch, Flutter). 
* **Risks:** Simulating high numbers of Qutrits on a standard laptop can cause memory bottlenecks. 
* **Mitigation:** We implement aggressive classical PCA (Principal Component Analysis) to reduce the dataset's footprint before the quantum encoding stage.

---

# Slide 5: IMPACT AND BENEFITS
* **Accuracy:** Quantum entanglement allows the model to map non-linear correlations in complex biomedical data (like multi-gene interactions) that classical Random Forests miss.
* **Commercialization:** The Flask + Flutter architecture means this is not just a research script; it is a deployable SaaS product that hospitals can use via a standard web browser.
* **Scalability:** As physical quantum hardware (IBM/Google) matures and supports Qutrits natively, our software architecture can be ported directly from the simulator to physical hardware with zero architectural rewrites.

---

# Slide 6: PROJECT TIMELINE & PROTOTYPE
* **Phase 1 (Hours 1-10):** Dataset ingestion (UCI Medical Data) and implementation of the 3-bit to 2-trit mathematical compression pipeline. 
* **Phase 2 (Hours 11-20):** PennyLane QNN circuit design and PyTorch hybrid training loop optimization.
* **Phase 3 (Hours 21-30):** Flutter UI dashboard integration, REST API connection, and XAI (Explainable AI) output generation. 
* **Phase 4 (Hours 31-36):** Code freeze, documentation, and live benchmarking against classical baselines.
