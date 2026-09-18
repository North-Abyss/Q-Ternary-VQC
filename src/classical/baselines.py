from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
from sklearn.neural_network import MLPClassifier
import xgboost as xgb

class SVMBaseline:
    def __init__(self, random_state=42):
        self.model = SVC(kernel='rbf', probability=True, random_state=random_state)
        self.name = "SVM (RBF)"
        
    def fit(self, X, y):
        self.model.fit(X, y)
        
    def predict(self, X):
        return self.model.predict(X)
        
    def predict_proba(self, X):
        return self.model.predict_proba(X)

class RandomForestBaseline:
    def __init__(self, n_estimators=100, random_state=42):
        self.model = RandomForestClassifier(n_estimators=n_estimators, random_state=random_state)
        self.name = "Random Forest"
        
    def fit(self, X, y):
        self.model.fit(X, y)
        
    def predict(self, X):
        return self.model.predict(X)
        
    def predict_proba(self, X):
        return self.model.predict_proba(X)

class XGBoostBaseline:
    def __init__(self, random_state=42):
        self.model = xgb.XGBClassifier(use_label_encoder=False, eval_metric='logloss', random_state=random_state)
        self.name = "XGBoost"
        
    def fit(self, X, y):
        self.model.fit(X, y)
        
    def predict(self, X):
        return self.model.predict(X)
        
    def predict_proba(self, X):
        return self.model.predict_proba(X)

class MLPBaseline:
    def __init__(self, random_state=42):
        self.model = MLPClassifier(hidden_layer_sizes=(100, 50), max_iter=500, random_state=random_state)
        self.name = "MLP (Neural Network)"
        
    def fit(self, X, y):
        self.model.fit(X, y)
        
    def predict(self, X):
        return self.model.predict(X)
        
    def predict_proba(self, X):
        return self.model.predict_proba(X)

def get_all_baselines():
    """Returns a list of all classical baseline models."""
    return [
        SVMBaseline(),
        RandomForestBaseline(),
        XGBoostBaseline(),
        MLPBaseline()
    ]
