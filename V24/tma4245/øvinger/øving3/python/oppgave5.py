import numpy as np

# f_XY[x][y]
f_XY = [[1/18, 1/6, 1/18, 1/18], [1/18, 1/18, 1/6, 1/18], [1/18, 1/18, 1/18, 1/6]]

# Oppgave a)
print("\nOppgave a)")

f_X = [sum(x) for x in f_XY]
print(f_X, end="\n\n")

f_Y_given_X = []
for x in range(len(f_XY)):
    f_Y_given_X.append([f_XY[x][y] / f_X[x] for y in range(len(f_XY[0]))])
print(f_Y_given_X, end="\n\n")

# Oppgave b)
print("\nOppgave b)")

E_X = sum([x * sum(y) for x, y in enumerate(f_XY)])
print(E_X)

E_Y = sum([y * sum(x) for y, x in enumerate(list(np.array(f_XY).T))]) 
print(E_Y)

f_Y = [sum(np.array(f_XY)[:, i]) for i in range(len(f_XY[0]))]
print(f_X[0] * f_Y[1])

Cov_XY = sum([sum([(x - E_X) * (y - E_Y) * f_XY[x][y] for y in range(len(f_XY[0]))]) for x in range(len(f_XY))])
print(Cov_XY)
