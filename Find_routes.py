#####################################################
# Routes between standard source-target compartments
#####################################################

"""
Created: March 2025
Author:  Yvette Mellink and Anne Hids (RIVM)
"""

# READ ME
# This script computes all possible routes between a source and a
# target compartment. It does so for a list of standard source-
# target combinations.

import pandas as pd
import pickle
import os
from pathlib import Path
import itertools
import config

# Set working directory to where the scripts are located
if config.OS_env == 'win':
    os.chdir("N:/Documents/GitHub/rivm-syso/DPMFA_NL_EU")
    outputbasefolder = os.path.join(os.getcwd(), 'output')
else: 
    os.chdir("/data/BioGrid/hidsa/GitHub/DPMFA_NL_EU")
    outputbasefolder = '/mnt/scratch_dir/hidsa/DPMFA_output/output' 

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


def save_routes_to_pickle(dict_Routes, filename):

    with open(filename, 'wb') as f:
        pickle.dump(dict_Routes, f)
    print(" ")
    print(f"Routes saved to {filename}.")

#%%
# INPUT

# Load the output of the CaseStudy runner
def load_pickle_file(file_path):
    """Loads a pickle file if it exists."""
    if file_path.exists():
        with open(file_path, "rb") as f:
            return pickle.load(f)
    else:
        raise FileNotFoundError(f"File '{file_path}' not found.")

# Get all material names
if os.path.exists(outputbasefolder):
    materials = [folder for folder in os.listdir(outputbasefolder) 
                 if os.path.isdir(os.path.join(outputbasefolder, folder))]
    print(materials)
else:
    print(f"The folder '{outputbasefolder}' does not exist.")

for mat in materials:
    
    output_folder = os.path.join(outputbasefolder, mat)
    
    # Get the folder for the specified datetime or latest run
    if output_folder is None:
        raise FileNotFoundError("No output folder found.")
    
    # Create file path to the FromTo.pkl file
    FromTo_file = Path(output_folder) / "Pickle_files" / "FromTo.pkl"
    
    # Load into a DataFrame
    df_from_to  = load_pickle_file(FromTo_file)
    
    # Step 2: Define From compartments of interest
    source_comps = config.source_comps
    recycling_from_comps = config.from_recycling_comps
    
    # Step 3: Define To compartments of interest
    sink_comps = config.sink_comps
    recycling_to_comps = config.to_recycling_comps
    
    # Step 4: Create all possible combinations of from_comps and to_comps
    source_sink_combinations = list(itertools.product(source_comps, sink_comps))
    recycling_combinations = list(itertools.product(recycling_from_comps, recycling_to_comps))
    
    # Step 5: Create a DataFrame with Source and Target compartments
    df_source_sink_combos = pd.DataFrame(source_sink_combinations, columns = ["Source compartment", "Target compartment"])
    df_recycling_combos = pd.DataFrame(recycling_combinations, columns= ["Source compartment", "Target compartment"])
    
    df_source_target_combos = pd.concat([df_source_sink_combos, df_recycling_combos], axis=0, ignore_index=True)
        
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # COMPUTATION
    
    # Initialize the dictionary in which the routes will be stored
    dict_Routes = {}
    
    # Compute all routes for all source-target combinations
    for _, row in df_source_target_combos.iterrows():
        
        source = row['Source compartment']
        target = row['Target compartment']
        key    = (source, target)
        
        routes = find_routes(df_from_to, source, target)
        
        dict_Routes[key] = routes
        
    dict_Routes = {key: value for key, value in dict_Routes.items() if value}
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # OUTPUT
    
    # Define filename
    pickle_file_name = "Computed_routes_for_source_target_combinations.pkl"
    
    # Get full path in current directory
    pickle_file_path = os.path.join(output_folder, "Pickle_files", pickle_file_name)
    
    # Save the pickle
    with open(pickle_file_path, "wb") as f:
        pickle.dump(dict_Routes, f)
