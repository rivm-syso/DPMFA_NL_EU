
PrepData <- function(data_folder,
                     Baseline,
                     measure_names,
                     source_compartments,
                     sink_compartments){

load(paste0(data_folder, "DPMFA_calculated_mass_flows_", Baseline, "_years_of_interest.RData"))
Baseline_data <- DPMFA_years_of_interest |>
  mutate(data_source = "Baseline")
rm(DPMFA_years_of_interest,metadata)

message(paste("DPMFA FromCompartments removed:",Baseline_data |> 
                filter(!From_compartment %in% source_compartments) |>
                distinct(From_compartment)))
message(paste("DPMFA ToCompartments removed:",Baseline_data |> 
                filter(!To_Compartment %in% sink_compartments) |> 
                distinct(To_Compartment) ))

Baseline_data <- Baseline_data |>
  filter(From_compartment %in% source_compartments) |>
  filter(To_Compartment %in% sink_compartments)

### Read in Measures output ####
measure_file_paths <- list.files(data_folder)
measure_file_paths_yoi <- measure_file_paths[grep("years_of_interest", measure_file_paths)]
measure_file_paths_yoi <- measure_file_paths_yoi[grep("DPMFA_calculated_mass_flows",measure_file_paths_yoi)]
measure_file_paths_yoi_filtered <- measure_file_paths_yoi[str_detect(measure_file_paths_yoi, paste(measure_names, collapse = "|"))]
rm(measure_file_paths, measure_file_paths_yoi)

Clothing_data_all <- Baseline_data
rm(Baseline_data)
for(filename in measure_file_paths_yoi_filtered) {
  load(paste0(data_folder, "/", filename))
  
  measure_name <- str_remove(filename, "DPMFA_calculated_mass_flows_")
  measure_name <- str_remove(measure_name, "_years_of_interest.RData")
  measure_name <- str_replace_all(measure_name, "_", " ")
  
  Measure_data <- DPMFA_years_of_interest |>
    mutate(data_source = measure_name)
  
  Measure_clothing <- Measure_data |>
    filter(From_compartment  %in% source_compartments) |>
    filter(To_Compartment %in% sink_compartments)
  
  Clothing_data_all <- bind_rows(Clothing_data_all, Measure_clothing)
}

#### Calculate statistics ####
Clothing_data_all <- Clothing_data_all %>%
  mutate(
    Mass_Polymer_kt = map(Mass_Polymer_kt, ~
                            .x %>%
                            as.data.frame() %>%
                            mutate(RUN = row_number()) # add RUN column
    )
  ) 


Clothing_data_all <- 
  Clothing_data_all |> unnest(Mass_Polymer_kt, keep_empty = TRUE) 

return(Clothing_data_all)

}
