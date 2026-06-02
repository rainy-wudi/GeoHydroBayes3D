from __future__ import annotations

from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def save_training_curve(history: pd.DataFrame, path: str | Path):
    path = Path(path)
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.plot(history["epoch"], history["train_loss"], label="Training loss")
    ax.plot(history["epoch"], history["validation_mse_scaled"], label="Validation MSE")
    ax.set_xlabel("Epoch")
    ax.set_ylabel("Scaled loss")
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(path, dpi=300)
    plt.close(fig)


def save_parity_plot(y_true, y_pred, path: str | Path):
    path = Path(path)
    y_true = np.asarray(y_true).ravel()
    y_pred = np.asarray(y_pred).ravel()
    fig, ax = plt.subplots(figsize=(5, 5))
    ax.scatter(y_true, y_pred, s=10, alpha=0.6)
    mn = min(y_true.min(), y_pred.min())
    mx = max(y_true.max(), y_pred.max())
    ax.plot([mn, mx], [mn, mx], linestyle="--", linewidth=1)
    ax.set_xlabel("Reference hydraulic head (m)")
    ax.set_ylabel("Predicted hydraulic head (m)")
    fig.tight_layout()
    fig.savefig(path, dpi=300)
    plt.close(fig)


def save_sensitivity_bar(table: pd.DataFrame, path: str | Path):
    path = Path(path)
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.bar(table["parameter"], table["ST_mean_head"])
    ax.set_ylabel("Total-effect index")
    ax.tick_params(axis="x", rotation=30)
    fig.tight_layout()
    fig.savefig(path, dpi=300)
    plt.close(fig)
