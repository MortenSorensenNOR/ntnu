#!/usr/bin/env python3
"""
Simple ADC capture tool
Usage: python3 adc_capture.py [port] [duration_seconds]

Capture starts immediately when remote connects and sends header.
"""

import socket
import struct
import numpy as np
import sys
import time

ADCS = 3
BYTES_PER_SAMPLE = ADCS * 2
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 12345
DURATION = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0  # seconds


def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', PORT))
    server.listen(1)

    print(f"Listening on port {PORT}...")

    conn, addr = server.accept()
    print(f"Connected from {addr}")

    # Read header
    header = conn.recv(8)
    sample_period_us = struct.unpack('d', header)[0]
    sample_rate = 1e6 / sample_period_us
    print(f"Sample period: {sample_period_us} µs ({sample_rate/1000:.2f} kHz)")

    print(f"Capturing {DURATION}s of data...")
    start_time = time.time()
    buffer = b''

    while time.time() - start_time < DURATION:
        try:
            chunk = conn.recv(4096)
            if not chunk:
                print("Connection closed by remote")
                break
            buffer += chunk
        except BlockingIOError:
            pass

    elapsed = time.time() - start_time
    print(f"Captured {len(buffer)} bytes in {elapsed:.2f}s")

    # Process data
    usable = len(buffer) - (len(buffer) % BYTES_PER_SAMPLE)
    if usable > 0:
        samples = np.frombuffer(buffer[:usable], dtype=np.uint16).reshape(-1, ADCS)
        # Convert to voltage: 12-bit ADC, 3.3V reference
        voltage = samples * (3.3 / 4095)

        # Save to file
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        filename = f"adc_capture_{timestamp}.npy"
        np.save("data/" + filename, voltage)
        print(f"Saved {len(samples)} samples ({ADCS} channels) to {filename}")
        print(f"Array shape: {voltage.shape}")
    else:
        print("No complete samples received")

    conn.close()
    server.close()
    print("Connection closed")


if __name__ == "__main__":
    main()
