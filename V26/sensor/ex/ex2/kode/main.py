import numpy as np
import matplotlib.pyplot as plt

# 1.
dt = 0.2e-3
fs = 1/dt
print(fs, fs/2)

l = 900
t = np.arange(0, l) * dt
y = np.sin(2 * np.pi * 100 * t)

plt.figure()
plt.plot(t[:200], y[:200])
plt.xlabel("Tid (s)")
plt.ylabel("Amplitude (V)")
plt.savefig("../Bilder/1.png", dpi=300)
# plt.show()


# 2a.
df = fs / 1024
print(df)

y_pad = np.append(y, np.zeros(1024 - l))
y_fft = np.fft.fft(y_pad)
f     = np.arange(1024) * df 

plt.figure()
plt.plot(f, np.abs(y_fft))
plt.xlabel("Frekvens (Hz)")
plt.ylabel(r"$|X(f)|$")
plt.savefig("../Bilder/2a.png", dpi=300)
# plt.show()

# 2b.
plt.figure()
plt.plot(f, np.abs(y_fft)**2)
plt.xlabel("Frekvens (Hz)")
plt.ylabel(r"$|X(f)|^2$")
plt.savefig("../Bilder/2b.png", dpi=300)
# plt.show()

# 2c.
plt.figure()
plt.plot(f, np.abs(y_fft)**2)
plt.xlabel("Frekvens (Hz)")
plt.ylabel(r"$|X(f)|^2$")
plt.xlim(0, 200)
plt.savefig("../Bilder/2c.png", dpi=300)

# 2d.
mag = np.abs(y_fft)
mag = mag / np.max(mag)

plt.figure()
plt.plot(f, 20*np.log(mag))
plt.xlabel("Frekvens (Hz)")
plt.ylabel(r"Relativ effekt (dB)")
plt.ylim(-80, 10)
plt.savefig("../Bilder/2d.png", dpi=300)
# plt.show()

# 3a.
df = fs / 4096
print(df)

y_pad = np.append(y_pad, np.zeros(4096 - 1024))
y_fft = np.fft.fft(y_pad)
f     = np.arange(4096) * df 

plt.figure()
plt.plot(f, np.abs(y_fft))
plt.xlabel("Frekvens (Hz)")
plt.ylabel(r"$|X(f)|$")
plt.savefig("../Bilder/3a.png", dpi=300)
# plt.show()

# 3b.
df = fs / (2*4096)
print(df)

y_pad = np.append(y_pad, np.zeros(4096))
y_fft = np.fft.fft(y_pad)
f     = np.arange(2*4096) * df 

plt.figure()
plt.plot(f, np.abs(y_fft))
plt.xlabel("Frekvens (Hz)")
plt.ylabel(r"$|X(f)|$")
plt.savefig("../Bilder/3b.png", dpi=300)
# plt.show()

# 4.
df = fs / 1024
y_fft_padding = y_fft
f_padding     = f

win   = np.hanning(1024)
y_pad = np.append(y, np.zeros(1024 - l))
y_pad = y_pad * win
y_fft = np.fft.fft(y_pad) 
f     = np.arange(1024) * df 

plt.figure()
plt.plot(f_padding, np.abs(y_fft_padding), label="Padding")
plt.plot(f, np.abs(y_fft), label="Hanning window")
plt.xlabel("Frekvens (Hz)")
plt.ylabel(r"$|X(f)|$")
plt.legend(loc="upper center")
# plt.savefig("../Bilder/4.png", dpi=300)
plt.show()
