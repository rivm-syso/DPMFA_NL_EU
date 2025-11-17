# -*- coding: utf-8 -*-
"""
Created on Mon Apr 14 09:45:24 2025


"""

# -*- coding: utf-8 -*-
"""
RIVM note: Script copied from EMPA plastic-dpmfa package:
https://github.com/empa-tsl/plastic-dpmfa
plastic-dpmfa/setup_model_new.py
only global variables (name of database, name/location of folder) are added

Original: 
Created on 09.04.2020
@author: Delphine Kawecki

"""

import os
import config
import paths

# Set working directory to where the scripts are located
if config.OS_env == 'win':
    os.chdir(win_main_folder)
else: 
    os.chdir(lin_main_folder)

import csv
import numpy as np
from dpmfa import simulator as sc
from dpmfa import components as cp
import pandas as pd
import pickle

import setup_model_new as su  # or if cloned, change to location of cloned package

# Fetch configurations
startYear = config.startyear
Tperiods = config.endyear - config.startyear + 1
Speriod = config.Speriod 
RUNS = config.RUNS
seed = config.seed
reg = config.reg
mat = "RUBBER"
mainfolder = os.getcwd()

# Steps to find or create folders  
if config.OS_env == 'win': 
    inputfolder = ".\\input\\" + reg + "\\"
    outputbasefolder = mainfolder
else:
    inputfolder = "./input/" + reg + "/"
    outputbasefolder = outputbasefolder_lin  

db_name = reg + ".db" 

os.chdir(inputfolder) 

pathtoDB = os.path.abspath(db_name)

#%%
#########################################
# Run the model
#########################################
          
## Initiate model parameters
modelname = mat + " in " + reg 
endYear = startYear + Tperiods - 1 
    
# for plots
xScale=np.arange(startYear,startYear+Tperiods)        
    
# Run setup model    
model = su.setupModel(pathtoDB,modelname,RUNS,mat, startYear, endYear)

# check validity
#model.checkModelValidity() 
#model.debugModel()

# set up the simulator object    
simulator = sc.Simulator(RUNS, Tperiods, seed, True, True)
# define what model  needs to be run
simulator.setModel(model)
simulator.runSimulation()
#simulator.debugSimulator()

print('Simulation succesful...\n')

# Change directory back to the main folder (where the scripts are)
os.chdir(outputbasefolder)

# If it does not exist, create an output folder
# If it does not exist, create an output folder
if config.OS_env == "win":
    outputfolder = ".\\output\\" +  mat + "\\"
else:
    outputfolder = "./output/" + mat + "/" 
    
# If it does not exist, create a CSV folder in the output folder
if config.OS_env == "win":
    csvfolder = ".\\output\\" + mat + "\\" + "csv\\"
else: 
    csvfolder = "./output/" + mat + "/" + "csv/"
    
if not os.path.exists(csvfolder):
    os.makedirs(csvfolder)
else:
    # If the folder exists, remove all csv files in it
    for file_name in os.listdir(csvfolder):
        file_path = os.path.join(csvfolder, file_name)
        os.remove(file_path)
    
#%%
### Get inflows, outflows, stocks and sinks
loggedInflows = simulator.getLoggedInflows() 
loggedOutflows = simulator.getLoggedOutflows()
loggedTotalOutflows = simulator.getLoggedTotalOutflows()
stocks = simulator.getStocks()
sinks = simulator.getSinks()
loggedTotalOutflows = simulator.getLoggedTotalOutflows()
modelledYears = range(config.startyear, config.endyear+1)

#%%
## display mean ± std for each outflow
print('-----------------------')
for Speriod in range(Tperiods):  
    print('Logged Outflows period '+str(Speriod)+' (year: '+str(startYear+Speriod)+'):')
    print('')
    # loop over the list of compartments with loggedoutflows
    for Comp in loggedOutflows:
        print('Flows from ' + Comp.name +':' )
        # in this case name is the key, value is the matrix(data), in this case .items is needed
        for Target_name, value in Comp.outflowRecord.items():
            print(' --> ' + str(Target_name)+ ': Mean = '+str(round(np.mean(value[:,Speriod]),0))+' ± '+str(round(np.std(value[:,Speriod]),0)) + ' kiloton'  )
            print('')
