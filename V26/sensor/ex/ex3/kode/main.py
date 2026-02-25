import numpy as np
import matplotlib.pyplot as plt

nrand = int(1e4)
c = 343

# oppgave 2
tauvec = lambda: (1 + 2*0.01*(np.random.rand(nrand) - 0.5))
dvec   = lambda: (1 + 2*0.02*(np.random.rand(nrand) - 0.5))
f = tauvec() / dvec()
print(f"f maks relativ feil: {np.max(f)}")

# oppgave 3
thetas = np.linspace(0.001, np.pi/2, 20)
relative_erros = []

montecarlo_verdier = []
teoretisk_verdier = []

d_real = 0.1
for theta in thetas:
    f = np.cos(theta)
    fc = f / c
    tau = fc * d_real

    dvals = dvec() * d_real
    tauvals = tauvec() * tau

    theta_vals = []
    for i in range(len(dvals)):
        if tauvals[i] * c > dvals[i]:
            continue
        theta_vals.append(float(np.arccos(c * tauvals[i] / dvals[i])))
    
    feil = max(abs(theta_vals - theta))
    rel_feil = feil / theta
    teoretisk = 0.03 * abs(1 / np.tan(theta)) * 1 / abs(theta)
    montecarlo_verdier.append(rel_feil)
    teoretisk_verdier.append(teoretisk)

    print(f"theta: {theta}, maks relativ feil: {rel_feil}")
    print(f"theoretisk mask relativ feil: {teoretisk}")
    print()

plt.plot(thetas, np.array(montecarlo_verdier), label="Montecarlo simulert")
plt.plot(thetas, np.array(teoretisk_verdier), label="Teoretisk")
plt.yscale('log')
plt.xlabel(r"$\theta$")
plt.ylabel(r"$|\Delta\theta|/|\theta|_\max$")
plt.legend()
plt.show()
