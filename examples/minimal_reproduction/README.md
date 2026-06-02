# Minimal reproduction

This example runs the smallest public workflow that demonstrates the repository without requiring confidential FEM outputs or project-specific Abaqus files.

From the repository root, run:

```bash
python examples/minimal_reproduction/run_demo.py
```

The script performs four steps:

1. Load `data/Final_ML_Dataset.csv`.
2. Run a KD-tree mapping example using the anonymized demonstration mesh.
3. Train a compact PA-DNN surrogate for 20 epochs when PyTorch is installed, or a small Random Forest fallback when PyTorch is unavailable.
4. Compute demonstration sensitivity outputs.

Generated files are written to `outputs/minimal_demo/`. They are not required as repository inputs and can be regenerated locally.
