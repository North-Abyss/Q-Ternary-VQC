# Hybrid Quantum Machine Learning Platform for Early Disease Detection

**SIH Problem Statement ID:** 26139  
**Team:** [Your Team Name]  
**Leader:** Yuvanesh KS (@North-Abyss)

## Overview
This repository contains the core logic for a Hybrid Quantum Machine Learning pipeline targeting early disease detection. It leverages a unique mathematical compression algorithm that maps classical binary vectors into ternary quantum states (Qutrits), drastically reducing the required quantum circuitry size while maintaining high-dimensional feature mapping.

## Technology Stack
- **Quantum Machine Learning Engine:** PennyLane (Xanadu)
- **Deep Learning Framework:** PyTorch
- **Classical ML Baseline:** scikit-learn, XGBoost
- **Explainable AI (XAI):** SHAP
- **Backend API:** Flask
- **Data Pipeline:** pandas, numpy

## Repository Structure
```
.
├── src/
│   ├── data/                 # Loaders, preprocessor, and 2³→3² compression
│   ├── quantum/              # Qutrit VQC with CSUM entanglement & data re-uploading
│   ├── classical/            # Baselines (SVM, RF, XGBoost, MLP)
│   ├── evaluation/           # Metrics calculation and visualization
│   ├── explainability/       # SHAP integration
│   ├── api/                  # Flask REST API
│   └── main.py               # Unified CLI Runner
├── outputs/                  # Auto-generated ROC curves, SHAP plots, CMs
├── tests/                    # Unit tests
├── README.md
├── requirements.txt
└── run.sh
```

## Setup Instructions

1. **Activate the Virtual Environment (if not already active):**
   ```bash
   source .venv/bin/activate
   ```
2. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## Running the Pipeline

Run the full end-to-end pipeline (data loading, preprocessing, classical baseline training, quantum model training, evaluation, XAI generation, and API startup).

```bash
# Run full pipeline with Wisconsin Breast Cancer dataset
python src/main.py --dataset breast_cancer --n-features 12 --n-layers 3 --epochs 50

# Run full pipeline and start the Flask API
python src/main.py --start-api

# Skip quantum training (fast classical check)
python src/main.py --classical-only
```

## Results & Visualizations
After running `main.py`, check the `outputs/` directory for:
- `roc_curves.png`: Comparison of Quantum vs Classical models.
- `cm_*.png`: Confusion matrices.
- `training_loss.png`: VQC convergence.
- `shap_*.png`: Explainability plots for clinical interpretability.

## License
This repository is strictly governed by the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)** License.
- **Attribution:** You must credit this repository (`North-Abyss/Qutrit-QML-SIH`) and its authors.
- **Non-Commercial:** You may **not** sell this software or use it for commercial profit.
- **Always FOSS:** Any derivative works must remain Free and Open Source Software under the exact same license terms.
