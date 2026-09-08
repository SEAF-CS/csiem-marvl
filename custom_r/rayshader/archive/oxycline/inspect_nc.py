import netCDF4 as nc, numpy as np
F = r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
d = nc.Dataset(F)
print("=== DIMENSIONS ===")
for k,v in d.dimensions.items(): print(f"  {k}: {len(v)}")
print("\n=== VARIABLES (name: dims shape) ===")
for k,v in d.variables.items():
    print(f"  {k:20s} {str(v.dimensions):40s} {v.shape}")
# salinity-like vars
print("\n=== salt/sal candidates ===")
for k in d.variables:
    if any(s in k.lower() for s in ['sal','salt']): print("  ", k, d.variables[k].shape)
# time range
T = d.variables['ResTime']
times = nc.num2date(T[:], T.units)
print("\ntime:", str(times[0])[:13], "->", str(times[-1])[:13], "| nsteps", len(times))
