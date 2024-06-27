# DPMFA_NL_EU 
DPMFA model based on code by EMPA and data in collaboration with TNO

--------------------------------------------------------------------------------------------------------------------------------------------------------------

Dependencies: 

Python (version 3.11.7)
Numpy (version 1.26.4)
Pandas (version 2.4.1)
dpmfa (version 1.1) 
sqlite (version 3.41.2)
Anaconda (needed to create and run batch files)

How to run:

Step 1: 
Change the directory at the top of the main.py, write_metadata.py and casestudy_runner.py scripts to where the DPMFA_NL_EU code is located on your computer. 

Step 2: 
In Create_batch_files.py, change the directory in line 65 to the directory where programs are installed on your computer. 

Step 3: 
Set the parameters to your preferences in config.py.

Step 4: 
Run main.py. This will create the databases needed as input for the model, as well as casestudy runner files for each of the source-material combinations, 
and a batch file to run all casestudy_runner files at once names 'Run_all'. 

Step 5:
Click on the Run_all.bat file on your computer, the model will now run. 

--------------------------------------------------------------------------------------------------------------------------------------------------------------

Licensed under
Attribution-NonCommercial-ShareAlike
CC BY-NC-SA

Reason for license is this work being based on DPMFA package and other work by EMPA.
https://github.com/empa-tsl/dpmfa
