import numpy as np
import matplotlib.pyplot as plt
import sounddevice as sd

time = 4  # seconds
Fs = 3000 # Hz

dt = 1 / (time * Fs)
t = np.arange(0, time * Fs)

f1 = 0.3
x  = np.cos(2 * np.pi * f1 * t)

sd.play(x, Fs)
sd.wait()
