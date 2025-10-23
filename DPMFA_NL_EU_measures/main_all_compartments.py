# -*- coding: utf-8 -*-
"""
Created on Mon May 15 09:36:29 2023

@author: Michelle Steenmeijer and Anne Hids (RIVM)
"""

import os
import sys
import config

# Set working directory to where the scripts are located
if config.OS_env == 'win':
    os.chdir("N:/Documents/GitHub/DPMFA_Analysis/DPMFA_NL_EU_measures")
else: 
    os.chdir("/data/BioGrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures")
    
mainfolder = os.getcwd()

if os.path.isfile('main_all_compartments.py') == False:
    sys.exit("Main folder setting is not correct. Script stopped, please try again from the correct folder.")

# Execute the code from input2csv.py
with open("input2csv.py") as f:
    code = f.read()
exec(code)
#%%

os.chdir(mainfolder)
with open("db_setup_all_compartments.py") as f:
    code = f.read()
exec(code)
#%%
os.chdir(mainfolder)

with open("Create_batch_files_all_compartments.py") as f:
    code = f.read()
exec(code)

os.chdir(mainfolder)
