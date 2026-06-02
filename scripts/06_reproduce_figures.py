import sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / 'src'))

from pathlib import Path
import subprocess, sys

scripts = [
    '01_demo_kdtree_mapping.py',
    '02_train_padnn.py',
    '03_compare_surrogates.py',
    '05_run_sensitivity_analysis.py',
]
for s in scripts:
    cmd = [sys.executable, str(Path(__file__).resolve().parent / s)]
    if s == '02_train_padnn.py':
        cmd += ['--epochs', '60']
    print('Running:', ' '.join(cmd))
    subprocess.check_call(cmd)
print('Reproduction scripts completed. Check the outputs/ directory.')
