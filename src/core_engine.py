import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import pennylane as qml
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split

# -----------------------------------------------------------------------------
# 1. Classical Pre-processing: 3-bit to 2-trit Compression
# -----------------------------------------------------------------------------
def compress_3bits_to_2trits(binary_vector):
    """
    Compresses a binary vector (array of 0s and 1s) into a base-3 trit vector.
    Maps clusters of 3 binary bits (2^3 = 8 states) into 2 trits (3^2 = 9 states).
    This mathematically reduces spatial dimensionality before feeding into Qutrits.
    
    Args:
        binary_vector (np.ndarray): 1D array of binary features.
        
    Returns:
        np.ndarray: 1D array of ternary features (0, 1, 2).
    """
    # Pad vector with 0s if length is not a multiple of 3 to ensure perfect clusters
    remainder = len(binary_vector) % 3
    if remainder != 0:
        padding = 3 - remainder
        binary_vector = np.pad(binary_vector, (0, padding), 'constant')
    
    # Reshape into clusters of 3 bits
    chunks = binary_vector.reshape(-1, 3)
    
    # Convert each 3-bit cluster to its decimal representation (0 to 7)
    # [bit2, bit1, bit0] -> bit2 * 4 + bit1 * 2 + bit0 * 1
    powers_of_2 = np.array([4, 2, 1])
    decimals = np.dot(chunks, powers_of_2)
    
    # Convert each decimal (0 to 7) to 2 base-3 trits
    # Max decimal is 7 (binary 111). In base-3, 7 is 21 (2 * 3^1 + 1 * 3^0)
    trit1 = decimals // 3
    trit0 = decimals % 3
    
    # Combine into a single array of trits
    trit_vector = np.stack((trit1, trit0), axis=1).flatten()
    return trit_vector

def batch_compress(binary_matrix):
    """
    Applies 3-bit to 2-trit compression to a batch of binary vectors.
    """
    return np.array([compress_3bits_to_2trits(row) for row in binary_matrix])


# -----------------------------------------------------------------------------
# 2. Quantum Circuit: PennyLane Qutrit QNN
# -----------------------------------------------------------------------------
# For demonstration, we assume our compressed data has 4 trits 
# (which means the original binary dataset had up to 6 binary features).
N_WIRES = 4

# Initialize the PennyLane device configured for Qutrit operations
dev = qml.device("default.qutrit", wires=N_WIRES)

@qml.qnode(dev, interface="torch")
def qutrit_circuit(inputs, weights):
    """
    Variational Quantum Neural Network (QNN) for Qutrits.
    
    Args:
        inputs (tensor): The compressed trit data of shape (N_WIRES,).
        weights (tensor): Trainable weights for the circuit of shape (n_layers, N_WIRES, 3).
        
    Returns:
        tensor: The expectation values of a Qutrit observable (analogous to Pauli-Z)
    """
    # Phase 1: State Embedding 
    # Embed the classical trits into the qutrit state using rotations in different subspaces
    for wire in range(N_WIRES):
        # We embed the ternary input {0, 1, 2} as rotation angles
        angle = inputs[wire] * (2.0 * np.pi / 3.0)
        qml.TRZ(angle, wires=wire, subspace=[0, 1])
        qml.TRZ(angle, wires=wire, subspace=[1, 2])
        
    # Phase 2: Variational Layers
    n_layers = weights.shape[0]
    for layer in range(n_layers):
        # Trainable rotations (SU(3) components) for each wire
        for wire in range(N_WIRES):
            qml.TRX(weights[layer, wire, 0], wires=wire, subspace=[0, 1])
            qml.TRY(weights[layer, wire, 1], wires=wire, subspace=[1, 2])
            qml.TRZ(weights[layer, wire, 2], wires=wire, subspace=[0, 2])
            
        # Optional: In a highly advanced setup, we would add multi-qutrit entangling gates here 
        # (like generalized CNOT for qutrits). We stick to SU(3) subspace rotations for this baseline.
        
    # Phase 3: Measurement
    # Expected value of a Gell-Mann observable (e.g., THermitian)
    # We construct a simple observable for wire 0: diagonal with values [1, 0, -1]
    # to evaluate disease classification mapping.
    obs = np.array([[1.0, 0.0, 0.0],
                    [0.0, 0.0, 0.0],
                    [0.0, 0.0, -1.0]])
    return qml.expval(qml.THermitian(obs, wires=0))


