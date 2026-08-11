import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

def load_bode(path):
    df = pd.read_csv(path, comment="#")
    df.columns = ["freq", "ch1_mag", "ch2_mag", "ch2_phase"]
    return df

def find_3db_crossings(freq, mag, peak_db):
    """Return all frequencies where magnitude crosses peak_db - 3."""
    threshold = peak_db - 3
    crossings = []
    for i in range(len(mag) - 1):
        if (mag[i] - threshold) * (mag[i+1] - threshold) < 0:
            # linear interpolation in log-frequency space
            t = (threshold - mag[i]) / (mag[i+1] - mag[i])
            f = np.exp(np.log(freq[i]) + t * (np.log(freq[i+1]) - np.log(freq[i])))
            crossings.append((f, threshold))
    return crossings

PEAK_DB = 20.0

I = load_bode("IF_I_filter_freqs.csv")
Q = load_bode("IF_Q_filter_freqs.csv")

I_crossings = find_3db_crossings(I["freq"].values, I["ch2_mag"].values, PEAK_DB)
Q_crossings = find_3db_crossings(Q["freq"].values, Q["ch2_mag"].values, PEAK_DB)

fig, (ax_mag, ax_phase) = plt.subplots(2, 1, figsize=(9, 7), sharex=True)
fig.suptitle("IF-filter frekvensrespons (Bode-diagram)", fontsize=13)

# Forsterkning
ax_mag.semilogx(I["freq"], I["ch2_mag"], label="I-filter", color="tab:blue")
ax_mag.semilogx(Q["freq"], Q["ch2_mag"], label="Q-filter", color="tab:orange", linestyle="--")
ax_mag.axhline(PEAK_DB - 3, color="gray", linestyle=":", linewidth=1, label=f"{PEAK_DB-3:.0f} dB (−3 dB-grense)")

for f, m in I_crossings:
    ax_mag.axvline(f, color="tab:blue", linestyle="--", linewidth=0.8, alpha=0.6)
    ax_mag.plot(f, m, "o", color="tab:blue", markersize=6)
    ax_mag.annotate(f"{f:.1f} Hz", xy=(f, m), xytext=(4, 6),
                    textcoords="offset points", color="tab:blue", fontsize=8)

for f, m in Q_crossings:
    ax_mag.axvline(f, color="tab:orange", linestyle="--", linewidth=0.8, alpha=0.6)
    ax_mag.plot(f, m, "s", color="tab:orange", markersize=6)
    ax_mag.annotate(f"{f:.1f} Hz", xy=(f, m), xytext=(4, -14),
                    textcoords="offset points", color="tab:orange", fontsize=8)

ax_mag.set_ylabel("Forsterkning (dB)")
ax_mag.legend()
ax_mag.grid(True, which="both", linestyle=":", alpha=0.7)
ax_mag.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, _: f"{x:g}"))

# Fase
ax_phase.semilogx(I["freq"], I["ch2_phase"], label="I-filter", color="tab:blue")
ax_phase.semilogx(Q["freq"], Q["ch2_phase"], label="Q-filter", color="tab:orange", linestyle="--")
ax_phase.set_ylabel("Fase (grader)")
ax_phase.set_xlabel("Frekvens (Hz)")
ax_phase.legend()
ax_phase.grid(True, which="both", linestyle=":", alpha=0.7)
ax_phase.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, _: f"{x:g}"))

plt.tight_layout()
plt.savefig("IF_filters_bode.pdf", bbox_inches="tight")
plt.savefig("IF_filters_bode.png", dpi=150, bbox_inches="tight")
plt.show()
print("Saved IF_filters_bode.pdf / .png")
