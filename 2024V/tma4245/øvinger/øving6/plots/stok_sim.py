import numpy as np
import matplotlib.pyplot as plt

#Initialisering av parameterverdier
n = 25
alpha = 0.5
beta = 0.25
sigma = 0.25

#Simulering av data etter modell
# x_1,x_2,...,x_n i intervallet [-5,5]
x = np.array([-3.842, -3.784, -3.745, -3.708, -3.37,  -3.288, -2.312, -2.078, -2.019, 
              -1.595,-1.106, -0.352, -0.171,  1.166,  2.196,  2.538,  2.772,  3.186,  
              3.309,3.876, 4.2,    4.261,  4.337,  4.352,  4.359])
# genererer tilhørende verdier for y_1,y_2,...,y_n
y = alpha + beta * x + np.random.normal(loc=0,scale=sigma,size=n) 

def estimerELR(x,y):
    #Beregner gjennomsnitt
    xStrek = np.mean(x)
    yStrek = np.mean(y)
    #Estimater for parametere
    betaHat = np.sum((x-xStrek)*y)/np.sum((x-xStrek)**2)
    alphaHat = yStrek - betaHat * xStrek
    S2 = np.sum((y-(alphaHat+betaHat*x))**2)/(len(x)-2)
    #Returnerer resultatet i en liste
    return [alphaHat,betaHat,S2]

paramHat = estimerELR(x,y)
print('alphaHat: ',paramHat[0])
print('betaHat: ',paramHat[1])
print('s2: ',paramHat[2])

alpha_hat = paramHat[0]
beta_hat = paramHat[1]
s2_hat = paramHat[2]

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

# Show the plot
plt.savefig("../Bilder/2b.png")





