import numpy as np
import matplotlib.pyplot as plt
import os
import re
from scipy.signal import correlate, butter, sosfilt

# Parametere
c = 343
d = 0.065
f_start = 2e3
f_stop = 8e3

a = d / np.sqrt(3)

mic1 = np.array([0.0,  1.0]) * a
mic2 = np.array([-np.sqrt(3)/2, -0.5]) * a
mic3 = np.array([ np.sqrt(3)/2, -0.5]) * a


def estimate_angle_from_samples(n21, n31, n32):
    num = np.sqrt(3) * (n31 + n21)
    x = -n21 + n31 + 2 * n32
    if x == 0:
        theta = np.sign(num) * np.pi / 2
    else:
        theta = np.arctan(num / x)
        if x < 0:
            theta += np.pi
    return (np.pi - theta + np.pi) % (2 * np.pi) - np.pi


def parabolic_offset(r, l_star):
    """Sub-sample offset fra parabolsk tilpasning rundt toppindeksen l_star."""
    if l_star <= 0 or l_star >= len(r) - 1:
        return 0.0
    y_m, y_0, y_p = r[l_star - 1], r[l_star], r[l_star + 1]
    denom = y_m - 2 * y_0 + y_p
    if denom == 0:
        return 0.0
    return 0.5 * (y_m - y_p) / denom


def estimate_delay(x_i, x_j, interpolate, max_lag=None):
    """Estimert forsinkelse n_ij = τ_j − τ_i (i sampler).
    max_lag: begrens søket til ±max_lag sampler (fysisk maksimum = d·fs/c)."""
    r = correlate(x_j, x_i, mode='full', method='fft')
    N = len(x_i)
    lags = np.arange(-(N - 1), N)
    if max_lag is not None:
        mask = np.abs(lags) <= max_lag
        l_star = int(np.argmax(r * mask))
    else:
        l_star = int(np.argmax(r))
    offset = parabolic_offset(r, l_star) if interpolate else 0.0
    return lags[l_star] + offset


def process_file(filepath):
    npz = np.load(filepath)
    sample_period_us = float(npz['sample_period'])
    fs = 1.0 / (sample_period_us * 1e-6)
    raw = npz['data'].astype(np.float64)
    raw -= raw.mean(axis=0)

    # Bandpass rundt chirpens frekvensområde
    sos = butter(4, [f_start, f_stop], btype='band', fs=fs, output='sos')
    r1 = sosfilt(sos, raw[:, 0])
    r2 = sosfilt(sos, raw[:, 1])
    r3 = sosfilt(sos, raw[:, 2])

    n_max = d * fs / c

    # Uten interpolasjon
    n21 = estimate_delay(r1, r2, interpolate=False, max_lag=n_max)
    n31 = estimate_delay(r1, r3, interpolate=False, max_lag=n_max)
    n32 = estimate_delay(r2, r3, interpolate=False, max_lag=n_max)
    theta_round = estimate_angle_from_samples(n21, n31, n32)

    # Med parabolsk interpolasjon
    n21i = estimate_delay(r1, r2, interpolate=True, max_lag=n_max)
    n31i = estimate_delay(r1, r3, interpolate=True, max_lag=n_max)
    n32i = estimate_delay(r2, r3, interpolate=True, max_lag=n_max)
    theta_interp = estimate_angle_from_samples(n21i, n31i, n32i)

    debug = dict(n21_r=n21, n31_r=n31, n32_r=n32,
                 n21_i=n21i, n31_i=n31i, n32_i=n32i)

    # Lab-konvensjonen for vinkel er speilvendt (med klokken) ift. simuleringen.
    # Ekvivalent med at det fysiske arrayet er speilvendt om x-aksen.
    return fs, -theta_round, -theta_interp, debug


def parse_true_angle(filename):
    m = re.search(r'_(\d+)_deg_sweep', filename)
    if m:
        return int(m.group(1))
    m = re.search(r'_minus_(\d+)', filename)
    if m:
        return -int(m.group(1))
    return None


DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'np_data')
files = [f for f in os.listdir(DATA_DIR) if f.endswith('.npz')]

rows = []
for f in files:
    true_deg = parse_true_angle(f)
    if true_deg is None:
        continue
    fs, th_r, th_i, debug = process_file(os.path.join(DATA_DIR, f))
    rows.append((f, true_deg, th_r, th_i, debug))

rows.sort(key=lambda r: (r[1], r[0]))

true_deg = np.array([r[1] for r in rows])
est_r_deg = np.rad2deg(np.array([r[2] for r in rows]))
est_i_deg = np.rad2deg(np.array([r[3] for r in rows]))

# Kortest signerte feil, med bølgen rundt ±180°
err_r = ((est_r_deg - true_deg + 180) % 360) - 180
err_i = ((est_i_deg - true_deg + 180) % 360) - 180

# Trekk estimatene nær sann vinkel for ryddig plot
est_r_plot = true_deg + err_r
est_i_plot = true_deg + err_i

print(f"{'Fil':45s} {'Sann':>6s} {'Heltall':>10s} {'Interp':>10s} {'Feil_h':>9s} {'Feil_i':>9s}  {'n21_r':>6s} {'n31_r':>6s} {'n32_r':>6s}  {'n21_i':>7s} {'n31_i':>7s} {'n32_i':>7s}")
for (f, td, _, _, dbg), er, ei, eh, ep in zip(rows, est_r_plot, est_i_plot, err_r, err_i):
    print(f"{f:45s} {td:6d} {er:10.2f} {ei:10.2f} {eh:+9.2f} {ep:+9.2f}"
          f"  {dbg['n21_r']:6.0f} {dbg['n31_r']:6.0f} {dbg['n32_r']:6.0f}"
          f"  {dbg['n21_i']:7.3f} {dbg['n31_i']:7.3f} {dbg['n32_i']:7.3f}")

print(f"\nRMS feil heltall:    {np.sqrt(np.mean(err_r**2)):.3f}°")
print(f"RMS feil interp.:    {np.sqrt(np.mean(err_i**2)):.3f}°")
print(f"Maks |feil| heltall: {np.max(np.abs(err_r)):.3f}°")
print(f"Maks |feil| interp.: {np.max(np.abs(err_i)):.3f}°")

# Plot
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(11, 8))

lo = min(true_deg.min(), est_r_plot.min(), est_i_plot.min()) - 10
hi = max(true_deg.max(), est_r_plot.max(), est_i_plot.max()) + 10
ax1.plot([lo, hi], [lo, hi], 'k--', linewidth=1, label='Sann vinkel')
ax1.scatter(true_deg, est_r_plot, marker='o', s=60, label='Heltallssampler')
ax1.scatter(true_deg, est_i_plot, marker='x', s=60, label='Parabolsk interpolasjon')
ax1.set_xlabel('Sann vinkel (°)')
ax1.set_ylabel('Estimert vinkel (°)')
ax1.set_title('Estimert vinkel for måledata')
ax1.legend()
ax1.grid(True)

xs = np.arange(len(rows))
width = 0.4
ax2.bar(xs - width / 2, err_r, width, label='Heltallssampler')
ax2.bar(xs + width / 2, err_i, width, label='Parabolsk interpolasjon')
ax2.set_xticks(xs)
ax2.set_xticklabels([r[0].replace('.npz', '') for r in rows],  # r[0] = filename
                    rotation=55, ha='right', fontsize=8)
ax2.set_ylabel('Feil (°)')
ax2.set_title('Estimeringsfeil per måling')
ax2.axhline(0, color='k', linewidth=0.5)
ax2.legend()
ax2.grid(True, axis='y')

plt.tight_layout()
plt.show()
