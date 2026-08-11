import sys
import glob
import os
import numpy as np

def bin_to_numpy(bin_path, channels=3):
    with open(bin_path, 'r') as fid:
        sample_period = np.fromfile(fid, count=1, dtype=float)[0]
        data = np.fromfile(fid, dtype='uint16')
        data = data.reshape((-1, channels))
    return sample_period, data

if __name__ == "__main__":
    if len(sys.argv) > 1:
        bin_path = sys.argv[1]
    else:
        files = sorted(glob.glob("data/*.bin"), key=os.path.getmtime)
        if not files:
            sys.exit("No .bin files found in data/")
        bin_path = files[-1]

    out_path = sys.argv[2] if len(sys.argv) > 2 else bin_path.replace('.bin', '.npz')

    print(f"Using: {bin_path}")
    sample_period, data = bin_to_numpy(bin_path)
    np.savez(out_path, sample_period=sample_period, data=data)
    print(f"Saved to {out_path}")
