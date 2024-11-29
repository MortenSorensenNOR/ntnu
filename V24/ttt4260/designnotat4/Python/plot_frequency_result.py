import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

data_path = '../Data/andre_ordens_filter_spektrum.csv'
data = pd.read_csv(data_path)

frekvens = data['Frequency (Hz)'][:len(data['Frequency (Hz)'])//2]
respons = data['Trace 2 (dBV)'][:len(data['Frequency (Hz)'])//2]

f2600_index = np.argmin(np.abs(np.array([frekvens]) - 2600))
f5200_index = np.argmin(np.abs(np.array([frekvens]) - 5200))

fig, ax = plt.subplots(figsize=(10, 6))

ax.plot(frekvens, respons, label='Spektrum av utgangssignal $\hat{x}_2(t)$')
ax.scatter(2600, respons[f2600_index], color='brown', label="Demping av frekvenskomponent ved f i $\hat{x}_2(t)$:" + f" {respons[f2600_index]:.2f}dBV")
ax.scatter(5200, respons[f5200_index], color='green', label="Demping av frekvenskomponent ved 2f i $\hat{x}_2(t)$:" + f" {respons[f5200_index]:.2f}dBV")   

ax.set_title('Frekvensspektrum til utgangen av systemet $\hat{x}_2(t)$ ved inngangsfrekvens $f = 2600$Hz')
ax.set_xlabel('Frekvens (Hz)')
ax.set_ylabel('Level (dBV)')
ax.set_xticks(np.arange(0, np.array(frekvens)[-1], 2600))
ax.grid(True)
ax.legend()


plt.tight_layout()
# plt.show()
plt.savefig("../Notat/Bilder/test_analog_resulting_spectrum.png")
