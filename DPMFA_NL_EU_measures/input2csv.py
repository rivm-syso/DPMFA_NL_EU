# -*- coding: utf-8 -*-
"""
Created on Tue May  2 14:27:04 2023

@author: Michelle Steenmeijer and Anne Hids (RIVM)
"""
import pandas as pd
import numpy as np
import os
import config
import warnings
from Input_projection_function import project_input

warnings.filterwarnings("ignore", category=UserWarning, module="openpyxl")
pd.options.mode.chained_assignment = None  

# Fetch configurations from the config.py file
nodatayear  = config.nodatayear
startyear   = config.startyear
endyear     = config.endyear
reg         = config.reg
file        = config.inputfile + ".xlsx"
model_type  = config.model_type
NL_nested   = config.NL_nested

#%%
#########################################
# Compartments csv
#########################################

# From the excel maininput file, reads the 'Compartments' sheet. The code reads
# in the first three columns on the sheet: 'name', 'fulllabel' and type. 
# Where 'name' contains the names of the compartments without spaces, 'fulllabel'
# contains the names of the compartments with spaces, and 'type' contains the 
# types of the compartments (stock, flow, sink). 

# If the model_type = pmfa, turn all stock compartments into flow compartments:

if model_type == 'dpmfa':
    comp = pd.read_excel(file, sheet_name = "Compartments", usecols = [0,1,2])
    comp = comp[["name","fulllabel","type"]]
else:
    comp = pd.read_excel(file, sheet_name = "Compartments", usecols = [0,1,2])
    comp = comp[["name","fulllabel","type"]]
    comp['type'] = comp['type'].replace('Stock', 'Flow')

print('Compartments to csv done.. \n')

#%%
#########################################
# Materials csv
#########################################

# From the excel maininput file, reads the 'Materials' sheet. The code reads
# in the one column that is present on the sheet: the column containing the 
# names of the materials the model can be excecuted for. 

mats = pd.read_excel(file, sheet_name = "Materials", usecols = [0])

print('Materials to csv done.. \n')

#%%
#########################################
# Lifetimes csv
#########################################

# From the excel maininput file, reads the 'Lifetimes' and '|Lifetimes_pairs' sheets. 
# The 'Lifetimes' sheet contains the column 'year', and a column with the name 
# of each compartment defined as a stock. 

# Kawecki 2021 lifetimes:
lt_21 = pd.read_excel(file, sheet_name = "Lifetimes")
# Transpose:
lt_21 = lt_21.T.iloc[1:].reset_index()

# In 2019 Kawecki used a detailed list of product categories. In 2021 Kawecki implemented the concept
# of lifetimes (for 200 years). However, lifetimes were not defined for all product categories from the 
# 2019 list. In addition, the names of product categories in the 2021 list differ a bit from the names 
# in 2019. For example, "Agricultural films"(2019) and "AgriculturalFilms" (2021).

# In our version of the model we use the detailed list of product categories from 2019 and link a 
# lifetime to each of these categories that corresponds to a (often broader) product category from 
# 2021. For example, to the 2019 category 'Cutlery' we assigned the lifetime of the 2021 product 
# caterogy 'Household'.

# If the model type = dpmfa: read the lifetime tables. Else: make empty df with
# the correct cols.

if model_type == 'dpmfa':
    # The table that couples the 2019 product categories with the 2019 categories:
    lt_pairs = pd.read_excel(file, sheet_name = "Lifetimes_pairs", usecols = [0,1])
    lt_pairs = pd.merge(lt_pairs, comp[['fulllabel','name']], how = 'left', left_on = 'Stock compartment', right_on = 'fulllabel').dropna()
    lt_pairs = lt_pairs[['Lifetime category','name']]
    
    # Here we link the lifetimes of Kawecki 2021 to all product categories from 2019:
    lt = pd.merge(lt_pairs, lt_21, how = 'left', left_on = 'Lifetime category', right_on = 'index')

    # Change the dataframe to the right format (so the format matches the format used
    # in the example csvs provided by Kawecki et al.):
    lt.drop(['Lifetime category','index'], axis = 1, inplace = True)
    lt.set_index('name', inplace = True)
    lt = lt.stack().reset_index().reset_index()
    lt['id'] = lt['index'] + 1
    del lt['index']
    lt.columns = ['comp', 'year', 'value', 'id']
    lt = lt[['id', 'comp', 'year', 'value']]
