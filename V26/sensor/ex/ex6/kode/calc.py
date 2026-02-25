import math

k = 1.38e-23  # Boltzmanns konstant
T = 160       # Kelvin
B = 6e6       # Hz
G_dB = 36
NF_dB = 1.6
R_in = 100    # Ohm
V_p = 22e-6   # Volt amplitude

G = 10**(G_dB/10)
F = 10**(NF_dB/10)

# Støyeffekt inn
P_noise_in = k * T * B
print(f"P_noise_in = {P_noise_in:.3e} W")

# Støyeffekt ut (oppgave 1a)
P_noise_out = G * F * k * T * B
print(f"P_noise_out = {P_noise_out:.3e} W")
print(f"P_noise_out = {10*math.log10(P_noise_out/1e-3):.1f} dBm")

# Signaleffekt inn (oppgave 1b)
P_signal_in = V_p**2 / (2 * R_in)
print(f"\nP_signal_in = {P_signal_in:.3e} W")
print(f"P_signal_in = {10*math.log10(P_signal_in/1e-3):.1f} dBm")

# SNR
SNR = P_signal_in / (F * P_noise_in)
print(f"\nSNR = {SNR:.3f}")
print(f"SNR = {10*math.log10(SNR):.1f} dB")
