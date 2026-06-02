# Demonstration dataset for surrogate-assisted Bayesian hydraulic inversion

This folder contains an anonymized demonstration dataset prepared for the Computers & Geosciences submission code repository.

## Important note

The public repository does **not** include complete proprietary FEM simulation outputs, Abaqus ODB files, project-specific generated `.inp` files, `metadata.mat`, raw investigation records, or original site coordinates. The demonstration files preserve the computational schema, parameter ranges, borehole count, and response structure needed to verify code execution. They are intended to reproduce the workflow, not to disclose the confidential engineering dataset.

## What was anonymized

- Absolute site coordinates are not provided in this package.
- Demonstration coordinates use anonymized/local model coordinates suitable for testing KD-tree mapping and plotting.
- Hydraulic heads are provided in a model datum, using the same -50.6 m reference shift used in the supplied MCMC script.
- A mean-shifted public head level is also provided for visualization.
- `Final_ML_Dataset.csv` contains generated demonstration heads consistent with the published workflow schema and parameter bounds; these are not raw Abaqus/FEM outputs.

## Main files

- `data/Final_ML_Dataset.csv`: 1000-row PA-DNN training/demo matrix with 6 inputs and 23 hydraulic-head outputs.
- `data/parameters.csv`: long parameter table with 50 parameter groups and 20 realizations per group.
- `data/unique_parameters.csv`: 50 unique macroscopic parameter combinations.
- `data/borehole_data.csv`: long-format borehole hydraulic-head table compatible with the preprocessing script.
- `data/borehole_observations.csv`: anonymized borehole locations and field-observation-derived heads.
- `data/mesh_centroids_demo.csv`: anonymized synthetic unstructured mesh centroids for KD-tree mapping demonstrations.
- `data/random_field_example.csv`: one mapped random-field example over the demonstration mesh.
- `data/posterior_validation_heads.csv`: measured/calculated heads for quick verification-figure reproduction.
- `metadata/data_dictionary.csv`: field definitions.
- `metadata/demo_config.yaml`: parameter bounds and anonymization metadata.

## Compatibility with your current scripts

The output columns are kept as `zk*` names so that your existing scripts using

```python
Y_cols = [col for col in df.columns if col.startswith('zk')]
```

can run with minimal changes. For a public repository, you can later rename these to `BH01`--`BH23` and update the detection rule accordingly.

## Suggested citation in manuscript/code availability

The source code and anonymized demonstration dataset used to reproduce the computational workflow are available at the project repository. The demonstration dataset preserves the statistical structure and input/output schema of the study but does not contain the complete confidential engineering FEM database.
