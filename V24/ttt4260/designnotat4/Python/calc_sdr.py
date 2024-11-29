import numpy as np

def calc(x_hat, x2):
    sdr = (x2**2)/(x_hat**2 - x2**2)
    sdr_db = 10 * np.log10(sdr)
    return sdr, sdr_db

x_hat = 7.14
x2 = 6.25

x2 = x2 * 1e-3
x_hat = x_hat * 1e-3

print(calc(x_hat, x2))
