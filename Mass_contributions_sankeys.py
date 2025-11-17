# Script for calculating mass contributions from and to specific compartments
"""
Created: March 2025
Authors:  Yvette Mellink and Anne Hids (RIVM)
"""

import numpy as np
import pickle
import os
import csv

import config

in_use_discarded_comps = config.in_use_discarded_to_comps
sink_comps = config.sink_comps
kleding_comps = config.to_clothing_comps
#kleding_comps = ["Apparel accessories"]
# Set working directory to where the scripts are located
if config.OS_env == 'win':
    os.chdir(win_main_folder)
    outputbasefolder = sankey_output_folder_win
    output_folder = outputbasefolder
else: 
    os.chdir(lin_main_folder)
    output_folder = sankey_output_folder_lin 
    outputbasefolder = output_folder

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
#materials = ["Acryl"]
#mat = "PET"

# Calculate masses in loop
for mat in materials:
    
    # Specify the folder where the output of the casestudy runner is located
    casestudy_output_folder = os.path.join(outputbasefolder, mat)
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
    # Initialize the main dictionary
   
    csvfolder = os.path.join(outputbasefolder, mat, "sankey_data")
    os.makedirs(csvfolder, exist_ok=True)

    # dictionary om te aggregeren: (kleding_comp, discard_comp, sink_comp) -> massa
    mass_dict = {}
    sink_comps = ["Elimination"]
    for kleding_comp in kleding_comps:
        for sink_comp in sink_comps:
            key = (kleding_comp, sink_comp)
            routes = dict_Routes.get(key, find_routes(df_from_to, kleding_comp, sink_comp))
            #routes = routes[:2]  # Neem de eerste twee routes
            start_mass = np.array(loggedTotalOutflows.get(kleding_comp))
            for route in routes:
                # Bouw een lijst van alle TC-matrices voor deze route
                tc_matrices = []
                for i in range(len(route) - 1):
                    fkey_tuple = (route[i].strip(), route[i+1].strip())
                    tc_matrix = np.array(dict_Transfer_Coefficients.get(fkey_tuple))
                    tc_matrices.append(tc_matrix)
                # Vermenigvuldig alle TC-matrices element-wise
                if tc_matrices:
                    route_matrix = np.multiply.reduce(tc_matrices)
                else:
                    route_matrix = np.ones_like(start_mass)
                # Vermenigvuldig met startmassa
                route_mass = start_mass * route_matrix
                # Aggregeer per discard_compartiment in de route
                for idx, comp in enumerate(route):
                    if comp in in_use_discarded_comps and idx > 0:
                        discard_comp = comp
                        agg_key = (kleding_comp, discard_comp, sink_comp)
                        if agg_key not in mass_dict:
                            mass_dict[agg_key] = np.zeros_like(route_mass)
                        mass_dict[agg_key] += route_mass  # Voeg de massa van deze route toe

    # Schrijf alles per combinatie naar CSV
    for (kleding_comp, discard_comp, sink_comp), massa in mass_dict.items():
        filename = f"{mat}_{kleding_comp}_via_{discard_comp}_to_{sink_comp}.csv"
        with open(os.path.join(csvfolder, filename), 'w', newline='') as f:
            writer = csv.writer(f)
            for row in massa.tolist():
                writer.writerow(row)
