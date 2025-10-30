
###################################

sink_compartments <- c("Agricultural soil",
                       "Natural soil",
                       "Residential soil",
                       "Road side soil",
                       "Surface water",
                       "Outdoor air",
                       "Sub-surface soil",
                       "Sea water",
                       "Landfill",
                       "Elimination",
                       "Export",
                       "Secondary material reuse",
                       "Plastic products",
                       "Export of primary plastics",
                       "Textile reuse",
                       "Footwear reuse")

source_compartments <- c( "Apparel accessories",
                          "Clothing (product sector)", "Clothing waste collection",             "Home textile waste collection",         "Household textiles (product sector)",   "Jackets and coats",                    
                          "Leggings stockings tights and socks",   "Manufacturing of clothing",            "Sweaters and midlayers"  ,             
                          "Technical textile waste collection",    "Technical textiles",                    "Textile recycling",                     "Wastewater (micro)",                   
                          "Wastewater (macro)",                   
                          "Boots"        ,                         "Closed-toed shoes"     ,                "Dresses skirts and jumpsuits"   ,       "Footwear waste collection" ,           
                          "Open-toed shoes"   ,                    "Pants and shorts"    ,                  "Shirts and blouses"     ,               "Swimwear" ,                            
                          "T-shirts" ,                             "Underwear"  )

measure_names <- c("Fringes_low",
                   "Fringes_high",
                   
                   "Wastewater_low",
                   "Wastewater_high",
                   
                   "Recycling_low",
                   "Recycling_high",
                   
                   # "Indoor_air_filter_low",
                   # "Indoor_air_filter_high",
                   
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

################################
# Read in baseline
load(paste0(data_folder, "/DPMFA_calculated_mass_flows_Baseline_NL_v3_years_of_interest.RData"))

Baseline_data <- DPMFA_years_of_interest |>
  mutate(data_source = "Baseline")

Baseline_clothing <- Baseline_data |>
  filter(From_compartment %in% source_compartments) |>
  filter(To_Compartment %in% sink_compartments)

#################################
# Read in measures output data

measure_file_paths <- list.files(data_folder)
measure_file_paths_yoi <- measure_file_paths[grep("years_of_interest", measure_file_paths)]
measure_file_paths_yoi <- measure_file_paths_yoi[grep("DPMFA_calculated_mass_flows",measure_file_paths_yoi)]
pattern <- paste(measure_names, collapse = "|")
measure_file_paths_yoi_filtered <- measure_file_paths_yoi[str_detect(measure_file_paths_yoi, pattern)]

Clothing_data_all <- Baseline_clothing

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

#################################
# Calculate statistics

Clothing_data_all <- Clothing_data_all %>%
  mutate(
    Mass_Polymer_kt = map(Mass_Polymer_kt, ~
                            .x %>%
                            as.data.frame() %>%
                            mutate(RUN = row_number())
    )
  )
### from here this part is new (10 9 2025)

AggrF <- function(x_kt){
  x_kt|> 
    pivot_longer(cols=-RUN, names_to = "Year", values_to = "Mass_Polymer_kt") |>  
    ungroup() |>
    group_by(Year) |>
    summarise(Mean_mass_t = mean(Mass_Polymer_kt)*1000,
              min_t = min(Mass_Polymer_kt)*1000,
              p5_t =quantile(Mass_Polymer_kt,probs = 0.05)*1000,
              p25_t =quantile(Mass_Polymer_kt,probs = 0.25)*1000,
              p50_t =quantile(Mass_Polymer_kt,probs = 0.50)*1000,
              p75_t =quantile(Mass_Polymer_kt,probs = 0.75)*1000,
              p95_t =quantile(Mass_Polymer_kt,probs = 0.95)*1000,
              max_t = max(Mass_Polymer_kt)*1000,
              n = n())
}

Clothing_data_statistics <-
  Clothing_data_all %>%
  ungroup() |> 
  mutate(Aggr_t =  
           map(.x = Mass_Polymer_kt, .f = AggrF)) |>    
  mutate(Mass_Polymer_kt = NULL) |> 
  unnest(Aggr_t, keep_empty = TRUE)

####################################
# save output

saveRDS(Clothing_data_statistics, file = paste0(out_date,"_ClothingDataSummary.rds"))
