# -*- coding: utf-8 -*-
"""
Created on Tue May  2 14:27:04 2023

@author: Michelle Steenmeijer and Anne Hids (RIVM)
"""
import pandas as pd
import numpy as np
import os
import config

# Fetch configurations from the config.py file
nodatayear  = config.nodatayear
startyear   = config.startyear
endyear     = config.endyear
reg         = config.reg
file        = config.inputfile 
model_type  = config.model_type

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

# From the excel maininput file, reads the Input_NL or Input_EU sheet. 
# The sheets each contain the columns 'Compartment', 'Year', 'Material', 
# 'Source', and columns containing the DQIS scores for each of the 5 categories. 
# The data that is read from the excel sheet is modified to match the format
# used in the example csvs provided by Kawecki et al. 

# Select region (NL or EU):
if reg == 'NL':
    input_ = pd.read_excel(file, sheet_name = "Input_NL")
else:
    input_ = pd.read_excel(file, sheet_name = "Input_EU")

# Rename columns to match the format:
col = {
       'Geo': 'dqisgeo',
       'Temp': 'dqistemp',
       'Mat': 'dqismat',
       'Tech': 'dqistech',
       'Rel': 'dqisrel',
       'Material': 'mat',
       'Data (kt)': 'value',
       'Compartment': 'comp',
       } 

input_.rename(columns = col, inplace = True)
input_.columns = input_.columns.str.lower()
input_ = input_[[ 'comp', 'year', 'mat', 'value', 'dqisgeo', 'dqistemp',
       'dqismat', 'dqistech', 'dqisrel', 'source']]

# If no final year is given in the input data, then the endyear (defined in config.py) is used:
input_['year'].fillna(endyear, inplace = True)

# In the columns defined  in the line below, replace '' with nan, and convert 
# the column to type float.
for col in ['value', 'dqisgeo', 'dqistemp', 'dqismat', 'dqistech', 'dqisrel']:
    input_[col] = input_[col].replace(' ', np.nan)
    input_[col] = input_[col].astype(float)

# Define the main columns to group the data by
maincols = ['comp','year','mat', 'source']

# To the input_ dataframe, copy all rows, and in these copied rows change year to 
# nodatayear and value to zero. This is done as a starting point for interpolation 
# excecuted later in the code. 
input_zero = input_.copy()
input_zero['year'] = nodatayear
input_zero['value'] = 0
input_ = pd.concat([input_, input_zero])
input_ = input_.drop_duplicates()

# Create a dictionary of tuples by grouping the input_dataframe by columns 
# comp and mat.
dfs = dict(tuple(input_.groupby(['comp','mat', 'source'])))

# Create the same dictionary, but the tuples become dataframes
dfs_l = []
for i, df in dfs.items(): 
    dfs_l.append(df)

# Create a dataframe just containing all years from nodatayear to endyear (needed later)
allyears = pd.DataFrame({'year': range(nodatayear, endyear+1)})

# In this loop, the values for input are interpolated from 0 in nodatayear to
# endyear, using the input values provided in the excel file. 

