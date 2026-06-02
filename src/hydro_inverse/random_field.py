from __future__ import annotations

import numpy as np
import pandas as pd
from scipy.spatial import cKDTree


def lognormal_parameters(mean: float, cov: float) -> tuple[float, float]:
    """Return log-space mean and standard deviation for a lognormal variable."""
    if mean <= 0:
        raise ValueError("mean must be positive")
    if cov < 0:
        raise ValueError("coefficient of variation must be non-negative")
    sigma2 = np.log1p(cov**2)
    mu = np.log(mean) - 0.5 * sigma2
    return float(mu), float(np.sqrt(sigma2))


def generate_demo_random_field(
    mesh: pd.DataFrame,
    log10_k_by_layer: dict[int, float] | None = None,
    cov: float = 0.5,
    seed: int = 42,
    smooth_k: int = 16,
) -> pd.DataFrame:
    """Generate a lightweight spatially smoothed demonstration random field.

    The manuscript uses finite-element simulations and stochastic random fields.
    This public function reproduces the data structure and spatial mapping logic
    without releasing proprietary finite-element files.
    """
    rng = np.random.default_rng(seed)
    if log10_k_by_layer is None:
        log10_k_by_layer = {1: -6.9, 2: -7.6, 3: -8.6}
    coords = mesh[["x_demo_m", "y_demo_m", "z_demo_m"]].to_numpy(float)
    tree = cKDTree(coords)
    noise = rng.normal(0.0, cov * 0.10, size=len(mesh))
    _, neigh = tree.query(coords, k=min(smooth_k, len(mesh)))
    smoothed = noise[neigh].mean(axis=1)
    out = mesh.copy()
    base = np.array([log10_k_by_layer.get(int(layer), -7.5) for layer in out["layer_id"]])
    out["log10_K_demo"] = base + smoothed
    out["K_demo_m_per_s"] = 10 ** out["log10_K_demo"]
    return out
