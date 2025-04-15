# -*- coding: utf-8 -*-
"""
RIVM note: Script copied from EMPA dpmfa-db package:
https://github.com/empa-tsl/dpmfa-db
dpmfa-db/example_data/db_setup.py

Original: 
Created on Tue Oct  8 11:36:27 2019

@author: dew

Altered by Anne Hids (RIVM)

To run this script, SQLite needs to be installed on the computer.

"""
import os
import config
import pandas as pd
import sqlite3
import shutil

# Fetch configurations
reg = config.reg
sellist = config.sellist

# Steps to find or create folders  
if config.OS_env == 'win': 
    inputfolder = ".\\input\\" + reg + "\\" 
else:
    inputfolder = "./input/" + reg + "/"  

db_name = reg + ".db"
os.chdir(inputfolder)  

source_pathtoDB = os.path.abspath(db_name)

# if the database already exist, remove and start new
if os.path.isfile(db_name) == True:
    os.remove(db_name)

#%%
# create or open database
connection = sqlite3.connect(db_name,timeout=10)
cursor = connection.cursor()

### COMPARTMENTS ##############################################################

# create a table for compartments
cursor.execute("""
               CREATE TABLE IF NOT EXISTS compartments (
               name TEXT,
               fulllabel TEXT,
               type TEXT,
               PRIMARY KEY(fulllabel)
               );""")

# import table
df = pd.read_csv('Compartments.csv', sep = ";", decimal = ",")
# append data to database   
df.to_sql('compartments', connection, if_exists='append', index = False)

### MATERIALS #################################################################

# create a table for materials
cursor.execute("""
               CREATE TABLE IF NOT EXISTS materials (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               name TEXT
               );""")

# import table
df = pd.read_csv('Materials.csv', sep = ";", decimal = ",")

# append data to database   
df.to_sql('materials', connection, if_exists='append', index = False)

### TRANSFER COEFFICIENTS #####################################################

# create a table for transfer coefficients
cursor.execute("""
               CREATE TABLE IF NOT EXISTS transfercoefficients (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               comp1 INTEGER NOT NULL,
               comp2 INTEGER NOT NULL,
               year INTEGER,
               mat INTEGER NOT NULL,
               value DOUBLE,
               priority INTEGER NOT NULL,
               dqisgeo INTEGER NOT NULL,
               dqistemp INTEGER NOT NULL,
               dqismat INTEGER NOT NULL,
               dqistech INTEGER NOT NULL,
               dqisrel INTEGER NOT NULL,
               source TEXT,
               FOREIGN KEY(comp1) REFERENCES compartments(name),
               FOREIGN KEY(comp2) REFERENCES compartments(name),
               FOREIGN KEY(mat) REFERENCES materials(name)
               );""")

# import table
df = pd.read_csv('TC.csv', sep = ";", decimal = ",")

# append data to database   
df.to_sql('transfercoefficients', connection, if_exists='append', index = False)


### INPUT #####################################################################

# create a table for input
cursor.execute("""
               CREATE TABLE IF NOT EXISTS input (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               comp TEXT,
               year INTEGER,
               mat TEXT,
               value DOUBLE,
               dqisgeo INTEGER NOT NULL,
               dqistemp INTEGER NOT NULL,
               dqismat INTEGER NOT NULL,
               dqistech INTEGER NOT NULL,
               dqisrel INTEGER NOT NULL,
               source TEXT,
               FOREIGN KEY(comp) REFERENCES compartments(name),
               FOREIGN KEY(mat) REFERENCES materials(id)
               );""")


# explore directory for files
for root, dirs, files in os.walk(".", topdown=False):
    for name in files:
        
        # test if "Input" is in file name, if not, skip
        if not "Input" in name:
            continue
        
        # else import table
        df = pd.read_csv(name, sep = ";", decimal = ",")
       
        # append data to database   
        df.to_sql('input', connection, if_exists='append', index = False)


### LIFETIMES #################################################################

