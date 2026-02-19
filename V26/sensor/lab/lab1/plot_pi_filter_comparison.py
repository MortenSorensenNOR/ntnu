import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Filter components
C1 = 100e-6    # 100 µF (left leg)
L = 100e-3     # 100 mH (series inductor)
C2 = 470e-6    # 470 µF (right leg)
C3 = 100e-9    # 100 nF (right leg, parallel with C2)
C_right = C2 + C3  # Total right leg capacitance

# Read the CSV files
df_no_r = pd.read_csv('data/power_filter.csv', comment='#')
df_20ohm = pd.read_csv('data/power_filter_20ohm.csv', comment='#')

# Extract frequency and magnitude data (Channel 2 is relative to Channel 1)
freq_no_r = df_no_r['Frequency (Hz)']
mag_no_r = df_no_r['Channel 2 Magnitude (dB)']

freq_20ohm = df_20ohm['Frequency (Hz)']
mag_20ohm = df_20ohm['Channel 2 Magnitude (dB)']


def pi_filter_response(freq, L, C, R=0):
    """
    Calculate magnitude response of LC pi filter in dB.

    Transfer function: H(s) = 1 / (s²LC + sRC + 1)

    Note: C1 doesn't affect V_out/V_in when V_in is measured at filter input.
    """
    s = 2j * np.pi * freq
    H = 1 / (s**2 * L * C + s * R * C + 1)
    return 20 * np.log10(np.abs(H))


# Generate theoretical response
freq_theory = np.logspace(0, 3, 500)  # 1 Hz to 1000 Hz
mag_theory_ideal = pi_filter_response(freq_theory, L, C_right, R=0)
mag_theory_20ohm = pi_filter_response(freq_theory, L, C_right, R=20)

# Calculate resonant frequency
f0 = 1 / (2 * np.pi * np.sqrt(L * C_right))
print(f"Resonant frequency: {f0:.2f} Hz")

# Create plot
fig, ax = plt.subplots(figsize=(10, 6))

# Plot theoretical curves
ax.semilogx(freq_theory, mag_theory_ideal, 'k--',
            label='Theoretical (ideal)', linewidth=1.5)
ax.semilogx(freq_theory, mag_theory_20ohm, 'k:',
            label='Theoretical (20Ω)', linewidth=1.5)

# Plot measured data
ax.semilogx(freq_no_r, mag_no_r, 'C0',
            label='Measured (no resistor)', linewidth=1.5)
ax.semilogx(freq_20ohm, mag_20ohm, 'C1',
            label='Measured (20Ω resistor)', linewidth=1.5)

# Mark resonant frequency
ax.axvline(x=f0, color='gray', linestyle='-.', alpha=0.5,
           label=f'$f_0$ = {f0:.1f} Hz')

ax.set_xlabel('Frequency (Hz)')
ax.set_ylabel('Magnitude (dB)')
ax.set_title('LC Pi Filter Comparison')
ax.grid(True, which='both', linestyle='-', alpha=0.7)
ax.legend(loc='lower left')
ax.set_xlim([1, 1000])

plt.tight_layout()
plt.savefig('pi_filter_comparison.png', dpi=150)
plt.show()

print("Plot saved to pi_filter_comparison.png")
