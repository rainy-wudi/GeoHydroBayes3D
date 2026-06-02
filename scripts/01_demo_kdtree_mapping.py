import sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / 'src'))

from hydro_inverse.config import load_config, resolve_path
from hydro_inverse.kdtree_mapping import nearest_neighbor_mapping
import pandas as pd

cfg = load_config()
mesh = pd.read_csv(resolve_path(cfg['paths']['mesh_centroids']))
reference = pd.read_csv(resolve_path(cfg['paths']['random_field_reference']))
outdir = resolve_path(cfg['paths']['output_dir']) / 'kdtree_mapping'
outdir.mkdir(parents=True, exist_ok=True)
mapped = nearest_neighbor_mapping(mesh, reference)
mapped.to_csv(outdir / 'kdtree_mapped_field.csv', index=False)
print(f'Saved: {outdir / "kdtree_mapped_field.csv"}')
print(mapped[['element_id', 'nearest_distance_m', 'log10_K_demo']].head().to_string(index=False))
