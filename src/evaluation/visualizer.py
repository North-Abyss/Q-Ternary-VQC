import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import roc_curve, confusion_matrix
import os
import numpy as np

class Visualizer:
    def __init__(self, output_dir='outputs'):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        
    def plot_roc_curves(self, results_dict, y_true):
        """
        Plots overlayed ROC curves for multiple models.
        results_dict: {model_name: y_prob}
        """
        plt.figure(figsize=(10, 8))
        for name, y_prob in results_dict.items():
            if y_prob is not None:
                fpr, tpr, _ = roc_curve(y_true, y_prob)
                plt.plot(fpr, tpr, lw=2, label=name)
                
        plt.plot([0, 1], [0, 1], color='gray', lw=2, linestyle='--')
        plt.xlim([0.0, 1.0])
        plt.ylim([0.0, 1.05])
        plt.xlabel('False Positive Rate')
        plt.ylabel('True Positive Rate')
        plt.title('Receiver Operating Characteristic (ROC)')
        plt.legend(loc="lower right")
        plt.tight_layout()
        plt.savefig(os.path.join(self.output_dir, 'roc_curves.png'), dpi=300)
        plt.close()

    def plot_confusion_matrix(self, y_true, y_pred, model_name):
        """
        Plots a confusion matrix heatmap.
        """
        cm = confusion_matrix(y_true, y_pred)
        plt.figure(figsize=(6, 5))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
        plt.title(f'Confusion Matrix - {model_name}')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.tight_layout()
        
        safe_name = model_name.replace(" ", "_").replace("(", "").replace(")", "").lower()
        plt.savefig(os.path.join(self.output_dir, f'cm_{safe_name}.png'), dpi=300)
        plt.close()

    def plot_training_loss(self, losses):
        """
        Plots training loss over epochs.
        """
        plt.figure(figsize=(8, 5))
        plt.plot(range(1, len(losses) + 1), losses, marker='o', linestyle='-')
        plt.title('Quantum Model Training Loss')
        plt.xlabel('Epoch')
        plt.ylabel('Binary Cross-Entropy Loss')
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(self.output_dir, 'training_loss.png'), dpi=300)
        plt.close()

    def plot_compression_ratio(self, original_dim, compressed_dim):
        """
        Plots a bar chart comparing original and compressed dimensions.
        """
        plt.figure(figsize=(6, 5))
        dims = [original_dim, compressed_dim]
        labels = ['Original (Bits)', 'Compressed (Trits)']
        colors = ['#4C72B0', '#55A868']
        
        bars = plt.bar(labels, dims, color=colors)
        plt.title('Q-Ternary Compression Ratio')
        plt.ylabel('Dimensionality')
        
        # Add text on top of bars
        for bar in bars:
            yval = bar.get_height()
            plt.text(bar.get_x() + bar.get_width()/2, yval + 0.1, int(yval), ha='center', va='bottom')
            
        plt.tight_layout()
        plt.savefig(os.path.join(self.output_dir, 'compression_ratio.png'), dpi=300)
        plt.close()
