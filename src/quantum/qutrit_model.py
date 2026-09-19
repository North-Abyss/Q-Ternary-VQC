"""
=============================================================================
Designed and Engineered by: Yuvanesh KS (Alias: North-Abyss)
GitHub: https://github.com/North-Abyss
License: CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike)

Core Innovation: Q-Ternary (2³ → 3²) Medical Data Compression & VQC Entanglement
=============================================================================
"""
import torch
import torch.nn as nn
import pennylane as qml
import numpy as np
from .circuit_utils import ring_entangle, get_observable

class QutritClassifier(nn.Module):
    def __init__(self, n_wires: int, n_layers: int = 3):
        super().__init__()
        self.n_wires = n_wires
        self.n_layers = n_layers
        
        # Initialize trainable weights for the quantum circuit
        weight_shape = (n_layers, n_wires, 3)
        self.q_weights = nn.Parameter(0.1 * torch.randn(weight_shape))
        
        # Initialize the PennyLane device configured for Qutrit operations
        self.dev = qml.device("default.qutrit", wires=self.n_wires)
        
        # Define the QNode
        @qml.qnode(self.dev, interface="torch")
        def qutrit_circuit(inputs, weights):
            for layer in range(self.n_layers):
                # 1. Data Re-uploading: Re-encode the classical trits at every layer
                for wire in range(self.n_wires):
                    angle = inputs[wire] * (2.0 * np.pi / 3.0)
                    # Encode across both sub-spaces of the qutrit
                    qml.TRZ(angle, wires=wire, subspace=[0, 1])
                    qml.TRZ(angle, wires=wire, subspace=[1, 2])
                    
                # 2. Variational Layer: Trainable rotations (SU(3) components)
                for wire in range(self.n_wires):
                    qml.TRX(weights[layer, wire, 0], wires=wire, subspace=[0, 1])
                    qml.TRY(weights[layer, wire, 1], wires=wire, subspace=[1, 2])
                    qml.TRZ(weights[layer, wire, 2], wires=wire, subspace=[0, 2])
                    
                # 3. Entanglement Layer: CSUM gates in ring topology
                ring_entangle(self.n_wires)
                
            # 4. Measurement: Measure Gell-Mann lambda_3 on ALL wires
            return [qml.expval(get_observable(w)) for w in range(self.n_wires)]
            
        self.qnode = qutrit_circuit

    def forward(self, x):
        """
        Forward pass for a batch of inputs.
        """
        batch_size = x.shape[0]
        # Evaluate the circuit for each sample in the batch
        # outputs shape: (batch_size, n_wires)
        circuit_outputs = torch.stack([torch.hstack(self.qnode(x[i], self.q_weights)) for i in range(batch_size)])
        
        # Sum the expectation values across all wires to get a single scalar per sample
        summed_outputs = torch.sum(circuit_outputs, dim=1)
        
        # Sigmoid to map output expectation sum to [0, 1] probability
        return torch.sigmoid(summed_outputs)
