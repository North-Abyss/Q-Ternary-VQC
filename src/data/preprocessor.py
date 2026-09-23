"""
=============================================================================
Designed and Engineered by: Yuvanesh KS (Alias: North-Abyss)
GitHub: https://github.com/North-Abyss
License: CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike)

Core Innovation: Q-Ternary (2³ → 3²) Medical Data Compression & VQC Entanglement
=============================================================================
"""
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer
from .loader import DataBundle

class Preprocessor:
    def __init__(self, binarization_threshold_method='median'):
        self.imputer = SimpleImputer(strategy='median')
        self.scaler = StandardScaler()
        self.thresholds = None
        self.binarization_threshold_method = binarization_threshold_method

    def fit_transform(self, bundle: DataBundle) -> DataBundle:
        # 1. Impute missing values
        X_train = self.imputer.fit_transform(bundle.X_train)
        X_test = self.imputer.transform(bundle.X_test)
        
        # 2. Normalize
        X_train = self.scaler.fit_transform(X_train)
        X_test = self.scaler.transform(X_test)
        
        # 3. Calculate thresholds for binarization (using median of normalized train data)
        if self.binarization_threshold_method == 'median':
            self.thresholds = np.median(X_train, axis=0)
        else:
            self.thresholds = np.zeros(X_train.shape[1])
            
        # 4. Binarize
        X_train_bin = (X_train > self.thresholds).astype(int)
        X_test_bin = (X_test > self.thresholds).astype(int)
        
        # 5. Compress 3-bits to 2-trits
        X_train_comp = self.batch_compress(X_train_bin)
        X_test_comp = self.batch_compress(X_test_bin)
        
        return DataBundle(
            X_train=X_train_comp,
            X_test=X_test_comp,
            y_train=bundle.y_train,
            y_test=bundle.y_test,
            feature_names=bundle.feature_names,
            dataset_name=bundle.dataset_name + " (Compressed)"
        )

    def transform(self, X: np.ndarray) -> np.ndarray:
        """Applies inference-time transformations: impute, scale, binarize, and compress."""
        X_imp = self.imputer.transform(X)
        X_scl = self.scaler.transform(X_imp)
        X_bin = (X_scl > self.thresholds).astype(int)
        return self.batch_compress(X_bin)

    @staticmethod
    def compress_3bits_to_2trits(binary_vector: np.ndarray) -> np.ndarray:
        """
        Compresses a binary vector into a base-3 trit vector (3 bits -> 2 trits).
        """
        remainder = len(binary_vector) % 3
        if remainder != 0:
            padding = 3 - remainder
            binary_vector = np.pad(binary_vector, (0, padding), 'constant')
        
        chunks = binary_vector.reshape(-1, 3)
        powers_of_2 = np.array([4, 2, 1])
        decimals = np.dot(chunks, powers_of_2)
        
        trit1 = decimals // 3
        trit0 = decimals % 3
        
        trit_vector = np.stack((trit1, trit0), axis=1).flatten()
        return trit_vector

    @classmethod
    def batch_compress(cls, binary_matrix: np.ndarray) -> np.ndarray:
        return np.array([cls.compress_3bits_to_2trits(row) for row in binary_matrix])
