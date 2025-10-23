# Script for calculating mass flows from and to specified compartments

"""
Created: March 2025
Author:  Yvette Mellink and Anne Hids (RIVM)
"""

#%%
# Import packages
import os
import config

inputfile = "Fringes_low"

 #%%
# Set working directory to where the scripts are located
if config.OS_env == 'win':
    os.chdir("N:/Documents/GitHub/DPMFA_Analysis/DPMFA_NL_EU_measures")
else: 
    os.chdir("/data/BioGrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures")

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
