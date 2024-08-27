import numpy as np
import struct

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

registers = """
fffffaf9
"""

registers = registers.split("\n")
for register in registers:
    if register != "":
        print(hex_to_float(register))
