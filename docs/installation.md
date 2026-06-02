# Installation

This repository provides a lightweight Python workflow and an optional MATLAB workflow. The public data are anonymized demonstration data, so installation does not require Abaqus or access to the original confidential simulation archive.

## Python environment

Python 3.10 or later is recommended. The repository can be installed with Conda:

```bash
conda env create -f environment.yml
conda activate hydro-inverse
pip install -e .
```

or with `venv` and `pip`:

```bash
python -m venv .venv

# Windows
.venv\Scripts\activate

# Linux/macOS
source .venv/bin/activate

pip install -r requirements.txt
pip install -e .
```

## Verify the installation

Run the tests:

```bash
pytest
```

Run the minimal reproduction:

```bash
python examples/minimal_reproduction/run_demo.py
```

Successful execution writes demonstration outputs to `outputs/minimal_demo/`. If PyTorch is installed, the demo trains a compact PA-DNN surrogate. If PyTorch is unavailable, it trains a small Random Forest fallback so the repository can still be smoke-tested.

## Optional MATLAB/Abaqus workflow

The MATLAB scripts in `matlab_random_field_generation/` generate stratified hydraulic-conductivity random fields and prepare Abaqus input files. MATLAB is required for this optional workflow. The Statistics and Machine Learning Toolbox is recommended for Latin Hypercube Sampling, although the repository includes a small fallback helper.

Abaqus is needed only if users want to run the generated input files. Large generated `.inp`, `.inc`, `.odb`, `.dat`, `.msg`, `.sta`, and related files are excluded from the public repository.