else: 
    col_names = ['id', 'comp', 'year', 'value']
    lt = pd.DataFrame(columns = col_names)

print('Lifetimes to csv done.. \n')

#%%
#########################################
# Input csv
#########################################

# Read in the projection sheet
projections = pd.read_excel(file, sheet_name = "Input projections", usecols = [0,1])
col = {'Year' : 'year',
       'Plastics Use (mt)' : 'projected_value'
       }
projections = projections.rename(columns = col)

allyears = pd.DataFrame({'year': range(nodatayear, endyear+1)})

# If NL_nested == True and the region is EU, subtract the input values for NL from the EU input values
if NL_nested == True and reg == "EU":
    input_NL = project_input(file, "Input_NL", startyear, endyear, nodatayear, projections)
    input_EU = project_input(file, "Input_EU", startyear, endyear, nodatayear, projections)
    
    original_ids = input_EU['id']
    
    joined_inputs = pd.merge(input_EU, input_NL, on=['comp', 'year', 'mat'], how='outer', suffixes=('_EU', '_NL'))
    
    # Because of the sorting and the outer join, rows are already matched correctly, except for when NL and EU both have 2 entries, resulting in 4 rows per combination
    count_combinations = joined_inputs.groupby(['year', 'comp', 'mat']).size().reset_index(name='count')
    count_is_4 = count_combinations[count_combinations['count'] == 4][['year', 'mat', 'comp']] 
    
    count_under_4 = joined_inputs.merge(count_is_4, how='outer', indicator=True)
    count_under_4 = count_under_4[(count_under_4._merge=='left_only')].drop('_merge', axis=1)
    
    count_is_4_result = pd.DataFrame()

    for i in range(len(count_is_4)):
        row_i = count_is_4.iloc[[i]]
        where_count_is_4 = joined_inputs.merge(row_i, on=['comp', 'year', 'mat'], how ='inner')
        unique_indices = where_count_is_4['id_EU'].unique()
        
        max_EU = where_count_is_4['value_EU'].max()
        min_EU = where_count_is_4['value_EU'].min()
        max_NL = where_count_is_4['value_NL'].max()
        min_NL = where_count_is_4['value_NL'].min()
        
        # Select the row where EU value is high and where NL value is high, do the same for low
        highest_row = where_count_is_4[(where_count_is_4['value_EU'] == max_EU) & (where_count_is_4['value_NL'] == max_NL)]
        lowest_row = where_count_is_4[(where_count_is_4['value_EU'] == min_EU) & (where_count_is_4['value_NL'] == min_NL)]
        
        # Change the source of the data 
        highest_row.loc[highest_row.index[0], 'source_EU'] = 'Scaling from NL to EU using population - High SimpleBox estimate'
        lowest_row.loc[lowest_row.index[0], 'source_EU'] = 'Scaling from NL to EU using population - Low SimpleBox estimate'

        count_is_4_result = pd.concat([count_is_4_result, highest_row, lowest_row])
        
    input_ = pd.concat([count_under_4, count_is_4_result])
    input_['value'] = input_['value_EU'] - input_['value_NL']
    input_ = input_[[ 'comp', 'year', 'mat', 'value', 'dqisgeo_EU', 'dqistemp_EU', 'dqismat_EU', 'dqistech_EU', 'dqisrel_EU', 'source_EU']]
    input_ = input_.rename(columns={'dqisgeo_EU': 'dqisgeo', 'dqistemp_EU': 'dqistemp', 'dqismat_EU':'dqismat','dqistech_EU': 'dqistech', 'dqisrel_EU': 'dqisrel', 'source_EU':'source'})
    input_['id'] = original_ids
    
