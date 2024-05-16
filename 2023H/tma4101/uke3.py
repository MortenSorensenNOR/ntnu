import numpy as np
import matplotlib.pyplot as plt

def g(x):
    return 1/np.log(x)

x = np.linspace(1, 5)
y = g(x)

plt.plot(x, x)
plt.plot(x, y)
plt.show()
