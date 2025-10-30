# Readin different DPMFA output and place in same object
library(tidyverse)

#### selection ####
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
                          "Clothing waste collection",             "Home textile waste collection",         "Household textiles (product sector)",   "Jackets and coats",                    
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

Clothing_data_all <- PrepData(data_folder,
                     Baseline,
                     measure_names,
                     source_compartments,
                     sink_compartments)

#### Read in Baseline ####
load(paste0(data_folder, "/DPMFA_calculated_mass_flows_", Baseline, "years_of_interest.RData"))
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

rm(sink_compartments, source_compartments, measure_names)

#### save output ####
saveRDS(Clothing_data_all, 
        file = paste0("/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Output/",
                      out_date,"_ClothingDataAll.rds"))



