import time
import numpy as np

def MonPro_Alg(a_bar, b_bar, n, n_prime, k):
    t = a_bar * b_bar
    m = t * n_prime % (1 << k)
    print(f"m: {t * n_prime} % {1 << k} = {m}")
    u = (t + m * n) >> k
    if u >= n:
        return u - n
    else:
        return u

def MonPro_Hardware(a_bar, b_bar, n, k):
    u = 0
    for i in range(k):
        u = u + ((a_bar >> i) & 1) * b_bar
        print(f"u: {u}")
        if u & 1:
            u = u + n
        u = u >> 1
    return u

x_bar = 1930
M_bar = 1990
n = 2117
n_prime = 1217279347
k = 32

start = time.time()
alg = MonPro_Alg(x_bar, M_bar, n, n_prime, k)
end = time.time()
# print("Algorithm:", end - start)

start = time.time()
hardware = MonPro_Hardware(x_bar, M_bar, n, k)
end = time.time()
# print("Hardware:", end - start)
#
print(alg, hardware)
assert(alg == hardware)
