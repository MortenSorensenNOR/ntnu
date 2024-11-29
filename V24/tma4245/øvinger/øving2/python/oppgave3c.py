import numpy as np
import matplotlib.pyplot as plt

def generateX(n,alpha):
    u = np.random.uniform(size=n) #array med n elementer.
    x = np.sqrt(-alpha * np.log(1 - u))
    return x

def generateY(n):
    x_vals = [generateX(n, 1), generateX(n, 1), \
              generateX(n, 1.2), generateX(n, 1.2), \
              generateX(n, 1.2)]
    x = []
    for i in range(n):
        x.append([x_vals[0][i], x_vals[1][i], x_vals[2][i], x_vals[3][i], x_vals[4][i]])
        
    x_sorted = []
    for i in range(n):
        x_sorted.append(sorted(x[i]))

    y = []
    for i in range(n):
        y.append(x[i][2])
    return np.array(y)

n = 100000

simulerte_Y = generateY(n)
plt.hist(simulerte_Y, density=True,bins=100, label="Simulert")

plt.xlabel("Levetid")
plt.ylabel("f_Y(y)")

# plt.show()
plt.savefig("multi.png", dpi=500)
