import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import linregress

# Filsti til den opplastede CSV-filen
file_path = "ELMAG_res.csv"

# Lese inn filen for å sjekke innholdet
df = pd.read_csv(file_path)

# Hente relevante kolonner
x = df["d(mm)"].values  # Uavhengig variabel (distanse i mm)
y = df["C"].values       # Avhengig variabel (kapasitans i F)

x = np.array([1/v for v in x])
y = np.array([v for v in y])

# Utføre lineær regresjon
(slope, intercept, r_value, p_value, std_err) = linregress(x, y)

# Generere regresjonslinje
x_fit = np.linspace(min(x), max(x), 100)
y_fit = slope * x_fit + intercept

epsilon_0 = 8.85e-12
Area = slope / epsilon_0 * 1/1000
print(f"Calculated area of capasitor plate: \t{Area}")

known_radius = 0.07
print(f"Known area of plate: \t\t\t{np.pi * known_radius**2}")

# Plot resultatene
plt.figure(figsize=(8, 5))
plt.scatter(x, y, label="Måledata", color="blue")
plt.plot(x_fit, y_fit, label=f"Regresjon: C = {slope:.2e} * d + {intercept:.2e}", color="red")
plt.xlabel("d (mm)")
plt.ylabel("C (F)")
plt.title("Lineær regresjon av C vs. d")
plt.legend()
plt.grid()
# plt.show()
plt.savefig("plot.png", dpi=300)

file_path = "ELMAG_res_freq.csv"
df = pd.read_csv(file_path)

# Hente relevante kolonner
x = df["frekvens"].values  # Uavhengig variabel (distanse i mm)
y = df["C"].values       # Avhengig variabel (kapasitans i F)

x = np.array([v for v in x])
y = np.array([v for v in y])

print(x, y)

# Utføre lineær regresjon
(slope, intercept, r_value, p_value, std_err) = linregress(x, y)

# Generere regresjonslinje
x_fit = np.linspace(min(x), max(x), 100)
y_fit = slope * x_fit + intercept

# Plot resultatene
plt.figure(figsize=(8, 5))
plt.scatter(x, y, label="Måledata", color="blue")
plt.plot(x_fit, y_fit, label=f"Regresjon: C = {slope:.2e} * d + {intercept:.2e}", color="red")
plt.xlabel("d (mm)")
plt.ylabel("C (F)")
plt.title("Lineær regresjon av C vs. d")
plt.legend()
plt.grid()
# plt.show()
plt.savefig("plot_freq.png", dpi=300)