print('-----------------------')

#%%
### export data
# In CSV files, columns are years, rows are runs
# export outflows to csv
for Comp in loggedOutflows: # loggedOutflows is the compartment list of compartments with loggedoutflows
    for Target_name, value in Comp.outflowRecord.items(): # in this case name is the key, value is the matrix(data), in this case .items is needed     
        with open(os.path.join(csvfolder,"loggedOutflows_"+ reg +  '_' + mat +"_" + Comp.name + "_to_" + Target_name + ".csv"), 'w') as RM :  
            a = csv.writer(RM, delimiter=' ')
            data = np.asarray(value)
            a.writerows(data)
    

#%%
# export inflows to csv
for Comp in loggedInflows: # loggedOutflows is the compartment list of compartmensts with loggedoutflows
    with open(os.path.join(csvfolder,"loggedInflows_"+ reg + '_' + mat+ "_" + Comp +".csv"), 'w') as RM :
        a = csv.writer(RM, delimiter=' ')
        data = np.asarray(loggedInflows[Comp])
        a.writerows(data) 


#%%
    
# export sinks to csv
for sink in sinks:
    if isinstance(sink,cp.Stock):
        continue
    with open(os.path.join(csvfolder,"sinks_" + reg + '_' + mat + "_" + sink.name +".csv"), 'w') as RM :
        a = csv.writer(RM, delimiter=' ')
        data = np.asarray(sink.inventory)
        a.writerows(data)


#%%
# export stocks to csv
for stock in stocks:
    with open(os.path.join(csvfolder,"stocks_"+ reg + '_' + mat + "_" + stock.name +".csv"), 'w') as RM :
        a = csv.writer(RM, delimiter=' ')
        data = np.asarray(stock.inventory)
        a.writerows(data)

print('Written all results to csv files.\n')
#%%
# Calculate TCs
# Create an empty dictionary to store transfer coefficients
# Get transfer coefficients
 
# Create an empty dictionary to store transfer coefficients
dict_Transfer_Coefficients = {}
 
# Loop over each compartment in LoggedOutflows
for compartment in loggedOutflows:
    #print(f"\nProcessing compartment: {compartment.name}")  # Debugging statement
    # Loop over each destination in the compartment's outflowRecord
    for target_name, mass_flows in compartment.outflowRecord.items():
        # .outflowRecord is an arary in which each Monte Carlo run has a row and
        # each year has a column. For the next computions I want a row for each
        # year and a column for each Monte Carlo run. So I transpose the mass_flows
        mass_flows = mass_flows.T
        #print(f"  Processing outflow to target: {target_name}")  # Debugging statement
        # Get the total outflow for the compartment from LoggedTotalOutflows
        total_outflow = loggedTotalOutflows.get(compartment.name, None)
        # LoggedTotalOutflows.get(compartment.name) returns an array in which each 
        # Monte Carlo run has a row and each year has a column. For the next 
        # computions I want a row for each year and a column for each Monte Carlo 
        # run. So I transpose the total_outflow
        total_outflow = total_outflow.T
        #print("Total outflow from", compartment.name," =", total_outflow)
        if total_outflow is not None:
            #print(f"    Total outflow found for {compartment.name}")  # Debugging statement
            # Initialize a list to hold rows for the DataFrame
            df_rows = []
            # Prepare the column names for the DataFrame
            columns = ["Year"] + [f"TC (for Monte Carlo run {i+1})" for i in range(RUNS)]
            for year_index, year in enumerate(modelledYears):
                #print(f"    Processing year: {year}")  # Debugging statement
                tc_row = [year]  # Start the row with the modelled year
                # For each Monte Carlo run, calculate the transfer coefficient
                for run_index in range(RUNS):
                    # Get the mass flow for this year and run from the mass_flows array
                    mass_flow = mass_flows[year_index, run_index]
                    # Get the total outflow for this year and run
                    total_outflow_value = total_outflow[year_index, run_index]
                    # Compute the transfer coefficient (mass flow / total outflow)
                    if total_outflow_value != 0:
                        tc = mass_flow / total_outflow_value
                    else:
                        tc = 0  # Handle division by zero, if necessary
                    tc_row.append(tc)  # Add the TC for this Monte Carlo run
                    #print(f"      Monte Carlo run {run_index+1}: Mass flow = {mass_flow}, Total outflow = {total_outflow_value}, TC = {tc}")  # Debugging statement
                # Append the tc_row (containing the year and TC values) to df_rows
                df_rows.append(tc_row)
            # Convert the df_rows to a DataFrame and assign it to the dictionary
            df_transfer_coefficients = pd.DataFrame(df_rows, columns=columns)
            # Transpose the DataFrame and fix the headers
            df_transposed = df_transfer_coefficients.set_index("Year").T
            # Store the transposed DataFrame in the dictionary
            dict_Transfer_Coefficients[(compartment.name, target_name)] = df_transposed
        else:
            print(f"    No total outflow found for {compartment.name}")

