import numpy as np

V_DD = 1.8
I_D = 10e-6
V_x = (4*np.sqrt(10) + 45)/100
print(V_x)

R = (V_DD - V_x)/I_D
print(R)
