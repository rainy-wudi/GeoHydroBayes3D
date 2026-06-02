import sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / 'src'))

import argparse
from hydro_inverse.config import load_config, resolve_path
from hydro_inverse.data import load_dataset, get_feature_target_columns
from hydro_inverse.surrogate_padnn import train_padnn
from hydro_inverse.plotting import save_training_curve

parser = argparse.ArgumentParser()
parser.add_argument('--epochs', type=int, default=None)
args = parser.parse_args()

cfg = load_config()
df = load_dataset(resolve_path(cfg['paths']['dataset']))
x_cols, y_cols = get_feature_target_columns(df, cfg['columns']['input'], cfg['columns']['output_prefix'])
outdir = resolve_path(cfg['paths']['output_dir']) / 'padnn'
tr = cfg['training']
result = train_padnn(
    df, x_cols, y_cols, outdir,
    epochs=args.epochs or tr['epochs'],
    batch_size=tr['batch_size'],
    learning_rate=tr['learning_rate'],
    physical_loss_weight=tr['physical_loss_weight'],
    test_size=tr['test_size'],
    random_seed=cfg['random_seed'],
    hidden_layers=tuple(tr['hidden_layers']),
    dropout=tr['dropout'],
)
save_training_curve(result.history, outdir / 'padnn_training_curve.png')
print('PA-DNN metrics:', result.metrics)
print(f'Saved model in: {outdir}')
