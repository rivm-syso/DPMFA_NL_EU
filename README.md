[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.12636554.svg)](https://doi.org/10.5281/zenodo.12636554)

Dynamic probabilistic material flow analysis (DPMFA) model for the
Netherlands and the EU. Based on code by EMPA and data in collaboration
with TNO.

Author: Institute of Public Health and the Environment (RIVM)

# Model description

This model is used to calculate micro- and macroplastic emissions for
certain product groups and polymers to the environment. The input needed
to run the model is present in MainInputfile.xlsx. The plastic emissions
to environmental sinks are calculated over time and probabilistically by
using Monte Carlo simulations.

# Dependencies

-   Python (version 3.11.7)
-   Numpy (version 1.26.4)
-   Pandas (version 2.4.1)
-   dpmfa (version 1.1)
-   sqlite (version 3.41.2)
-   Anaconda (needed to create and run batch files)

# How to run the model
There are two ways to run the model: 
1.  per polymer per source compartment (e.g. Agriculture)
2.  per polymer, from all sources at once. 

## Running the model per polymer per source compartment
Running the model per polymer per source compartment yields the flows of micro- 
and macroplastic from each source compartment separately. 

To run the model, please follow these steps:

1.  Change the directory at the top of the main.py, write_metadata.py
    and CaseStudy_Runner.py scripts to the folder where the model code
    is located on your computer.

2.  If you want to run the model in batch in windows, change the directory in 
    line 65 to the directory where programs are installed on your computer in 
    Create_batch_files.py. Usually this is :/C, so this probably does not need 
    to be changed.

3.  Set the parameters to your preferences in config.py. Comment line 12
    or 13 depending on your operating system. Comment line 16 or 17
    depending on whether you want to run a dynamic probabilistic MFA or
    a probabilistic MFA. Comment line 20 or 21 depending on the region
    for which you want to run the model.

4.  Run main_all_compartments.py. This will create: 
    1.  the databases needed as input for the model 
    2.  CaseStudy_Runner files for each of the polymers
    3.  if the operating system in config.py is 'win': a batch file to run all 
    CaseStudy_Runner files at once named 'Run_all' 
    4.  if the operating system in config.py is 'lin': a text file containing 
    LSF commands, for running the CaseStudy_Runner files in the linux terminal. 

5.  If the operating system in config.py is 'win': Navigate to the Run_all.bat 
    file in your file explorer and double
    click in order to run it. All output files can be found in the
    folder 'output' that has been created in the directory you provided
    in step 1. If the operating system in config.py is 'lin': open the 
    LSF_commands.txt file, and copy the contents into the linux terminal. Make 
    sure the working directory of the terminal is set to the DPMFA_NL_EU folder. 

### Output

Within the output folder is a folder for each category that the model
has run for. Within each of these folders, there is a folder for each
material within the category. In these material folders are the CSV\
files containing the output. There are 4 types of CSVs:

-   Inflow: logged inflow into each compartment in kilotonnes

-   Outflow: logged outflow from one compartment to another in\
    kilotonnes

-   Sink: logged inflows into the sinks (final compartments in MFA)\
    in kilotonnes

-   Stock: logged quantities of material present in a stock\
    compartment.

Within the CSV files, the rows represent the number of runs (as\
defined in config.py), and the columns represent the years.

## Running the model per polymer 
Running the model per polymer yields the flows of micro- 
and macroplastic from all sources at once. Three scripts were added to calculate
specific flows after running the model.  

To run the model, please follow these steps:

1.  Change the directory at the top of the main_all_compartments.py, write_metadata.py
    and all_compartments_CaseStudy_Runner.py scripts to the folder where the model code
    is located on your computer.

2.  If you want to run the model in batch in windows, change the directory in 
    line 65 to the directory where programs are installed on your computer in 
    Create_batch_files.py. Usually this is :/C, so this probably does not need 
    to be changed.

3.  Set the parameters to your preferences in config.py. Comment line 12
    or 13 depending on your operating system. Comment line 16 or 17
    depending on whether you want to run a dynamic probabilistic MFA or
    a probabilistic MFA. Comment line 20 or 21 depending on the region
    for which you want to run the model.

4.  Run main_all_compartments.py. This will create: 
    1)  the databases needed as Afterinput for the model 
    2)  CaseStudy_Runner files for each of the polymers
    3)  if the operating system in config.py is 'win': a batch
    file to run all CaseStudy_Runner files at once named 
    'Run_all' 
    4) if the operating system in config.py is 'lin': a text 
    file containing LSF commands, for running the 
    CaseStudy_Runner files in the linux terminal. 

5.  If the operating system in config.py is 'win': Navigate to the Run_all.bat 
    file in your file explorer and double
    click in order to run it. All output files can be found in the
    folder 'output' that has been created in the directory you provided
    in step 1. If the operating system in config.py is 'lin': open the 
    LSF_commands.txt file, and copy the contents into the linux terminal. Make 
    sure the working directory of the terminal is set to the DPMFA_NL_EU folder. 

### Output

Within the Output folder is a folder for each polymer the model has run for. 
In each of these folders there are two folders: one folder containing csv files, 
and one folder containing pickle files. The pickle files are needed to calculate 
the mass flows later. There are 4 types of CSVs in the csv folder:

-   Inflow: logged inflow into each compartment in kilotonnes

-   Outflow: logged outflow from one compartment to another in\
    kilotonnes

-   Sink: logged inflows into the sinks (final compartments in MFA)\
    in kilotonnes

-   Stock: logged quantities of material present in a stock\
    compartment.

Within the CSV files, the rows represent the number of runs (as\
defined in config.py), and the columns represent the years.

### Calculating specific mass flows

Important: before calculating the mass flows, change the file path for your
operating system in the following scripts: 

-   Calculate_mass_flows.py
-   Find_routes.py
-   Mass_contributions.py. 

After completing the previous steps it is possible to calculate specific mass 
flows using the Calculate_mass_flows.py script. The flows to be calculated are 
defined in config.py. For the 2025 publication we were interested in two types
of flows: 
1) flows from certain compartments to all sinks (defined by source_comps and
sink_comps in config.py)
2) flows from certain compartments to recycling compartments (defined by 
from_recycling_comps and to_recycling_comps in config.py).

The flows between these compartments are calculated using by running the 
Calculate_mass_flows.py script. This script calls two other scripts: Find_routes.py
(which finds all routes between the compartments specified in config.py) and 
Mass_contributions.py (which calculates the mass contributions for each found 
route).

The output from the Calculate_mass_flows.py script is saved in the csv folder of
each material, with the prefix: calculatedMassFlows. 

------------------------------------------------------------------------

Licensed under Attribution-NonCommercial-ShareAlike CC BY-NC-SA
(<https://creativecommons.org/licenses/#licenses>)

Reason for license is this work being based on DPMFA package and other
work by EMPA.

<https://github.com/empa-tsl/plastic-dpmfa>
