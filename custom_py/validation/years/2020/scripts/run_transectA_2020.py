# Transect A model-vs-field sections for the 2020A hindcast (A002 mesh;
# DWER-CSMWQ surface+bottom bottle profiles -- see the engine header).
#
# Thin wrapper: the engine is common/lib/transectA_modern.py, shared with the
# other modern years so the spine, station set and bathymetry treatment are
# identical across them.  Optional argv[1] filters windows by a date substring.
import os, runpy
from pathlib import Path

os.environ['TRANSECT_SIM'] = '2020A'
runpy.run_path(str(Path(__file__).resolve().parents[3] / 'common' / 'lib'
                   / 'transectA_modern.py'), run_name='__main__')
