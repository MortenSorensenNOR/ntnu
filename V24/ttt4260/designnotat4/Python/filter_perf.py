import os
import csv
import numpy as np
import matplotlib.pyplot as plt

header = []
data_1 = []
data_2 = []
filename1 = "../Data/forste_ordens_filter_respons.csv"
filename2 = "../Data/andre_ordens_filter_respons.csv"

with open(filename1) as csvfile:
    csvreader = csv.reader(csvfile)
    header = next(csvreader)
    for datapoint in csvreader:
        values = [float(value) for value in datapoint]
        data_1.append(values)

with open(filename2) as csvfile:
    csvreader = csv.reader(csvfile)
    header = next(csvreader)
    for datapoint in csvreader:
        values = [float(value) for value in datapoint]
        data_2.append(values)

data_1 = data_1[0:len(data_1) // 2]
data_2 = data_2[0:len(data_2) // 2]

frekvens1 = [(p[0]) for p in data_1]
frekvens2 = [(p[0]) for p in data_2]
respons1 = [(p[2]) for p in data_1]
respons2 = [(p[2]) for p in data_2]

f2600_index = index_of_closest = np.argmin(np.abs(np.array([frekvens1]) - 2600))
f5200_index = index_of_closest = np.argmin(np.abs(np.array([frekvens1]) - 5200))

fig, ax = plt.subplots(figsize=(10, 6))

ax.plot(frekvens1,respons1, label = "Amplituderespons første orden")
ax.plot(frekvens2,respons2, label = "Amplituderespins andre orden")
ax.axvline(x=2600*2, color='r', linestyle='-.', linewidth=1, label='Ideell senterfrekens for filter')
ax.axvline(x=2600, color='b', linestyle='--', linewidth=2, label='Frekvens til inngangssignal $x_1(t)$ - $f$')

ax.scatter(2600, respons1[f2600_index], color='brown', label=f"Demping f første orden: {respons1[f2600_index]:.2f}dB")  # You can customize the color and marker style
ax.scatter(2600, respons2[f2600_index], color='orange', label=f"Demping f andre orden: {respons2[f2600_index]:.2f}dB")  # You can customize the color and marker style

ax.scatter(5200, respons1[f5200_index], color='red', label=f"Demping 2f første orden: {respons1[f5200_index]:.2f}dB")  # You can customize the color and marker style
ax.scatter(5200, respons2[f5200_index], color='green', label=f"Demping 2f andre orden: {respons2[f5200_index]:.2f}dB")  # You can customize the color and marker style

ax.set_xticks(np.arange(0, frekvens1[-1], 2600))
ax.set_xlabel("Frekvens (Hz)")
ax.set_ylabel("Amplituderepons (dB)")
ax.set_title("Amplituderespons til realiserte system")
ax.legend()
ax.grid(True)
# plt.show()

plt.savefig("../Notat/Bilder/test_filter_perf.png")
