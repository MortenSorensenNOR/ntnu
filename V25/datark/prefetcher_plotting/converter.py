import os
import csv

input_folder = './input'
output_folder = './output'

# Ensure the output folder exists
os.makedirs(output_folder, exist_ok=True)

csv_data = []

# Process each file in the input folder
for filename in os.listdir(input_folder):
    input_path = os.path.join(input_folder, filename)

    # Read the data from the input file
    with open(input_path, 'r') as file:
        data = file.read()

    lines = data.strip().split("\n")
    current_stat = None
    current_category = None
    config = filename.split(".")[0]
    
    for line in lines:
        line = line.strip()
        if line.startswith("Summary of benchmarking follows"):
            current_category = "Summary"
        elif line.startswith("Detailed stats follow"):
            current_stat = "Detailed"
        elif line.startswith("-----") and current_stat == "Summary":
            current_stat = line.strip("-")
        elif current_category == "Summary" and ": " in line:
            key_value = line.split(": ")
            if len(key_value) == 2 and current_category:
                csv_data.append([key_value[0], "ipc", key_value[1], config])
        elif current_stat == "Detailed" and "_s stats:" in line:
            current_category = line.split(" stats:")[0]
        elif current_stat == "Detailed" and ": " in line:
            key_value = line.split(": ")
            if len(key_value) == 2 and current_category:
                csv_data.append([current_category, key_value[0], key_value[1], config])

output_path = os.path.join(output_folder, f"results.csv")

with open(output_path, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['binary', 'metric', 'value', 'config'])  # CSV header
    writer.writerows(csv_data)

print(f"CSV file '{output_path}' has been created.")
