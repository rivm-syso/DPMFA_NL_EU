# -*- coding: utf-8 -*-
"""
Created on Wed Mar  6 15:20:18 2024

@author: Anne Hids (RIVM)
"""

import os
import shutil
import fileinput
import pandas as pd
import config

region = config.reg

if config.OS_env == 'win': 
    csv_name = ".\\input_" + config.inputfile + "\\" + region + "\\Materials.csv"
else:
    csv_name = "./input_" + config.inputfile + "/" + region + "/Materials.csv"

# import table
df = pd.read_csv(csv_name, sep = ";")

#%% Create a CaseStudy_Runner file for each material 
destlist = []

for i in df.index:
    dest = "CaseStudy_Runner_" + config.inputfile + "_" + df['Name'][i] + ".py"    
    destlist.append(dest) 
    
    if os.path.isfile(dest) == True:
        os.remove(dest)
    
    shutil.copyfile('all_compartments_CaseStudy_Runner.py', dest)
    
    with fileinput.FileInput(dest, inplace=True) as file:
        for line in file:
            if line.startswith("mat"):
                j = 'mat = "' + df['Name'][i] + '"'
                print(j)
            else:
                print(line, end='')
                
    with fileinput.FileInput(dest, inplace=True) as file:
        for line in file:
            if line.startswith("inputfile"):
                j = 'inputfile = "' + config.inputfile + '"'
                print(j)
            else:
                print(line, end='')    

print("Writing batch files done...")

#%% Create a Find_routes and Mass_contributions
dest = "Calculate_mass_flows_" + config.inputfile + ".py"   
shutil.copyfile('Calculate_mass_flows.py', dest)
 
with fileinput.FileInput(dest, inplace=True) as file:
    for line in file:
        if line.startswith("inputfile"):
            j = 'inputfile = "' + config.inputfile + '"'
            print(j)
        else:
            print(line, end='')  
            
dest = "Find_routes_" + config.inputfile + ".py"
shutil.copyfile('Find_routes.py', dest)

with fileinput.FileInput(dest, inplace=True) as file:
    for line in file:

        if line.startswith("inputfile"):
            j = 'inputfile = "' + config.inputfile + '"\n'
            print(j, end='')
            
dest = "Mass_contributions_" + config.inputfile + ".py" 
shutil.copyfile('Mass_contributions.py', dest)
   
with fileinput.FileInput(dest, inplace=True) as file:
    for line in file:
        if line.startswith("inputfile"):
            j = 'inputfile = "' + config.inputfile + '"'
            print(j)
        else:
            print(line, end='')  
            
dest = "write_metadata_" + config.inputfile + ".py" 
shutil.copyfile('write_metadata.py', dest)
   
with fileinput.FileInput(dest, inplace=True) as file:
    for line in file:
        if line.startswith("inputfile"):
            j = 'inputfile = "' + config.inputfile + '"'
            print(j)
        else:
            print(line, end='')  

if config.OS_env == 'win': 
    #%% Create a batch file to run the CaseStudy_Runner files with
    def find(name, path):
            for root, dirs, files in os.walk(path):
                if name in files:
                    return os.path.join(root, name)
            
    # Specify the file name that we're looking for 
    file_name = 'activate.bat'

    # Specify on which computer disk this file can be found
    programs_path = 'C:/' # AH: Verander naar de schijf waar programma's worden geïnstalleerd op jouw computer!

    # Find the file        
    activate_file_path = find('activate.bat', programs_path)
    activate_file_path = '"' + activate_file_path + '"'

    # Change the directory to where we can find the CaseStudy_Runner files
    os.chdir("N:/Documents/GitHub/rivm-syso/DPMFA_NL_EU") # AH: Verander naar de GitHub/DPMFA map of je computer
    filedir = os.getcwd() 

    # Get the path to write_metadata.py
    if config.OS_env == 'win': 
        md = filedir + "\\write_metadata.py"
    else: 
        md = filedir + "/write_metadata.py"

    md = '"' + md + '"'

    # Delete the file if it already exists
    batchfilename = 'Run_all.bat'

    if os.path.isfile(batchfilename) == True:
        os.remove(batchfilename)

    # Create a new file
    f = open(batchfilename, "x")

    # Write the file                
    f.write("@ECHO OFF")
    f.write("\n")
    f.write("REM Runs CaseStudy_Runner for all selection-material combinations")
    f.write("\n")
    f.write("\n")
    f.write("CALL " )
    f.write(activate_file_path)
    f.write("\n")
    f.write("python ")
    f.write(md)
    f.write("\n")
    f.write("ECHO Ran write_metadata.py")
    f.write("\n")
    f.write("\n")

    for i in destlist:
        dest = os.path.join(filedir, i)
        dest = '"' + dest + '"'
        f.write("CALL " )
        f.write(activate_file_path)
        f.write("\n")
        f.write("python ")
        f.write(dest)
        f.write("\n")
        f.write("ECHO Ran ")
        f.write(i)
        f.write("\n")
        f.write("\n")

    f.write("PAUSE")
    f.close()

    print("Writing Run_all.bat done...")

else:
    #%% Create text files with the commands needed to run the CaseStudy_Runner files in linux
    cmd = "bsub -n 1 -W " + str(config.runtime) + " -M " + str(config.maxmemory) + " python "

     # Delete the file if it already exists
    commandsfile = "HPC_commands_" + config.inputfile + ".txt"

    if os.path.isfile(commandsfile) == True:
        os.remove(commandsfile)

    # Create a new file
    f = open(commandsfile, "x")

    f.write(cmd + dest + " & ")

    # Write the file                
    for i in destlist:
        f.write(cmd + i + " & ")
       
    with open(commandsfile, 'rb+') as f:
        f.seek(-2, os.SEEK_END)  # Go to the second-to-last character
        f.truncate()  # Remove everything from this point to the end

    f.close()
    print("Writing HPC_commands.txt done...")

