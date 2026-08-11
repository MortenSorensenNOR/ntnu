import sys
import glob
import os
import numpy as np
import matplotlib.pyplot as plt

if len(sys.argv) > 1:
    DATA_PATH = sys.argv[1]
else:
    files = sorted(glob.glob("data/*.npz"), key=os.path.getmtime)
    if not files:
        sys.exit("No .npz files found in data/")
    DATA_PATH = files[-1]

print(f"Using: {DATA_PATH}")

d = np.load(DATA_PATH)
fs = 1e6 / float(d['sample_period'])

I = d['data'][1:, 0].astype(float)
Q = d['data'][1:, 1].astype(float)

N = len(I)
t = np.arange(N) / fs

fig, axes = plt.subplots(2, 1, figsize=(12, 5), sharex=True)
fig.suptitle(f"Tidsserie  —  {os.path.basename(DATA_PATH)}", fontsize=13)

axes[0].plot(t, I, linewidth=0.4, color='tab:blue')
axes[0].set_ylabel("I (ADC counts)")
axes[0].grid(True, linestyle=':', alpha=0.5)

axes[1].plot(t, Q, linewidth=0.4, color='tab:orange')
axes[1].set_ylabel("Q (ADC counts)")
axes[1].set_xlabel("Tid (s)")
axes[1].grid(True, linestyle=':', alpha=0.5)

plt.tight_layout()
out_png = DATA_PATH.replace('.npz', '_timeseries.png')
out_pdf = DATA_PATH.replace('.npz', '_timeseries.pdf')
plt.savefig(out_png, dpi=150, bbox_inches='tight')
plt.savefig(out_pdf, bbox_inches='tight')
print(f"Saved {out_png}  and  {out_pdf}")
plt.show()
