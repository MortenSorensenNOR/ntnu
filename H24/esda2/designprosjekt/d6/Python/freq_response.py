import numpy as np
import matplotlib.pyplot as plt

# Plot FFT of input and output signal
# Should plot frequency vs. maginitude in dBV
# All signal values are in volts
file = "inverting_100k_signal"
data = np.genfromtxt(f'../Data/{file}.csv', delimiter=',', skip_header=1)

# Plot input and output signal magnitude vs frequency
t = data[:, 0]
v_pluss = data[:, 1]
v_out = data[:, 2]


# Normalize input and output signal
v_pluss = v_pluss - np.mean(v_pluss)
v_out = v_out - np.mean(v_out)

# Calculate FFT of input and output signal
fft_v_pluss = np.fft.fft(v_pluss)
fft_v_out = np.fft.fft(v_out)

# Calculate magnitude of FFT
mag_v_pluss = np.abs(fft_v_pluss)
mag_v_out = np.abs(fft_v_out)

# Convert magnitude to dBV
mag_v_pluss_dbv = 20*np.log10(mag_v_pluss)
mag_v_out_dbv = 20*np.log10(mag_v_out)

# Calculate frequency axis
N = len(t)
f = np.fft.fftfreq(N, d=t[1]-t[0])
freq_10khz_index = np.where(f >= 10000)[0][0]

# Plot magnitude vs frequency (but only 0 to 10kHz)
plt.plot(f[1:freq_10khz_index], mag_v_pluss_dbv[1:freq_10khz_index], label='$v^{+}(f)$')
plt.plot(f[1:freq_10khz_index], mag_v_out_dbv[1:freq_10khz_index], label='$v_{out}(f)$')

# Add labels and title
plt.title(f'Inverterende forsterker frekvensspekter, $A = 10$, $R_L = 100$k$\Omega$, $v^+ = {int(np.ceil(np.max(v_pluss)*1000))}$mV')
plt.xlabel('Frekvens (Hz)')
plt.ylabel('Magnitude (dBV)')
plt.legend(loc='upper right')
plt.grid()
# plt.show()
plt.savefig(f'../Notat/Bilder/{file[:-7]}_freq.png')
