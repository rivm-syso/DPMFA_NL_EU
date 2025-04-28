# -*- coding: utf-8 -*-
"""
Created on Mon May 15 09:30:27 2023

@author: Michelle Steenmeijer and Anne Hids (RIVM)
"""

# Input file
inputfile = "MainInputFile_Textiles_28_4_2025.xlsx"

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

runtime = 300
maxmemory = 16000

# List of input categories 
sellist = ['Intentionally produced microparticles', 'Clothing', 
            'Household textiles (product sector)', 'Technical textiles', 'Paint', 
            'Domestic primary plastic production', 'Import of primary plastics', 
            'Agriculture', 'Packaging', 'Tyre wear']

# List of 'from' compartments of interest for calculating mass flows
from_comps = [
    # Product sectors
    "Clothing (product sector)", # This compartment is not an input compartment, but gets inflow from import and production 
    "Intentionally produced microparticles",
    "Tyre wear",
    "Transport of primary plastics", # This includes domestic pellet production and import of pellets
    "Agriculture",
    "Paint",
    "Technical textiles",
    "Packaging",
    "Household textiles (product sector)",
    
    # Recyling compartments
    "Agricultural plastic recycling",
    "Packaging recycling",
    "Textile recycling",
    
    # Clothing and footwear categories
    "Apparel accessories",
    "Boots",
    "Close-toed shoes",
    "Dresses skirts and jumpsuits",
    "Jackets and coats",
    "Leggings stockings tights and socks",
    "Open-toed shoes",
    "Pants and shorts",
    "Shirts and blouses",
    "Sweaters and midlayers",
    "Swimwear",
    "T-shirts",
    "Underwear"
]

# List of 'to' compartments of interest for calculating mass flows
to_comps = [
    "Landfill",
    "Natural soil (micro)",
    "Textile reuse",
    "Export",
    "Elimination",
    "Agricultural soil (macro)",
    "Residential soil (macro)",
    "Surface water (macro)",
    "Agricultural soil (micro)",
    "Secondary material reuse",
    "Road side soil (macro)",
    "Natural soil (macro)",
    "Residential soil (micro)",
    "Sub-surface soil (micro)",
    "Outdoor air (micro)",
    "Export of primary plastics",
    "Plastic products",
    "Surface water (micro)",
    "Sea water (micro)",
    "Road side soil (micro)",
    "Indoor air (micro)"
]
