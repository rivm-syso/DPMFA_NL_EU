# -*- coding: utf-8 -*-
"""
Created on Mon May 15 09:30:27 2023

@author: Michelle Steenmeijer and Anne Hids (RIVM)
"""

# Input file
inputfile = "MainInputFile.xlsx"

# Select operating system for folder structures (windows or linux)
OS_env = 'win' 
#OS_env = 'lin' 

# Select the model type: dpmfa or pmfa
model_type = 'pmfa'
#model_type = 'dpmfa'

# Selection of regions
reg = 'NL'
#reg = 'EU'

# Select startyear and endyear 
startyear = 2019
endyear = 2020

#  Running variables
Speriod = 3 # special period for detailed output printing
RUNS = 100 # number of runs 
seed = 2250 
nodatayear  = 1950 # year for which no data is available, needed for interpolation (has to be the same or smaller than startyear)

# List of input categories 
sellist = ['Intentionally produced microparticles', 'Clothing (product sector)', 
            'Household textiles (product sector)', 'Technical textiles', 'Paint', 
            'Domestic primary plastic production', 'Import of primary plastics', 
            'Agriculture', 'Packaging', 'Tyre wear']
