import sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / 'src'))

import argparse
import json
from pathlib import Path
import numpy as np
from hydro_inverse.config import load_config, resolve_path
from hydro_inverse.data import load_dataset, get_feature_target_columns, load_borehole_observations, observations_in_model_order
from hydro_inverse.surrogate_padnn import load_padnn, train_padnn, predict_padnn
from hydro_inverse.mcmc_inversion import uniform_bounds_from_data, run_inversion

parser = argparse.ArgumentParser()
parser.add_argument('--steps', type=int, default=None)
parser.add_argument('--ensure-model-epochs', type=int, default=60)
args = parser.parse_args()

cfg = load_config()
df = load_dataset(resolve_path(cfg['paths']['dataset']))
x_cols, y_cols = get_feature_target_columns(df, cfg['columns']['input'], cfg['columns']['output_prefix'])
model_dir = resolve_path(cfg['paths']['output_dir']) / 'padnn'
if not (model_dir / 'padnn_model.pt').exists():
    print('PA-DNN model not found; training a compact model for inversion demo...')
    train_padnn(df, x_cols, y_cols, model_dir, epochs=args.ensure_model_epochs, random_seed=cfg['random_seed'])
model, sx, sy, x_cols_loaded, y_cols_loaded = load_padnn(model_dir)
obs = load_borehole_observations(resolve_path(cfg['paths']['borehole_observations']))
y_obs = np.array(observations_in_model_order(obs, y_cols_loaded), dtype=float)
bounds = uniform_bounds_from_data(df, x_cols_loaded)
predict_fn = lambda X: predict_padnn(model, sx, sy, X)
outdir = resolve_path(cfg['paths']['output_dir']) / 'mcmc'
mc = cfg['mcmc']
summary = run_inversion(
    predict_fn, y_obs, bounds, outdir,
    walkers=mc['walkers'], steps=args.steps or mc['steps'], burn_in=min(mc['burn_in'], (args.steps or mc['steps'])//3),
    sigma_m=mc['observation_sigma_m'], proposal_scale=mc['proposal_scale'], random_seed=cfg['random_seed'],
)
# Human-readable version with parameter names.
named = {name: val for name, val in zip(x_cols_loaded, summary['posterior_p50'])}
(outdir / 'mcmc_median_named.json').write_text(json.dumps(named, indent=2), encoding='utf-8')
print(json.dumps(named, indent=2))
print(f'Saved MCMC outputs in: {outdir}')
