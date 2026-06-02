from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import json
import numpy as np
import pandas as pd
import torch
# Limit CPU threading to make the demo stable on shared review machines.
torch.set_num_threads(1)
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
from sklearn.metrics import r2_score, mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import joblib


class PADNN(nn.Module):
    """Physics-enhanced multi-output neural surrogate for borehole heads."""

    def __init__(self, input_dim: int, output_dim: int, hidden_layers=(128, 256, 128), dropout=0.1):
        super().__init__()
        layers = []
        last = input_dim
        for width in hidden_layers:
            layers += [nn.Linear(last, width), nn.BatchNorm1d(width), nn.ReLU(), nn.Dropout(dropout)]
            last = width
        layers.append(nn.Linear(last, output_dim))
        self.net = nn.Sequential(*layers)

    def forward(self, x):
        return self.net(x)


def weak_gradient_penalty(y_pred: torch.Tensor) -> torch.Tensor:
    """Weak smoothness penalty between adjacent borehole outputs.

    The public dataset does not include the full FEM field; therefore this term
    acts as a lightweight analogue of the weak-form physical regularization used
    in the manuscript.
    """
    if y_pred.shape[1] < 2:
        return torch.tensor(0.0, device=y_pred.device)
    diffs = y_pred[:, 1:] - y_pred[:, :-1]
    return torch.mean(diffs**2)


@dataclass
class TrainResult:
    model: PADNN
    scaler_x: StandardScaler
    scaler_y: StandardScaler
    history: pd.DataFrame
    metrics: dict
    y_columns: list[str]


def train_padnn(
    df: pd.DataFrame,
    x_cols: list[str],
    y_cols: list[str],
    output_dir: str | Path,
    epochs: int = 100,
    batch_size: int = 32,
    learning_rate: float = 1e-3,
    physical_loss_weight: float = 0.1,
    test_size: float = 0.2,
    random_seed: int = 42,
    hidden_layers=(128, 256, 128),
    dropout: float = 0.1,
    device: str | None = None,
) -> TrainResult:
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(random_seed)
    torch.manual_seed(random_seed)

    X = df[x_cols].to_numpy(float)
    Y = df[y_cols].to_numpy(float)
    X_train, X_test, Y_train, Y_test = train_test_split(
        X, Y, test_size=test_size, random_state=random_seed
    )

    scaler_x = StandardScaler().fit(X_train)
    scaler_y = StandardScaler().fit(Y_train)
    X_train_s = scaler_x.transform(X_train)
    X_test_s = scaler_x.transform(X_test)
    Y_train_s = scaler_y.transform(Y_train)
    Y_test_s = scaler_y.transform(Y_test)

    device = device or ("cuda" if torch.cuda.is_available() else "cpu")
    model = PADNN(len(x_cols), len(y_cols), hidden_layers=hidden_layers, dropout=dropout).to(device)
    opt = torch.optim.Adam(model.parameters(), lr=learning_rate)
    mse = nn.MSELoss()

    loader = DataLoader(
        TensorDataset(torch.tensor(X_train_s, dtype=torch.float32), torch.tensor(Y_train_s, dtype=torch.float32)),
        batch_size=batch_size,
        shuffle=True,
    )

    history = []
    for epoch in range(1, epochs + 1):
        model.train()
        train_losses = []
        for xb, yb in loader:
            xb, yb = xb.to(device), yb.to(device)
            opt.zero_grad()
            pred = model(xb)
            loss_data = mse(pred, yb)
            loss_phys = weak_gradient_penalty(pred)
            loss = loss_data + physical_loss_weight * loss_phys
            loss.backward()
            opt.step()
            train_losses.append(float(loss.detach().cpu()))

        model.eval()
        with torch.no_grad():
            val_pred = model(torch.tensor(X_test_s, dtype=torch.float32, device=device)).cpu().numpy()
            val_mse = float(np.mean((val_pred - Y_test_s) ** 2))
        history.append({"epoch": epoch, "train_loss": float(np.mean(train_losses)), "validation_mse_scaled": val_mse})

    model.eval()
    with torch.no_grad():
        pred_scaled = model(torch.tensor(X_test_s, dtype=torch.float32, device=device)).cpu().numpy()
    y_pred = scaler_y.inverse_transform(pred_scaled)
    metrics = {
        "r2": float(r2_score(Y_test, y_pred, multioutput="variance_weighted")),
        "rmse_m": float(np.sqrt(mean_squared_error(Y_test, y_pred))),
        "n_train": int(len(X_train)),
        "n_test": int(len(X_test)),
        "epochs": int(epochs),
        "device": device,
    }

    torch.save({"state_dict": model.state_dict(), "input_dim": len(x_cols), "output_dim": len(y_cols),
                "hidden_layers": list(hidden_layers), "dropout": dropout, "x_cols": x_cols, "y_cols": y_cols},
               output_dir / "padnn_model.pt")
    joblib.dump({"scaler_x": scaler_x, "scaler_y": scaler_y}, output_dir / "padnn_scalers.joblib")
    pd.DataFrame(history).to_csv(output_dir / "padnn_training_history.csv", index=False)
    (output_dir / "padnn_metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    return TrainResult(model, scaler_x, scaler_y, pd.DataFrame(history), metrics, y_cols)


def load_padnn(model_dir: str | Path, device: str | None = None):
    model_dir = Path(model_dir)
    device = device or ("cuda" if torch.cuda.is_available() else "cpu")
    ckpt = torch.load(model_dir / "padnn_model.pt", map_location=device)
    model = PADNN(ckpt["input_dim"], ckpt["output_dim"], tuple(ckpt["hidden_layers"]), ckpt.get("dropout", 0.1)).to(device)
    model.load_state_dict(ckpt["state_dict"])
    model.eval()
    scalers = joblib.load(model_dir / "padnn_scalers.joblib")
    return model, scalers["scaler_x"], scalers["scaler_y"], ckpt["x_cols"], ckpt["y_cols"]


def predict_padnn(model: PADNN, scaler_x: StandardScaler, scaler_y: StandardScaler, X, device: str | None = None):
    device = device or ("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)
    model.eval()
    X_s = scaler_x.transform(np.asarray(X, dtype=float))
    with torch.no_grad():
        pred_s = model(torch.tensor(X_s, dtype=torch.float32, device=device)).cpu().numpy()
    return scaler_y.inverse_transform(pred_s)
