import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

data_path = '../Data/ulin_sys_spektrum.csv'
data = pd.read_csv(data_path)

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 12))

ax1.plot(data['Frequency (Hz)'], data['Trace 1 (dBV)'], label='Inngangssignal $x_1(t)$')
ax1.set_title('Frekvensspektrum til inngangssignalet $x_1(t)$ ved $f = 2600$Hz')
ax1.set_xlabel('Frekvens (Hz)')
ax1.set_ylabel('Level (dBV)')
ax1.grid(True)

ax2.plot(data['Frequency (Hz)'], data['Trace 2 (dBV)'], label='Utgangssignal $y(t)$')
ax2.set_title('Frekvensspektrum til utgangen av systemet $y(t)$ ved $f = 2600$Hz')
ax2.set_xlabel('Frekvens (Hz)')
ax2.set_ylabel('Level (dBV)')
ax2.grid(True)

ax1.set_xticks(np.arange(0, np.array(data['Frequency (Hz)'])[-1], 2600))
ax2.set_xticks(np.arange(0, np.array(data['Frequency (Hz)'])[-1], 2600))

plt.tight_layout()
plt.savefig("../Notat/Bilder/ulin_sys_spektrum_plot.png")