dfs_l2 = []
for df in dfs_l:
    df = df.drop_duplicates()
    df_og = df.copy()
    df_og = df.set_index('year')
    last_year = df_og.index.max()
    nodatayear_to_lastyear = pd.DataFrame({'year': range(nodatayear, last_year+1)})
    df_og = df_og.reset_index() 
    df = df[['year', 'value']].drop_duplicates()
    df = df.set_index('year').reindex(nodatayear_to_lastyear['year'])
    df = df.interpolate().reset_index()
    
    # Extrapolate if the last year in the DataFrame is larger than the final year
    if last_year < allyears['year'].iloc[-1]:
        last_valid_value = df.loc[df['year'] == last_year, 'value'].iloc[0]
        
        if last_valid_value == 0:
            remaining_years = allyears.loc[allyears['year'] > last_year, 'year'].to_frame()
            remaining_years['value'] = 0
            df = pd.concat([df, remaining_years], ignore_index=True)
        
        else:     
            # Calculate fractions
            fractions = pd.DataFrame([{'year': year, 'value': df['value'].iloc[-1] * (projections.loc[projections['year'] == year, 'projected_value'].iloc[0] / last_valid_value)} for year in range(last_year + 1, allyears['year'].iloc[-1] + 1)])
            ref_value = projections.loc[projections['year'] == last_year, 'projected_value'].values[0]
            fractions['fraction'] = fractions['value']/ref_value 
        
           # Extrapolating values for the remaining years
            remaining_years = allyears.loc[allyears['year'] > last_year, 'year'].to_frame()
            remaining_years['value'] = last_valid_value
            
            # Aligning indices and performing the multiplication
            remaining_years = pd.merge(remaining_years, fractions[['year', 'fraction']], on='year', how='left')
            remaining_years['value'] *= remaining_years['fraction']
            
            extrapolated_data = remaining_years.drop(columns=['fraction'])
        
            # Concatenate extrapolated data with the existing DataFrame
            df = pd.concat([df, extrapolated_data], ignore_index=True)

    df['comp'] = df_og['comp'].iloc[0]
    df['mat'] = df_og['mat'].iloc[0]
    df = pd.merge(df, input_[['comp', 'year', 'mat', 'dqisgeo', 'dqistemp', 'dqismat','dqistech', 'dqisrel', 'source']], how = 'left', on = ['comp', 'year', 'mat'])
    
    # In the code below, DQIS scores for temp are filled based on the year the 
    # year the DQIStemp score for the input value was 1. DQIS scores 1-3 years
    # from the input value get score 2, 4-6 years from the input value get score 3, 
    # 6+ years get score 4.
    
    # Select the indices of the rows where dqistemp is not NaN
    df.loc[df['year'] == nodatayear, 'dqistemp'] = np.NaN         # set DQIStemp in 1950 to nan
    df_sub = pd.notna(df['dqistemp'])
    indices = df.loc[df_sub].index
    sel_dfs = {}
    
    # Create a df for every index. The row at index is the only row with a 
    # filled out dqistemp score. The rest is filled according to the rules. 
    # Finally, all dfs are combined into one df, where the lowest score is 
    # selected if there is overlap.      
    for idx in indices:
        # Create a copy of df, where every temp score except for the score in row idx = nan
        selected_df = df.copy()
        selected_df.loc[selected_df.index != idx, 'dqistemp'] = np.nan
        
        if pd.notnull(idx):
            for i in range(len(selected_df)):                            
                if pd.isnull(selected_df.iloc[i]['dqistemp']):           
                    year_diff = abs(i - idx)
                    if year_diff <= 3:
                        selected_df.iloc[i, selected_df.columns.get_loc('dqistemp')] = 2
                    elif year_diff <= 10:
                        selected_df.iloc[i, selected_df.columns.get_loc('dqistemp')] = 3
                    else:
                        selected_df.iloc[i, selected_df.columns.get_loc('dqistemp')] = 4
        # Give each df a different name based on index
        df_name = f"df_{idx}"
        
        # Store df in dataframe
        sel_dfs[df_name] = selected_df
        
    # Make and empty df to store the combined df
    comb_df = pd.DataFrame()
    
    # Combine the dfs into one
    for df_name, df in sel_dfs.items():
        if comb_df.empty:
            comb_df = df.copy()
        
        else: 
            comb_df = pd.merge(comb_df, df, how='outer', on=['year', 'value', 'comp', 'mat', 'dqisgeo', 'dqismat', 'dqistech', 'dqisrel', 'source'])
        
            # Select the minimum 'dqistemp' value from the current and combined DataFrame
            comb_df['dqistemp'] = comb_df[['dqistemp_x', 'dqistemp_y']].min(axis=1)
    
            # Drop unnecessary columns
            comb_df.drop(['dqistemp_x', 'dqistemp_y'], axis=1, inplace=True)
    
    # fill the other values with present values (other DQIS scores, source etc) 
    df = comb_df.ffill().bfill()  
    # append dataframe to list of dataframes                               
    dfs_l2.append(df)                                      

# Concatenate the dataframes in the list to one large dataframe
input_ = pd.concat(dfs_l2).reset_index(drop = True)#.drop_duplicates()

# Fill in a 4 for every missing dqis value (least reliable value)
input_.fillna(4, inplace = True)                         

# If more than 2 input values are given for a year, select min and max value:

# Group by the main columns and count the number of unique values
unique_counts = input_.groupby(maincols)['value'].transform('nunique')

# Filter rows where unique value counts are greater than 2
over_two_unique = input_[unique_counts > 2]

## Now add the min and max rows to the df again
# For each group with more than 2 unique values, get indices of rows with min and max values
idx_min = over_two_unique.groupby(maincols)['value'].idxmin()
idx_max = over_two_unique.groupby(maincols)['value'].idxmax()

# Concatenate indices of min and max rows
min_max_idx = pd.concat([idx_min, idx_max])

# Extract the rows with minimum and maximum values for these groups
min_max_rows = input_.loc[min_max_idx]

# Remove all rows present in over_two_unique from the input_ df
input_ = input_.drop(over_two_unique.index)

# Drop duplicate rows
input_ = input_.drop_duplicates(subset=['year', 'value', 'comp', 'mat']) 

# Concatenate min_max_rows and input_ to get the final DataFrame
input_ = pd.concat([input_, min_max_rows], ignore_index=True)

# Add id column
input_['id'] = input_.index+1

# Reorder columns
col_order = ['id', 'comp', 'year', 'mat', 'value', 'dqisgeo', 'dqistemp', 'dqismat', 'dqistech', 'dqisrel', 'source']
input_ = input_[col_order]

# Select only the years from startyear to endyear
input_ = input_[(input_['year'] >= startyear) & (input_['year'] <= endyear)]

print('Input to csv done.. \n')

#########################################
#%% Transfer coefficients
#########################################

# From the excel maininput file, reads the 'Transfer coeficients' sheet.
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
    inputfolder = ".\\input\\" + reg 
else:
    inputfolder = "./input/" + reg

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