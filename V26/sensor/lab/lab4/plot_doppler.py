import sys
import glob
import os
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import spectrogram

if len(sys.argv) > 1:
    DATA_PATH = sys.argv[1]
else:
    files = sorted(glob.glob("data/*.npz"), key=os.path.getmtime)
    if not files:
        sys.exit("No .npz files found in data/")
    DATA_PATH = files[-1]

print(f"Using: {DATA_PATH}")

FC = 24e9       # carrier frequency (Hz)
C  = 3e8        # speed of light (m/s)

d = np.load(DATA_PATH)
sample_period_us = float(d['sample_period'])   # microseconds
fs = 1e6 / sample_period_us                    # Hz  →  31250 Hz

raw = d['data'][1:]            # first sample is always wrong
I = raw[:, 0].astype(float)   # ADC 1
Q = raw[:, 1].astype(float)   # ADC 2

# Remove DC from each channel
I -= I.mean()
Q -= Q.mean()

# Complex IQ signal → signed Doppler (positive = approaching, negative = receding)
iq = I + 1j * Q

# --- Spectrogram -----------------------------------------------------------
# nperseg controls time vs. frequency resolution trade-off.
# 1024 pts → freq resolution ≈ 30 Hz, time step ≈ 8 ms (with 75 % overlap)
nperseg  = 1024
noverlap = nperseg * 3 // 4

f, t, Sxx = spectrogram(iq, fs=fs, nperseg=nperseg, noverlap=noverlap,
                        window='hann', scaling='spectrum',
                        return_onesided=False)

# Shift so negative frequencies are on the bottom
f    = np.fft.fftshift(f)
Sxx  = np.fft.fftshift(Sxx, axes=0)

Sxx_dB = 10 * np.log10(np.abs(Sxx) + 1e-12)

# --- Instantaneous dominant Doppler (ignore DC ±5 Hz) ----------------------
dc_mask = np.abs(f) < 5
Sxx_nodc = Sxx_dB.copy()
Sxx_nodc[dc_mask, :] = -np.inf
peak_idx  = np.argmax(Sxx_nodc, axis=0)
peak_freq = f[peak_idx]

# ---- Plot -----------------------------------------------------------------
fig, axes = plt.subplots(2, 1, figsize=(11, 7),
                         gridspec_kw={'height_ratios': [3, 1]})
fig.suptitle("Doppler-spektrogram over tid (IQ)", fontsize=13)

ax = axes[0]
pcm = ax.pcolormesh(t, f, Sxx_dB, shading='auto', cmap='inferno')
cb  = fig.colorbar(pcm, ax=ax, pad=0.02)
cb.set_label("Effekt (dB)")
ax.axhline(0, color='white', linewidth=0.5, linestyle='--', alpha=0.5)
ax.set_ylabel("Doppler-frekvens (Hz)\n(+ = nærmer seg, − = fjerner seg)")
ax.set_xlabel("Tid (s)")
ax.set_ylim(-fs / 2, fs / 2)
ax.grid(True, linestyle=':', alpha=0.4)

peak_speed = peak_freq * C / (2 * FC)   # m/s, signed

ax2 = axes[1]
ax2.plot(t, peak_speed, color='tab:cyan', linewidth=0.8)
ax2.axhline(0, color='gray', linewidth=0.5, linestyle='--')
ax2.set_ylabel("Hastighet (m/s)\n(+ = nærmer seg)")
ax2.set_xlabel("Tid (s)")
ax2.grid(True, linestyle=':', alpha=0.4)

# Secondary y-axis in km/h
ax2r = ax2.twinx()
ax2r.set_ylim(np.array(ax2.get_ylim()) * 3.6)
ax2r.set_ylabel("Hastighet (km/h)")

plt.tight_layout()
out_png = DATA_PATH.replace('.npz', '_doppler.png')
out_pdf = DATA_PATH.replace('.npz', '_doppler.pdf')
plt.savefig(out_png, dpi=150, bbox_inches='tight')
plt.savefig(out_pdf, bbox_inches='tight')
print(f"Saved {out_png}  and  {out_pdf}")
plt.show()
