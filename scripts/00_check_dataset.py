import sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / 'src'))

import json
from hydro_inverse.config import load_config, resolve_path
from hydro_inverse.data import load_dataset, get_feature_target_columns, load_borehole_observations

cfg = load_config()
df = load_dataset(resolve_path(cfg['paths']['dataset']))
x_cols, y_cols = get_feature_target_columns(df, cfg['columns']['input'], cfg['columns']['output_prefix'])
obs = load_borehole_observations(resolve_path(cfg['paths']['borehole_observations']))
summary = {
    'dataset_rows': len(df),
    'dataset_columns': len(df.columns),
    'input_columns': x_cols,
    'n_outputs': len(y_cols),
    'output_columns': y_cols,
    'n_boreholes_observed': len(obs),
    'head_min_m': float(df[y_cols].min().min()),
    'head_max_m': float(df[y_cols].max().max()),
}
outdir = resolve_path(cfg['paths']['output_dir'])
outdir.mkdir(exist_ok=True)
(outdir / 'dataset_check.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps(summary, indent=2))
