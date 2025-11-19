DPMFA_NL_EU_measures
================

# README

The model in this (DPMFA_NL_EU/DPMFA_NL_EU_measures) folder is nearly
the same model as the model in the DPMFA_NL_EU folder, with one
important difference: the model has been adjusted so that it can be used
to calculate emissions for different maininput files in parallel. This
is especially useful when calculating emissions for different mitigation
measures. To calculate emissions for different maininput files in
parallel please do the following: - All maininputfiles used to run in
parallel must have a different name - All maininputfiles must be run for
the same region, time period, model type (PMFA or DPMFA)and number of
runs, because there is one config.py file where these variables are
defined.

## Running the model per polymer

To run the model in parallel for different maininputfiles, please follow
these steps:

1.  Change the directory at the top of the following scripts to the
    folder where the model code is located:

    - main_all_compartments.py
    - write_metadata.py
    - all_compartments_CaseStudy_Runner.py
    - Calculate_mass_flows.py
    - Find_routes.py
    - Mass_contributions.py.

2.  If you want to run the model in batch in windows, change the
    directory in line 65 to the directory where programs are installed
    on your computer in Create_batch_files.py. Usually this is :/C, so
    this probably does not need to be changed.

3.  Set the parameters to your preferences in config.py. Set the
    variable ‘inputfile’ to one of the maininputfiles you want to model
    emissions for, without the ‘.xlsx’ extension. Comment line 12 or 13
    depending on your operating system. Comment line 16 or 17 depending
    on whether you want to run a dynamic probabilistic MFA or a
    probabilistic MFA. Comment line 20 or 21 depending on the region for
    which you want to run the model.

4.  Run main_all_compartments.py. This will create:

    1)  the databases needed as input for the model
    2)  CaseStudy_Runner files for each of the polymers
    3)  if the operating system in config.py is ‘win’: a batch file to
        run all CaseStudy_Runner files at once named ‘Run_all’
    4)  if the operating system in config.py is ‘lin’: a text file
        containing LSF commands, for running the CaseStudy_Runner files
        in the linux terminal.

5.  If the operating system in config.py is ‘win’: Navigate to the
    Run_all\_‘inputfile_name’.bat file in your file explorer and double
    click in order to run it. All output files can be found in the
    folder ‘output’ that has been created in the directory you provided
    in step 1. If the operating system in config.py is ‘lin’: open the
    LSF_commands\_‘inputfile_name’.txt file, and copy the contents into
    the linux terminal. Make sure the working directory of the terminal
    is set to the DPMFA_NL_EU/DPMFA_NL_EU_measures folder.

6.  Repeat steps 3 to 5 for every maininputfile you want to model
    emissions for in parallel. This is possible because all scripts and
    input/output folders are named specifically for each maininputfile
    so they don’t interfere with each other.

### Output

An output folder is created for each maininputfile. Inside each output
folder is a folder for each polymer the model has run for. In each of
these folders there are two folders: one folder containing csv files,
and one folder containing pickle files. The pickle files are needed to
calculate the mass flows later. There are 4 types of CSVs in the csv
folder:

- Inflow: logged inflow into each compartment in kilotonnes

- Outflow: logged outflow from one compartment to another in  
  kilotonnes

- Sink: logged inflows into the sinks (final compartments in MFA)  
  in kilotonnes

- Stock: logged quantities of material present in a stock  
  compartment.

Within the CSV files, the rows represent the number of runs (as  
defined in config.py), and the columns represent the years.

### Calculating specific mass flows

After completing the previous steps it is possible to calculate specific
mass flows using the Calculate_mass_flows\_‘inputfile_name’.py script.
The flows to be calculated are defined in config.py. For the 2025
publication we were interested in two types of flows: 1) flows from
certain compartments to all sinks (defined by source_comps and
sink_comps in config.py) 2) flows from certain compartments to recycling
compartments (defined by from_recycling_comps and to_recycling_comps in
config.py).

The flows between these compartments are calculated using by running the
Calculate_mass_flows\_‘inputfile_name’.py script. This script calls two
other scripts: Find_routes\_‘inputfile_name’.py (which finds all routes
between the compartments specified in config.py) and
Mass_contributions\_‘inputfile_name’.py (which calculates the mass
contributions for each found route).

The output from the Calculate_mass_flows\_‘inputfile_name’.py script is
saved in the csv folder of each material, with the prefix:
calculatedMassFlows.

The Calculate_mass_flows\_‘inputfile_name’.py scripts can also be run in
parallel for each of the maininputfiles.

------------------------------------------------------------------------

Licensed under Attribution-NonCommercial-ShareAlike CC BY-NC-SA
(<https://creativecommons.org/licenses/#licenses>)

Reason for license is this work being based on DPMFA package and other
work by EMPA.

<https://github.com/empa-tsl/plastic-dpmfa>
