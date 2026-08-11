import numpy as np
import matplotlib.pyplot as plt

# Load 60-degree test data
data = np.load('np_data/test_1_60_deg_sweep.npz')
sp = float(data['sample_period'])   # sample period in microseconds
fs = 1.0 / (sp * 1e-6)
raw = data['data'].astype(np.float64)

# Drop first sample (always garbage) and remove DC offset
raw = raw[1:]
raw -= raw.mean(axis=0)

# Convert to volts (12-bit ADC, ±2 V full scale)
v = raw * (2.0 / 2048)
t = np.arange(len(raw)) * sp * 1e-6  # seconds

# Zoom window around the chirp
t_start, t_end = 0.9, 2.1
mask = (t >= t_start) & (t <= t_end)
t_zoom = t[mask]
v_zoom = v[mask]

mic_labels = ['Mikrofon 1:', 'Mikrofon 2:', 'Mikrofon 3:']

fig, axes = plt.subplots(3, 2, figsize=(14, 8), sharex='col')
for ch in range(3):
    ax_t = axes[ch, 0]
    ax_s = axes[ch, 1]

    # Time-domain (zoomed, autoscaled amplitude)
    ax_t.plot(t_zoom, v_zoom[:, ch], linewidth=0.5)
    ax_t.set_title(mic_labels[ch])
    ax_t.set_ylabel('Amplitude [V]')
    if ch == 2:
        ax_t.set_xlabel('Tid [s]')

    # Spectrogram (same time window)
    i0 = int(t_start * fs)
    i1 = int(t_end * fs)
    ax_s.specgram(v[i0:i1, ch], Fs=fs, NFFT=512, noverlap=480,
                  cmap='inferno', xextent=(t_start, t_end))
    ax_s.set_title(mic_labels[ch])
    ax_s.set_ylabel('Frekvens [Hz]')
    ax_s.set_ylim(0, 12000)
    if ch == 2:
        ax_s.set_xlabel('Tid [s]')

plt.tight_layout()
plt.savefig('signal_60deg_combined.png', dpi=150)
plt.show()
