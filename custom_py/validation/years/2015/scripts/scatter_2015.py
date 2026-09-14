# Point-by-point obs-vs-model scatter for 2015 (1991-style; map-plot composite
# sources; day/depth-matched). Thin wrapper over common/lib/scatter_modern.py.
import os, runpy
from pathlib import Path

_default = '2015B' if os.environ.get('MODEL_VER', '1.8.0').startswith('1.8') else ('2015A' if '2015' in ('2013', '2015') else '2015B')
os.environ.setdefault('TRANSECT_SIM', _default)
os.environ.setdefault('MODEL_VER', '1.8.0')
runpy.run_path(str(Path(__file__).resolve().parents[3] / 'common' / 'lib' / 'scatter_modern.py'), run_name='__main__')
