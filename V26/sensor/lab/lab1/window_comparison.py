from raspi_import import raspi_import
import matplotlib.pyplot as plt
import numpy as np
import sys
import os

os.makedirs("images", exist_ok=True)

filename = sys.argv[1] if len(sys.argv) > 1 else 'data/1khz_sin.bin'

sample_period, data = raspi_import(filename)

data = data.copy()
data -= (2**12 - 1) / 2
data = data * (3.3 / ((2**12) - 1))

data_length = data.shape[0]
signal = data[:, 0]  # ADC 1

n = np.arange(data_length)
fs = int(1 / sample_period)

k = int(np.ceil(np.log2(data_length)))

# vindusfunksjoner
w_rect = np.ones(data_length)
w_hann = np.sin(np.pi * n / data_length) ** 2
w_black = 0.42 - 0.5 * np.cos(2 * np.pi * n / data_length) + 0.08 * np.cos(4 * np.pi * n / data_length)

windows = [
    ("Rektangulær", w_rect),
    ("Hanning", w_hann),
    ("Blackman", w_black),
]

N_fixed = 2**k
df = np.linspace(-0.5, 0.5, N_fixed) * fs

fig, ax = plt.subplots(3, 1, figsize=(10, 10.5))

for i, (name, w) in enumerate(windows):
    fft = abs(np.fft.fft(w * signal, N_fixed))
    fft = abs(np.fft.fftshift(fft))
    Sdb = 20 * np.log10(fft / max(fft))

    ax[i].plot(df, Sdb)
    ax[i].set_title(f"Vindusfunksjon: {name}")
    ax[i].set_ylabel("Effekt [dB]")
    ax[i].set_xlabel("Frekvens [Hz]")
    ax[i].set_xlim(10, 15000)
    ax[i].set_ylim(-120, 0)

fig.tight_layout()
plt.savefig("images/window_comparison.png", dpi=300, bbox_inches='tight')
plt.close()

# zero padding med hanning
N_vals = [2**k, 2**(k+1), 2**(k+2)]

fig1, ax1 = plt.subplots(3, 1, figsize=(10, 10.5))

for i, N in enumerate(N_vals):
    df = np.linspace(-0.5, 0.5, N) * fs

    fft = abs(np.fft.fft(w_hann * signal, N))
    fft = abs(np.fft.fftshift(fft))
    Sdb = 20 * np.log10(fft / max(fft))

    ax1[i].plot(df, Sdb)
    ax1[i].set_title(f"Zero-padding: $N = 2^{{{k+i}}}$ = {N}")
    ax1[i].set_ylabel("Effekt [dB]")
    ax1[i].set_xlabel("Frekvens [Hz]")
    ax1[i].set_xlim(10, 15000)
    ax1[i].set_ylim(-120, 0)

fig1.tight_layout()
plt.savefig("images/zeropadding_comparison.png", dpi=300, bbox_inches='tight')
plt.close()