# create a table for lifetimes
cursor.execute("""
               CREATE TABLE IF NOT EXISTS lifetimes (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               comp TEXT,
               year INTEGER,
               value DOUBLE,
               FOREIGN KEY(comp) REFERENCES compartments(name)
               );""")

# import table
df = pd.read_csv('Lifetimes.csv', sep = ";", decimal = ",")

# append data to database   
df.to_sql('lifetimes', connection, if_exists='append', index = False)


# commit changes
connection.commit()

# close connection
connection.close()


print('Converting csv files to '+ reg +' database done...\n')

#%%
#########################################
# Create selection databases
#########################################

## Create a new database for sel[i], containing only the input rows for sel[i]

selmatdf = pd.DataFrame()

for sel in sellist:
    # Create a folder for the new input database (if it does not exist)
    if config.OS_env == 'win': 
        selfolder = ".\\"  
    else:
        selfolder = "./" 
         
    # Change working directory to selfolder  
    os.chdir(selfolder) 
    
    # Create a path for the copied db file
    db_name = reg + "_" + sel + ".db"
    pathtoDB = os.path.abspath(db_name)
    
    # if the database already exist, remove and start new
    if os.path.isfile(db_name) == True:
        os.remove(db_name)
        
    # Copy the database to the new folder
    shutil.copy(source_pathtoDB, pathtoDB)
    
    # Open a connection to the new database
    connection = sqlite3.connect(pathtoDB)
    cursor = connection.cursor()
       
    if sel == "Clothing" and reg == "NL":
        comps = ["Import of clothing (EU)", "Import of clothing (Global)"]
    elif sel == "Clothing" and reg == "EU": 
        comps = ["Import of clothing (Global)", "Import of plastic sheets", "Import of yarn", 'Domestic primary plastic production', 'Import of primary plastics']    
    else:
        comps = [sel]
    
    query = f"SELECT * FROM input WHERE comp IN ({','.join(['?'] * len(comps))})"
    
    # Execute the query with the list of `comps` as parameters
    cursor.execute(query, comps)
    
    # Convert the results to a DataFrame
    input_selection = pd.DataFrame(cursor.fetchall())
    
    # Rename columns of dataframe
    col = {
           0: 'id',
           1: 'comp',
           2: 'year',
           3: 'mat',
           4: 'value',
           5: 'dqisgeo',
           6: 'dqistemp',
           7: 'dqismat',
           8: 'dqistech',
           9: 'dqisrel',
           10: 'source'
           } 

    input_selection.rename(columns = col, inplace = True)
    
    # Remove the original input table from the database
    cursor.execute("DROP TABLE input")
    
    ## Insert input_selection as the new input table in the database
    # Create a table for input
    cursor.execute("""
                   CREATE TABLE IF NOT EXISTS input (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   comp TEXT,
                   year INTEGER,
                   mat TEXT,
                   value DOUBLE,
                   dqisgeo INTEGER NOT NULL,
                   dqistemp INTEGER NOT NULL,
                   dqismat INTEGER NOT NULL,
                   dqistech INTEGER NOT NULL,
                   dqisrel INTEGER NOT NULL,
                   source TEXT,
                   FOREIGN KEY(comp) REFERENCES compartments(name),
                   FOREIGN KEY(mat) REFERENCES materials(id)
                   );""")

    # Append data to database   
    input_selection.to_sql('input', connection, if_exists='append', index = False)

    # Check which materials occur in selection and add these to a selmatcombis
    cursor.execute("SELECT DISTINCT mat FROM input")
    materials = []
    materials = cursor.fetchall()
    materials_series = pd.Series()
    materials_series = pd.Series([mat[0] for mat in materials])
    
    selmatcombis = pd.DataFrame()
    selmatcombis['mat'] = materials_series
    selmatcombis['sel'] = sel
    
    selmatdf = pd.concat([selmatdf, selmatcombis], axis = 0)
    
    # Commit changes
    connection.commit()

    # Close connection
    connection.close()    
    
selmatdf.to_csv('selection_material_combinations.csv', sep = ";", index = True, header = True)

os.chdir(mainfolder)

print('Creating selection databases done...')

