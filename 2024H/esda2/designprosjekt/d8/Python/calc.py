import numpy as np
import matplotlib.pyplot as plt

# Read freq data from ../Data/bandpass_filter_freq.csv
# Freq, Channel 1 Mag dB, Channel 2 Mag dB, Channel 2 Phase (deg)
data = np.genfromtxt('../Data/bandpass_filter_freq.csv', delimiter=',', skip_header=1) 

# Get data
freq = data[:,0]
channel1 = data[:,1]
channel2 = data[:,2]
phase = data[:,3]
