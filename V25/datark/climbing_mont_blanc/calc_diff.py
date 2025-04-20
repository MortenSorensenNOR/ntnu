# create_ppm_p6.py

width = 123
height = 123

with open("test.ppm", "wb") as f:
    # Write the P6 header (note: ends with a single newline)
    header = f"P6\n{width} {height}\n255\n"
    f.write(header.encode())

    # Write binary RGB pixel data
    for y in range(height):
        for x in range(width):
            r = int((x / width) * 255)      # Horizontal red gradient
            g = 0                           # Green stays 0
            b = int((y / height) * 255)     # Vertical blue gradient
            f.write(bytes([r, g, b]))

