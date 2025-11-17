# Script for calculating mass contributions from and to specific compartments
"""
Created: March 2025
Authors:  Yvette Mellink and Anne Hids (RIVM)
"""

import numpy as np
import pandas as pd
import pickle
import os
import csv

import config
import paths

# Set working directory to where the scripts are located
if config.OS_env == 'win':
    os.chdir(win_main_folder)
    outputbasefolder = os.getcwd()
else: 
    os.chdir(lin_main_folder)
    outputbasefolder = outputbasefolder_lin

# Define the "output" folder path
output_folder = os.path.join(outputbasefolder, "output")

# Get all material names
if os.path.exists(output_folder):
    materials = [folder for folder in os.listdir(output_folder) 
                 if os.path.isdir(os.path.join(output_folder, folder))]
    print(materials)
else:
    print(f"The folder '{output_folder}' does not exist.")
   
#%%
# FUNCTIONS

def find_routes(df_from_to, source, target, visited=None):
    
    """
    Recursively finds all unique routes from source compartment to target compartment.
    """
    if visited is None:
        visited = set()

    # Base case: if source is the target, return the route
    if source == target:
        return [[target]]

    visited.add(source)
    routes = []

    # Find all outflows from the current source
    outflows = df_from_to[df_from_to['From'] == source]

    for _, row in outflows.iterrows():
        next_compartment = row['To']
        if next_compartment not in visited:
            sub_routes = find_routes(df_from_to, next_compartment, target, visited.copy())
            for sub_route in sub_routes:
                routes.append([source] + sub_route)

    return routes

#%% 
# Calculate masses in loop
for mat in materials:
    
    # Specify the folder where the output of the casestudy runner is located
    casestudy_output_folder = os.path.join(outputbasefolder, "output", mat)
    if casestudy_output_folder is None:
        raise FileNotFoundError("No output folder found.")
    
    #%% 
    # Load needed files
    
    # TC dictionary
    with open(os.path.join(casestudy_output_folder, 'Pickle_files', 'TransferCoefficients.pkl'), 'rb') as file:  # Open the file in binary read mode
        dict_Transfer_Coefficients = pickle.load(file)
        
    # loggedTotalOutflows
    with open(os.path.join(casestudy_output_folder, 'Pickle_files', 'LoggedTotalOutflows.pkl'), 'rb') as file:  # Open the file in binary read mode
        loggedTotalOutflows = pickle.load(file)
        
    # From to
    with open(os.path.join(casestudy_output_folder, 'Pickle_files', 'FromTo.pkl'), 'rb') as file:  # Open the file in binary read mode
        df_from_to = pickle.load(file)
    
    # Routes
    with open(os.path.join(casestudy_output_folder, 'Pickle_files', 'Computed_routes_for_source_target_combinations.pkl'), 'rb') as file:  # Open the file in binary read mode
        dict_Routes = pickle.load(file)
    
    # AllMassFlows
    with open(os.path.join(casestudy_output_folder, 'Pickle_files', 'AllMassFlows.pkl'), 'rb') as file:  # Open the file in binary read mode
        dict_all_mass_flows = pickle.load(file)
             
    #%%
  
    df_requested_source_target_combos = pd.DataFrame(
        list(dict_Routes.keys()), 
        columns=["Source compartment", "Target compartment"]
    )
    
    # Filter so that Source compartment and Target compartment are not the same to avoid errors
    df_requested_source_target_combos = df_requested_source_target_combos[
    df_requested_source_target_combos["Source compartment"] != df_requested_source_target_combos["Target compartment"]
]
    
    #%%
    # Initialize the main dictionary
    dict_mass_contributions_in_targets = {}
    
    # Iterate through each source-target pair
    for _, row in df_requested_source_target_combos.iterrows():
        source = row['Source compartment']
        target = row['Target compartment']
        key_1 = (source, target)
        
        print(f"Processing: {source} --> {target}")
        
        # Ensure there is a dictionary for this target compartment
        if target not in dict_mass_contributions_in_targets:
            dict_mass_contributions_in_targets[target] = {}
        
        # Find unique routes for this source-target pair
        routes = dict_Routes.get(key_1, find_routes(df_from_to, source, target))
        
        for route in routes:
            flow_keys = [f"{route[i]}, {route[i+1]}" for i in range(len(route) - 1)]
            
            fkey0 = flow_keys[0] 
            fkey_tuple = tuple(map(str.strip, fkey0.split(',')))
            TC_matrix = dict_Transfer_Coefficients.get(fkey_tuple)
            
            remaining_flow_keys = flow_keys[1:]
            for fkey in remaining_flow_keys:
                fkey_tuple = tuple(map(str.strip, fkey.split(',')))
                next_matrix = dict_Transfer_Coefficients.get(fkey_tuple)  # Get the matrix for the current flow key
                
                # Perform element-wise multiplication
                TC_matrix = np.array(TC_matrix) * np.array(next_matrix)  # Element-wise multiplication in NumPy
                
            # Get the total mass that the compartment started with
            mass_matrix_source = loggedTotalOutflows.get(source)
            
            # Multiply the initial mass with the TC matrix element wise
            from_to_mass_matrix = np.array(TC_matrix) * np.array(mass_matrix_source)  
            
            # Store the result in the dictionary
            if source not in dict_mass_contributions_in_targets[target]:
                dict_mass_contributions_in_targets[target][source] = np.zeros_like(from_to_mass_matrix)
           
            # Aggregate the contribution from this route
            dict_mass_contributions_in_targets[target][source] += from_to_mass_matrix
    
    #%% 
    # Save the output as csv (for anaylsis in R) and as a pickle  (for analysis in python)        
    csvfolder = os.path.join(outputbasefolder, "output", mat, "csv")
    
    # Save each array in the dictionary as a CSV
    for target in dict_mass_contributions_in_targets.keys():
        target_dict = dict_mass_contributions_in_targets[target]
        for source in target_dict.keys():
            source_array = target_dict[source]
            
            with open(os.path.join(csvfolder, "calculatedMassFlows_" + config.reg + "_" + mat + "_" + source + "_to_" + target + ".csv"), 'w') as RM:
                a = csv.writer(RM, delimiter = ' ')
                a.writerows(source_array)
        
    pickle_output_folder = os.path.join(outputbasefolder, "output", mat, 'Pickle_files')
    
    # Provide a name for the pickle file
    pickle_file_name = "dict_mass_contributions_in_targets.pkl"
    
      # Full path to the pickle file
    pickle_file_path = os.path.join(pickle_output_folder, pickle_file_name)
    
    # Save the mass contributions dictionary to a pickle file
    with open(pickle_file_path, "wb") as f:
        pickle.dump(dict_mass_contributions_in_targets, f)
