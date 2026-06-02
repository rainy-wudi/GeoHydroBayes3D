# Mapping from original scripts to cleaned repository components

The submitted working folder contained project-specific scripts with local Windows paths and commercial finite-element dependencies. For public release, the workflow has been reorganized into reusable Python modules and a cleaned MATLAB random-field generation folder.

| Original script category | Representative original files | Cleaned repository location |
|---|---|---|
| LHS parameter sampling and data preparation | `LHS_cube.py`, `Data_Prepare.py`, `step1_preprocessing_grouped.py` | `data/Final_ML_Dataset.csv`, `src/hydro_inverse/data.py` |
| MATLAB random-field generation | `generate_random_field_optimized.m`, `batch_random_field_full.m`, `generate_stratified_random_field_full.m` | `matlab_random_field_generation/`, `src/hydro_inverse/random_field.py` |
| Abaqus input-file generation and permeability assignment | `generate_inp_full_mapping.m`, `generate_inp_with_permeability_optimized.m`, `read_inp_mesh_fast.m` | `matlab_random_field_generation/`, `src/hydro_inverse/kdtree_mapping.py`, `scripts/01_demo_kdtree_mapping.py` |
| KD-tree / unstructured mesh mapping | `generate_inp_with_permeability_optimized.m`, `read_inp_mesh_fast.m` | `src/hydro_inverse/kdtree_mapping.py`, `scripts/01_demo_kdtree_mapping.py` |
| PA-DNN training | `Train_PA_DNN.py`, `step2_train_grouped.py` | `src/hydro_inverse/surrogate_padnn.py`, `scripts/02_train_padnn.py` |
| RF/SVR baseline comparison | `Train_PADNN_SVR_RF.py`, `Train_SVR_RF_DNN.py` | `src/hydro_inverse/surrogate_baselines.py`, `scripts/03_compare_surrogates.py` |
| MCMC inversion | `MCMC_PADNN_Inversion.py`, `MCMC_Inversion.py`, `run_mcmc.py` | `src/hydro_inverse/mcmc_inversion.py`, `scripts/04_run_mcmc_inversion.py` |
| Sensitivity analysis | `Sobol_Sensitivity.py`, `Sobol_Sensitivity_Analysis.py` | `src/hydro_inverse/sensitivity.py`, `scripts/05_run_sensitivity_analysis.py` |
| Figure generation | multiple `plot_*.py` scripts | `src/hydro_inverse/plotting.py`, `scripts/06_reproduce_figures.py` |

The MATLAB scripts are included to document the original random-field and Abaqus input-file generation workflow. Large generated Abaqus files and local project-specific templates are intentionally excluded from the public source-code package.