elif reg == "NL":
    input_ = project_input(file, "Input_NL", startyear, endyear, nodatayear, projections)
    
elif reg == "EU":
    input_ = project_input(file, "Input_EU", startyear, endyear, nodatayear, projections)

# reset index and id
input_ = input_.reset_index(drop=True)
input_['id'] = input_.index + 1

print('Input to csv done.. \n')

#########################################
#%% Transfer coefficients
#########################################

# From the excel maininput file, reads the 'Transfer coefficients' sheet.
# The sheet contains the columns 'Compartment 1', 'Compartment 2', 'Year', 'Material', 
# 'Source', and columns containing the DQIS scores for each of the 5 categories. 
# The data that is read from the excel sheet is modified to match the format
# used in the example csvs provided by Kawecki et al. 

tc = pd.read_excel(file, sheet_name = "Transfer coefficients")

# Only keep DQIS geo scores corresponding to the region chosen in config.py
if reg == 'NL':
    geo = 'Geo NL'
else:
    geo = 'Geo EU'

# Keep only relevant columns
tc = tc[['From', 'To', 'Material',  'Priority', 
          geo, 'Temp', 'Mat', 'Tech', 'Rel',  'Data', 'Scale']]

# Only keep the TCs corresponding to the region chosen in config.py
if reg == 'NL':
    tc = tc[tc['Scale'] != 'EU']
else:
    tc = tc[tc['Scale'] != 'NL']
del tc['Scale']

# Rename columns to match format
col = {
       'From': 'comp1',
       'To': 'comp2',       
       'Material': 'mat',
       'Data': 'value',
       'Temp': 'dqistemp',
       'Mat': 'dqismat',
       'Tech': 'dqistech',
       'Rel': 'dqisrel',
       geo : 'dqisgeo'
       } 

tc.rename(columns = col, inplace = True)
tc.columns = tc.columns.str.lower()

# Check if there are too many or not enough compartments
list1 = list(input_['comp'].unique())
list2 = list(tc['comp1'].unique())
list3 = list(tc['comp2'].unique())
list_TCinputs = list(set(list2).difference(list3))
list_missinginputs = list(set(list_TCinputs).difference(list1))
tc = tc[tc['comp1'].isin(list_missinginputs) == False]

# Replace "any" with the materials 
materials = ','.join(list(mats['Name']))
tc.loc[tc['mat'] == 'any', 'mat'] = materials
tc["mat"] = tc["mat"].str.split(",")
tc = tc.explode("mat")

# Separate rows where 'value' is "rest" from the other rows
tcrest = tc[tc['value'] == 'rest']
tc = tc[tc['value'] != 'rest'].drop_duplicates()
tc['value'] = tc['value'].astype('float')
maincols = ['comp1', 'comp2', 'mat', 'priority']
tcrest.iloc[:, 4:9] = 0                                             # Fill in DQIS scores for rest 

#### If there are more than 2 TCs for the same flow, only keep the min and max TC
maincols = ['comp1', 'comp2', 'mat']
unique_counts = tc.groupby(maincols)['value'].transform('nunique')  # Group by the main columns and count the number of unique values
over_two_unique = tc[unique_counts > 2]                             # Filter rows where unique value counts are greater than 2
idx_min = over_two_unique.groupby(maincols)['value'].idxmin()       # For each group with more than 2 unique values, get indices of rows with min and max values
idx_max = over_two_unique.groupby(maincols)['value'].idxmax()
min_max_idx = pd.concat([idx_min, idx_max])
min_max_rows = tc.loc[min_max_idx]                                  # Extract the rows with minimum and maximum values for these groups
tc = tc.drop(over_two_unique.index)                                 # Remove all rows present in over_two_unique from the tc df
tc = pd.concat([tc, min_max_rows], ignore_index=True)               # Concatenate min_max_rows and tc to get the final DataFrame

