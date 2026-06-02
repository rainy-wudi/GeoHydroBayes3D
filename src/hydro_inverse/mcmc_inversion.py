from __future__ import annotations

from pathlib import Path
import json
import numpy as np
import pandas as pd

try:
    import emcee  # type: ignore
except Exception:  # pragma: no cover
    emcee = None


def uniform_bounds_from_data(df: pd.DataFrame, x_cols: list[str], pad_fraction=0.02) -> np.ndarray:
    vals = df[x_cols].to_numpy(float)
    lo = vals.min(axis=0)
    hi = vals.max(axis=0)
    pad = (hi - lo) * pad_fraction
    return np.column_stack([lo - pad, hi + pad])


def log_prior(theta: np.ndarray, bounds: np.ndarray) -> float:
    theta = np.asarray(theta)
    if np.all((theta >= bounds[:, 0]) & (theta <= bounds[:, 1])):
        return 0.0
    return -np.inf


def log_likelihood(theta: np.ndarray, predict_fn, y_obs: np.ndarray, sigma_m=2.0) -> float:
    pred = np.asarray(predict_fn(np.asarray(theta)[None, :]))[0]
    residual = (pred - y_obs) / sigma_m
    return float(-0.5 * np.sum(residual**2 + np.log(2 * np.pi * sigma_m**2)))


def log_posterior(theta: np.ndarray, bounds: np.ndarray, predict_fn, y_obs: np.ndarray, sigma_m=2.0) -> float:
    lp = log_prior(theta, bounds)
    if not np.isfinite(lp):
        return -np.inf
    return lp + log_likelihood(theta, predict_fn, y_obs, sigma_m=sigma_m)


def run_inversion(
    predict_fn,
    y_obs: np.ndarray,
    bounds: np.ndarray,
    output_dir: str | Path,
    walkers: int = 24,
    steps: int = 1000,
    burn_in: int = 200,
    sigma_m: float = 2.0,
    proposal_scale: float = 0.03,
    random_seed: int = 42,
) -> dict:
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(random_seed)
    ndim = bounds.shape[0]
    center = bounds.mean(axis=1)
    width = bounds[:, 1] - bounds[:, 0]
    initial = center + 0.05 * width * rng.normal(size=(walkers, ndim))
    initial = np.clip(initial, bounds[:, 0], bounds[:, 1])

    if emcee is not None:
        sampler = emcee.EnsembleSampler(
            walkers,
            ndim,
            lambda th: log_posterior(th, bounds, predict_fn, y_obs, sigma_m=sigma_m),
        )
        sampler.run_mcmc(initial, steps, progress=False)
        chain = sampler.get_chain()
        log_prob = sampler.get_log_prob()
    else:
        chain = np.zeros((steps, walkers, ndim), dtype=float)
        log_prob = np.zeros((steps, walkers), dtype=float)
        current = initial.copy()
        current_lp = np.array([log_posterior(th, bounds, predict_fn, y_obs, sigma_m=sigma_m) for th in current])
        step_scale = proposal_scale * width
        for s in range(steps):
            for w in range(walkers):
                proposal = current[w] + rng.normal(scale=step_scale, size=ndim)
                prop_lp = log_posterior(proposal, bounds, predict_fn, y_obs, sigma_m=sigma_m)
                if np.log(rng.random()) < prop_lp - current_lp[w]:
                    current[w] = proposal
                    current_lp[w] = prop_lp
            chain[s] = current
            log_prob[s] = current_lp

    flat = chain[burn_in:].reshape(-1, ndim)
    flat_lp = log_prob[burn_in:].reshape(-1)
    best = flat[np.argmax(flat_lp)]
    summary = {
        "posterior_mean": flat.mean(axis=0).tolist(),
        "posterior_std": flat.std(axis=0).tolist(),
        "posterior_p05": np.percentile(flat, 5, axis=0).tolist(),
        "posterior_p50": np.percentile(flat, 50, axis=0).tolist(),
        "posterior_p95": np.percentile(flat, 95, axis=0).tolist(),
        "map_estimate": best.tolist(),
        "n_samples_after_burn_in": int(flat.shape[0]),
        "sampler": "emcee.EnsembleSampler" if emcee is not None else "fallback_random_walk",
    }
    np.save(output_dir / "mcmc_chain.npy", chain)
    pd.DataFrame(flat, columns=[f"theta_{i+1}" for i in range(ndim)]).to_csv(output_dir / "mcmc_posterior_samples.csv", index=False)
    (output_dir / "mcmc_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary
