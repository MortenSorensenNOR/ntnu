from sympy import symbols, Eq, solve, log

# Define the variables
R1, R2 = symbols('R1 R2')

# Known value
R_value = 10650

# Substitute the known value into the equations
equation1 = Eq(20*log((R_value + R2) / (R_value + R1 + R2), 10), -5)
equation2 = Eq(20*log((R2) / (R1 + R2), 10), -22)

# Solve the system of equations
solutions = solve((equation1, equation2), (R1, R2))

float_solutions = {key: value.evalf() for key, value in solutions.items()}

# Display the solutions as floats
print("Solutions for R1 and R2:", float_solutions)

