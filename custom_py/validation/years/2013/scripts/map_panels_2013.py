# Per-window station maps for the 2013A Transect A comparison.
#
# Thin wrapper: the engine is common/lib/transectA_modern_maps.py, shared with
# the other modern years.
import os, runpy
from pathlib import Path

# 2013 is A002 under model 1.7 but B010 under 1.8 (MODEL_VER env selects)
os.environ['TRANSECT_SIM'] = '2013B' if os.environ.get('MODEL_VER', '1.7').startswith('1.8') else '2013A'
runpy.run_path(str(Path(__file__).resolve().parents[3] / 'common' / 'lib'
                   / 'transectA_modern_maps.py'), run_name='__main__')
