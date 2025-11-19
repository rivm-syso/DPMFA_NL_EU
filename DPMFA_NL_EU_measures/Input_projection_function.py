# -*- coding: utf-8 -*-
"""
Created on Tue Dec  3 10:45:15 2024


"""
# From the excel maininput file, reads the Input_NL or Input_EU sheet. 
# The sheets each contain the columns 'Compartment', 'Year', 'Material', 
# 'Source', and columns containing the DQIS scores for each of the 5 categories. 
# The data that is read from the excel sheet is modified to match the format
# used in the example csvs provided by Kawecki et al. 

def project_input(file, inputsheetname, startyear, endyear, nodatayear, projections):
    import numpy as np
    import pandas as pd
    
    input_ = pd.read_excel(file, sheet_name = inputsheetname)
    
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
        last_year = int(df_og.index.max())
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
    #input_ = input_[(input_['value'] != 0)]
    
    return(input_)
