import pandas as pd
import numpy as np
from dataclasses import dataclass
from typing import Tuple, List, Optional
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split

@dataclass
class DataBundle:
    """Standardized container for loaded datasets."""
    X_train: np.ndarray
    X_test: np.ndarray
    y_train: np.ndarray
    y_test: np.ndarray
    feature_names: List[str]
    dataset_name: str

def load_wisconsin_breast_cancer(test_size: float = 0.2, random_state: int = 42) -> DataBundle:
    """
    Loads the Wisconsin Breast Cancer dataset from sklearn.
    Returns a standardized DataBundle with a stratified train/test split.
    """
    # Load dataset
    data = load_breast_cancer()
    X = data.data
    y = data.target
    feature_names = list(data.feature_names)
    
    # Stratified split to ensure class balance in train and test sets
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, 
        test_size=test_size, 
        random_state=random_state, 
        stratify=y
    )
    
    return DataBundle(
        X_train=X_train,
        X_test=X_test,
        y_train=y_train,
        y_test=y_test,
        feature_names=feature_names,
        dataset_name="Wisconsin Breast Cancer"
    )

def load_ckd_dataset(file_path: str, test_size: float = 0.2, random_state: int = 42) -> DataBundle:
    """
    Loads the Chronic Kidney Disease dataset from a CSV file.
    Assumes the target column is named 'class' or is the last column.
    """
    df = pd.read_csv(file_path)
    
    # Simple assumption: target is 'class' or the last column
    target_col = 'class' if 'class' in df.columns else df.columns[-1]
    
    y = df[target_col].values
    X = df.drop(columns=[target_col]).values
    feature_names = list(df.drop(columns=[target_col]).columns)
    
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, 
        test_size=test_size, 
        random_state=random_state, 
        stratify=y
    )
    
    return DataBundle(
        X_train=X_train,
        X_test=X_test,
        y_train=y_train,
        y_test=y_test,
        feature_names=feature_names,
        dataset_name="Chronic Kidney Disease"
    )
