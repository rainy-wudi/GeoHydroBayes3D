import sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / 'src'))

from hydro_inverse.config import load_config, resolve_path
from hydro_inverse.data import load_dataset, get_feature_target_columns
from hydro_inverse.surrogate_baselines import compare_baselines

cfg = load_config()
df = load_dataset(resolve_path(cfg['paths']['dataset']))
x_cols, y_cols = get_feature_target_columns(df, cfg['columns']['input'], cfg['columns']['output_prefix'])
outdir = resolve_path(cfg['paths']['output_dir']) / 'baselines'
table = compare_baselines(df, x_cols, y_cols, outdir, random_seed=cfg['random_seed'])
print(table.to_string(index=False))
