import time
import numpy as np
from sympy import nextprime

"""
r = 2^k
r_inv is such that r * r^-1 = 1 mod n
n_prime is such that r * r_inv - n * n_prime = 1

We may find r_inv and n_prime using the Extended Euclidean Algorithm
"""

def ExtendedGCD(a, b):
    if a == 0:
        return (b, 0, 1)

    gcd, x1, y1 = ExtendedGCD(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return (gcd, x, y)

def MontgomeryInverse(r, n):
    _, r_inv, n_prime = ExtendedGCD(r, n) # gcd(r, n) = 1
    r_inv = r_inv % n
    n_prime = (1 - r * r_inv) // n # n_prime = (gcd - r * r_inv) / n
    return r_inv, -n_prime

def MontgomeryProduct(a_bar, b_bar, n, n_prime, k):
    t = a_bar * b_bar
    m = t * n_prime % (1 << k)
    u = (t + m * n) >> k
    if u >= n:
        return u - n
    else:
        return u

def MontgomeryModularExponentiation(M, e, n, k):
    """
    This function only works if n is an odd number
    """
    r = 1 << k
    r_inv, n_prime = MontgomeryInverse(r, n)
    M_bar = (M * r) % n
    x_bar = r % n

    for i in range(k - 1, -1, -1):
        x_bar = MontgomeryProduct(x_bar, x_bar, n, n_prime, k)
        if (e >> i) & 1:
            print(x_bar, M_bar, n, n_prime, k)
            x_bar = MontgomeryProduct(x_bar, M_bar, n, n_prime, k)
            print(x_bar)

    x = MontgomeryProduct(x_bar, 1, n, n_prime, k)
    return x

def ModInverse(x, w):
    y = pow(x, -1, 2**w) # Can be done more efficiently in hardware, see algorithm doc
    return y

def MontgomeryModularExponentiationAllN(M, e, n, k):
    if (n % 2 == 1):
        return MontgomeryModularExponentiation(M, e, n, k)
    
    # Calculate q and j, where q * 2^j = n
    j = 0
    for i in range(0, k+1):
        j = i
        if ((n >> i) & 1) == 1:
            break
    q = n >> j

    x_1 = MontgomeryModularExponentiation(M, e, q, k)
    x_2 = pow(M, e, 2**j) # Can be done more efficiently in hardware
    q_inv = ModInverse(q, j)

    y = pow((x_2 - x_1) * q_inv, 1, 2**j)
    x = x_1 + q * y
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

k = 32
p = 29
q = 73
n = (p * q)

M = 12
e = 65537

gcd = np.gcd(e, (p - 1) * (q - 1))
if (gcd != 1):
    print("Error: gcd(e, (p - 1) * (q - 1)) != 1")
    exit()
assert(np.log2(n) <= k)

x_mont = MontgomeryModularExponentiationAllN(M, e, n, k)
x_verify = ModularExponentiationVerify(M, e, n)

print(x_mont, x_verify)

assert(x_mont == x_verify)