# -----------------------------------------------------------------------------
# 3. Hybrid Training: PyTorch & Scikit-Learn Baseline
# -----------------------------------------------------------------------------

class QutritClassifier(nn.Module):
    def __init__(self, n_layers, n_wires):
        super().__init__()
        self.n_layers = n_layers
        self.n_wires = n_wires
        
        # Initialize trainable weights for the quantum circuit
        weight_shape = (n_layers, n_wires, 3)
        self.q_weights = nn.Parameter(0.1 * torch.randn(weight_shape))
        
    def forward(self, x):
        # Iterate over the batch and compute quantum circuit outputs
        batch_size = x.shape[0]
        outputs = torch.zeros(batch_size, device=x.device)
        for i in range(batch_size):
            outputs[i] = qutrit_circuit(x[i], self.q_weights)
            
        # Sigmoid to map output expectation [-1, 1] to [0, 1] probability
        return torch.sigmoid(outputs)


def train_hybrid_model():
    """
    Main training loop comparing Classical SVM against our Hybrid Qutrit Engine.
    """
    # 1. Generate dummy biomedical binary data (0s and 1s)
    # 100 samples, 6 binary features
    X, y = make_classification(n_samples=100, n_features=6, n_informative=4, 
                               n_redundant=0, n_classes=2, random_state=42)
    # Threshold continuous dummy features to create binary categorical features (0 or 1)
    X_binary = (X > 0).astype(int)
    
    # Split dataset
    X_train_bin, X_test_bin, y_train, y_test = train_test_split(X_binary, y, test_size=0.2, random_state=42)
    
    # 2. Classical Baseline (SVM)
    print("===============================================")
    print("--- Training Classical Baseline (SVM) ---")
    svm_clf = SVC(kernel='rbf')
    svm_clf.fit(X_train_bin, y_train)
    svm_preds = svm_clf.predict(X_test_bin)
    svm_acc = accuracy_score(y_test, svm_preds)
    print(f"Classical SVM Accuracy: {svm_acc * 100:.2f}%\n")
    
    # 3. Apply 3-bit to 2-trit compression (The Architectual Moat)
    print("--- Compressing Data (3-bit to 2-trit) ---")
    X_train_trit = batch_compress(X_train_bin)
    X_test_trit = batch_compress(X_test_bin)
    print(f"Original Classical Shape: {X_train_bin.shape}")
    print(f"Compressed Quantum Shape: {X_train_trit.shape}\n")
    
    # 4. Quantum Model Training (PyTorch)
    print("--- Training Quantum Qutrit Model (PyTorch + PennyLane) ---")
    X_train_t = torch.tensor(X_train_trit, dtype=torch.float32)
    y_train_t = torch.tensor(y_train, dtype=torch.float32)
    X_test_t = torch.tensor(X_test_trit, dtype=torch.float32)
    y_test_t = torch.tensor(y_test, dtype=torch.float32)
    
    model = QutritClassifier(n_layers=2, n_wires=N_WIRES)
    criterion = nn.BCELoss()
    optimizer = optim.Adam(model.parameters(), lr=0.1)
    
    epochs = 10
    for epoch in range(epochs):
        optimizer.zero_grad()
        outputs = model(X_train_t)
        loss = criterion(outputs, y_train_t)
        loss.backward()
        optimizer.step()
        
        if (epoch+1) % 2 == 0:
            print(f"Epoch {epoch+1}/{epochs} | Loss: {loss.item():.4f}")
            
    # 5. Quantum Model Evaluation
    with torch.no_grad():
        q_preds_prob = model(X_test_t)
        q_preds = (q_preds_prob > 0.5).int().numpy()
        q_acc = accuracy_score(y_test, q_preds)
        
    print(f"\nQuantum Hybrid Model Accuracy: {q_acc * 100:.2f}%")
    print("===============================================")


if __name__ == "__main__":
    train_hybrid_model()
