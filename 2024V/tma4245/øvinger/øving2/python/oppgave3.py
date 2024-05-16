import numpy as np
import matplotlib.pyplot as plt

def generateX(n,alpha):
    u = np.random.uniform(size=n) #array med n elementer.
    x = np.sqrt(-alpha * np.log(1 - u))
    return x

# Sett antall realisasjoner og verdien til alpha
n = 10000000
alpha = 1

# simuler realisasjoner av X
simulerte_X = generateX(n, alpha)

# Lag sannsynlighetshistogram for de simulerte verdiene,
# vi spesifiserer antall intervaller ved å sette "bins=100"
plt.hist(simulerte_X, density=True,bins=100, label="Simulert")

# Angi navn på aksene
plt.xlabel("Levetid")
plt.ylabel("$f_X(x)$")

# Regn ut og plott sannsynlighetstettheten til X på samme plott
x = np.linspace(0, 4, 10000)
f_x = 2 * x * np.exp(-x**2/alpha) / alpha
plt.plot(x, f_x, label="Analytisk")

plt.legend()

# Avslutt med å generere alle elementene du har plottet
# plt.show()
plt.savefig("f_x.png", dpi=500)
