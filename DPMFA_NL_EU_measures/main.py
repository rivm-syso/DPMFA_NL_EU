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
    os.chdir("N:/Documents/GitHub/rivm-syso/DPMFA_NL_EU")
else: 
    os.chdir("/data/BioGrid/hidsa/GitHub/DPMFA_NL_EU")
    
mainfolder = os.getcwd()

if os.path.isfile('main.py') == False:
    sys.exit("Main folder setting is not correct. Script stopped, please try again from the correct folder.")

# Execute the code from input2csv.py
with open("input2csv.py") as f:
    code = f.read()
exec(code)
#%%

os.chdir(mainfolder)
with open("db_setup.py") as f:
    code = f.read()
exec(code)
#%%
os.chdir(mainfolder)

with open("Create_batch_files.py") as f:
    code = f.read()
exec(code)

os.chdir(mainfolder)
