import os
import numpy as np
import matplotlib.pyplot as plt
import csv

header = []
data = []
filename = "../Data/ulin_signal_250kHz.csv"

with open(filename) as csvfile:
    csvreader = csv.reader(csvfile)
    header = next(csvreader)
    for datapoint in csvreader:
        values = [float(value) for value in datapoint]
        data.append(values)

data = data[len(data)//2:int(2.5 * len(data)//4)]

time = [(p[0]) for p in data]
ch1 = [(p[1]) for p in data]
ch2 = [(p[2]) for p in data]

fig, ax = plt.subplots(figsize=(10, 6))

ax.plot(time, ch1, label = "$x_1(t)$")
ax.plot(time, ch2, label = "Første ordens filter $x_2(t)$")

ax.set_xlabel("Tid (s)")
ax.set_ylabel("Spenning (V)")
ax.set_title("Inngangssignal $x_1(t)$ vs. utgangssignal $x_2(t)$")
ax.legend(loc="upper right")

plt.show()
