# Computational workflow

## 1. Demonstration dataset

`data/Final_ML_Dataset.csv` is the main machine-learning table. Each row corresponds to one parameter-realization case and contains six input parameters and 23 simulated borehole hydraulic-head responses.

The public dataset is anonymized demonstration data. It does not include the original engineering investigation records, original site coordinates, proprietary finite-element outputs, Abaqus result files, or project-specific generated `.inp` files.

For the shortest reproducible run:

```bash
python examples/minimal_reproduction/run_demo.py
```

## 2. KD-tree mapping

`src/hydro_inverse/kdtree_mapping.py` provides a clean implementation of nearest-neighbor KD-tree mapping for unstructured geoscience mesh centroids. It replaces project-specific scripts with absolute paths and commercial finite-element dependencies.

Run:

```bash
python scripts/01_demo_kdtree_mapping.py
```

## 3. PA-DNN surrogate training

The PA-DNN surrogate maps six geostatistical parameters to 23 borehole hydraulic heads. A weak smoothness penalty is included to demonstrate the physics-enhanced regularization logic.

Run:

```bash
python scripts/02_train_padnn.py --epochs 100
```

## 4. Baseline comparison

Random Forest and Support Vector Regression are trained as benchmark surrogates.

Run:

```bash
python scripts/03_compare_surrogates.py
```

## 5. Bayesian inversion

The trained PA-DNN surrogate is used as a fast likelihood evaluator. The script uses `emcee` when available and otherwise falls back to a built-in random-walk sampler.

Run:

```bash
python scripts/04_run_mcmc_inversion.py --steps 1000
```

## 6. Sensitivity analysis

A Saltelli-style estimator is used to compute first-order and total-effect indices for the spatially averaged hydraulic head.

Run:

```bash
python scripts/05_run_sensitivity_analysis.py
```

## Optional MATLAB random-field and Abaqus input-file workflow

The original random-field generation and Abaqus input-file preparation scripts are provided in `matlab_random_field_generation/`. This workflow is intended for users who want to regenerate stratified hydraulic-conductivity fields and assign permeability values to Abaqus finite elements.

Typical steps are:

1. Prepare an Abaqus template file, commonly named `Job-0.inp`.
2. Edit the sampling ranges, layer elevations, and number of realizations in `matlab_random_field_generation/batch_random_field_full.m`.
3. Run the batch script in MATLAB.
4. Check generated input files using `verify_generated_inp.m` and `diagnose_template_structure.m`.
5. Run the generated Abaqus jobs locally or with the optional `submit_all_jobs.py` helper.

Generated Abaqus input, include, and result files are intentionally excluded from the public repository because they can be large and project-specific.
