# -*- coding: utf-8 -*-
"""
Created on Mon May 15 09:30:27 2023

@author: Michelle Steenmeijer and Anne Hids (RIVM)
"""

# Input file
inputfile = "MainInputFile_Textile_test_2.xlsx"

# Select operating system for folder structures (windows or linux)
OS_env = 'win' 
#OS_env = 'lin' 

# Select the model type: dpmfa or pmfa
model_type = 'pmfa'
#model_type = 'dpmfa'

# Selection of regions
reg = 'NL'
#reg = 'EU'

# When this variable is True and reg = 'EU', NL input will be subtracted from EU input.  
NL_nested = False

# Select startyear and endyear 
startyear = 2010
endyear = 2025

#  Running variables
Speriod = 3 # special period for detailed output printing
RUNS = 10 # number of runs 
seed = 2250 
nodatayear  = 1950 # year for which no data is available, needed for interpolation (has to be smaller than startyear)

# List of input categories 
sellist = ['Intentionally produced microparticles', 'Clothing', 
            'Household textiles (product sector)', 'Technical textiles', 'Paint', 
            'Domestic primary plastic production', 'Import of primary plastics', 
            'Agriculture', 'Packaging', 'Tyre wear']
