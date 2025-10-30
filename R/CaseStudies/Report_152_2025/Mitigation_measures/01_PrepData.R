library(tidyverse)

### Tag for naming output file
out_date <- "20251017"

sapply(list.files("Mitigation_measures/functions",pattern = "\\.R$", full.names = TRUE),
       FUN = source)

plot_theme = theme(
  axis.title.x = element_text(size = 16),
  axis.text = element_text(size = 14), 
  plot.title = element_text(hjust = 0.5, vjust = 1),
  axis.title.y = element_text(size = 16),
  plot.background = element_rect(fill = 'white'),
  panel.background = element_rect(fill = 'white'),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  axis.line = element_line(color='black'),
  plot.margin = margin(1.5, 1, 1, 1, "cm")
  #panel.grid.major = element_line(colour = "grey",size=0.25)
)

### selection 
Sink_compartments <- c("Agricultural soil",
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

Source_compartments <- c( "Apparel accessories",
                          "Clothing waste collection",
                          "Home textile waste collection", 
                          "Household textiles (product sector)", 
                          "Jackets and coats",                    
                          "Leggings stockings tights and socks", 
                          "Manufacturing of clothing",       
                          "Sweaters and midlayers"  ,             
                          "Technical textile waste collection",  
                          "Technical textiles",                  
                          "Textile recycling",                  
                          "Wastewater (micro)",                   
                          "Wastewater (macro)",                   
                          "Boots"        ,                  
                          "Closed-toed shoes"     ,         
                          "Dresses skirts and jumpsuits"   ,  
                          "Footwear waste collection" ,
                          "Open-toed shoes"   ,           
                          "Pants and shorts"    ,       
                          "Shirts and blouses"     ,    
                          "Swimwear" ,                            
                          "T-shirts" ,                 
                          "Underwear"  )

Measure_names <- c("Fringes_low",
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

Clothing_data_all <- PrepData(data_folder = 
                                "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Output/",
                              Baseline = "Baseline_NL_v3",
                              measure_names = Measure_names,
                              source_compartments = Source_compartments,
                              sink_compartments = Sink_compartments)

saveRDS(Clothing_data_all, 
        file = paste0("/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Output/",
                      out_date,"_ClothingDataAll.rds"))