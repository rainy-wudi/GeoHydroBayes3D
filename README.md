# Surrogate-assisted Bayesian inversion of 3D hydraulic conductivity fields

This repository contains the reproducible Python and MATLAB workflow accompanying the manuscript:

**Surrogate-assisted Bayesian inversion of three-dimensional heterogeneous hydraulic conductivity fields on unstructured geoscience meshes**

The code demonstrates the main computational components used in the study:

1. preparation of a machine-learning dataset from parameter sets and borehole hydraulic heads;
2. KD-tree mapping between unstructured geoscience mesh centroids and hydraulic-conductivity fields;
3. training of a physics-enhanced deep neural-network surrogate (PA-DNN);
4. comparison with Random Forest and Support Vector Regression baselines;
5. Bayesian inversion of hydraulic-conductivity parameters using the trained surrogate;
6. global sensitivity analysis and figure reproduction;
7. MATLAB-based stratified random-field generation and Abaqus input-file preparation for the original finite-element workflow.

The public dataset included here is an **anonymized demonstration dataset**. It preserves the schema, parameter ranges, borehole count, and hydraulic-head response structure required to reproduce the computational workflow. It does not contain original site coordinates, raw engineering investigation files, proprietary finite-element output files, Abaqus result files, or project-specific generated `.inp` files.

## Repository structure

```text
GeoHydroBayes3D/
|-- README.md
|-- LICENSE
|-- requirements.txt
|-- environment.yml
|-- configs/                         # YAML configuration files
|-- data/                            # anonymized demonstration datasets only
|   |-- Final_ML_Dataset.csv
|   `-- README_demo_dataset.md
|-- docs/
|   |-- installation.md
|   |-- workflow.md
|   `-- code_availability_statement.md
|-- examples/
|   `-- minimal_reproduction/
|-- legacy/                          # inventory of original project scripts
|-- matlab_random_field_generation/   # MATLAB random-field and Abaqus input workflow
|-- metadata/
|   |-- data_dictionary.csv
|   `-- code_package_manifest.md
|-- outputs/                         # generated outputs; ignored except README
|-- scripts/                         # command-line reproduction scripts
|-- src/
|   `-- hydro_inverse/               # reusable Python package
`-- tests/                           # lightweight integrity tests
```

## Installation

A clean Python 3.10+ environment is recommended.

```bash
conda env create -f environment.yml
conda activate hydro-inverse
pip install -e .
```

Alternatively:

```bash
python -m venv .venv

# Windows
.venv\Scripts\activate

# Linux/macOS
source .venv/bin/activate

pip install -r requirements.txt
pip install -e .
```

Detailed installation notes are provided in `docs/installation.md`.

## Quick start

Run a minimal end-to-end demo using the anonymized data:

```bash
python examples/minimal_reproduction/run_demo.py
```

This command checks the public demonstration dataset, runs the KD-tree mapping example, trains a compact PA-DNN surrogate when PyTorch is installed, and writes demo sensitivity outputs to `outputs/minimal_demo/`. If PyTorch is unavailable, the script trains a small Random Forest fallback so the public workflow can still be smoke-tested.

Run individual steps:

```bash
python scripts/00_check_dataset.py
python scripts/01_demo_kdtree_mapping.py
python scripts/02_train_padnn.py --epochs 100
python scripts/03_compare_surrogates.py
python scripts/04_run_mcmc_inversion.py --steps 1000
python scripts/05_run_sensitivity_analysis.py
python scripts/06_reproduce_figures.py
```

All outputs are written to `outputs/`.

Run the lightweight tests:

```bash
pytest
```

## Data

The main demonstration dataset is:

```text
data/Final_ML_Dataset.csv
```

It contains six input parameters:

- `log10_K_Lower`
- `log10_K_Middle`
- `log10_K_Upper`
- `COV`
- `dh`
- `dv`

and 23 hydraulic-head response columns named `zk...`, corresponding to anonymized demonstration boreholes.

See `metadata/data_dictionary.csv`, `data/README_demo_dataset.md`, and `docs/workflow.md` for details.

## MATLAB random-field workflow

The original finite-element random-field generation workflow is provided in:

```text
matlab_random_field_generation/
```

This folder contains MATLAB scripts for stratified hydraulic-conductivity random-field generation, element-centroid mapping, Abaqus `.inp` file generation, generated-file verification, and optional Abaqus batch submission. Large generated Abaqus files are intentionally excluded from the public source package. Users should provide their own Abaqus template input file, commonly named `Job-0.inp`, and regenerate the project-specific simulation inputs locally.

See `matlab_random_field_generation/README.md` for a script-by-script description.

## Code availability statement for the manuscript

A draft statement is provided in:

```text
docs/code_availability_statement.md
```

After uploading this repository to GitHub and archiving a release on Zenodo, replace the placeholders with the final URL and DOI if needed.

## License

The code is released under the MIT License. The anonymized demonstration dataset can be released under CC BY 4.0 if permitted by the project owner.
