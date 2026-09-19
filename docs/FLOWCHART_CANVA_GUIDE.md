# Egreen Quanta — Flowchart Build Guide (For Canva / Google Slides)

Use this guide to manually recreate the architecture flowchart in Canva or Google Slides.
Each section below tells you exactly what shape to place, what text to put inside, what color to use, and where the arrows go.

---

## SLIDE LAYOUT

**Orientation:** Landscape (16:9)
**Background:** White (#FFFFFF)
**Title:** "FLOW CHART" — Top-left corner, bold, teal/dark blue, 24pt

---

## COLOR KEY (Use these exact hex codes in Canva)

| Role | Fill Color | Border Color | Text Color |
|:-----|:-----------|:-------------|:-----------|
| **Input Data (Red-Orange)** | #FF6B6B | #CC0000 | White |
| **Classical Processing (Cyan/Teal)** | #4ECDC4 | #009688 | White |
| **Quantum Circuit (Blue)** | #45B7D1 | #0288D1 | White |
| **Compression (Purple/Magenta)** | #DDA0DD | #9C27B0 | Black |
| **Output / Decision (Green)** | #66BB6A | #2E7D32 | White |
| **Arrow Labels** | — | — | Black, 10pt |

---

## SECTION 1 — LEFT SIDE (Input Column)

### Box 1A — "Raw Clinical Data"
- **Shape:** Rounded Rectangle
- **Color:** Red-Orange (#FF6B6B)
- **Text:** `Raw Clinical Data`
- **Subtext:** `(Wisconsin Breast Cancer — 12 Features)`
- **Position:** Far left, middle-height

### Box 1B — "Feature Selection"
- **Shape:** Rounded Rectangle
- **Color:** Cyan (#4ECDC4)
- **Text:** `Feature Selection`
- **Subtext:** `PCA + Mutual Information`
- **Position:** Below Box 1A
- **Arrow from 1A → 1B:** Label: `12 raw features`

### Box 1C — "Binarization"
- **Shape:** Rounded Rectangle
- **Color:** Cyan (#4ECDC4)
- **Text:** `Binarization`
- **Subtext:** `Convert to 0/1`
- **Position:** Below Box 1B
- **Arrow from 1B → 1C:** Label: `selected features`

---

## SECTION 2 — CENTER-LEFT (Compression Column)

### Box 2A — "3-bit Binary Clustering"
- **Shape:** Rectangle
- **Color:** Purple/Magenta (#DDA0DD)
- **Text:** `3-bit Binary Clustering`
- **Position:** To the right of Box 1C
- **Arrow from 1C → 2A:** Label: `binary vector`

### Box 2B — "Q-Ternary Mapping (2³ → 3²)"
- **Shape:** Rectangle
- **Color:** Purple/Magenta (#DDA0DD)
- **Text:** `Q-Ternary Mapping`
- **Subtext:** `2³ → 3² (8 states → 9 states)`
- **Position:** Below Box 2A
- **Arrow from 2A → 2B:** (no label, just arrow)

### Box 2C — "33% Dimensionality Reduction"
- **Shape:** Rectangle
- **Color:** Purple/Magenta (#DDA0DD)
- **Text:** `33% Dimensionality Reduction`
- **Subtext:** `12 features → 8 qutrits`
- **Position:** Below Box 2B
- **Arrow from 2B → 2C:** (no label, just arrow)

### Box 2D — "Calculate Rotation Angles (θ)"
- **Shape:** Rectangle
- **Color:** Purple/Magenta (#DDA0DD)
- **Text:** `Calculate Rotation Angles (θ)`
- **Position:** Below Box 2C
- **Arrow from 2C → 2D:** (no label, just arrow)

---

## SECTION 3 — CENTER-RIGHT (Quantum VQC Column)

### Box 3A — "Data Embedding — TRZ(θ)"
- **Shape:** Rounded Rectangle
- **Color:** Blue (#45B7D1)
- **Text:** `Data Embedding`
- **Subtext:** `TRZ(θ) Rotations`
- **Position:** To the right of Box 2D
- **Arrow from 2D → 3A:** Label: `angles (θ)`

### Box 3B — "Trainable Weights — TRX, TRY, TRZ"
- **Shape:** Rounded Rectangle
- **Color:** Blue (#45B7D1)
- **Text:** `Trainable Weights`
- **Subtext:** `TRX, TRY, TRZ (72 params)`
- **Position:** Below Box 3A
- **Arrow from 3A → 3B:** (no label, just arrow)

### Box 3C — "CSUM Ring Entanglement"
- **Shape:** Rounded Rectangle
- **Color:** Blue (#45B7D1)
- **Text:** `CSUM Ring Entanglement`
- **Subtext:** `Controlled-SUM gates`
- **Position:** Below Box 3B
- **Arrow from 3B → 3C:** (no label, just arrow)

### 🔁 FEEDBACK LOOP ARROW
- **Arrow from 3C → 3A:** Curved arrow looping back up
- **Label on arrow:** `Data Re-uploading (×3 Layers)`
- **Style:** Dashed line, blue color

---

## SECTION 4 — RIGHT SIDE (Output Column)

### Box 4A — "Gell-Mann Measurement (λ₃)"
- **Shape:** Rounded Rectangle
- **Color:** Cyan (#4ECDC4)
- **Text:** `Gell-Mann Measurement`
- **Subtext:** `Observable: λ₃ (all 8 wires)`
- **Position:** To the right of Box 3C
- **Arrow from 3C → 4A:** Label: `quantum state`

### Box 4B — "Sum Expectation Values"
- **Shape:** Rounded Rectangle
- **Color:** Cyan (#4ECDC4)
- **Text:** `Sum Expectation Values`
- **Position:** Below Box 4A
- **Arrow from 4A → 4B:** (no label, just arrow)

### Box 4C — "Sigmoid Activation"
- **Shape:** Rounded Rectangle
- **Color:** Cyan (#4ECDC4)
- **Text:** `Classical Sigmoid Activation`
- **Subtext:** `Probability: 0.0 → 1.0`
- **Position:** Below Box 4B
- **Arrow from 4B → 4C:** (no label, just arrow)

### Box 4D — "Final Prediction" (DECISION DIAMOND)
- **Shape:** Diamond ◇
- **Color:** Green (#66BB6A)
- **Text:** `Cancer (1) / Normal (0)`
- **Position:** Below Box 4C
- **Arrow from 4C → 4D:** Label: `probability`

---

## SECTION 5 — BOTTOM ANNOTATION BAR (Optional)

Place a thin horizontal bar at the very bottom of the slide with these stats:

| Stat | Value |
|:-----|:------|
| Total Parameters | **72** |
| Classical Baseline (XGBoost) | **94.74%** |
| Quantum VQC Accuracy | **86.84%** |
| Peak RAM Usage | **1.2 GB** |
| Parameter Reduction | **97%** |

---

## ARROW SUMMARY (Quick Reference)

| From | To | Arrow Label | Style |
|:-----|:---|:------------|:------|
| Raw Clinical Data | Feature Selection | `12 raw features` | Solid |
| Feature Selection | Binarization | `selected features` | Solid |
| Binarization | 3-bit Binary Clustering | `binary vector` | Solid |
| 3-bit Clustering | Q-Ternary Mapping | — | Solid |
| Q-Ternary Mapping | 33% Reduction | — | Solid |
| 33% Reduction | Rotation Angles | — | Solid |
| Rotation Angles | Data Embedding | `angles (θ)` | Solid |
| Data Embedding | Trainable Weights | — | Solid |
| Trainable Weights | CSUM Entanglement | — | Solid |
| CSUM Entanglement | Data Embedding | `Re-uploading (×3)` | **Dashed, Blue** |
| CSUM Entanglement | Gell-Mann Measurement | `quantum state` | Solid |
| Gell-Mann | Sum Expectation | — | Solid |
| Sum Expectation | Sigmoid | — | Solid |
| Sigmoid | Final Prediction ◇ | `probability` | Solid |

---

## ASCII LAYOUT REFERENCE

Use this visual map to arrange your boxes and arrows in Canva.

```text

       1. INPUT COLUMN           2. COMPRESSION COLUMN          3. QUANTUM VQC COLUMN             4. OUTPUT COLUMN
+------------------------+   +-------------------------+   +-----------------------------+   +------------------------+
|                        |   |                         |   |                             |   |                        |
| [Raw Clinical Data]    |   | [3-bit Clustering] <----+   | [Data Embedding] <--------+ |   | [Gell-Mann Measure] <----+
|          |             |   |          |              |   |          |                | |   |          |             |   |
|          v             |   |          v              |   |          v                | |   |          v             |   |
| [Feature Selection]    |   | [Q-Ternary Mapping]     |   | [Trainable Weights]       | |   | [Sum Expectation]      |   |
|          |             |   |          |              |   |          |                | |   |          |             |   |
|          v             |   |          v              |   |          v                | |   |          v             |   |
| [Binarization]         |   | [33% Dim Reduction]     |   | [CSUM Entanglement] ------+ |   | [Sigmoid Activation]   |   |
|          |             |   |          |              |   |          | (re-upload)    | |   |          |             |   |
+----------|-------------+   |          v              |   +----------|------------------+   |          v             |   |
           |                 | [Calculate Angles]      |              |                      |  <Final Prediction>    |   |
           |                 |          |              |              |                      |                        |   |
           | (binary vector) +----------|--------------+              | (quantum state)      +------------------------+   |
           +----------------------------+                             +---------------------------------------------------+
                                        |
                             (angles θ) +--------------------------------> (to Data Embedding)

```
