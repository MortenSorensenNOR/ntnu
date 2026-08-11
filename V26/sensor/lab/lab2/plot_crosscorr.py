import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import correlate, butter, sosfilt

# --- Load and preprocess (same as angle_real_interp.py) ---
data = np.load('np_data/test_1_60_deg_sweep.npz')
sp = float(data['sample_period'])
fs = 1.0 / (sp * 1e-6)
raw = data['data'][1:].astype(np.float64)  # drop first garbage sample
raw -= raw.mean(axis=0)

f_start, f_stop = 2e3, 8e3
sos = butter(4, [f_start, f_stop], btype='band', fs=fs, output='sos')
r1 = sosfilt(sos, raw[:, 0])
r2 = sosfilt(sos, raw[:, 1])
r3 = sosfilt(sos, raw[:, 2])

# --- Cross-correlations ---
pairs = [
    ('Mic 1 vs Mic 2', r1, r2),
    ('Mic 1 vs Mic 3', r1, r3),
    ('Mic 2 vs Mic 3', r2, r3),
]

def parabolic_offset(r, l_star):
    if l_star <= 0 or l_star >= len(r) - 1:
        return 0.0
    y_m, y_0, y_p = r[l_star - 1], r[l_star], r[l_star + 1]
    denom = y_m - 2 * y_0 + y_p
    if denom == 0:
        return 0.0
    return 0.5 * (y_m - y_p) / denom

x_lim = (-10, 10)

fig, axes = plt.subplots(3, 1, figsize=(10, 9), sharex=True)

for ax, (label, xi, xj) in zip(axes, pairs):
    cc = correlate(xj, xi, mode='full', method='fft')
    N = len(xi)
    lags = np.arange(-(N - 1), N)

    # Integer peak
    l_star = int(np.argmax(cc))
    lag_int = lags[l_star]
    offset = parabolic_offset(cc, l_star)
    lag_interp = lag_int + offset

    # Fixed zoom window around lag=0
    zoom = 10
    center = int(np.where(lags == 0)[0][0])
    sl = slice(center - zoom, center + zoom + 1)
    lags_z = lags[sl]
    cc_z = cc[sl]

    # Parabola through the 3 points around the peak
    y_m, y_0, y_p = cc[l_star - 1], cc[l_star], cc[l_star + 1]
    # Fit: f(x) = a*x^2 + b*x + c, with x relative to l_star
    # Using the 3-point values at x = -1, 0, +1
    a = (y_m - 2*y_0 + y_p) / 2
    b = (y_p - y_m) / 2
    c = y_0
    x_parab = np.linspace(-1.5, 1.5, 200)
    y_parab = a * x_parab**2 + b * x_parab + c

    ax.plot(lags_z, cc_z, 'o-', markersize=4, label='Krysskorrelasjon')
    ax.plot(x_parab + lag_int, y_parab, '-', linewidth=2,
            label='Parabel (3-punkt)')
    ax.axvline(lag_int, color='C1', linestyle='--', linewidth=1.2,
               label=f'Heltall topp: {lag_int} samples')
    ax.axvline(lag_interp, color='C2', linestyle='--', linewidth=1.2,
               label=f'Interpolert topp: {lag_interp:.3f} samples')
    ax.scatter([lag_int], [cc[l_star]], color='C1', zorder=5, s=60)
    ax.scatter([lag_interp], [a*offset**2 + b*offset + c],
               color='C2', zorder=5, s=60)

    ax.set_title(label)
    ax.set_xlabel('Lag [samples]')
    ax.set_ylabel('Korrelasjon')
    ax.legend(fontsize=8)
    ax.grid(True)

plt.tight_layout()
plt.savefig('crosscorr_60deg.png', dpi=150)
plt.show()
