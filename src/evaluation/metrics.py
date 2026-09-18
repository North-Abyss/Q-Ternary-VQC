from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix
import numpy as np

def calculate_metrics(y_true, y_pred, y_prob):
    """
    Calculates standard binary classification metrics.
    """
    metrics = {
        "Accuracy": accuracy_score(y_true, y_pred),
        "Precision": precision_score(y_true, y_pred, zero_division=0),
        "Recall": recall_score(y_true, y_pred, zero_division=0),
        "F1": f1_score(y_true, y_pred, zero_division=0),
    }
    
    # AUC-ROC requires probabilities
    if y_prob is not None:
        try:
            metrics["AUC-ROC"] = roc_auc_score(y_true, y_prob)
        except ValueError:
            metrics["AUC-ROC"] = np.nan
            
    # Calculate specificity from confusion matrix
    cm = confusion_matrix(y_true, y_pred)
    if cm.shape == (2, 2):
        tn, fp, fn, tp = cm.ravel()
        metrics["Specificity"] = tn / (tn + fp) if (tn + fp) > 0 else 0.0
    else:
        metrics["Specificity"] = np.nan
        
    return metrics
