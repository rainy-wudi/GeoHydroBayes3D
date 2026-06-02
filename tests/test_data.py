from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))
from hydro_inverse.data import load_dataset, get_feature_target_columns


def test_dataset_schema():
    df = load_dataset(Path(__file__).resolve().parents[1] / 'data' / 'Final_ML_Dataset.csv')
    x_cols, y_cols = get_feature_target_columns(df)
    assert len(x_cols) == 6
    assert len(y_cols) == 23
    assert len(df) >= 100
