from __future__ import annotations

from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline


def train_fast_surrogate(df: pd.DataFrame, x_cols: list[str], y_cols: list[str], random_seed=42):
    X = df[x_cols].to_numpy(float)
    y = df[y_cols].to_numpy(float).mean(axis=1)
    model = make_pipeline(StandardScaler(), RandomForestRegressor(n_estimators=150, random_state=random_seed, n_jobs=1))
    model.fit(X, y)
    return model


def saltelli_first_total_indices(predict_fn, bounds: np.ndarray, n: int = 512, random_seed=42):
    """Estimate first-order and total-effect indices for scalar model output.

    This lightweight implementation is used for the public demonstration dataset.
    The output is the spatially averaged hydraulic head predicted by a surrogate.
    """
    rng = np.random.default_rng(random_seed)
    d = bounds.shape[0]
    lo, hi = bounds[:, 0], bounds[:, 1]
    A = lo + (hi - lo) * rng.random((n, d))
    B = lo + (hi - lo) * rng.random((n, d))
    YA = np.asarray(predict_fn(A), dtype=float).reshape(-1)
    YB = np.asarray(predict_fn(B), dtype=float).reshape(-1)
    V = np.var(np.concatenate([YA, YB]), ddof=1)
    if V <= 0:
        raise ValueError("Model output variance is zero; sensitivity indices cannot be estimated.")
    S1, ST = [], []
    for i in range(d):
        ABi = A.copy()
        ABi[:, i] = B[:, i]
        YABi = np.asarray(predict_fn(ABi), dtype=float).reshape(-1)
        s1_val = float(np.mean((YB - np.mean(YB)) * (YABi - YA)) / V)
        st_val = float(0.5 * np.mean((YA - YABi) ** 2) / V)
        S1.append(max(0.0, s1_val))
        ST.append(max(0.0, st_val))
    return np.array(S1), np.array(ST)


def run_sensitivity(df: pd.DataFrame, x_cols: list[str], y_cols: list[str], output_dir: str | Path, n=512, random_seed=42):
    from .mcmc_inversion import uniform_bounds_from_data
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    model = train_fast_surrogate(df, x_cols, y_cols, random_seed=random_seed)
    bounds = uniform_bounds_from_data(df, x_cols, pad_fraction=0.0)
    predict_fn = lambda X: model.predict(X)
    s1, st = saltelli_first_total_indices(predict_fn, bounds, n=n, random_seed=random_seed)
    table = pd.DataFrame({"parameter": x_cols, "S1_mean_head": s1, "ST_mean_head": st})
    table.to_csv(output_dir / "sensitivity_indices.csv", index=False)
    return table
