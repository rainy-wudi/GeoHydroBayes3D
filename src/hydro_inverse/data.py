from __future__ import annotations

from pathlib import Path
from typing import Iterable, Tuple
import pandas as pd

DEFAULT_INPUT_COLUMNS = [
    "log10_K_Lower",
    "log10_K_Middle",
    "log10_K_Upper",
    "COV",
    "dh",
    "dv",
]


def load_dataset(path: str | Path) -> pd.DataFrame:
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"Dataset not found: {path}")
    df = pd.read_csv(path)
    if df.empty:
        raise ValueError(f"Dataset is empty: {path}")
    return df


def get_feature_target_columns(
    df: pd.DataFrame,
    input_columns: Iterable[str] = DEFAULT_INPUT_COLUMNS,
    output_prefix: str = "zk",
) -> Tuple[list[str], list[str]]:
    x_cols = list(input_columns)
    missing = [c for c in x_cols if c not in df.columns]
    if missing:
        raise ValueError(f"Missing input columns: {missing}")
    y_cols = [c for c in df.columns if c.lower().startswith(output_prefix.lower())]
    if not y_cols:
        raise ValueError(f"No output columns found with prefix: {output_prefix}")
    return x_cols, y_cols


def load_borehole_observations(path: str | Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    required = {"borehole_id", "model_column", "observed_head_model_datum_m"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"Missing borehole-observation columns: {sorted(missing)}")
    return df


def observations_in_model_order(obs: pd.DataFrame, y_cols: list[str], value_col="observed_head_model_datum_m"):
    lookup = dict(zip(obs["model_column"].astype(str), obs[value_col]))
    missing = [c for c in y_cols if c not in lookup]
    if missing:
        raise ValueError(f"Observation file does not contain all model columns. Missing: {missing}")
    return [float(lookup[c]) for c in y_cols]
