import os
import joblib
import argparse
from evaluation.visualizer import Visualizer
from explainability.xai_engine import XAIEngine

def generate_graphs_for_run(run_dir: str):
    eval_file = os.path.join(run_dir, "eval_data.pkl")
    graphs_dir = os.path.join(run_dir, "graphs")
    
    if not os.path.exists(eval_file):
        print(f"❌ Error: {eval_file} not found. Cannot generate graphs for this run.")
        return False
        
    os.makedirs(graphs_dir, exist_ok=True)
    
    print(f"📥 Loading evaluation data from {eval_file}...")
    eval_data = joblib.load(eval_file)
    
    # Extract data
    losses = eval_data.get("losses", [])
    original_dim = eval_data.get("original_dim", 12)
    n_wires = eval_data.get("n_wires", 2)
    roc_dict = eval_data.get("roc_dict", {})
    y_test = eval_data.get("y_test")
    q_preds = eval_data.get("q_preds")
    c_preds = eval_data.get("c_preds")
    best_classical_name = eval_data.get("best_classical_name", "SVM")
    X_train_selected = eval_data.get("X_train_selected")
    X_test_selected = eval_data.get("X_test_selected")
    feature_names = eval_data.get("feature_names", [])
    
    print("\n--- 📈 Generating Visualizations ---")
    viz = Visualizer(output_dir=graphs_dir)
    if losses:
        viz.plot_training_loss(losses)
    viz.plot_compression_ratio(original_dim, n_wires)
    
    if roc_dict is not None and y_test is not None:
        viz.plot_roc_curves(roc_dict, y_test)
        
    if y_test is not None and q_preds is not None:
        viz.plot_confusion_matrix(y_test, q_preds, "Qutrit VQC")
        
    if y_test is not None and c_preds is not None:
        viz.plot_confusion_matrix(y_test, c_preds, best_classical_name)
        
    print(f"🖼️ Visualizations saved to {graphs_dir}/ directory.")

    print("\n--- 🧠 Generating SHAP Explanations ---")
    # Load the best classical model for SHAP (faster than quantum SHAP)
    safe_name = best_classical_name.replace(" ", "_").lower()
    c_model_path = os.path.join(run_dir, f"{safe_name}_baseline.pkl")
    
    if os.path.exists(c_model_path) and X_train_selected is not None and X_test_selected is not None:
        c_model = joblib.load(c_model_path)
        class BaselineWrapper:
            def __init__(self, m, n):
                self.model = m
                self.name = n
            def predict(self, x): return self.model.predict(x)
            
        wrapper = BaselineWrapper(c_model, best_classical_name)
        xai = XAIEngine(wrapper, X_train_selected, feature_names, output_dir=graphs_dir)
        # Using fewer samples for SHAP to make generation faster on demand
        xai.explain_dataset(X_test_selected, n_samples=20)
        print(f"🖼️ SHAP plots saved to {graphs_dir}/ directory.")
    else:
        print(f"⚠️ Skipping SHAP: Required model {c_model_path} or data missing.")

    print("✅ Graph generation completed successfully!")
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Graphs for a Run")
    parser.add_argument("--run-dir", type=str, required=True, help="Path to the run directory (e.g., models/run_timestamp)")
    args = parser.parse_args()
    generate_graphs_for_run(args.run_dir)
