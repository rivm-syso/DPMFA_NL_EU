# -*- coding: utf-8 -*-
"""
Created on Tue Mar 12 08:02:07 2024

@author: Anne Hids (RIVM)
"""

import os

# Change to the working directory on your computer
os.chdir("N:/Documents/GitHub_opgeschoond")

import config
import datetime

#%% Write a metadatafile 

# Delete the file if it already exists
if config.OS_env == 'win': 
    mdfilename = "output\\metadata.txt" 
else:
    mdfilename = "/output/metadata.txt" 

if os.path.isfile(mdfilename) == True:
    os.remove(mdfilename)

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
f.write("\n")
f.write("End")

f.close()
