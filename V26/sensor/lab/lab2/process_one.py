import sys
import numpy as np
from scipy.signal import correlate, butter, sosfilt

c = 343
d = 0.065
f_start = 2e3
f_stop = 8e3
a = d / np.sqrt(3)


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
    if l_star <= 0 or l_star >= len(r) - 1:
        return 0.0
    y_m, y_0, y_p = r[l_star - 1], r[l_star], r[l_star + 1]
    denom = y_m - 2 * y_0 + y_p
    if denom == 0:
        return 0.0
    return 0.5 * (y_m - y_p) / denom


def estimate_delay(x_i, x_j, interpolate):
    r = correlate(x_j, x_i, mode='full', method='fft')
    N = len(x_i)
    lags = np.arange(-(N - 1), N)
    l_star = int(np.argmax(r))
    offset = parabolic_offset(r, l_star) if interpolate else 0.0
    return lags[l_star] + offset


def process_file(filepath):
    npz = np.load(filepath)
    sample_period_us = float(npz['sample_period'])
    fs = 1.0 / (sample_period_us * 1e-6)
    raw = npz['data'].astype(np.float64)
    raw -= raw.mean(axis=0)

    sos = butter(4, [f_start, f_stop], btype='band', fs=fs, output='sos')
    r1 = sosfilt(sos, raw[:, 0])
    r2 = sosfilt(sos, raw[:, 1])
    r3 = sosfilt(sos, raw[:, 2])

    n21 = estimate_delay(r1, r2, interpolate=False)
    n31 = estimate_delay(r1, r3, interpolate=False)
    n32 = estimate_delay(r2, r3, interpolate=False)
    theta_round = estimate_angle_from_samples(n21, n31, n32)

    n21 = estimate_delay(r1, r2, interpolate=True)
    n31 = estimate_delay(r1, r3, interpolate=True)
    n32 = estimate_delay(r2, r3, interpolate=True)
    theta_interp = estimate_angle_from_samples(n21, n31, n32)

    return fs, -theta_round, -theta_interp


filepath = sys.argv[1] if len(sys.argv) > 1 else 'test_0_minus_90.npz'
fs, th_r, th_i = process_file(filepath)
print(f'Integer:      {np.rad2deg(th_r):.2f}°')
print(f'Interpolated: {np.rad2deg(th_i):.2f}°')
