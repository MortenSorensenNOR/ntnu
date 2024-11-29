import numpy as np
import matplotlib.pyplot as plt

# Variabler
iterations = 10**5
mu_g = 9.7929
sigma_g = 2.79
mu_t = 7.02
sigma_t = 1
mu_s = 241.3
sigma_s = 2

g_vals = []
g_vals_sim = []

for _ in range(iterations):
    # Simulerer t og s for å finne g
    t = np.random.normal(loc=mu_t, scale=sigma_t) 
    s = np.random.normal(loc=mu_s, scale=sigma_s) 
    g = (2 * s) / (t**2)
    g_vals_sim.append(g)

    # Genererer g med hensyn på en normalfordeling med mu_g og sigma_g
    g = np.random.normal(loc=mu_g, scale=sigma_g)
    g_vals.append(g)

mu_sim = np.mean(g_vals_sim)
var_sim = np.var(g_vals_sim, ddof=1)

print(f"Simulert: mu = {mu_sim} og varians = {var_sim}")
print(f"Normalfordeling: mu = {mu_g} og varians = {sigma_g**2}")


