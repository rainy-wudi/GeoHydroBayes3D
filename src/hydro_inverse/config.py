from pathlib import Path
import yaml


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def load_config(config_path="configs/default.yaml") -> dict:
    path = Path(config_path)
    if not path.is_absolute():
        path = repo_root() / path
    with path.open("r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    return cfg


def resolve_path(path_like) -> Path:
    path = Path(path_like)
    return path if path.is_absolute() else repo_root() / path
