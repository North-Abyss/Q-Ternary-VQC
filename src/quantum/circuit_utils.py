import numpy as np
import pennylane as qml

def csum_matrix() -> np.ndarray:
    """
    Returns the 9x9 unitary matrix for the Qutrit CSUM (Controlled-SUM) gate.
    Action: |a, b> -> |a, (a + b) mod 3>
    """
    U = np.zeros((9, 9), dtype=complex)
    for a in range(3):
        for b in range(3):
            # Input basis state index
            in_idx = a * 3 + b
            # Output basis state index
            out_b = (a + b) % 3
            out_idx = a * 3 + out_b
            U[out_idx, in_idx] = 1.0
    return U

def get_observable(wire: int):
    """
    Returns the Gell-Mann lambda_3 observable for a given wire.
    This corresponds to the diagonal generator diag(1, -1, 0).
    """
    return qml.GellMann(wires=wire, index=3)

def ring_entangle(n_wires: int):
    """
    Applies CSUM gates in a ring topology between adjacent qutrits.
    """
    if n_wires < 2:
        return
        
    csum = csum_matrix()
    for i in range(n_wires):
        control = i
        target = (i + 1) % n_wires
        qml.QutritUnitary(csum, wires=[control, target])
