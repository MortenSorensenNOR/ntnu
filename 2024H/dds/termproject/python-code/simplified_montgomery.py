import math
import numpy as np
import random
from Crypto.Util import number
from Crypto.Util.number import inverse

def MonPro(a_bar, b_bar, n, k):
    u = 0
    for i in range(k):
        u = u + ((a_bar >> i) & 1) * b_bar
        if u & 1:
            u = u + n
        u = u >> 1
    return u

def RSA_Montgomery(M, e, n, k):
    k = k + 1
    r = 1 << k
    r_square = (r * r) % n
    M_bar = MonPro(M, r_square, n, k)
    x_bar = r % n

    for i in range(k - 1, -1, -1):
        x_bar = MonPro(x_bar, x_bar, n, k)

        if (e >> i) & 1:
            x_bar = MonPro(M_bar, x_bar, n, k)

    x = MonPro(x_bar, 1, n, k)

    return x

def ModularExponentiationVerify(base, exp, mod):
    result = 1
    base = base % mod

    while exp > 0:
        if exp % 2 == 1:
            result = (result * base) % mod
        
        base = (base * base) % mod
        exp = exp // 2

    return result

k = 64

p = number.getPrime(16)
q = number.getPrime(16)
n = (p * q)
phi = (p - 1) * (q - 1)

assert(n < (1 << k))

e = 65537
d = inverse(e, phi)

M = 12312321321421

x_mont_encrypt = RSA_Montgomery(M, e, n, k)
x_verify_encrypt = ModularExponentiationVerify(M, e, n)
assert(x_mont_encrypt == x_verify_encrypt)

x_mont_decrypt = RSA_Montgomery(x_mont_encrypt, d, n, k)
x_verify_decrypt = ModularExponentiationVerify(x_mont_encrypt, d, n)
assert(x_mont_decrypt == x_verify_decrypt)
