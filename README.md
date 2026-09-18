# Hybrid Quantum Machine Learning Platform for Early Disease Detection

**SIH Problem Statement ID:** 26139  
**Team:** [Your Team Name]  
**Leader:** Yuvanesh KS (@North-Abyss)

## Overview
This repository contains the core logic for a Hybrid Quantum Machine Learning pipeline targeting early disease detection. It leverages a unique mathematical compression algorithm that maps classical binary vectors into ternary quantum states (Qutrits), drastically reducing the required quantum circuitry size while maintaining high-dimensional feature mapping.

## Technology Stack
- **Quantum Machine Learning Engine:** PennyLane (Xanadu)
- **Deep Learning Framework:** PyTorch
- **Classical ML Baseline:** scikit-learn
- **Backend API Controller:** Python & Flask (Planned for Phase 3)
- **Frontend Dashboard:** Flutter (Planned for Phase 3)

## Repository Structure
```
.
├── src/
│   └── core_engine.py       # Core hybrid QML model (PennyLane + PyTorch)
├── docs/
│   └── sih_presentation.md  # SIH Idea Submission Template slides
├── PROJECT_LOG.md           # Active sprint & architecture logs
├── requirements.txt         # Python dependencies
└── README.md                # Project documentation
```

## Quick Start
1. Create and activate the virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Linux/Mac
   # or .venv\Scripts\activate on Windows
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the core engine to benchmark Quantum Qutrit model against Classical SVM:
   ```bash
   python src/core_engine.py
   ```
