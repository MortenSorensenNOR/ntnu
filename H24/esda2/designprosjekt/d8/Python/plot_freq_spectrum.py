import numpy as np
import matplotlib.pyplot as plt

# File path
data_path = "../Data"
file = "total_system_freq_1h.csv"
file_path = data_path + "/" + file

# Read frequency spectrum data from file 
data = np.loadtxt(file_path, delimiter=",", skiprows=1)

# Extract data columns
freq = data[:,0]
amp1 = data[:,1]
amp2 = data[:,3]

# Find frequencies where amplitude is -3dB from peak
# amp3dB = amp2.max() - 3
# print(f"3dB amplitude: {amp3dB}")
# f3dB = freq[np.where(amp2 >= amp3dB)]
# f3dB = np.concatenate((freq[np.where(freq == f3dB[0])[0]-1], f3dB, freq[np.where(freq == f3dB[-1])[0]+1]))
#
# # The data does not contain the exact 3dB amplitude, so we interpolate the frequency from f3dB[0] and f3dB[1]
# band_start = f3dB[0] + (amp3dB - amp2[np.where(freq == f3dB[0])]) / (amp2[np.where(freq == f3dB[1])] - amp2[np.where(freq == f3dB[0])]) * (f3dB[1] - f3dB[0])
# band_end = f3dB[-1] + (amp3dB - amp2[np.where(freq == f3dB[-1])]) / (amp2[np.where(freq == f3dB[-2])] - amp2[np.where(freq == f3dB[-1])]) * (f3dB[-2] - f3dB[-1])
#
# print(band_start, band_end)
#
# # Calculate Q factor
# Q = band_start / (band_end - band_start)
# print(f"Band width: {band_end - band_start}")
# print(f"Q factor: {Q}")
# print(f"Band start: {band_start}")
# print(f"Band end: {band_end}")

# Plot frequency spectrum
plt.plot(freq, amp1, label="Støysignal $s(f)$")
plt.plot(freq, amp2, label="Båndbegrenset signal $y(f)$")

# Plot stippled vertical line at 3320 Hz
plt.axvline(x=3320, color='k', linestyle='--', label="3320 Hz")

# Plot stippled vertical line at band start
# plt.axvline(x=band_start, color='r', linestyle='--', label="Bandstart")
#
# # Plot stippled vertical line at band end
# plt.axvline(x=band_end, color='g', linestyle='--', label="Bandslutt")

plt.xlabel("Frekvens (Hz)")
plt.ylabel("Amplitude (dBV)")
# plt.xscale("log")

plt.title("Frekvensspekter til ferdig system ved $H_0 = 1$")
plt.legend()
# plt.show()

# Save plot as image
save_path = "../Notat/Bilder"
save_file = "total_system_freq.png"
plt.savefig(save_path + "/" + save_file)