#### Check if tcs from each compartment do not exceed 1
tc = tc.reset_index(drop=True).drop_duplicates()                    # Remove duplicate rows
tc_summed = tc[['comp1', 'mat', 'value']].groupby(['comp1', 'mat']).sum(['value']).reset_index() #Calculate the sum of TCs from each compartment

# Separate rows with worst/best case scenarios from the rest of the rows, and remove these rows from the original tc df
scen = tc[pd.isna(tc['dqismat'])]
tc = tc.dropna(subset=['dqismat'])
scen.iloc[:, 4:9] = 0                                               # Fill in DQIS scores for scenarios

# Merge the rest rows and the scen rows into one df
restscen = pd.concat([tcrest, scen], ignore_index=True)
# Repeat every row of df for every year in allyears
restscen = restscen.assign(dummy=1).merge(allyears.explode('year').assign(dummy=1), on='dummy').drop(columns='dummy')

#### Fill the year column with the appropriate values based on the DQIS criteria for temporal representativeness
tc['year'] = 0
for i in range(len(tc)):
    if tc['dqistemp'].values[i] == 1:
        tc.iloc[i, tc.columns.get_loc('year')] = 2019
    elif tc['dqistemp'].values[i] == 2:
        tc.iloc[i, tc.columns.get_loc('year')] = 2016
    elif tc['dqistemp'].values[i] == 3:
        tc.iloc[i, tc.columns.get_loc('year')] = 2009
    else:
        tc.iloc[i, tc.columns.get_loc('year')] = 2008

# Create a dataframe of tcs containing all years (tc_empty2)
tc_empty = tc.copy()
tc_empty2 =pd.DataFrame()
firstyear = nodatayear
for i in range(len(allyears)):
      tc_empty['year'] = firstyear
      tc_empty['dqistemp'] = np.nan
      tc_empty2 = pd.concat([tc_empty2, tc_empty])
      firstyear = firstyear+1

# Merge the tc and tc_empty_2 dataframes into one, keeping all values present in tc
# Merge based on comp1, comp2, year and mat
merged_tc = tc_empty2.merge(tc, on=['comp1', 'comp2', 'year', 'mat'], suffixes=('_tc_empty2', '_tc'), how='outer')

# Overwrite values from tc_empty2 with values from tc
merged_tc['dqistemp'] = merged_tc['dqistemp_tc'].combine_first(merged_tc['dqistemp_tc_empty2'])

# Drop redundant columns
merged_tc.drop(merged_tc.iloc[:,12:18], inplace = True, axis = 1)
merged_tc.drop(['dqistemp_tc_empty2', 'priority_tc'], inplace = True, axis = 1)

# Rename columns:
col = {
   'priority_tc_empty2' : 'priority',
   'dqisgeo_tc_empty2': 'dqisgeo',
   'dqismat_tc_empty2': 'dqismat',
   'dqistech_tc_empty2': 'dqistech',
   'dqisrel_tc_empty2': 'dqisrel',
   'value_tc_empty2': 'value'
   } 
merged_tc.rename(columns = col, inplace = True)

# drop duplicate rows
merged_tc.drop_duplicates(inplace=True)

# Create a dictionary contaning 1 dataframe per comp1 comp2 mat combination
dfs_tc = dict(tuple(merged_tc.groupby(['comp1', 'comp2', 'mat', 'value'])))

