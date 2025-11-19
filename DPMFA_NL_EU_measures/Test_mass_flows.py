# Test the output

import os
import pickle
import numpy as np

mat = "RUBBER"

mainfolder = os.getcwd()

#%%
# Load pickle files

with open(os.path.join(mainfolder, 'output', mat, 'Pickle_files', 'dict_mass_contributions_in_targets.pkl'), 'rb') as file:  # Open the file in binary read mode
    dict_mass_contributions = pickle.load(file)

with open(os.path.join(mainfolder, 'output', mat, 'Pickle_files', 'LoggedInflows.pkl'), 'rb') as file:  # Open the file in binary read mode
    loggedInflows = pickle.load(file)

#%%
# Sum calculated flows into sinks

dict_summed_arrays = {}

# Check calculated masses in sinks against the total inflow into sinks from the masses
for target, source_dict in dict_mass_contributions.items():
    arrays_to_sum = list(source_dict.values())

    # Check array shapes
    shapes = [arr.shape for arr in arrays_to_sum]
    if len(set(shapes)) > 1:  # If not all shapes are the same
        print(f"Target '{target}' has arrays with mismatched shapes: {shapes}")
        continue  # Skip this target or handle accordingly

    # Perform element-wise summation
    summed_array = np.sum(arrays_to_sum, axis=0)
    dict_summed_arrays[target] = summed_array

#%% 
# Sum original inflows into sinks

dict_original_inflows = {}

# Get targets
targets = list(dict_mass_contributions.keys())

# Sum the original inflows into sinks
for target in targets:
    # Filter loggedInflows for the specific target
    arrays_to_sum = loggedInflows.get(target)  # Use .get() to avoid KeyError if the target doesn't exist
    
    # If there is data for the target, store it in dict_original_inflows
    if arrays_to_sum is not None:  # Check if loggedInflows contains data for the target
        dict_original_inflows[target] = arrays_to_sum
    else:
        print(f"No inflows found for target: {target}")  # Debug message if target is not in loggedInflows

# Check key intersection between both dictionaries
common_targets = set(dict_summed_arrays.keys()).intersection(set(dict_original_inflows.keys()))

# Compare arrays for each target in the common set
for target in common_targets:
    # Extract the arrays
    summed_array = dict_summed_arrays[target]
    original_inflow = dict_original_inflows[target]
    
    # Verify that the shapes match
    if summed_array.shape != original_inflow.shape:
        print(f"Shape mismatch for target '{target}': "
              f"summed_array.shape = {summed_array.shape}, original_inflow.shape = {original_inflow.shape}")
        continue  # Skip to the next target if shapes don't match

    # Strict comparison (element-wise equality)
    if np.array_equal(summed_array, original_inflow):
        print(f"Target '{target}': Arrays are exactly equal.")
    else:
        # Approximate comparison with tolerance
        if np.allclose(summed_array, original_inflow, atol=1e-6):
            print(f"Target '{target}': Arrays are approximately equal (within tolerance).")
        else:
            print(f"Target '{target}': Arrays are different!")

            # Calculate element-wise difference
            difference = summed_array - original_inflow
            print(f"Element-wise differences for target '{target}':\n{difference}")

            # Optionally, locate the indices of significant differences
            mismatch_indices = np.where(difference != 0)  # Indices where arrays differ
            if mismatch_indices[0].size > 0:  # Check if there are differences
                print(f"Mismatched indices for target '{target}': {mismatch_indices}")

# Dictionary to store relative differences
dict_relative_differences = {}

# Ensure both dictionaries contain the same keys
common_targets = set(dict_summed_arrays.keys()).intersection(set(dict_original_inflows.keys()))

# Iterate through each common target
for target in common_targets:
    summed_array = dict_summed_arrays[target]
    original_inflow = dict_original_inflows[target]
    
    # Check for shape mismatch
    if summed_array.shape != original_inflow.shape:
        print(f"Shape mismatch for target '{target}': summed_array.shape = {summed_array.shape}, original_inflow.shape = {original_inflow.shape}")
        continue

    # Calculate relative difference
    with np.errstate(divide='ignore', invalid='ignore'):  # Handle division by zero
        relative_difference = np.abs(summed_array - original_inflow) / np.abs(original_inflow)
        relative_difference[np.isnan(relative_difference)] = 0  # Replace NaN values (caused by 0/0) with 0
        relative_difference[np.isinf(relative_difference)] = np.inf  # Handle infinities explicitly (e.g., divide by 0)

    # Store the result
    dict_relative_differences[target] = relative_difference

# Print results
for target, relative_diff in dict_relative_differences.items():
    print(f"Target: {target}")
   # print(f"Relative Difference:\n{relative_diff * 100:.2f}%")

# Initialize variables to store the maximum relative difference and associated info
max_relative_difference = 0
max_target = None
max_index = None

# Iterate through relative differences dictionary
for target, relative_diff in dict_relative_differences.items():
    # Find the maximum value in the current relative differences array
    current_max = np.max(relative_diff)
    
    if current_max > max_relative_difference:  # Check if it is the largest so far
        max_relative_difference = current_max
        max_target = target
        max_index = np.unravel_index(np.argmax(relative_diff), relative_diff.shape)  # Get the index of the max value

# Print the results
print(f"Largest relative difference: {max_relative_difference}")
print(f"Found in target: {max_target}, at index: {max_index}")