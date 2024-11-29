import numpy as np
import matplotlib.pyplot as plt

def S_n(n, t):
    s = 0
    for i in range(1,n):
        s += 2 * (-1)**(i+1)/i * np.sin(i*t)
    return s

def S_n2(n, t):
    s = 1/2
    for i in range(1,n):
        s += 2/np.pi * 1/(2*i-1)*np.sin(2*i-1)*t
    return s


t = np.linspace(0, 2*np.pi, 500)

x1_1 = S_n(10, t)
x1_2 = S_n(100, t)
x1_3 = S_n(1000, t)
x1_4 = S_n(10000, t)

x2_1 = S_n2(1000, t)
x2_2 = S_n2(10000, t)
x2_3 = S_n2(100000, t)
# x2_4 = S_n2(10000, t)

fig, ax = plt.subplots(2, 1)

ax[0].plot(t, x1_1, label="n=10")
ax[0].plot(t, x1_2, label="n=100")
ax[0].plot(t, x1_3, label="n=1000")
ax[0].plot(t, x1_4, label="n=10000")

ax[1].plot(t, x2_1, label="n=1000")
ax[1].plot(t, x2_2, label="n=10000")
ax[1].plot(t, x2_3, label="n=100000")
# ax[1].plot(t, x2_4, label="n=10000")

ax[0].legend()
ax[1].legend()
plt.show()
