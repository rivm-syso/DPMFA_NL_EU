# -*- coding: utf-8 -*-
"""
Created on Tue Mar 12 08:02:07 2024

@author: Anne Hids (RIVM)
"""

import os
import config

# Set working directory to where the scripts are located
if config.OS_env == 'win': 
    os.chdir("N:/Documents/GitHub/rivm-syso/DPMFA_NL_EU")
else:
    os.chdir('/mnt/scratch_dir/hidsa/DPMFA_output')  

import datetime

#%% Write a metadatafile 

# Delete the file if it already exists
if config.OS_env == 'win': 
    mdfilename = "output\\metadata.txt" 
else:
    mdfilename = "output/metadata.txt" 

# Ensure the output directory exists
os.makedirs(os.path.dirname(mdfilename), exist_ok=True)

# Delete the file if it already exists
if os.path.isfile(mdfilename):
    try:
        os.remove(mdfilename)
    except OSError as e:
        print(f"Error: {e.strerror} - {e.filename}")

# Create a new file
f = open(mdfilename, "x")

# Get the date and time
d = datetime.datetime.now()
dt = d.strftime('%d-%m-%Y %H:%M:%S')

# Write the file                
f.write("Metadatafile for the DPMFA model")
f.write("\n")
f.write("\n")
f.write("Start date and time: ")
f.write(dt)
f.write("\n")
f.write("\n")
f.write("Configurations:")
f.write("\n")
f.write("\n")
f.write("Region: " + config.reg)
f.write("\n")
f.write("Startyear: " + str(config.startyear))
f.write("\n")
f.write("Endyear: " + str(config.endyear))
f.write("\n")
f.write("Runs: " + str(config.RUNS))
f.write("\n")
f.write("Model type: " + str(config.model_type))
f.write("\n")
f.write("Seed: " + str(config.seed))
f.write("\n")
f.write("Maininputfile version: " + str(config.inputfile))
f.write("\n")
f.write("NL_nested: " + str(config.NL_nested))
f.write("\n")
f.write("\n")
f.write("End")

f.close()
