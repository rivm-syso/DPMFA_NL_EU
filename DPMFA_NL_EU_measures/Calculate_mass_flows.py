# Script for calculating mass flows from and to specified compartments

"""
Created: March 2025
Author:  Yvette Mellink and Anne Hids (RIVM)
"""

#%%
# Import packages
import os
import config
import paths

inputfile = "Fringes_low"

 #%%
# Set working directory to where the scripts are located
if config.OS_env == 'win':
    os.chdir(win_main_folder)
else: 
    os.chdir(lin_main_folder)

#%% 
# Run the script that finds all relevant routes
with open("Find_routes_" + inputfile + ".py") as f:
    code = f.read()
exec(code)

#%%
# Calculate mass contributions
with open("Mass_contributions_" + inputfile + ".py") as f:
    code = f.read()
exec(code)
