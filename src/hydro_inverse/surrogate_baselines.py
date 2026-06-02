from __future__ import annotations

from pathlib import Path
import json
import time
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.svm import SVR
from sklearn.metrics import r2_score, mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import joblib


def compare_baselines(df: pd.DataFrame, x_cols: list[str], y_cols: list[str], output_dir: str | Path, random_seed=42, max_svr_samples=500):
    """Train RF and SVR baseline surrogates on the demonstration dataset.

    The original study used full engineering runs. For public demonstration, SVR
    is capped at a moderate sample count so that reviewers can run the script on
    ordinary laptops.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    X = df[x_cols].to_numpy(float)
    Y = df[y_cols].to_numpy(float)
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2, random_state=random_seed)
    sx = StandardScaler().fit(X_train)
    sy = StandardScaler().fit(Y_train)
    Xtr, Xte = sx.transform(X_train), sx.transform(X_test)
    Ytr, Yte = sy.transform(Y_train), sy.transform(Y_test)

    rng = np.random.default_rng(random_seed)
    if len(Xtr) > max_svr_samples:
        idx = rng.choice(len(Xtr), size=max_svr_samples, replace=False)
        Xtr_svr, Ytr_svr = Xtr[idx], Ytr[idx]
    else:
        Xtr_svr, Ytr_svr = Xtr, Ytr

    models = {
        "RandomForest": (RandomForestRegressor(n_estimators=80, random_state=random_seed, n_jobs=1), Xtr, Ytr),
        "SVR": (MultiOutputRegressor(SVR(C=5.0, gamma="scale", epsilon=0.03, cache_size=200)), Xtr_svr, Ytr_svr),
    }
    rows = []
    for name, (model, xfit, yfit) in models.items():
        t0 = time.perf_counter()
        model.fit(xfit, yfit)
        fit_s = time.perf_counter() - t0
        pred = sy.inverse_transform(model.predict(Xte))
        r2 = r2_score(Y_test, pred, multioutput="variance_weighted")
        rmse = np.sqrt(mean_squared_error(Y_test, pred))
        X_eval = np.repeat(Xte[: min(100, len(Xte))], 100, axis=0)  # 10,000 evaluations
        t0 = time.perf_counter()
        _ = model.predict(X_eval)
        eval_s = time.perf_counter() - t0
        rows.append({"model": name, "r2": float(r2), "rmse_m": float(rmse), "fit_seconds": float(fit_s), "time_for_10k_eval_s": float(eval_s)})
        joblib.dump({"model": model, "scaler_x": sx, "scaler_y": sy, "x_cols": x_cols, "y_cols": y_cols}, output_dir / f"{name.lower()}_model.joblib")
    table = pd.DataFrame(rows)
    table.to_csv(output_dir / "baseline_comparison.csv", index=False)
    (output_dir / "baseline_comparison.json").write_text(json.dumps(rows, indent=2), encoding="utf-8")
    return table
