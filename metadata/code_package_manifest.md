# Code package manifest

This revised code package contains:

- Python source package: `src/hydro_inverse/`
- Python command-line reproduction scripts: `scripts/`
- Anonymized demonstration datasets: `data/`
- Minimal public reproduction example: `examples/minimal_reproduction/`
- MATLAB random-field and Abaqus input-file scripts: `matlab_random_field_generation/`
- Documentation and availability statements: `docs/`
- Metadata and data dictionary files: `metadata/`
- Lightweight tests: `tests/`

Large generated Abaqus files and raw confidential engineering files are not included.

## Public-release exclusions

The repository intentionally excludes:

- original site coordinates and raw engineering investigation records;
- proprietary FEM output archives and Abaqus `.odb` files;
- generated Abaqus `.inp`, `.inc`, `.dat`, `.msg`, `.sta`, `.sim`, and related job files;
- local Python caches, test caches, and generated output folders.

The included CSV files are demonstration files for executing and testing the workflow.
