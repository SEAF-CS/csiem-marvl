# Transect A model-vs-field sections for the 2015A hindcast (A002 mesh;
# DWER-CSMWQ surface+bottom bottle profiles -- see the engine header).
#
# Thin wrapper: the engine is common/lib/transectA_modern.py, shared with the
# other modern years so the spine, station set and bathymetry treatment are
# identical across them.  Optional argv[1] filters windows by a date substring.
import os, runpy
from pathlib import Path

# 2015 is A002 under model 1.7 but B010 under 1.8 (MODEL_VER env selects)
os.environ['TRANSECT_SIM'] = '2015B' if os.environ.get('MODEL_VER', '1.7').startswith('1.8') else '2015A'
runpy.run_path(str(Path(__file__).resolve().parents[3] / 'common' / 'lib'
                   / 'transectA_modern.py'), run_name='__main__')
