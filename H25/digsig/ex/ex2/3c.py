import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import freqz

# ---------------------------------------
# System definitions from the difference equations
# 1) y[n] = x[n] + 2x[n-1] + x[n-2]
b1 = np.array([1, 2, 1], dtype=float)
a1 = np.array([1.0])

# 2) y[n] = -0.9 y[n-1] + x[n]  ->  a = [1, 0.9], b = [1]
b2 = np.array([1.0])
a2 = np.array([1.0, 0.9])

# Frequency grid (0 to pi)
worN = 2048
w1, H1 = freqz(b1, a1, worN=worN)        # w in rad/sample
w2, H2 = freqz(b2, a2, worN=worN)

# Magnitude and phase
mag1 = np.abs(H1)
mag2 = np.abs(H2)

phase1 = np.angle(H1)                     # wrapped phase
phase2 = np.angle(H2)

# Optional: unwrapped phase if you prefer smooth curves
# phase1 = np.unwrap(np.angle(H1))
# phase2 = np.unwrap(np.angle(H2))

# ---- Plot System 1 ----
plt.figure(figsize=(9, 6))
plt.subplot(2,1,1)
plt.plot(w1, mag1)
plt.title('System 1: y[n] = x[n] + 2x[n-1] + x[n-2]')
plt.ylabel(r'Magnitude $|H_1(e^{jω})|$')
plt.grid(True)

plt.subplot(2,1,2)
plt.plot(w1, phase1)
plt.xlabel('ω (rad/sample)')
plt.ylabel(r'Phase $\angle H_1(e^{jω})$ [rad]')
plt.grid(True)
plt.tight_layout()

plt.savefig("Bilder/3c_1.png", dpi=300)

# ---- Plot System 2 ----
plt.figure(figsize=(9, 6))
plt.subplot(2,1,1)
plt.plot(w2, mag2)
plt.title(r'System 2: $y[n] = -0.9 y[n-1] + x[n]$')
plt.ylabel(r'Magnitude $|H_2(e^{jω})|$')
plt.grid(True)

plt.subplot(2,1,2)
plt.plot(w2, phase2)
plt.xlabel('ω (rad/sample)')
plt.ylabel(r'Phase $\angle H_2(e^{jω})$ [rad]')
plt.grid(True)
plt.tight_layout()

plt.savefig("Bilder/3c_2.png", dpi=300)

# plt.show()
