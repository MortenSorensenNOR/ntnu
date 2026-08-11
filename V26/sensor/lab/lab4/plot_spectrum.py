import sys
import glob
import os
import argparse
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import welch, stft

parser = argparse.ArgumentParser()
parser.add_argument("data_path", nargs="?", help=".npz file to analyse")
parser.add_argument("--t-start", type=float, default=None, help="Start of analysis window (s)")
parser.add_argument("--t-end",   type=float, default=None, help="End of analysis window (s)")
args = parser.parse_args()

if args.data_path:
    DATA_PATH = args.data_path
else:
    files = sorted(glob.glob("data/*.npz"), key=os.path.getmtime)
    if not files:
        sys.exit("No .npz files found in data/")
    DATA_PATH = files[-1]

print(f"Using: {DATA_PATH}")

FC           = 24e9   # carrier frequency (Hz)
C            = 3e8    # speed of light (m/s)
MAX_SPEED_MS = 20.0   # ignore peaks beyond ±20 m/s (72 km/h)

d = np.load(DATA_PATH)
fs = 1e6 / float(d['sample_period'])

I_full = d['data'][1:, 0].astype(float)
Q_full = d['data'][1:, 1].astype(float)
I_full -= I_full.mean()
Q_full -= Q_full.mean()
iq_full = I_full + 1j * Q_full
N_full  = len(iq_full)
t_full  = np.arange(N_full) / fs

# ── auto-detect the stable-speed region via short-time FFT ──────────────────
def find_stable_window(iq, fs, nperseg=2048, min_duration=1.0, dc_guard=5.0,
                       max_doppler=None):
    """
    Returns (t_start, t_end) of the longest contiguous region where the
    instantaneous Doppler peak stays within ±std_threshold of its median.
    Falls back to the second half of the signal if nothing is found.
    """
    f_stft, t_stft, Zxx = stft(iq, fs=fs, nperseg=nperseg,
                                noverlap=nperseg // 2, window='hann')
    f_stft = np.fft.fftshift(f_stft)
    Zxx    = np.fft.fftshift(Zxx, axes=0)
    power  = np.abs(Zxx) ** 2

    # mask DC and out-of-range bins
    mask = np.abs(f_stft) < dc_guard
    if max_doppler is not None:
        mask |= np.abs(f_stft) > max_doppler
    power[mask, :] = 0

    peak_freq = f_stft[np.argmax(power, axis=0)]   # instantaneous peak (Hz)

    # collect all contiguous stable runs, scored by median |peak_freq|
    # so "standing still" (near-zero Doppler) can't beat a moving segment
    runs = []   # list of (start_idx, length, median_abs_freq)
    cur_len, cur_start = 0, 0
    for i in range(len(peak_freq)):
        # a frame is "stable" if it's close to its local neighbours
        # we'll re-score runs after collecting them
        cur_len += 1
        if i + 1 == len(peak_freq) or abs(peak_freq[i + 1] - peak_freq[i]) > 3 * np.std(np.diff(peak_freq)):
            runs.append((cur_start, cur_len,
                         float(np.median(np.abs(peak_freq[cur_start:cur_start + cur_len])))))
            cur_start = i + 1
            cur_len   = 0

    dt = t_stft[1] - t_stft[0]

    # keep only runs long enough and with meaningful Doppler (above dc_guard)
    valid = [(s, l, mf) for s, l, mf in runs
             if l * dt >= min_duration and mf > dc_guard]

    if not valid:
        # fallback: use second half
        half = t_full[-1] / 2
        return half, t_full[-1]

    # pick the run with the highest median |Doppler frequency|
    best_start, best_len, _ = max(valid, key=lambda x: x[2])

    t0 = t_stft[best_start]
    t1 = t_stft[min(best_start + best_len - 1, len(t_stft) - 1)]
    return float(t0), float(t1)

max_doppler_hz = MAX_SPEED_MS * 2 * FC / C

if args.t_start is not None or args.t_end is not None:
    t_start = args.t_start if args.t_start is not None else 0.0
    t_end   = args.t_end   if args.t_end   is not None else t_full[-1]
else:
    t_start, t_end = find_stable_window(iq_full, fs,
                                        max_doppler=max_doppler_hz)

i0 = int(t_start * fs)
i1 = int(t_end   * fs)
i0 = max(0, min(i0, N_full - 1))
i1 = max(i0 + 1, min(i1, N_full))

print(f"Analysis window: {t_start:.2f} s – {t_end:.2f} s  "
      f"({(i1-i0)/fs:.2f} s,  {i1-i0} samples)")

iq = iq_full[i0:i1]
I  = I_full[i0:i1]
Q  = Q_full[i0:i1]

# Welch's method: average many overlapping FFTs for a smooth spectrum
freqs, psd = welch(iq, fs=fs, nperseg=2048, noverlap=1024,
                   window='hann', return_onesided=False)
freqs = np.fft.fftshift(freqs)
psd   = np.fft.fftshift(psd)

psd_dB = 10 * np.log10(psd + 1e-12)

# Find peak Doppler and convert to speed (limit search to ±MAX_SPEED_MS)
max_doppler_hz = MAX_SPEED_MS * 2 * FC / C
search_mask = (np.abs(freqs) < 5) | (np.abs(freqs) > max_doppler_hz)
psd_nodc = psd.copy(); psd_nodc[search_mask] = 0
peak_freq = freqs[np.argmax(psd_nodc)]
peak_speed = peak_freq * C / (2 * FC)   # m/s, signed

fig, ax = plt.subplots(figsize=(10, 5))
ax.plot(freqs, psd_dB, linewidth=0.7, color='tab:blue')
ax.axvline(peak_freq, color='tab:red', linewidth=1, linestyle='--',
           label=f"Topp: {peak_freq:.1f} Hz  →  {peak_speed:.2f} m/s ({peak_speed*3.6:.2f} km/h)")
ax.set_xlabel("Doppler-frekvens (Hz)  /  hastighet (m/s)\n(+ = nærmer seg, − = fjerner seg)")
ax.set_ylabel("Effekt (dB)")
ax.set_title(f"Doppler-spektrum  —  {os.path.basename(DATA_PATH)}"
             f"\n(vindu: {t_start:.2f} – {t_end:.2f} s)")
ax.axvline(0, color='gray', linewidth=0.8, linestyle='--', alpha=0.6)
ax.grid(True, linestyle=':', alpha=0.5)
ax.set_xlim(-fs / 2, fs / 2)
ax.legend()

# Secondary x-axis showing speed
ax2 = ax.twiny()
ax2.set_xlim(np.array(ax.get_xlim()) * C / (2 * FC))
ax2.set_xlabel("Hastighet (m/s)")

plt.tight_layout()
out_png = DATA_PATH.replace('.npz', '_spectrum.png')
out_pdf = DATA_PATH.replace('.npz', '_spectrum.pdf')
plt.savefig(out_png, dpi=150, bbox_inches='tight')
plt.savefig(out_pdf, bbox_inches='tight')
print(f"Saved {out_png}  and  {out_pdf}")
plt.show()
