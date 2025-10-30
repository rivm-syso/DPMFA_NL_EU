
#env = "win"
env = "lin"

if(env == "win"){
  
} else {
  data_path <- "~/my_biogrid/DPMFA_output/"
}

batch_scripts_path <- file.path("Output_Analysis/Batch_load_data_scripts")
dir.create(batch_scripts_path, showWarnings = FALSE)

measure_names <- c("Fringes_low",
                   "Fringes_high",
                   
                   "Wastewater_low",
                   "Wastewater_high",
                   
                   "Recycling_low",
                   "Recycling_high",
                   
                   "Indoor_air_filter_low",
                   "Indoor_air_filter_high",
                   
                   "Prewashing_low",
                   "Prewashing_high",
                   
                   "Replace_low",
                   "Replace_high",
                   
                   "Washer_dryer_filters_low",
                   "Washer_dryer_filters_high",
                   
                   "Clean_dryer_filter_low",
                   "Clean_dryer_filter_high",
                   
                   "External_filter_low",
                   "External_filter_high",
                   
                   "Vacuuming_low",
                   "Vacuuming_high",
                   
                   "Production_method_finishes_low",
                   "Production_method_finishes_high",
                   
                   "Delicate_washing_cycle_low",
                   "Delicate_washing_cycle_high",
                   
                   "Clothesline_instead_of_dryer_low",
                   "Clothesline_instead_of_dryer_high",
                   
                   "Lifetime_low",
                   "Lifetime_high")

for (name in measure_names) {
  # Lees het originele script in als tekst
  script_lines <- readLines("Output_Analysis/Load_calculated_mass_flows_measures.R")
  
  script_lines <- sub(
    pattern = 'folder_name\\s*<-\\s*["\'].*["\']',
    replacement = paste0('folder_name <- "', name, '"'),
    x = script_lines
  )
  
  # Maak de bestandsnaam voor het nieuwe script
  new_script_name <- paste0("Load_calculated_mass_flows_", name, ".R")
  new_script_path <- file.path(batch_scripts_path, new_script_name)
  
  # Schrijf het aangepaste script weg
  writeLines(script_lines, new_script_path)
}
