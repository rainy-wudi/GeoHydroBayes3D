import sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / 'src'))

from hydro_inverse.config import load_config, resolve_path
from hydro_inverse.data import load_dataset, get_feature_target_columns
from hydro_inverse.kdtree_mapping import nearest_neighbor_mapping
from hydro_inverse.sensitivity import run_sensitivity
import pandas as pd

cfg = load_config(REPO_ROOT / 'configs/default.yaml')
outdir = resolve_path(cfg['paths']['output_dir']) / 'minimal_demo'
outdir.mkdir(parents=True, exist_ok=True)

print('[1/4] Loading demonstration dataset...')
df = load_dataset(resolve_path(cfg['paths']['dataset']))
x_cols, y_cols = get_feature_target_columns(df, cfg['columns']['input'], cfg['columns']['output_prefix'])
print(f'      {len(df)} samples, {len(x_cols)} inputs, {len(y_cols)} outputs')

print('[2/4] Running KD-tree mapping demo...')
mesh = pd.read_csv(resolve_path(cfg['paths']['mesh_centroids']))
ref = pd.read_csv(resolve_path(cfg['paths']['random_field_reference']))
nearest_neighbor_mapping(mesh, ref).to_csv(outdir / 'kdtree_mapping_demo.csv', index=False)

print('[3/4] Training compact PA-DNN demo model...')
try:
    from hydro_inverse.surrogate_padnn import train_padnn
except ModuleNotFoundError as exc:
    if exc.name != 'torch':
        raise
    from sklearn.ensemble import RandomForestRegressor
    from sklearn.metrics import mean_squared_error, r2_score
    from sklearn.model_selection import train_test_split
    import numpy as np

    print('      PyTorch is not installed; training a small Random Forest fallback.')
    X = df[x_cols].to_numpy(float)
    Y = df[y_cols].to_numpy(float)
    X_train, X_test, Y_train, Y_test = train_test_split(
        X, Y, test_size=0.2, random_state=cfg['random_seed']
    )
    model = RandomForestRegressor(n_estimators=40, random_state=cfg['random_seed'], n_jobs=1)
    model.fit(X_train, Y_train)
    pred = model.predict(X_test)
    metrics = {
        'model': 'RandomForest fallback',
        'r2': float(r2_score(Y_test, pred, multioutput='variance_weighted')),
        'rmse_m': float(np.sqrt(mean_squared_error(Y_test, pred))),
    }
    pd.DataFrame([metrics]).to_csv(outdir / 'fallback_surrogate_metrics.csv', index=False)
    print('      metrics:', metrics)
else:
    result = train_padnn(df, x_cols, y_cols, outdir / 'padnn', epochs=20, random_seed=cfg['random_seed'])
    print('      metrics:', result.metrics)

print('[4/4] Running sensitivity demo...')
run_sensitivity(df, x_cols, y_cols, outdir / 'sensitivity', n=128, random_seed=cfg['random_seed'])
print(f'Done. Outputs are in: {outdir}')
