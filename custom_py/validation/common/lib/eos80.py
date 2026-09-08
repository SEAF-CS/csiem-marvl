"""EOS-80 potential density (surface reference, p=0), promoted from the per-runner copies.

    rho   = eos80_potential_density(S, T)     # kg m^-3
    sigma_t = rho - 1000.0                     # what the SMCWS field figures use

S in psu, T in deg C; array-friendly (numpy / xarray).  Shared by the depth-time / transect /
map validation components so density is computed identically for model and field.
"""
import numpy as np


def eos80_potential_density(S, T):
    T2, T3, T4, T5 = T * T, T * T * T, T * T * T * T, T * T * T * T * T
    Ssq = np.sqrt(np.clip(S, 0, None)); S1p5 = S * Ssq; S2 = S * S
    a = [999.842594, 6.793952e-2, -9.095290e-3, 1.001685e-4, -1.120083e-6, 6.536332e-9]
    rho_w = a[0] + a[1] * T + a[2] * T2 + a[3] * T3 + a[4] * T4 + a[5] * T5
    b = [8.24493e-1, -4.0899e-3, 7.6438e-5, -8.2467e-7, 5.3875e-9]
    c = [-5.72466e-3, 1.0227e-4, -1.6546e-6]; d0 = 4.8314e-4
    return rho_w + (b[0] + b[1] * T + b[2] * T2 + b[3] * T3 + b[4] * T4) * S \
        + (c[0] + c[1] * T + c[2] * T2) * S1p5 + d0 * S2
