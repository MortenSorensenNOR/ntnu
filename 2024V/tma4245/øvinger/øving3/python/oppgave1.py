# Importer nødvendige biblioteker, denne cellen må kjøres før annen kode.
import numpy as np
import matplotlib.pyplot as plt

# UTLEVERT KODE (ingenting her skal endres)
# punktsannsynlighet
f_x = np.array([0.05,0.10,0.25,0.40,0.15,0.05])

# kumulativ fordelingsfunksjon
F_x = [np.sum(f_x[:i]) for i in range(1,7)]

def simX(n):
    # verdimengde
    x = np.arange(6)
    
    # for lagring av realisasjoner
    x_sim = np.zeros(n)
    
    for i in range(n): # vi simulerer hver og en x for seg
        u = np.random.uniform() # en realisasjon fra U(0,1)
        if(u < F_x[0]): # hvis u er mindre enn den laveste
            # verdien i F_x vil
            # vi at realisasjonen skal være 0
            x_sim[i] = x[0]
        elif(u <= F_x[1]): # hvis u er mindre enn den nest
            # laveste verdien (men større enn laveste)
            # vil vi at x skal bli 1
            x_sim[i] = x[1]
        elif(u <= F_x[2]):
            x_sim[i] = x[2]
        elif(u <= F_x[3]):
            x_sim[i] = x[3]
        elif(u <= F_x[4]):
            x_sim[i] = x[4]
        elif(u > F_x[4]):
            x_sim[i] = x[5]
    
    return x_sim

n = 10000
simulert_X = simX(n)

P_X_le_2 = [x for x in simulert_X if x <= 2]
P_X_le_2 = len(P_X_le_2) / n

print("Approksimert sannsynlighet: ", P_X_le_2)

# Forventningsverdi
E_X = sum([x * v for x, v in enumerate(f_x)])
print(f"E[X] = {E_X}")

# Varians
Var_X = sum([x**2 * v for x, v in enumerate(f_x)]) - sum([x * v for x, v in enumerate(f_x)]) ** 2
print(f"Var[X] = {Var_X}")

# Simulert forventningsverdi og standardavvik
E_sim_X = sum(simulert_X) / n
print(f"Simulert E[X] = {E_sim_X}")

SD_sim_X = np.std(simulert_X)
print(f"Simulert SD[X] = {SD_sim_X}")
