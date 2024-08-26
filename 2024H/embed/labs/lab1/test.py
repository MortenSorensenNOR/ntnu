import numpy as np
import struct

# Define matrices A and B
A = np.array([
    [1.0, 2.0, 3.0, 4.0],
    [5.0, 6.0, 7.0, 8.0],
    [9.0, 10.0, 11.0, 12.0],
    [13.0, 14.0, 15.0, 16.0]
])

B = np.array([
    [16.0, 15.0, 14.0, 13.0],
    [12.0, 11.0, 10.0, 9.0],
    [8.0, 7.0, 6.0, 5.0],
    [4.0, 3.0, 2.0, 1.0]
])

# Compute the matrix product
C = np.dot(A, B)

# Print the result
print(C)

def hex_to_float(hex_str):
    # Ensure the hex string has exactly 8 characters
    if len(hex_str) != 8:
        raise ValueError("Hex string must be exactly 8 characters long.")
    
    # Convert the hexadecimal string to an integer
    int_value = int(hex_str, 16)
    
    # Pack the integer into a binary representation
    # 'I' stands for unsigned int, '<' means little-endian
    packed = struct.pack('<I', int_value)
    
    # Unpack the binary representation as a float
    # 'f' stands for float
    float_value = struct.unpack('<f', packed)[0]
    
    return float_value

# Example usage
hex_str = "440c0000"
print(hex_to_float(hex_str))

