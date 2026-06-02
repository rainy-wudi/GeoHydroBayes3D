from __future__ import annotations

import numpy as np
import pandas as pd
from scipy.spatial import cKDTree


def nearest_neighbor_mapping(
    query_points: pd.DataFrame,
    reference_points: pd.DataFrame,
    query_xyz=("x_demo_m", "y_demo_m", "z_demo_m"),
    reference_xyz=("x_demo_m", "y_demo_m", "z_demo_m"),
    value_columns=("log10_K_demo", "K_demo_m_per_s"),
) -> pd.DataFrame:
    """Map attributes from reference points to query points using a KD-tree.

    This function is the cleaned, reusable counterpart of the original KD-tree
    unstructured-mesh mapping scripts. It is intentionally independent of any
    commercial finite-element software.
    """
    q = query_points.loc[:, list(query_xyz)].to_numpy(float)
    r = reference_points.loc[:, list(reference_xyz)].to_numpy(float)
    if len(q) == 0 or len(r) == 0:
        raise ValueError("KD-tree mapping requires non-empty query and reference points.")
    tree = cKDTree(r)
    dist, idx = tree.query(q, k=1)
    mapped = query_points.copy()
    mapped["nearest_reference_index"] = idx.astype(int)
    mapped["nearest_distance_m"] = dist
    for col in value_columns:
        if col in reference_points.columns:
            mapped[col] = reference_points.iloc[idx][col].to_numpy()
    return mapped


def assign_layer_priority(mesh: pd.DataFrame, layer_col="layer_id") -> pd.DataFrame:
    """Apply a simple deeper-layer priority rule for interface elements.

    In the anonymized demonstration data, layer labels are already assigned.
    This helper is included to document where the stratum-priority rule is
    applied in the workflow.
    """
    out = mesh.copy()
    if layer_col in out.columns:
        out[layer_col] = out[layer_col].astype(int)
    return out
