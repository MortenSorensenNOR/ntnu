import numpy as np
import matplotlib.pyplot as plt

# Parametere
fs = 44100
c = 343
d = 0.065

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
    # Vikle til (-pi, pi]
    return (np.pi - theta + np.pi) % (2 * np.pi) - np.pi

# Sweep sann vinkel og estimer med kvantiserte forsinkelser
angles_in = np.linspace(-np.pi, np.pi, 1000, endpoint=False)
estimated = np.zeros_like(angles_in)

for i, theta in enumerate(angles_in):
    # theta er retningen til kilden; bølgen propagerer motsatt vei
    wave = np.array([-np.cos(theta), -np.sin(theta)])

    n21 = int(np.round(np.dot(mic2 - mic1, wave) / c * fs))
    n31 = int(np.round(np.dot(mic3 - mic1, wave) / c * fs))
    n32 = int(np.round(np.dot(mic3 - mic2, wave) / c * fs))

    estimated[i] = estimate_angle_from_samples(n21, n31, n32)

# Vikle feilen til (-pi, pi]
error = np.mod(estimated - angles_in + np.pi, 2 * np.pi) - np.pi

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8), sharex=True)

ax1.plot(np.rad2deg(angles_in), np.rad2deg(angles_in),
         'k--', linewidth=1, label='Sann vinkel')
ax1.plot(np.rad2deg(angles_in), np.rad2deg(estimated),
         '.', markersize=2, label='Estimert vinkel')
ax1.set_ylabel("Estimert vinkel (°)")
ax1.set_title(f"Beste mulige måling (d={d*100:.1f} cm, fs={fs} Hz)")
ax1.legend()
ax1.grid(True)

ax2.plot(np.rad2deg(angles_in), np.rad2deg(error))
ax2.set_xlabel("Sann vinkel (°)")
ax2.set_ylabel("Feil (°)")
ax2.set_title("Estimeringsfeil (estimert − sann)")
ax2.grid(True)

plt.tight_layout()
plt.show()

unique_angles = np.unique(np.round(estimated, 6))
diffs = np.diff(unique_angles)
print(f"Antall diskrete vinkler: {len(unique_angles)}")
print(f"Beste oppløsning:    {np.degrees(diffs.min()):.4f}°")
print(f"Dårligste oppløsning: {np.degrees(diffs.max()):.4f}°")
print(f"Maks |feil|:          {np.degrees(np.abs(error).max()):.4f}°")
