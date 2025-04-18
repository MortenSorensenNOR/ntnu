from PIL import Image
import numpy as np

# Load images and convert to RGB
img1 = Image.open('./image_test.ppm').convert('RGB')
img2 = Image.open('./image_test_accurate.ppm').convert('RGB')

# Convert to numpy arrays
arr1 = np.array(img1).astype(np.int16)
arr2 = np.array(img2).astype(np.int16)

# Sanity check
if arr1.shape != arr2.shape:
    raise ValueError("Images must have the same dimensions")

# Difference
diff = arr1 - arr2

# Prepare counts
channels = ['Red', 'Green', 'Blue']
for i, color in enumerate(channels):
    channel_diff = np.abs(diff[:, :, i])
    off_by_one = np.sum(channel_diff == 1)
    off_by_more = np.sum(channel_diff > 1)

    print(f"{color} channel:")
    print(f"  Pixels off by exactly 1: {off_by_one}")
    print(f"  Pixels off by more than 1: {off_by_more}")
