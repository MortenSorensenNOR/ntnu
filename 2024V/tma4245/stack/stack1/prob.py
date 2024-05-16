import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import fsolve

def f(t):
    if t <= 0:
        return 0
    return np.exp(-t)


