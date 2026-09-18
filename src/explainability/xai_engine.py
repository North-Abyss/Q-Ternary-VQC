import shap
import matplotlib.pyplot as plt
import os
import torch
import numpy as np

class XAIEngine:
    def __init__(self, model, X_train, feature_names, output_dir='outputs'):
        self.model = model
        self.feature_names = feature_names
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        
        # We need a wrapper function for SHAP that takes numpy arrays and returns numpy arrays
        def predict_wrapper(x):
            # If the model is a PyTorch model, we need to convert to tensor
            if hasattr(self.model, 'forward'):
                x_tensor = torch.tensor(x, dtype=torch.float32)
                with torch.no_grad():
                    return self.model(x_tensor).numpy().flatten()
            else:
                # Classical sklearn model
                if hasattr(self.model, 'predict_proba'):
                    return self.model.predict_proba(x)[:, 1]
                else:
                    return self.model.predict(x)
                    
        self.predict_wrapper = predict_wrapper
        
        # We use a subsample of X_train for the background to speed up KernelExplainer
        background = shap.sample(X_train, min(100, X_train.shape[0]))
        self.explainer = shap.KernelExplainer(self.predict_wrapper, background)

    def explain_dataset(self, X_test, n_samples=50):
        """
        Computes SHAP values for a subset of the test set and generates summary plots.
        """
        X_explain = X_test[:n_samples]
        shap_values = self.explainer.shap_values(X_explain)
        
        # Summary Plot (Bar)
        plt.figure(figsize=(10, 6))
        shap.summary_plot(shap_values, X_explain, feature_names=self.feature_names, plot_type="bar", show=False)
        plt.tight_layout()
        plt.savefig(os.path.join(self.output_dir, 'shap_feature_importance.png'), dpi=300)
        plt.close()
        
        # Summary Plot (Beeswarm)
        plt.figure(figsize=(10, 6))
        shap.summary_plot(shap_values, X_explain, feature_names=self.feature_names, show=False)
        plt.tight_layout()
        plt.savefig(os.path.join(self.output_dir, 'shap_summary.png'), dpi=300)
        plt.close()

    def explain_patient(self, patient_features, patient_id):
        """
        Generates a waterfall or force plot for a single patient's prediction.
        """
        # Ensure it's a 2D array
        if len(patient_features.shape) == 1:
            patient_features = patient_features.reshape(1, -1)
            
        shap_values = self.explainer.shap_values(patient_features)
        expected_value = self.explainer.expected_value
        
        # Force plot
        plt.figure(figsize=(12, 4))
        # shap.force_plot doesn't play well with matplotlib directly for saving static images sometimes,
        # but we can try to use waterfall if we format it right.
        # Alternatively, a simple bar plot of the SHAP values for this patient
        shap_vals = shap_values[0] if isinstance(shap_values, list) else shap_values
        if len(shap_vals.shape) > 1:
            shap_vals = shap_vals[0]
            
        plt.barh(self.feature_names, shap_vals)
        plt.title(f'Patient {patient_id} - Feature Contributions')
        plt.xlabel('SHAP Value (Impact on model output)')
        plt.tight_layout()
        plt.savefig(os.path.join(self.output_dir, f'shap_patient_{patient_id}.png'), dpi=300)
        plt.close()
