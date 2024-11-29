import numpy as np

x_vals = np.array([1.4, 1.0, 1.6, 1.1, 1.0])

mu_l = 0.852
mu_u = 1.588

new_mu_l = np.exp(mu_l + 0.5*0.5**2)
new_mu_u = np.exp(mu_u + 0.5*0.5**2)

print(new_mu_l, new_mu_u)
