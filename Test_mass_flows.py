# Test the output

import os
import pickle
import numpy as np
import config

mat = "Acryl"


outputbasefolder = 'S:\\BioGrid\\hidsa\\DPMFA_output\\output_Baseline_EU_23_7-2025'

sources = ["Clothing (product sector)", # This compartment is not an input compartment, but gets inflow from import and production 
    "Intentionally produced microparticles",
    "Tyre wear",
    'Domestic primary plastic production', 
    'Import of primary plastics', 
    "Agriculture",
    "Paint",
    "Technical textiles",
    "Packaging",
    "Household textiles (product sector)"]

clothing_categories = ["Apparel accessories",
    "Boots",
    "Closed-toed shoes",
    "Dresses skirts and jumpsuits",
    "Jackets and coats",
    "Leggings stockings tights and socks",
    "Open-toed shoes",
    "Pants and shorts",
    "Shirts and blouses",
    "Sweaters and midlayers",
    "Swimwear",
    "T-shirts",
    "Underwear"]

mainfolder = os.getcwd()

#%%
# Load pickle files

with open(os.path.join(outputbasefolder, mat, 'Pickle_files', 'dict_mass_contributions_in_targets.pkl'), 'rb') as file:  # Open the file in binary read mode
    dict_mass_contributions = pickle.load(file)

with open(os.path.join(outputbasefolder, mat, 'Pickle_files', 'LoggedInflows.pkl'), 'rb') as file:  # Open the file in binary read mode
    loggedInflows = pickle.load(file)

#%%
# Sum calculated flows into sinks
dict_summed_arrays = {}

for target, source_dict in dict_mass_contributions.items():
    # Filter alleen targets die in config.sink_comps zitten
    if target not in config.sink_comps:
        continue
    
    # Filter alleen de sources die in jouw 'sources'-lijst zitten
    filtered_arrays = [
        arr for src, arr in source_dict.items()
        if src in sources
    ]
    
    # Check array shapes
    shapes = [arr.shape for arr in filtered_arrays]
    if len(shapes) == 0:
        continue  # Geen arrays om op te tellen
    if len(set(shapes)) > 1:
        print(f"Target '{target}' has arrays with mismatched shapes: {shapes}")
        continue

    # Element-wise sum
    summed_array = np.sum(filtered_arrays, axis=0)
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
        if np.allclose(summed_array, original_inflow, atol=1e-10):
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

##################### Check mass balance for clothing categories to sinks

# Som van alle clothing-categorieën naar sinks
clothing_to_sink_arrays = {}

for sink in config.sink_comps:
    arrays = []
    # Neem alle sources in clothing_categories voor deze sink
    source_dict = dict_mass_contributions.get(sink, {})
    for source in clothing_categories:
        arr = source_dict.get(source)
        if arr is not None:
            arrays.append(arr)
    if arrays:
        # Controleer shapes
        shapes = [arr.shape for arr in arrays]
        if len(set(shapes)) > 1:
            print(f"Sink '{sink}' heeft arrays met verschillende shapes uit clothing_categories: {shapes}")
            continue
        # Sommeer
        clothing_to_sink_arrays[sink] = np.sum(arrays, axis=0)

clothing_product_to_sink_arrays = {}

for sink in config.sink_comps:
    source_dict = dict_mass_contributions.get(sink, {})
    arr = source_dict.get("Clothing (product sector)")
    if arr is not None:
        clothing_product_to_sink_arrays[sink] = arr

for sink in config.sink_comps:
    arr_cat = clothing_to_sink_arrays.get(sink)
    arr_prod = clothing_product_to_sink_arrays.get(sink)
    
    if arr_cat is None and arr_prod is None:
        print(f"Geen data voor sink '{sink}' in beide dicts.")
        continue
    
    if arr_cat is None or arr_prod is None:
        print(f"Geen data voor sink '{sink}' in één van beide dicts.")
        continue
    
    # Controleer shapes
    if arr_cat.shape != arr_prod.shape:
        print(f"Shape mismatch voor sink '{sink}': {arr_cat.shape} vs {arr_prod.shape}")
        continue

    # Controleer gelijkheid
    if np.array_equal(arr_cat, arr_prod):
        print(f"Sink '{sink}': Arrays zijn exact gelijk.")
    elif np.allclose(arr_cat, arr_prod, atol=1e-10):
        print(f"Sink '{sink}': Arrays zijn ongeveer gelijk (binnen tolerance).")
    else:
        print(f"Sink '{sink}': Arrays verschillen!")
        difference = arr_cat - arr_prod
        print(f"Verschil:\n{difference}")
        mismatch_indices = np.where(difference != 0)
        if mismatch_indices[0].size > 0:
            print(f"Verschillende indices: {mismatch_indices}")




 