# Initialize empty dataframe
tc_filled = []
# Fill out DQIStemp scores based on the available score
for df_key, df in dfs_tc.items():  
    #df.drop_duplicates(subset=['year'])
    df.set_index('year', inplace=True)
    first_valid_year = df['dqistemp'].first_valid_index()
    if first_valid_year is not None:
        dqistemp_value = df.at[first_valid_year, 'dqistemp']
        if dqistemp_value == 4:                                                         # If the only temp score available is 4, all other dqistemp scores also get value 4 (least reliable)
            df['dqistemp'] = 4
        elif dqistemp_value == 3:                                                       # If the only available temp score is 3, only that score is 3 and the other rows get value 4
            null_indices = df['dqistemp'].isnull()       
            year_diff = abs(df.index - first_valid_year)
            df.loc[null_indices & ~(year_diff == 0), 'dqistemp'] = 4
        elif dqistemp_value == 2:                                                       # If the only available temp score is 2, only that score keeps value 2  
            null_indices = df['dqistemp'].isnull()
            year_diff = abs(df.index - first_valid_year)
            df.loc[null_indices & (year_diff <= 3), 'dqistemp'] = 3                     # Rows with a max difference of 3 years get temp score 3
            df.loc[null_indices & (year_diff > 3), 'dqistemp'] = 4                      # Other rows get value 4
        elif dqistemp_value == 1:                                                       # If the only available temp score is 1, only that score keeps value 1
            null_indices = df['dqistemp'].isnull()
            year_diff = abs(df.index - first_valid_year)
            df.loc[null_indices & (year_diff <= 3), 'dqistemp'] = 2                     # Rows with a max difference of 3 years get temp score 2
            df.loc[null_indices & ((year_diff > 3) & (year_diff <= 10)), 'dqistemp'] = 3 # Rows with a difference of 4-10 years years get temp score 3
            df.loc[null_indices & (year_diff > 10), 'dqistemp'] = 4                      # Other rows get value 4
            
    # Update the modified DataFrame in the dictionary       
    dfs_tc[df_key] = df  
    
    # Rejoin the year column to the dataframe and reset the index
    df.reset_index()
    dfs_tc[df_key]['year'] = range(nodatayear, endyear+1)
    
# Turn dictionary into one dataframe again    
tc = pd.concat(dfs_tc).reset_index(drop = True)

# Concatenate tc and tcrest
tc = pd.concat([tc, restscen], ignore_index=True)

# Create a column containing row ids
tc['id'] = tc.index + 1

# TEMPORARY: If any geo eu scores are nan, dqis = 2
if reg == 'EU':
    tc['dqisgeo'] = tc['dqisgeo'].fillna(2)

# Add 'source' column to dataframe
tc['source'] = 'See Excel file'
    
# Reorder columns
col_order = ['id', 'comp1', 'comp2', 'year', 'mat', 'value', 'priority', 'dqisgeo', 'dqistemp', 'dqismat', 'dqistech', 'dqisrel', 'source']
tc = tc[col_order]

# Select the years between startyear and endyear
tc = tc[(tc['year'] >= startyear) & (tc['year'] <= endyear)]

# Make sure there are no rows containing nan values
tc = tc[~tc['comp1'].isna()]

print('TC to csv done.. \n')

#%%
# Step to check if there are too many values in Compartments 
tc_unique = pd.concat([tc['comp1'], tc['comp2']]).unique()
comp_unique = comp['fulllabel'].unique()
l_ = list(set(comp_unique).difference(tc_unique))
comp = comp[comp['fulllabel'].isin(l_) == False]

#%%

# If the folder does not already exist, create a folder for the chosen region  
if config.OS_env == 'win': 
    inputfolder = ".\\input_" + config.inputfile + "\\" + reg 
else:
    inputfolder = "./input_" + config.inputfile + "/" + reg

if not os.path.exists(inputfolder):
	os.makedirs(inputfolder)
os.chdir(inputfolder)

# Write compartments, materials, lifetimes, input and transfer coefficients to CSVs
comp.to_csv('Compartments.csv', sep = ';', index = False)
mats.to_csv('Materials.csv', sep = ';', index = False)
lt.to_csv('Lifetimes.csv', sep = ';', index = False)
input_.to_csv('Input.csv', sep = ';', index = False)
tc.to_csv('TC.csv', sep = ';', index = False)

os.chdir(mainfolder)

print('Printing all files to csv done.. \n')
