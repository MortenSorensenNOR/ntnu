import timeit
import numpy as np

def original(A):
    GD = 1
    perfect_square = False

    i = 2
    while i < A:
        rem = A % i
        if (rem == 0):
            GD = A / i
            break
        i += 1

    for j in range(i, A):
        j2 = j * j 
        if j2 == A:
            perfect_square = True
            break

    return [int(GD), perfect_square]

def optimized(A):
    GD = 1
    perfect_square = False

    i = 2
    while i < A:
        rem = A % i
        if (rem == 0):
            GD = int(A / i)
            break
        i += 1

    # Get log2 of A
    i = 0
    mask: int = 1 << 32
    while i < 32:
        bit = A & mask
        if bit:
            break
        mask = mask >> 1
        i += 1

    print(i)

    log2_A = 32 - i + 1
    if log2_A & 1:
        log2_A += 1

    sqrt_upper_bound = 1 << (log2_A >> 1)
    print(sqrt_upper_bound)

    # Find if number is perfect square
    for i in range(sqrt_upper_bound, 1, -1):
        i2 = i*i
        if i2 == A:
            perfect_square = True 
            break
        elif i2 < A:
            break
    
    return [GD, perfect_square]

optimized(2401)

# Test
# for i in range(1, 10000):
#     [orig_gd, orig_ps] = original(i)
#     [opti_gd, opti_ps] = optimized(i)
#
#     assert(orig_gd == opti_gd)
#     assert(orig_ps == opti_ps)

# print("All good :)")
