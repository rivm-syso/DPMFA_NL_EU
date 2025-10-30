# Script to make RData file for calculated mass flows
# Authors: Joris Quik and Anne Hids

# Load packages 
library(tidyverse)
library(readr)

env = "win"
#env = "lin"

################################ Load data #####################################
# when working from DWO, we can use:
#data_folder <- "/rivm/n/hidsa/Documents/DPMFA_textiel/Output_backup/output_28_7"
data_path <- "/rivm/biogrid/hidsa/DPMFA_output"
#data_path <- "~/my_scratch_dir/DPMFA_output"

folder_name <- "Baseline_EU_v3"

data_folder <- file.path(data_path, paste0("output_", folder_name))

#setwd(data_folder)

# Get csv file paths
file_paths <- list.files(path=data_folder, pattern = "\\.csv$", recursive=TRUE)
file_paths <- file_paths[str_detect(file_paths, "calculatedMassFlows")]
file_pathsdf <- as.data.frame(file_paths)

if(length(file_paths) == 0){
  print("No calculated mass flow files found")
}

print(folder_name)

########################### Get configurations #################################
filename <- paste0(data_folder, "/metadata.txt")
f <- readLines(filename, n=13)

ModelRunDate <- grep("Start date and time:",f, value=TRUE)
ModelRunDate <- as.Date(gsub("Start date and time: ", "", ModelRunDate), format = "%d-%m-%Y") # somehow time is not converted  with "%d-%m-%Y %H:%M:%S"

startyear <- grep("Startyear: ",f, value=TRUE)
startyear <- as.numeric(gsub("Startyear: ", "", startyear))

endyear <- grep("Endyear: ",f, value=TRUE)
endyear <- as.numeric(gsub("Endyear: ", "", endyear))

runs <- grep("Runs: ",f, value=TRUE)
runs <- as.numeric(gsub("Runs: ", "", runs))

modeltype <- grep("Model type: ", f, value=TRUE)
modeltype <- gsub("Model type: ", "", modeltype)
modeltype <- as.character(modeltype)

inputfile <- grep("Maininputfile version: ", f, value=TRUE)
inputfile <- gsub("Maininputfile version: ", "", inputfile)

region <- grep("Region: ", f, value=TRUE)
region <- gsub("Region: ", "", region)

metadata <- list(ModelRunDate = ModelRunDate,
                 startyear = startyear,
                 endyear = endyear,
                 runs = runs,
                 modeltype = modeltype,
                 inputfile = inputfile,
                 region = region)

############################# Define function ##################################
readdelimF <- function(root_folder, FileName, startyear, endyear, runs){
  data <- read_delim(file = paste0(root_folder,"/",FileName),
                     col_names = FALSE,delim = " ",
                     col_types = "d",
                     n_max = runs,
                     locale = locale(encoding = "UTF-8")) |>
    rename_with(~paste0(c(startyear:endyear)), everything() ) |> mutate(RUN = 1:runs)
}

############################## Make a dataframe from the calculated mass flows ################################

ONLY_calculatedMassFlows <- grep(paste0("calculatedMassFlows"), file_paths)

iD_massflows <-
  tibble(iD_source = file_paths[ONLY_calculatedMassFlows]) |> 
  separate_wider_delim(cols = everything(),
                       names = c("Type","Scale","Polymer", "From_compartment", "to", "To_compartment"),
                       delim = "_",
                       cols_remove = FALSE) |>
  mutate(Type = "calculatedMassflow") |> 
  mutate(To_compartment = str_remove(To_compartment,"\\.csv$")) |>
  select(-to)

# Add data to each row
DPMFA_calculatedMassFlow <- iD_massflows |>
  rowwise() |>
  mutate(Mass_Polymer_kt = list(readdelimF(root_folder = data_folder,
                                           FileName = iD_source,
                                           startyear = startyear,
                                           endyear = endyear,
                                           runs = runs)))

DPMFA_calculatedMassFlow <-
  DPMFA_calculatedMassFlow |> 
  separate_wider_delim(cols = To_compartment,
                       names = c("To_Compartment", "Material_Type"),
                       delim = " (",
                       too_few = "align_start",
                       too_many = "merge",
                       cols_remove = FALSE) |> 
  mutate(Material_Type = str_remove(Material_Type , "\\)")) |>
  mutate(Material_Type = case_when(Material_Type %in% c('macro', 'micro') ~ as.character(Material_Type),
                                   TRUE ~ NA_character_))

################################### save #######################################
if(env == "win"){
  data_folder <- "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Output"
} else {
  data_folder <- "~/my_biogrid/DPMFA_output/DPMFA_output"
}

# if (modeltype == "dpmfa"){
#   save(DPMFA_calculatedMassFlow, metadata,
#        file = paste0(data_folder,"/DPMFA_calculated_mass_flows_", folder_name,".RData"),
#        compress = "xz",
#        compression_level = 9)   
# } else {
#   save(DPMFA_calculatedMassFlow, metadata,
#        file = paste0(data_folder,"/PMFA_calculated_mass_flows_", folder_name,".RData"),
#        compress = "xz",
#        compression_level = 9)  
# }

########################## save data only for years of interest #######################

yoi <- c(2022, 2030, 2050)

DPMFA_years_of_interest <- DPMFA_calculatedMassFlow %>%
  mutate(Mass_Polymer_kt = map(Mass_Polymer_kt, ~ .x[, as.character(yoi), drop = FALSE]))

# Save data for years of interest 
if (modeltype == "dpmfa"){
  save(DPMFA_years_of_interest, metadata,
       file = paste0(data_folder,"/DPMFA_calculated_mass_flows_", folder_name, "_years_of_interest", ".RData"),
       compress = "xz",
       compression_level = 9)   
} else {
  save(DPMFA_years_of_interest, metadata,
       file = paste0(data_folder,"/PMFA_calculated_mass_flows_", folder_name, "_years_of_interest", ".RData"),
       compress = "xz",
       compression_level = 9)  
}

rm(list = ls())