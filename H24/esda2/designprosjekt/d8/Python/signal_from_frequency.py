import numpy as np
import matplotlib.pyplot as plt

# File path
data_path = "../Data"
file = "lfsr_noise_freq.csv"
file_path = data_path + "/" + file

# Read frequency spectrum data from file 
data = np.loadtxt(file_path, delimiter=",", skiprows=1)

# Extract data columns
freq = data[:,0]
amp1 = data[:,1]
# amp2 = data[:,3]

# Generate signal from frequency spectrum
# Generate time vector
Fs = 40000
t = np.arange(1, 1.01, 1/Fs)

# Generate signal from frequency spectrum
signal = np.zeros(len(t))
for i in range(len(freq)):
    signal += amp1[i] * np.sin(2 * np.pi * freq[i] * t)

# Plot signal
plt.plot(t, signal)
plt.xlabel("Tid (s)")
plt.ylabel("Amplitude")
plt.title("Signal generert fra frekvensspekter")
plt.show()

