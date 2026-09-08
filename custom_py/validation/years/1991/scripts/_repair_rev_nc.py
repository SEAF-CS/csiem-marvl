"""Salvage the corrupt 1991_aug_rev NC (ITER11 final output).

The archived rev NC (written 2026-07-14, and its byte-identical ITER11 archive copy)
contains ~50 of 1009 hourly steps with unreadable HDF chunks ("NetCDF: HDF error"),
scattered through steps 96-987, affecting every time-dependent variable. There is no
pristine copy (the model wrote directly to the archive folder). This script:
  1. scans every time-dependent variable per step and takes the union of bad steps,
  2. writes a repaired NC containing ONLY the intact steps (same schema, per-variable
     deflate settings copied from the source),
  3. verifies the result with a full sequential read of every variable.
The paired-cast engine tolerates +/-1 day, so all casts re-pair to steps at most a few
hours from the dropped ones; time-series products keep a continuous axis with ~5% gaps.
Output: <source>_repaired.nc alongside the original. The original is NOT modified.
"""
import numpy as np, netCDF4, sys, os

SRC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev.nc'
DST = SRC.replace('.nc', '_repaired.nc')

src = netCDF4.Dataset(SRC)
nt = len(src.dimensions['Time'])
tvars = [k for k, v in src.variables.items() if 'Time' in v.dimensions]
svars = [k for k in src.variables if k not in tvars]
print(f'{nt} steps; time-dep vars: {tvars}; static: {svars}', flush=True)

# ---- 1. scan ---------------------------------------------------------------
bad = set()
for k in tvars:
    v = src.variables[k]; nbad = 0
    for t in range(nt):
        if t in bad and k not in ('ResTime',):   # already known bad; still test ResTime (cheap, 1-D)
            continue
        try:
            _ = v[t, ...]
        except Exception:
            bad.add(t); nbad += 1
    print(f'  scanned {k:14s} newly-bad {nbad}  (union now {len(bad)})', flush=True)
good = [t for t in range(nt) if t not in bad]
print(f'bad steps ({len(bad)}): {sorted(bad)}', flush=True)
print(f'keeping {len(good)}/{nt} steps', flush=True)

# ---- 2. copy ---------------------------------------------------------------
if os.path.exists(DST):
    os.remove(DST)
dst = netCDF4.Dataset(DST, 'w', format='NETCDF4')
dst.setncatts({a: src.getncattr(a) for a in src.ncattrs()})
dst.setncattr('repair_note',
              f'Repaired copy of {os.path.basename(SRC)}: {len(bad)} of {nt} hourly steps had '
              f'unreadable HDF chunks and were dropped (indices {sorted(bad)}). '
              f'Created by _repair_rev_nc.py, 2026-08-27.')
for k, d in src.dimensions.items():
    dst.createDimension(k, len(good) if k == 'Time' else len(d))
for k, v in src.variables.items():
    f = v.filters() or {}
    w = dst.createVariable(k, v.dtype, v.dimensions,
                           zlib=bool(f.get('zlib')), complevel=f.get('complevel') or 4,
                           shuffle=bool(f.get('shuffle')), chunksizes=v.chunking() if v.chunking() != 'contiguous' else None)
    w.setncatts({a: v.getncattr(a) for a in v.ncattrs() if a != '_FillValue'})
for k in svars:
    dst.variables[k][:] = src.variables[k][:]
    print(f'  copied static {k}', flush=True)
for k in tvars:
    v, w = src.variables[k], dst.variables[k]
    for i, t in enumerate(good):
        w[i, ...] = v[t, ...]
        if i % 100 == 0:
            print(f'  {k}: {i}/{len(good)}', flush=True)
    print(f'  copied {k}', flush=True)
dst.close(); src.close()
print(f'wrote {DST}  ({os.path.getsize(DST)/1e9:.2f} GB)', flush=True)

# ---- 3. verify -------------------------------------------------------------
chk = netCDF4.Dataset(DST)
ok = True
for k, v in chk.variables.items():
    try:
        if 'Time' in v.dimensions:
            for t in range(len(chk.dimensions['Time'])):
                _ = v[t, ...]
        else:
            _ = v[:]
    except Exception as e:
        ok = False; print(f'VERIFY FAIL {k}: {e}', flush=True)
rt = np.asarray(chk.variables['ResTime'][:])
print(f'ResTime span: {rt[0]} -> {rt[-1]}  ({len(rt)} steps, monotonic={bool(np.all(np.diff(rt) > 0))})', flush=True)
chk.close()
print('VERIFY OK' if ok else 'VERIFY FAILED', flush=True)
