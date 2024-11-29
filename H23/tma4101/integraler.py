import numpy as np

def f(x):
    return 1/np.sqrt(2*np.pi) * np.exp(-(x**2)/2)

def calc_normaldistribution(a, b, n):
    val = 0
    dx = (b-a)/n
    c = a + dx
    while c <= b:
        val += (np.sinc(c) + np.sinc(c - dx))/2 * dx
        c += dx
    return val

print(calc_normaldistribution(0, np.pi, 10))