#%%
# Get flow definitions (From ... To ...)

# Make a temporary dictionary that contains all the flow definitions (From ... To ...)
dict_get_from_to = [(key[0], key[1]) for key in dict_Transfer_Coefficients.keys()]

# Create DataFrame
df_From_To = pd.DataFrame(dict_get_from_to, columns=['From', 'To'])

#%%
# Get all mass flows
# Create a folder name
all_flows_folder_name = "All_mass_flows"

# Create the full folder path
all_flows_folder_path = os.path.join(outputfolder, all_flows_folder_name)

# Create the folder
os.makedirs(all_flows_folder_path, exist_ok=True)

# Loop through compartments with logged outflows
for Comp in loggedOutflows:
    
    # Loop through all targets for the current compartment
    for Target_name, flows_array in Comp.outflowRecord.items():
        
        # Define the filename
        filename = f"{reg}_{mat}_logged_flows_from_{Comp.name}_to_{Target_name}.csv"
        filepath = os.path.join(all_flows_folder_path, filename)
        
        with open(filepath, 'w', newline='') as RM:
            writer = csv.writer(RM, delimiter=',')
            
            # Create the header
            header = ['Year'] + [f"Mass flow (kt) (for Monte Carlo run {i+1})" for i in range(RUNS)]
            writer.writerow(header)
            
            # Retrieve the flow data
            flows = np.asarray(flows_array)
            
            flows = flows.T
            
            # Add modelled years to the data
            rows = [[year] + list(row) for year, row in zip(modelledYears, flows)]
            
            # Write rows to the CSV file
            writer.writerows(rows)

# Create a dictionary to store the CSV dataframes of all mass flows
dict_all_mass_flows = {}

# Find all CSV files in the folder
csv_files_all_mass = [f for f in os.listdir(all_flows_folder_path) if f.endswith(".csv")]

if csv_files_all_mass:
    for csv_file_all_mass in csv_files_all_mass:
        csv_path                            = os.path.join(all_flows_folder_path, csv_file_all_mass)
        df_name                             = os.path.splitext(csv_file_all_mass)[0]
        simplified_key                      = df_name.replace((config.reg + "_" + mat + "_logged_flows_from_"), "").replace("_to_", ", ")
        df                                  = pd.read_csv(csv_path, index_col=0).T   # Load CSV with first column as index, then transpose
        dict_all_mass_flows[simplified_key] = df

else:
    print("No CSV files found in '2. All mass flows'.")

#%%
# Save pickle files needed to calculate mass flows later

# Create a folder name
pickle_files_folder_name = "Pickle_files"

# Create the full folder path
pickle_files_folder_path = os.path.join(outputfolder, pickle_files_folder_name)

# Create the folder if it doesn't exist
os.makedirs(pickle_files_folder_path, exist_ok=True)

# Dictionary of all model output objects to save
data_to_save = {
    "LoggedOutflows":                loggedOutflows,
    "LoggedInflows":                 loggedInflows,
    "LoggedTotalOutflows":           loggedTotalOutflows,
    "TransferCoefficients":          dict_Transfer_Coefficients,
    "FromTo":                        df_From_To,
    "AllMassFlows":                  dict_all_mass_flows
}

# Loop through 'data_to_save' and save each object as a pickle file
for name, data in data_to_save.items():
    file_path = os.path.join(pickle_files_folder_path, f"{name}.pkl")
    
    with open(file_path, "wb") as f:
        pickle.dump(data, f)
