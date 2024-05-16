import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

data_path = '../Data/andre_ordens_filter_spektrum.csv'
data = pd.read_csv(data_path)

fig, ax = plt.subplots(figsize=(10, 6))

ax.plot(np.array(data['Frequency (Hz)'])[:int(3 * len(data['Frequency (Hz)']) // 4)], np.array(data['Trace 2 (dBV)'])[:int(3 * len(data['Frequency (Hz)']) // 4)], label='Spektrumet av utgangssignalet $x_2(t)$', color='blue')
ax.set_title('Frekvensspektrum til inngangssignalet ved $f = 2600$Hz')
ax.set_xlabel('Frekvens (Hz)')
ax.set_ylabel('Level (dBV)')
ax.grid(True)

ax.set_xticks(np.arange(0, np.array(data['Frequency (Hz)'])[int(3 * len(data['Frequency (Hz)']) // 4)], 2600))
ax.legend()

plt.tight_layout()
plt.savefig("../Notat/Bilder/test_analog_resulting_spectrum.png")
# plt.show()
