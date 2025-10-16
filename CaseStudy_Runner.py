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

# Set working directory to where the scripts are located
if config.OS_env == 'win':
    os.chdir("N:/Documents/GitHub/rivm-syso/DPMFA_NL_EU")
else: 
    os.chdir("/data/BioGrid/hidsa/GitHub/DPMFA_NL_EU")

import csv
import numpy as np
from dpmfa import simulator as sc
from dpmfa import components as cp

import setup_model_new as su  # or if cloned, change to location of cloned package

# Fetch configurations
startYear = config.startyear
Tperiods = config.endyear - config.startyear + 1
Speriod = config.Speriod 
RUNS = config.RUNS
seed = config.seed
reg = config.reg
mat = "RUBBER"
sel = "Tyre wear"
mainfolder = os.getcwd()


# Steps to find or create folders  
if config.OS_env == 'win': 
    inputfolder = ".\\input\\" + reg + "\\"
    outputbasefolder = mainfolder
else:
    inputfolder = "./input/" + reg + "/"
    outputbasefolder = '/mnt/scratch_dir/quikj/DPMFA_output/Baseline_EU'  

db_name = reg + "_" + sel + ".db" 

os.chdir(inputfolder) 

pathtoDB = os.path.abspath(db_name)

#%%
#########################################
# Run the model
#########################################
          
## Initiate model parameters
modelname = sel + " " + mat + " in " + reg 
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
stocks = simulator.getStocks()
sinks = simulator.getSinks()

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
        with open(os.path.join(csvfolder,"loggedOutflows_"+ reg +  '_' + sel + '_' + mat +"_" + Comp.name + "_to_" + Target_name + ".csv"), 'w') as RM :  
            a = csv.writer(RM, delimiter=' ')
            data = np.asarray(value)
            a.writerows(data)
    

#%%
# export inflows to csv
for Comp in loggedInflows: # loggedOutflows is the compartment list of compartmensts with loggedoutflows
    with open(os.path.join(csvfolder,"loggedInflows_"+ reg + '_' + sel + '_' + mat+ "_" + Comp +".csv"), 'w') as RM :
        a = csv.writer(RM, delimiter=' ')
        data = np.asarray(loggedInflows[Comp])
        a.writerows(data) 


#%%
    
# export sinks to csv
for sink in sinks:
    if isinstance(sink,cp.Stock):
        continue
    with open(os.path.join(csvfolder,"sinks_" + reg + '_' + sel + '_' + mat + "_" + sink.name +".csv"), 'w') as RM :
        a = csv.writer(RM, delimiter=' ')
        data = np.asarray(sink.inventory)
        a.writerows(data)


#%%
# export stocks to csv
for stock in stocks:
    with open(os.path.join(csvfolder,"stocks_"+ reg + '_' + sel + '_' + mat + "_" + stock.name +".csv"), 'w') as RM :
        a = csv.writer(RM, delimiter=' ')
        data = np.asarray(stock.inventory)
        a.writerows(data)


print('Written all results to csv files.\n')

        
