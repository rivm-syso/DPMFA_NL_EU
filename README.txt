# DPMFA_NL_EU 
Dynamic probabilistic material flow analyisis (DPMFA) model for the Netherlands
and the EU. Based on code by EMPA and data in collaboration with TNO.

Author: Institute of Public Health and the Environment (RIVM)
https://doi.org/10.5281/zenodo.12636554

-------------------------------------------------------------------------------
Dependencies: 

Python (version 3.11.7)
Numpy (version 1.26.4)
Pandas (version 2.4.1)
dpmfa (version 1.1) 
sqlite (version 3.41.2)
Anaconda (needed to create and run batch files)

-------------------------------------------------------------------------------

How to run:

Step 1: 
Change the directory at the top of the main.py, write_metadata.py and 
CaseStudy_Runner.py scripts to the folder where the model code is located on
your computer. 

Step 2: 
In Create_batch_files.py, change the directory in line 65 to the directory 
where programs are installed on your computer. Usually this is :/C, so this 
probably does not need to be changed. 

Step 3: 
Set the parameters to your preferences in config.py. Comment line 12 or 13 
depending on your operating system. Comment line 16 or 17 depending on whether 
you want to run a dynamic probabilistic MFA or a probabilistic MFA. Comment 
line 20 or 21 depending on the region for which you want to run the model.

Step 4: 
Run main.py. This will create:
    1) the databases needed as input for the model
    2) CaseStudy_Runner files for each of the source-material combinations
    3) a batch file to run all CaseStudy_Runner files at once named 'Run_all'.

Step 5:
Navigate to the Run_all.bat file in your file explorer and double click in 
order to run it. All output files can be found in the folder 'output' that has
been created in the directory you provided. 

-------------------------------------------------------------------------------
Output:

Within the output folder is a folder for each category that the model has run
for. Within each of these folders, there is a folder for each material within
the category. In these material folders are the CSV files containing the 
output. There are 4 types of CSVs:

    1) Inflow: logged inflow into each compartment in kilotonnes
    2) Outflow: logged outflow from one compartment to another in kilotonnes
    3) Sink: logged inflows into the sinks (final compartments in MFA) in 
             kilotonnes
    4) Stock: logged quantaties of material present in a stock compartment. 
    
Within the CSV files, the rows represent the number of runs (as defined in 
config.py), and the columns represent the years.

-------------------------------------------------------------------------------

Licensed under
Attribution-NonCommercial-ShareAlike
CC BY-NC-SA

Reason for license is this work being based on DPMFA package and other work by EMPA.
https://github.com/empa-tsl/dpmfa
