from pathlib import Path
import sys
import pandas as pd
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))
from hydro_inverse.kdtree_mapping import nearest_neighbor_mapping


def test_kdtree_mapping_shape():
    root = Path(__file__).resolve().parents[1]
    mesh = pd.read_csv(root / 'data' / 'mesh_centroids_demo.csv').head(10)
    ref = pd.read_csv(root / 'data' / 'random_field_example.csv').head(50)
    mapped = nearest_neighbor_mapping(mesh, ref)
    assert len(mapped) == 10
    assert 'nearest_distance_m' in mapped.columns
    assert 'log10_K_demo' in mapped.columns
