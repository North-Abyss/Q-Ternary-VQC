import time
import numpy as np
import torch
from src.data.loader import load_wisconsin_breast_cancer
from src.data.preprocessor import Preprocessor
from src.data.feature_selector import FeatureSelector
from src.quantum.qutrit_model import QutritClassifier
from torch.utils.data import DataLoader, TensorDataset
import torch.nn as nn
import torch.optim as optim

def test_epoch_time():
    print("Preparing data...")
    bundle_raw = load_wisconsin_breast_cancer()
    selector = FeatureSelector(method='mutual_info', n_features=12)
    bundle_selected = selector.fit_transform(bundle_raw)
    prep = Preprocessor()
    bundle_compressed = prep.fit_transform(bundle_selected)
    
    X_train = bundle_compressed.X_train
    y_train = bundle_compressed.y_train
    
    device = torch.device("cpu")
    model = QutritClassifier(n_wires=8, n_layers=3).to(device)
    criterion = nn.BCELoss()
    optimizer = optim.Adam(model.parameters(), lr=0.01)
    
    X_train_t = torch.tensor(X_train, dtype=torch.float32)
    y_train_t = torch.tensor(y_train, dtype=torch.float32)
    
    dataset = TensorDataset(X_train_t, y_train_t)
    dataloader = DataLoader(dataset, batch_size=16, shuffle=True)
    
    print("Starting 1 epoch of training on CPU...")
    start_time = time.time()
    
    model.train()
    for batch_X, batch_y in dataloader:
        batch_X, batch_y = batch_X.to(device), batch_y.to(device)
        optimizer.zero_grad()
        outputs = model(batch_X)
        loss = criterion(outputs.to(torch.float32), batch_y.to(torch.float32))
        loss.backward()
        optimizer.step()
        
    end_time = time.time()
    print(f"\nTime taken for 1 full epoch (n_layers=3): {end_time - start_time:.2f} seconds.")

if __name__ == "__main__":
    test_epoch_time()
