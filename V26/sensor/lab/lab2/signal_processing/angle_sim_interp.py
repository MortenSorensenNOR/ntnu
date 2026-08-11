import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import correlate, chirp

# Parametere
fs = 44100
c = 343
d = 0.065

a = d / np.sqrt(3)

mic1 = np.array([0.0,  1.0]) * a
mic2 = np.array([-np.sqrt(3)/2, -0.5]) * a
mic3 = np.array([ np.sqrt(3)/2, -0.5]) * a
mics = [mic1, mic2, mic3]


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


def fractional_delay(signal, delay_samples):
    """Forsinker signalet med et (fraksjonelt) antall sampler via FFT-faseskift."""
    N = len(signal)
    S = np.fft.fft(signal)
    k = np.fft.fftfreq(N) * N
    return np.real(np.fft.ifft(S * np.exp(-2j * np.pi * k * delay_samples / N)))


def parabolic_offset(r, l_star):
    """Sub-sample offset fra parabolsk tilpasning rundt toppindeksen l_star."""
    if l_star <= 0 or l_star >= len(r) - 1:
        return 0.0
    y_m, y_0, y_p = r[l_star - 1], r[l_star], r[l_star + 1]
    denom = y_m - 2 * y_0 + y_p
    if denom == 0:
        return 0.0
    return 0.5 * (y_m - y_p) / denom


def estimate_delay(x_i, x_j, interpolate):
    """Estimert forsinkelse n_ij = τ_j − τ_i (i sampler)."""
    r = correlate(x_j, x_i, mode='full', method='fft')
    N = len(x_i)
    lags = np.arange(-(N - 1), N)
    l_star = int(np.argmax(r))
    offset = parabolic_offset(r, l_star) if interpolate else 0.0
    return lags[l_star] + offset


# Testsignal: chirp 2-8 kHz, 50 ms, Hann-vindu for å dempe kant-effekter
T = 0.05
t = np.arange(int(T * fs)) / fs
signal = chirp(t, f0=2000, f1=8000, t1=T, method='linear')
signal *= np.hanning(len(signal))

# Sweep kilderetninger
angles_in = np.linspace(-np.pi, np.pi, 1000, endpoint=False)
est_round = np.zeros_like(angles_in)
est_interp = np.zeros_like(angles_in)

for i, theta in enumerate(angles_in):
    source_dir = np.array([np.cos(theta), np.sin(theta)])
    wave = -source_dir  # propagasjonsretning
    tau = np.array([np.dot(m, wave) / c * fs for m in mics])

    # Generer mic-signaler med eksakt (fraksjonell) forsinkelse
    signals = [fractional_delay(signal, t_i) for t_i in tau]

    # Uten interpolasjon (kun heltallssampler fra toppen av CC)
    n21 = estimate_delay(signals[0], signals[1], interpolate=False)
    n31 = estimate_delay(signals[0], signals[2], interpolate=False)
    n32 = estimate_delay(signals[1], signals[2], interpolate=False)
    est_round[i] = estimate_angle_from_samples(n21, n31, n32)

    # Med parabolsk interpolasjon
    n21 = estimate_delay(signals[0], signals[1], interpolate=True)
    n31 = estimate_delay(signals[0], signals[2], interpolate=True)
    n32 = estimate_delay(signals[1], signals[2], interpolate=True)
    est_interp[i] = estimate_angle_from_samples(n21, n31, n32)


err_round = np.mod(est_round - angles_in + np.pi, 2 * np.pi) - np.pi
err_interp = np.mod(est_interp - angles_in + np.pi, 2 * np.pi) - np.pi

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8), sharex=True)

ax1.plot(np.rad2deg(angles_in), np.rad2deg(angles_in),
         'k--', linewidth=1, label='Sann vinkel')
ax1.plot(np.rad2deg(angles_in), np.rad2deg(est_round),
         '.', markersize=4, label='Heltallssampler')
ax1.plot(np.rad2deg(angles_in), np.rad2deg(est_interp),
         '.', markersize=4, label='Parabolsk interpolasjon')
ax1.set_ylabel("Estimert vinkel (°)")
ax1.set_title(f"Estimert vs. sann vinkel (d={d*100:.1f} cm, fs={fs} Hz)")
ax1.legend()
ax1.grid(True)

ax2.plot(np.rad2deg(angles_in), np.rad2deg(err_round), label='Heltallssampler')
ax2.plot(np.rad2deg(angles_in), np.rad2deg(err_interp), label='Parabolsk interpolasjon')
ax2.set_xlabel("Sann vinkel (°)")
ax2.set_ylabel("Feil (°)")
ax2.set_title("Estimeringsfeil (estimert − sann)")
ax2.legend()
ax2.grid(True)

plt.tight_layout()
plt.show()

n_max = d * fs / c
print(f"n_max = d·fs/c = {n_max:.3f} sampler")
print(f"Maks |feil| uten interpolasjon:     {np.degrees(np.abs(err_round).max()):.3f}°")
print(f"Maks |feil| med parabolsk interp.:  {np.degrees(np.abs(err_interp).max()):.3f}°")
print(f"RMS feil uten interpolasjon:        {np.degrees(np.sqrt(np.mean(err_round**2))):.3f}°")
print(f"RMS feil med parabolsk interp.:     {np.degrees(np.sqrt(np.mean(err_interp**2))):.3f}°")
