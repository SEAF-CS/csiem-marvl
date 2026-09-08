# Per-window CTD station maps for the 2023B Transect A comparison.
#
# Thin wrapper: the engine is common/lib/transectA_modern_maps.py, shared with
# the other modern years.
import os, runpy
from pathlib import Path

os.environ['TRANSECT_SIM'] = '2023B'
runpy.run_path(str(Path(__file__).resolve().parents[3] / 'common' / 'lib'
                   / 'transectA_modern_maps.py'), run_name='__main__')
