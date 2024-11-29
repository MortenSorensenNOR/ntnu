import numpy as np
import matplotlib.pyplot as plt

n = 25
alpha = 0.5
beta = 0.25
sigma = 0.10

x = np.array([-3.842, -3.784, -3.745, -3.708, -3.37,  -3.288, -2.312, -2.078, -2.019, 
              -1.595,-1.106, -0.352, -0.171,  1.166,  2.196,  2.538,  2.772,  3.186,  
              3.309,3.876, 4.2,    4.261,  4.337,  4.352,  4.359])

y = alpha + beta * x + np.random.normal(loc=0, scale=np.sqrt(sigma**2 * (0.1 + x**2)), size=n)

def estimerELR(x,y):
    xStrek = np.mean(x)
    yStrek = np.mean(y)

    betaHat = np.sum((x-xStrek)*y)/np.sum((x-xStrek)**2)
    alphaHat = yStrek - betaHat * xStrek
    S2 = np.sum((y-(alphaHat+betaHat*x))**2)/(len(x)-2)

    return [alphaHat,betaHat,S2]

(alpha_hat, beta_hat, _) = estimerELR(x, y)

def calcResiduals(alpha, beta, x_vals, y_vals):
    resid = np.zeros(len(x_vals))
    for i in range(len(x_vals)):
        resid[i] = y_vals[i] - (alpha + beta * x_vals[i])
    return resid

residuals = calcResiduals(alpha_hat, beta_hat, x, y)

# Create a figure and a grid of subplots
fig, ax = plt.subplots(nrows=1, ncols=1, sharex=True)

# Scatter plot of residuals
ax.axhline(y=0, color='red', linestyle='--')
ax.scatter(x, residuals, color='blue', alpha=0.6)
ax.set_ylabel('Estimerte residualer')
ax.set_xlabel('x-verdier')
ax.set_title('Residualplot')

plt.savefig("../Bilder/2c.png")
