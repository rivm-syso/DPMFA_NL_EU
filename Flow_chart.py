# -*- coding: utf-8 -*-
"""
Created on Wed Jan 29 16:04:50 2025

@author: hidsa
"""
import os
import pandas as pd
import numpy as np
from graphviz import Digraph

os.chdir("N:/Documents/GitHub/rivm-syso/DPMFA_NL_EU")
import config

current_directory = os.getcwd()

# Replace '/path/to/output' with the actual path to your output directory
#output_directory = "S:\BioGrid\hidsa\GitHub_opgeschoond\DPMFA_NL\Clothing (product sector)"
output_directory = "N:/Documents/GitHub/rivm-syso/DPMFA_NL_EU/output/Clothing"

# # Extract the startyear and endyear from the metadata textfile
# startyear = None
# endyear = None

# # Open the file in read mode
# with open(r"S:\BioGrid\hidsa\GitHub_opgeschoond\DPMFA_NL\metadata.txt", 'r') as file:
#     for line in file:
#         if line.startswith("Startyear:"):
#             startyear = int(line.split("Startyear:")[1].strip())

#         elif line.startswith("Endyear:"):
#             endyear = int(line.split("Endyear:")[1].strip())

#         if startyear is not None and endyear is not None:
#             break

startyear = config.startyear
endyear = config.endyear

# Read in all inflow data to a DataFrame
dfs = []

def list_all_files(directory):
    all_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            # Construct the full file path
            file_path = os.path.join(root, file)
            all_files.append(file_path)
    return all_files

for name in list_all_files(output_directory):
    if "loggedOutflows_" in name:
        name.split('_')
        data = pd.read_csv(name, sep = ' ', header = None).to_numpy()
        name = name.replace(".csv", "")
        mean=[]                                       
        q25=[]
        q75=[]
        minimum=[]
        maximum=[]
                
        for i in range(0,np.shape(data)[1]):
            mean.append(np.mean(data[:,i]))
            q25.append(np.percentile(data[:,i],25))
            q75.append(np.percentile(data[:,i],75))
            minimum.append(np.min(data[:,i]))
            maximum.append(np.max(data[:,i]))
            
        df = pd.DataFrame({
            'mean': mean,
            'q25': q25,
            'q75': q75,
            'minimum': minimum,
            'maximum': maximum,
            })
        df['region'] = name.split('_')[3]
        df['source'] =  name.split('_')[4]
        df['polymer'] = name.split('_')[5]
        df['Flow_from'] = name.split('_')[6]
        df['Flow_to'] = name.split('_')[8]
        df = df.reset_index()
        df['year'] = df['index'] + startyear
        df = df[['region', 'polymer', 'Flow_from', 'Flow_to', 'source', 'year', 'mean', 'q25','q75', 'minimum', 'maximum']]
        
        dfs.append(df)
        
outflows = pd.concat(dfs)

# Select one year and calculate TCs
outflows_2019 = outflows[outflows['year'] == 2019]
outflows_2019 = outflows_2019[['region', 'polymer', 'Flow_from', 'Flow_to', 'year', 'mean', 'source']]

source = outflows_2019['source'].unique()[0]

# Create a dictionary to store results for each polymer
fraction_results = {}

for mat in outflows_2019['polymer'].unique():
    outflows_mat = outflows_2019[outflows_2019['polymer'] == mat]
    
    # Group by 'Flow_from' to calculate total mass leaving each compartment
    total_outflows = outflows_mat.groupby('Flow_from')['mean'].sum().reset_index()
    total_outflows.rename(columns={'mean': 'total_outflow'}, inplace=True)
    
    # Merge total outflows back to the original data to calculate fractions
    outflows_mat = outflows_mat.merge(total_outflows, on='Flow_from')
    
    # Calculate the fraction of mass flow
    outflows_mat['fraction'] = outflows_mat['mean'] / outflows_mat['total_outflow']
    
    # Store the result in the dictionary
    fraction_results[mat] = outflows_mat[['Flow_from', 'Flow_to', 'fraction']]

    # Create a directed graph for each polymer
    dot = Digraph(comment=f'Flowchart for {mat}', format='png')
    
    # Set graph attributes for better layout
    dot.attr(rankdir='LR')  # Left to right layout
    dot.attr('node', shape='box')  # Rectangular nodes
    dot.attr(dpi='600')
    dot.attr(label=f'Flowchart for {source}, {mat}', labelloc='t', fontsize='20')  # Add title
    
    # Add nodes and edges with fractions as labels
    for _, row in outflows_mat.iterrows():
        flow_from = row['Flow_from']
        flow_to = row['Flow_to']
        fraction = row['fraction']
        
        # Add nodes
        dot.node(flow_from, flow_from)
        dot.node(flow_to, flow_to)
        
        # Add edge with label as fraction
        dot.edge(flow_from, flow_to, label=f'{fraction:.2%}')  # Display as percentage
    
    # Render the graph to a file
    dot.render(f'TC_Flowcharts/flowchart_{mat}_{source}', view=True)

