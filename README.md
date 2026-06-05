# Surrogate-assisted Bayesian inversion of 3D hydraulic conductivity fields

This repository contains the publicly shareable Python and MATLAB implementation accompanying the manuscript:

**Surrogate-assisted Bayesian inversion of three-dimensional heterogeneous hydraulic conductivity fields on unstructured geoscience meshes**

The repository demonstrates the main computational components developed and used in the study:

1. preparation of machine-learning datasets from model parameters and hydraulic-head responses;
2. KD-tree mapping between unstructured geoscience-mesh centroids and hydraulic-conductivity fields;
3. training of a physics-enhanced deep neural-network surrogate, referred to as PA-DNN;
4. comparison with Random Forest and Support Vector Regression baseline models;
5. Bayesian inversion of hydraulic-conductivity and geostatistical parameters using trained surrogate models;
6. global sensitivity analysis and generation of demonstration figures;
7. MATLAB-based stratified random-field generation and generic Abaqus input-file preparation.

## Confidentiality and reproducibility scope

The original engineering dataset used in the associated study cannot be made publicly available because it contains confidential project information and is subject to third-party data-use restrictions.

This repository therefore provides a **fully synthetic demonstration dataset** designed solely to verify the software implementation and demonstrate the complete computational workflow.

The synthetic dataset:

* does not contain original engineering measurements;
* does not contain original site coordinates, borehole locations, geological geometry, or monitoring records;
* does not contain proprietary finite-element outputs, Abaqus result files, or project-specific generated `.inp` files;
* is not produced by directly anonymizing or rescaling the original confidential dataset;
* uses representative synthetic inputs and responses that are compatible with the public workflow.

The public package supports independent verification of the code structure, algorithms, and end-to-end computational workflow. However, it cannot be used to exactly reproduce the site-specific numerical results presented in the manuscript.

## Repository structure

```text
GeoHydroBayes3D/
|-- README.md
|-- LICENSE
|-- requirements.txt
|-- environment.yml
|-- configs/                          # example YAML configuration files
|-- data/                             # synthetic demonstration data only
|   |-- Final_ML_Dataset.csv
|   `-- README_demo_dataset.md
|-- docs/
|   |-- installation.md
|   |-- workflow.md
|   `-- code_availability_statement.md
|-- examples/
|   `-- minimal_reproduction/
|-- legacy/                           # archived non-confidential compatibility scripts
|-- matlab_random_field_generation/   # generic MATLAB random-field and Abaqus workflow
|-- metadata/
|   |-- data_dictionary.csv
|   `-- code_package_manifest.md
|-- outputs/                          # generated outputs; ignored except README
|-- scripts/                          # command-line workflow scripts
|-- src/
|   `-- hydro_inverse/                # reusable Python package
`-- tests/                            # lightweight integrity tests
```

Only non-confidential source code, synthetic demonstration data, and generic configuration examples are included in this public repository.

## Installation

A clean Python 3.10 or later environment is recommended.

Using Conda:

```bash
conda env create -f environment.yml
conda activate hydro-inverse
pip install -e .
```

Alternatively, using Python virtual environments:

```bash
python -m venv .venv

# Windows
.venv\Scripts\activate

# Linux/macOS
source .venv/bin/activate

pip install -r requirements.txt
pip install -e .
```

Detailed installation instructions are provided in:

```text
docs/installation.md
```

## Quick start

Run the minimal end-to-end demonstration using the synthetic dataset:

```bash
python examples/minimal_reproduction/run_demo.py
```

The demonstration performs the following operations:

1. checks the integrity and expected structure of the synthetic dataset;
2. runs a KD-tree mapping example;
3. trains a compact PA-DNN surrogate when PyTorch is available;
4. generates demonstration sensitivity-analysis outputs;
5. writes all generated results to `outputs/minimal_demo/`.

If PyTorch is unavailable, the demonstration trains a compact Random Forest model as a fallback, allowing the public workflow to be smoke-tested without PyTorch.

Run individual workflow steps:

```bash
python scripts/00_check_dataset.py
python scripts/01_demo_kdtree_mapping.py
python scripts/02_train_padnn.py --epochs 100
python scripts/03_compare_surrogates.py
python scripts/04_run_mcmc_inversion.py --steps 1000
python scripts/05_run_sensitivity_analysis.py
python scripts/06_reproduce_figures.py
```

All generated outputs are written to:

```text
outputs/
```

Run the lightweight integrity tests:

```bash
pytest
```

## Synthetic demonstration data

The main public demonstration dataset is:

```text
data/Final_ML_Dataset.csv
```

The dataset contains six synthetic input parameters:

* `log10_K_Lower`
* `log10_K_Middle`
* `log10_K_Upper`
* `COV`
* `dh`
* `dv`

It also contains 23 synthetic hydraulic-head response columns with identifiers beginning with `zk`.

These identifiers are retained as generic column names required by the public workflow. They do not correspond to publicly disclosed real-world boreholes or monitoring locations.

The values in the public dataset are synthetic and are intended only for:

* software testing;
* demonstration of data-processing procedures;
* surrogate-model training examples;
* verification of Bayesian-inversion scripts;
* sensitivity-analysis demonstrations.

The synthetic dataset must not be interpreted as representing the original engineering site or its measured responses.

Additional information is provided in:

```text
metadata/data_dictionary.csv
data/README_demo_dataset.md
docs/workflow.md
```

## MATLAB random-field workflow

The generic finite-element random-field preparation workflow is provided in:

```text
matlab_random_field_generation/
```

This directory contains non-confidential MATLAB scripts for:

* stratified hydraulic-conductivity random-field generation;
* element-centroid mapping;
* generic Abaqus `.inp` file preparation;
* generated-file verification;
* optional Abaqus batch submission.

Project-specific Abaqus templates, original finite-element meshes, generated simulation inputs, result databases, and confidential engineering files are intentionally excluded from the public repository.

Users who wish to apply the workflow to their own model must provide their own Abaqus template input file, commonly named:

```text
Job-0.inp
```

The public Python demonstration workflow does not require Abaqus.

See the following file for a script-by-script description:

```text
matlab_random_field_generation/README.md
```

## Legacy scripts

The `legacy/` directory contains archived non-confidential scripts retained for methodological traceability and compatibility with the original research workflow.

These scripts are not required to run the minimal public demonstration. No confidential engineering data or proprietary project files should be stored in this directory.

## Code and data availability

The original engineering dataset used in the study cannot be made publicly available because it contains confidential project information and is subject to third-party data-use restrictions.

The source code, synthetic demonstration dataset, example configuration files, and workflow scripts are publicly available in this repository:

```text
https://github.com/rainy-wudi/GeoHydroBayes3D-Code
```

A versioned archive of the public code package will be made available through Zenodo. The final Zenodo DOI should be added here after the corresponding release has been successfully archived.

A manuscript-ready code and data availability statement is also provided in:

```text
docs/code_availability_statement.md
```

## Citation

When using the source code or synthetic demonstration workflow, please cite the associated manuscript and the archived Zenodo release.

A machine-readable citation file is provided in:

```text
CITATION.cff
```

## License

The source code in this repository is released under the MIT License. See:

```text
LICENSE
```

The MIT License applies to the source code only.

The synthetic demonstration dataset is provided solely for software verification, educational use, and demonstration of the public computational workflow. It contains no original engineering measurements or confidential project information.

The original engineering dataset is not included in this repository, is not covered by the MIT License, and remains subject to the applicable confidentiality and third-party data-use restrictions.
