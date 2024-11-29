import os
import numpy as np
import matplotlib.pyplot as plt
import csv

header1 = []
header2 = []
data1 = []
data2 = []
filename1 = "../Data/forste_ordens_filter_signal.csv"
filename2 = "../Data/andre_ordens_filter_signal.csv"

with open(filename1) as csvfile:
    csvreader = csv.reader(csvfile)
    header1 = next(csvreader)
    for datapoint in csvreader:
        values = [float(value) for value in datapoint]
        data1.append(values)

data1 = data1[len(data1)//2:int(2.5 * len(data1)//4)]

with open(filename2) as csvfile:
    csvreader = csv.reader(csvfile)
    header2 = next(csvreader)
    for datapoint in csvreader:
        values = [float(value) for value in datapoint]
        data2.append(values)

data2 = data2[len(data2)//2:int(2.5 * len(data2)//4)]

time1 = [(p[0]) for p in data1]
ch1_1 = [(p[1]) for p in data1]
ch2_1 = [(p[2]) for p in data1]

time2 = [(p[0]) for p in data2]
ch1_2 = [(p[1]) for p in data2]
ch2_2 = [(p[2]) for p in data2]

fig, ax = plt.subplots(figsize=(10, 6))

ax.plot(time1, ch1_1, label = "$x_1(t)$")
ax.plot(time1, ch2_1, label = "Første ordens filter $\hat{x}_2(t)$")
ax.plot(time2, ch2_2, label = "Andre ordens filter $\hat{x}_2(t)$")

ax.set_xlabel("Tid (s)")
ax.set_ylabel("Spenning (V)")
ax.set_title("Inngangssignal $x_1(t)$ vs. utgangssignal $\hat{x}_2(t)$")
ax.legend(loc="upper right")

# plt.show()
plt.savefig("../Notat/Bilder/test_analog_resulting_waveform.png")
