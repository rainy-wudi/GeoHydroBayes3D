# MATLAB random-field generation and Abaqus input-file workflow

This directory contains the MATLAB scripts used for stratified hydraulic-conductivity random-field generation and Abaqus input-file preparation. The scripts complement the cleaned Python workflow in `src/hydro_inverse/`.

## Main scripts

- `batch_random_field_full.m`: main batch workflow for Latin Hypercube Sampling, stratified random-field generation, and Abaqus `.inp` generation.
- `compute_element_centers.m`: computes element centroid coordinates from parsed Abaqus nodes and elements.
- `diagnose_template_structure.m`: inspects an Abaqus template to help locate mesh, material, and step sections before generation.
- `export_jobs_summary.m`: exports summary information for generated job batches.
- `generate_abaqus_submit_script_schemeC.m`: creates an Abaqus submission script for a generated batch.
- `generate_stratified_random_field_full.m`: generates stratified 3D random fields with horizontal and vertical correlation lengths.
- `generate_random_field_optimized.m`: optimized random-field generation routine.
- `generate_inp_full_mapping.m`: writes full element-wise permeability mappings to Abaqus input files, optionally using INCLUDE files.
- `generate_inp_simple_structure.m`: prepares a simple demonstration input structure for quick local checks.
- `generate_inp_with_permeability_optimized.m`: writes binned permeability assignments to Abaqus input files.
- `read_inp_mesh.m` and `read_inp_mesh_fast.m`: parse Abaqus mesh nodes and elements.
- `lhsdesign_with_bounds.m`: Latin Hypercube Sampling helper with a built-in fallback implementation.
- `patchrandom.m`: helper for drawing or patching random-field visualization outputs.
- `quick_test_inp_generation.m`: quick local smoke test for input-file generation logic.
- `random_view.m`: visualization helper for inspecting generated random fields.
- `test.m` and `test_inp_generation_auto.m`: local test scripts for MATLAB workflow checks.
- `verify_generated_inp.m`: utility for checking generated Abaqus files.
- `visualize_parameter_samples.m`: plots sampled parameter sets from the LHS workflow.
- `submit_all_jobs.py`: auxiliary Python script for batch Abaqus job submission.

## Required software

- MATLAB. The Statistics and Machine Learning Toolbox is recommended for Latin Hypercube Sampling. If it is unavailable, `lhsdesign_with_bounds.m` provides a simplified fallback.
- The Parallel Computing Toolbox is optional and can accelerate batch generation.
- Abaqus is required only to run the generated `.inp` files.
- Python 3 is required only for the optional Abaqus batch-submission helper script.

## Usage

1. Place an Abaqus template input file in the working directory. The default name used by the batch script is `Job-0.inp`.
2. Edit the parameter bounds, layer elevations, number of parameter samples, and number of realizations in `batch_random_field_full.m`.
3. Run the main workflow in MATLAB:

```matlab
batch_random_field_full
```

The generated Abaqus input files and metadata will be written to `RandomField_Full/` by default.

## Public-release notes

Large generated Abaqus files (`.inp`, `.inc`, `.odb`, `.dat`, `.msg`, `.sta`, `.sim`) and local project-specific templates are not included in this source-code package. Users should provide their own Abaqus template file and regenerate the random-field inputs from the scripts.
