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
    csv_name = ".\\input\\" + region + "\\selection_material_combinations.csv"
else:
    csv_name = "./input/" + region + "/selection_material_combinations.csv"

# import table
df = pd.read_csv(csv_name, sep = ";")

#%% Create a CaseStudy_Runner file for each material 
destlist = []

for i in df.index:
    dest = "CaseStudy_Runner_" + df['sel'][i].replace("(", "").replace(")", "").replace(" ", "_") + "_" + df['mat'][i] + ".py"    
    destlist.append(dest) 
    
    if os.path.isfile(dest) == True:
        os.remove(dest)
    
    shutil.copyfile('CaseStudy_Runner.py', dest)
    
    with fileinput.FileInput(dest, inplace=True) as file:
        for line in file:
            if line.startswith("mat"):
                j = 'mat = "' + df['mat'][i] + '"'
                print(j)
            else:
                print(line, end='')
            
    with fileinput.FileInput(dest, inplace=True) as file:
        for line in file:
            if line.startswith("sel"):
                j = 'sel = "' + df['sel'][i] + '"'
                print(j)
            else:
                print(line, end='')

print("Writing batch files done...")

if config.OS_env == 'win': 
    #%% Create a batch file to run the CaseStudy_Runner files with
    def find(name, path):
        for root, dirs, files in os.walk(path):
            if name in files:
                return os.path.join(root, name)
            
    # Specify the file name that we're looking for 
    file_name = 'activate.bat'
    
    # Specify on which computer disk this file can be found
    programs_path = 'C:/' # Change directory to where programs are installed on your computer
    
    # Find the file        
    activate_file_path = find('activate.bat', programs_path)
    activate_file_path = '"' + activate_file_path + '"'
    
    # Change the directory to where we can find the CaseStudy_Runner files
    filedir = os.getcwd() 
    
    # Get the path to write_metadata.py
    md = filedir + "\\write_metadata.py"
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
    
    # If the output folder does not exist, create folder
    if config.OS_env == 'win': 
        outputfolder = ".\\output\\" 
    else:
        outputfolder = "./output/" 
    
    if not os.path.exists(outputfolder):
    	os.makedirs(outputfolder)
    os.chdir(outputfolder)

else:
    #%% Create text files with the commands needed to run the CaseStudy_Runner files in linux
    cmd = "bsub -n 1 -W " + str(config.runtime) + " -M " + str(config.maxmemory) + " python "

     # Delete the file if it already exists
    commandsfile = 'LSF_commands.txt'

    if os.path.isfile(commandsfile) == True:
        os.remove(commandsfile)

    # Create a new file
    f = open(commandsfile, "x")

    f.write(cmd + "write_metadata.py & ")

    # Write the file                
    for i in destlist:
        f.write(cmd + i + " & ")
       
    with open(commandsfile, 'rb+') as f:
        f.seek(-2, os.SEEK_END)  # Go to the second-to-last character
        f.truncate()  # Remove everything from this point to the end

    f.close()
    print("Writing LSF_commands.txt done...")

# If the output folder does not exist, create folder
if config.OS_env == 'win': 
    outputfolder = ".\\output\\" 
else:
    outputfolder = "./output/" 

if not os.path.exists(outputfolder):
	os.makedirs(outputfolder)
os.chdir(outputfolder)