"""
Batch Doppler speed estimator
Processes every .npz in data/ and prints a table of estimated speeds.
"""

import glob
import os
import numpy as np
from scipy.signal import welch

FC           = 24e9   # carrier frequency (Hz)
C            = 3e8    # speed of light (m/s)
MAX_SPEED_MS = 20.0   # ignore peaks beyond ±20 m/s
DC_GUARD_HZ  = 5.0    # ignore bins within ±5 Hz of DC


def find_active_window(iq, fs, t_total, block_dur=0.05, threshold_ratio=0.2,
                       min_duration=0.5):
    """
    Find the contiguous region with the highest signal amplitude.

    Splits the signal into short blocks, computes RMS per block, then
    keeps blocks whose RMS exceeds threshold_ratio * max_RMS. Among
    contiguous runs of active blocks, returns the one with the highest
    mean RMS (i.e. the loudest/fastest movement, not just standing still).
    """
    block = max(1, int(block_dur * fs))
    n_blocks = len(iq) // block
    rms = np.array([np.sqrt(np.mean(np.abs(iq[i*block:(i+1)*block])**2))
                    for i in range(n_blocks)])
    t_blocks = (np.arange(n_blocks) + 0.5) * block_dur

    threshold = threshold_ratio * rms.max()
    active = rms > threshold

    # collect contiguous runs of active blocks
    runs = []
    cur_start = None
    for i, a in enumerate(active):
        if a and cur_start is None:
            cur_start = i
        elif not a and cur_start is not None:
            runs.append((cur_start, i - 1))
            cur_start = None
    if cur_start is not None:
        runs.append((cur_start, n_blocks - 1))

    # filter by minimum duration and pick the run with highest mean RMS
    valid = [(s, e) for s, e in runs
             if (e - s + 1) * block_dur >= min_duration]

    if not valid:
        return t_total / 2, t_total   # fallback

    best = max(valid, key=lambda se: rms[se[0]:se[1]+1].mean())
    t0 = t_blocks[best[0]] - block_dur / 2
    t1 = t_blocks[best[1]] + block_dur / 2
    return max(0.0, t0), min(t_total, t1)


def estimate_speed(path):
    d  = np.load(path)
    fs = 1e6 / float(d['sample_period'])

    I = d['data'][1:, 0].astype(float)
    Q = d['data'][1:, 1].astype(float)
    I -= I.mean()
    Q -= Q.mean()
    iq      = I + 1j * Q
    t_total = len(iq) / fs

    max_doppler_hz = MAX_SPEED_MS * 2 * FC / C
    t0, t1 = find_active_window(iq, fs, t_total)

    i0 = max(0, int(t0 * fs))
    i1 = min(len(iq), int(t1 * fs))
    iq_win = iq[i0:i1]

    freqs, psd = welch(iq_win, fs=fs, nperseg=2048, noverlap=1024,
                       window='hann', return_onesided=False)
    freqs = np.fft.fftshift(freqs)
    psd   = np.fft.fftshift(psd)

    search_mask = (np.abs(freqs) < DC_GUARD_HZ) | (np.abs(freqs) > max_doppler_hz)
    psd_search  = psd.copy()
    psd_search[search_mask] = 0

    peak_hz    = freqs[np.argmax(psd_search)]
    speed_ms   = peak_hz * C / (2 * FC)
    speed_kmh  = speed_ms * 3.6

    return speed_ms, speed_kmh, t0, t1


# ── main ────────────────────────────────────────────────────────────────────
files = sorted(glob.glob("data/*.npz"))
if not files:
    raise SystemExit("No .npz files found in data/")

col = 28
print(f"\n{'File':<{col}}  {'Speed (m/s)':>12}  {'Speed (km/h)':>13}  {'Window (s)':>14}")
print("-" * (col + 46))

for path in files:
    name = os.path.basename(path)
    speed_ms, speed_kmh, t0, t1 = estimate_speed(path)
    direction = "toward" if speed_ms > 0 else "away  "
    print(f"{name:<{col}}  {speed_ms:>+11.2f}  {speed_kmh:>+12.2f}   {t0:.2f} – {t1:.2f}")

print()
print("Sign convention: + = moving toward radar, − = moving away")
