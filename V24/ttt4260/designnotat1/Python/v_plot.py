import statistics 
import numpy as np
from scipy.stats import norm

# Plotting
import matplotlib.pyplot as plt

# Lese CSV
import csv


def read_csv(filename):
    header = []
    data = []

    # Henter data fra csvfil
    with open(filename) as csvfile:
        csvreader = csv.reader(csvfile)
    
        # Leser første linje i csv-fila (den med navn til kanalene)
        header = next(csvreader)
        for datapoint in csvreader:
            values = [float(value) for value in datapoint]
            data.append(values)

    # Legger inn data fra hver kanal i hver sin liste
    time = np.array([(p[0]) for p in data])
    ch1 = np.array([(p[1]) for p in data])
    ch2 = np.array([(p[2]) for p in data])

    return time, ch1, ch2

def plot_voltage(ax, time, ch1, ch2, title, label):
    # # Spennings plot
    ax.plot(time,ch1, label = '$v_1(t)$')
    ax.plot(time,ch2, label = '$v_2(t)$')

    # Tittel og aksenavn
    ax.set_title(title)
    ax.set_xlabel('Tid (s)')
    ax.set_ylabel('Spenning (V)')

    # Legend, loc = plassering
    ax.legend(loc='upper right')

    # Rutenett
    ax.grid(True)

def plot_gain(ax, time, ch1, ch2, title, label="$A_{max}$"):
    # Regner ut
    Amp_val = ch2/ch1
    
    # Amplitude plot
    ax.plot(time, Amp_val, label=f"{label}")
    
    ax.set_title(title)
    ax.set_xlabel('Tid (s)')
    ax.set_ylabel('Demping')

    ax.legend(loc='upper right')

def plot_gain_gausian(ax, time, ch1, ch2, title, label=""):
    Amp_val = ch2/ch1
    Amp_val = sorted([val for val in Amp_val if val >= 0 and val <= 1], reverse=True)
    print(max(Amp_val), 20*np.log10(max(Amp_val)))
    Amp_val = [20*np.log10(val) for val in Amp_val]
    weights = np.ones_like(Amp_val)/len(Amp_val)

    mu, std = norm.fit(Amp_val)
    print(mu, std)

    ax.hist(Amp_val, bins=250, density=True, alpha=0.7, color="blue", edgecolor="black", label="Histogram")
    
    x = np.linspace(np.min(Amp_val), np.max(Amp_val), 1000)
    ax.plot(x, norm.pdf(x, mu, std), label="Tilpasset gausisk fordeling", color="orange")

    ax.axvline(mu, color='red', linestyle='dashed', linewidth=2, label=f'Gjennomsnitt = {mu:.2f}')
    ax.axvline(mu + std, color='turquoise', linestyle='dashed', linewidth=2, label=f'Standard avvik = {std:.2f}')
    ax.axvline(mu - std, color='turquoise', linestyle='dashed', linewidth=2)

    ax.set_title(title)
    ax.set_xlabel('Demping [db]')
    ax.set_ylabel('')

    half = 1 if abs(round(mu - 6*std) - round(mu + 6*std)) < 8 else 0
    ax.set_xticks(np.arange(round(mu + 6*std), round(mu - 6*std), -0.5 if half else -1))
    ax.set_xlim(round(mu - 6*std), round(mu + 6*std))
    ax.legend(loc='upper right')

def desibel_plot(ax, time, ch1, ch2, title, label=""):
    Amp_val = ch2/ch1
    Amp_val = [20*np.log10(val) for val in Amp_val]
    
    ax.plot(time, Amp_val, label=label)
    
    ax.set_title(title)
    ax.set_xlabel('Tid [s]')
    ax.set_ylabel('Demping [dB]')

    ax.legend(loc='upper right')

# A_min = acq0001.csv 
# A_max = acq0005.csv
filename1 = '../Maalinger/acq0002.csv'
filename2 = '../Maalinger/acq0005.csv'

time1, ch1_1, ch2_1 = read_csv(filename1)
time2, ch1_2, ch2_2 = read_csv(filename2)

Amp_val_1 = ch2_1/ch1_1
Amp_val_1 = [val for val in Amp_val_1 if val >= 0]
Amp_val_1 = [20*np.log10(val) for val in Amp_val_1]

Amp_val_2 = ch2_2/ch1_2
Amp_val_2 = [val for val in Amp_val_2 if val >= 0]
Amp_val_2 = [20*np.log10(val) for val in Amp_val_2]

# Plotting
fig, ax = plt.subplots(2,1, figsize=(10,6))
fig.tight_layout(pad=2.5)
fig.set_figheight(6.5)
fig.set_figwidth(7.5)

plot_voltage(ax[0], time1, ch1_1, ch2_1, "$A_{min}$", "$v_2/v_1$")
plot_voltage(ax[1], time2, ch1_2, ch2_2, "$A_{max}$", "$v_2/v_1$")

# plt.show()
plt.savefig("../Notat/Bilder/voltage_plot.png", dpi=500)
