import numpy as np
from sklearn.feature_selection import mutual_info_classif, SelectKBest
from sklearn.decomposition import PCA
from .loader import DataBundle

class FeatureSelector:
    def __init__(self, method='mutual_info', n_features=12):
        self.method = method
        self.n_features = n_features
        self.selector = None

    def fit_transform(self, bundle: DataBundle) -> DataBundle:
        X_train = bundle.X_train
        X_test = bundle.X_test
        feature_names = bundle.feature_names
        
        # Ensure we don't ask for more features than we have
        actual_features = min(self.n_features, X_train.shape[1])
        
        # We need a multiple of 3 for perfect 3-bit to 2-trit compression 
        # (Though preprocessor handles padding, it's cleaner to select exact multiples)
        remainder = actual_features % 3
        if remainder != 0:
            actual_features -= remainder
            if actual_features == 0:
                actual_features = 3 # at least 3
                
        if self.method == 'mutual_info':
            self.selector = SelectKBest(mutual_info_classif, k=actual_features)
            X_train_sel = self.selector.fit_transform(X_train, bundle.y_train)
            X_test_sel = self.selector.transform(X_test)
            
            # Update feature names
            mask = self.selector.get_support()
            feature_names = [name for name, is_selected in zip(feature_names, mask) if is_selected]
            
        elif self.method == 'pca':
            self.selector = PCA(n_components=actual_features)
            X_train_sel = self.selector.fit_transform(X_train)
            X_test_sel = self.selector.transform(X_test)
            
            # PCA creates new synthetic features
            feature_names = [f"PC_{i+1}" for i in range(actual_features)]
        else:
            raise ValueError(f"Unknown feature selection method: {self.method}")
            
        return DataBundle(
            X_train=X_train_sel,
            X_test=X_test_sel,
            y_train=bundle.y_train,
            y_test=bundle.y_test,
            feature_names=feature_names,
            dataset_name=bundle.dataset_name
        )
