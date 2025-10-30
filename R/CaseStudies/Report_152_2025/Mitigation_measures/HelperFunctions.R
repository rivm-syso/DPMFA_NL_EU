

# Function that uses as input the prepare statistics output file from Calculated Mass output from DPMFA
# This function keeps micro and macro masses seperately

funMakeClothStats <- function(Clothing_data_statistics){
  
  MeasuresClothingStats <- Clothing_data_statistics |>
    filter(data_source == "Baseline") |>
    rename_with(~paste0("baseline_", .),
                -c(Type, Scale, Polymer, From_compartment, To_Compartment,Material_Type,To_compartment,iD_source , Year)
    ) |> right_join(Clothing_data_statistics ) |> filter(data_source != "Baseline") |> ungroup() |> 
    select(-baseline_data_source)
  
  # Calculate prevented emissions
  MeasuresClothingStats <- MeasuresClothingStats |>
    mutate(
      diff_Mean_mass_t = Mean_mass_t - baseline_Mean_mass_t,
      diff_min_t = min_t - baseline_min_t,
      diff_p5_t = p5_t - baseline_p5_t,
      diff_p25_t = p25_t - baseline_p25_t,
      diff_p50_t = p50_t - baseline_p50_t,
      diff_p75_t = p75_t - baseline_p75_t,
      diff_p95_t = p95_t - baseline_p95_t,
      diff_max_t = max_t - baseline_max_t
    ) 
  
  # 
  # MeasuresClothingStats |> distinct(To_Compartment) |> pull()
  soil_compartments <- c("Agricultural soil", "Natural soil", "Residential soil", "Road side soil", "Sub-surface soil")
  water_compartments <- c("Surface water", "Sea water")
  air_compartments <- c("Outdoor air")
  anthropogenic <- c("Elimination"     ,         "Export"             ,      "Landfill",  "Secondary material reuse" )
  
  MeasuresClothingStats <- 
    MeasuresClothingStats |>  mutate(
      `Environmental Compartment` = case_when(
        To_Compartment %in% soil_compartments ~ "soil",
        To_Compartment %in% water_compartments ~ "water",
        To_Compartment %in% air_compartments ~ "air",
        TRUE ~ "other"
      )
    )
  
  MeasuresClothingStats <-
    MeasuresClothingStats |> mutate(
      scenario = case_when(
        grepl("high", data_source, ignore.case = TRUE) ~ "high",
        grepl("low", data_source, ignore.case = TRUE) ~ "low",
        TRUE ~ NA_character_  # of bijvoorbeeld "other"
      ),
      Measure = str_trim(str_remove(data_source, regex(" high| low", ignore_case = TRUE)))
    )
  
  subDiff <- MeasuresClothingStats  %>%
    select(!c(starts_with("baseline"),Mean_mass_t:n)) |> 
    pivot_longer(
      cols = starts_with("diff"),
      names_to = "statistics",
      values_to = "Reduced MassFlow (t)",
      names_transform = list(statistics = ~sub("^(diff_)","", .x))
    ) #|> 
  #mutate(Calculation = "MeasureDiff")
  
  subMeasure <- MeasuresClothingStats  %>%
    select(!c(starts_with("baseline"),starts_with("diff"),n)) |> 
    pivot_longer(
      cols =  c(Mean_mass_t:max_t),
      names_to = "statistics",
      values_to = "Measure MassFlow (t)"
    ) #|> 
  #mutate(Calculation = "Measure")
  
  
  subBaseline <- MeasuresClothingStats  %>%
    select(!c(starts_with("diff"),Mean_mass_t:n,baseline_n)) |> 
    pivot_longer(
      cols = starts_with("baseline"),
      names_to = "statistics",
      values_to = "Baseline MassFlow (t)",
      names_transform = list(statistics = ~sub("^(baseline_)","", .x))
    )# |> 
  # mutate(Calculation = "Baseline")
  
  MeasuresClothingStatsL <- 
    subDiff |> 
    full_join(subMeasure) |> 
    full_join(subBaseline)
  
  return(MeasuresClothingStatsL)
}

funPlotMeasureSourceSpecific<- function(MeasuresClothingStatsL,
                                        selYear = "2050",
                                        SelMeasure = "Vacuuming",
                                        PlotStats= c("p25_t","p50_t","p75_t","zero"),
                                        MeasOrdering = 'min',
                                        selScale = "NL",
                                        SelTextSources=c( "Apparel accessories",
                                                          "Jackets and coats",                    
                                                          "Leggings stockings tights and socks",  
                                                          "Sweaters and midlayers"  ,  
                                                          "Dresses skirts and jumpsuits"   ,              
                                                          "Pants and shorts"    ,                 
                                                          "Shirts and blouses"     ,               
                                                          "Swimwear" ,                            
                                                          "T-shirts" ,                            
                                                          "Underwear"  ),
                                        ReduceExclude = 1000,
                                        EnvExclude = "other",
                                        MaterialType = "micro"){
  
  PlotClothingMicro <-
    MeasuresClothingStatsL |> 
    filter(statistics == "p25_t") |> 
    mutate(statistics = "zero",
           `Reduced MassFlow (t)` = 0,
           `Measure MassFlow (t)` =0,
           `Baseline MassFlow (t)` =0) |> rbind(MeasuresClothingStatsL) |> 
    ungroup() |> 
    filter(`Environmental Compartment`!=EnvExclude,
           Material_Type %in% MaterialType,
           Scale == selScale,
           From_compartment %in% SelTextSources,
           Measure == SelMeasure) |> 
    # select(Type, Scale, Polymer, From_compartment, `Environmental Compartment`, Year,diff_statistics,scenario,`DiffMassFlow (t)`, Measure) |>
    group_by(across(-c(Polymer,To_compartment,Material_Type, data_source, To_Compartment, `Environmental Compartment`,iD_source, `Reduced MassFlow (t)`,`Measure MassFlow (t)`,`Baseline MassFlow (t)`))) |> 
    summarise(across(`Reduced MassFlow (t)`:`Baseline MassFlow (t)`,sum)) |> 
    filter(statistics %in% PlotStats,
           Year == selYear,
           `Reduced MassFlow (t)` <= ReduceExclude) |> 
    # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
    ggplot(aes(x = `Reduced MassFlow (t)`, y = (fct_reorder(From_compartment, (`Reduced MassFlow (t)`), .fun = MeasOrdering)), fill = "black")) +
    # geom_point() +
    geom_line(linewidth = 2) +
    facet_wrap(~scenario) +
    # scale_x_continuous(expand = c(0,0))+
    plot_theme +
    labs(
      title = paste0(SelMeasure),
      # subtitle = "Maximum reduction environmental emissions",
      # x = "Emissions to environment (t)",
      y = ""
    ) +
    theme(legend.position = "none")
  return(PlotClothingMicro)
  
}


funPlotMeasureSpecific<- function(MeasuresClothingStatsL,
                                  selYear = "2050",
                                  SelMeasure = "Vacuuming",
                                  PlotStats= c("p25_t","p50_t","p75_t","zero"),
                                  MeasOrdering = 'min',
                                  selScale = "NL",
                                  SelTextSources=c( "Apparel accessories",
                                                    "Jackets and coats",                    
                                                    "Leggings stockings tights and socks",  
                                                    "Sweaters and midlayers"  ,  
                                                    "Dresses skirts and jumpsuits"   ,              
                                                    "Pants and shorts"    ,                 
                                                    "Shirts and blouses"     ,               
                                                    "Swimwear" ,                            
                                                    "T-shirts" ,                            
                                                    "Underwear"  ),
                                  ReduceExclude = 1000,
                                  EnvExclude = "other",
                                  MaterialType = "micro"){
  
  PlotClothingMicro <-
    MeasuresClothingStatsL |> 
    filter(statistics == "p25_t") |> 
    mutate(statistics = "zero",
           `Reduced MassFlow (t)` = 0,
           `Measure MassFlow (t)` =0,
           `Baseline MassFlow (t)` =0) |> rbind(MeasuresClothingStatsL) |> 
    ungroup() |> 
    filter(`Environmental Compartment`!=EnvExclude,
           Material_Type %in% MaterialType,
           Scale == selScale,
           From_compartment %in% SelTextSources,
           Measure == SelMeasure) |> 
    # select(Type, Scale, Polymer, From_compartment, `Environmental Compartment`, Year,diff_statistics,scenario,`DiffMassFlow (t)`, Measure) |>
    group_by(across(-c(Polymer,To_compartment,Material_Type, data_source, To_Compartment,iD_source, `Reduced MassFlow (t)`,`Measure MassFlow (t)`,`Baseline MassFlow (t)`))) |> 
    summarise(across(`Reduced MassFlow (t)`:`Baseline MassFlow (t)`,sum)) |> 
    filter(statistics %in% PlotStats,
           Year == selYear,
           `Reduced MassFlow (t)` <= ReduceExclude) |> 
    # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
    ggplot(aes(x = `Reduced MassFlow (t)`, y = (fct_reorder(From_compartment, (`Reduced MassFlow (t)`), .fun = MeasOrdering)), fill = "black")) +
    # geom_point() +
    geom_line(linewidth = 2) +
    facet_wrap(scenario~`Environmental Compartment`) +
    # scale_x_continuous(expand = c(0,0))+
    plot_theme +
    labs(
      title = paste0(SelMeasure),
      # subtitle = "Maximum reduction environmental emissions",
      # x = "Emissions to environment (t)",
      y = ""
    ) +
    theme(legend.position = "none")
  return(PlotClothingMicro)
  
}

funPlotMeasureSourceSpecificPercent <- function(MeasuresClothingStatsL,
                                        selYear = "2050",
                                        SelMeasure = "Vacuuming",
                                        PlotStats= c("p25_t","p50_t","p75_t","zero"),
                                        MeasOrdering = 'min',
                                        selScale = "NL",
                                        SelTextSources=c( "Apparel accessories",
                                                          "Jackets and coats",                    
                                                          "Leggings stockings tights and socks",  
                                                          "Sweaters and midlayers"  ,  
                                                          "Dresses skirts and jumpsuits"   ,              
                                                          "Pants and shorts"    ,                 
                                                          "Shirts and blouses"     ,               
                                                          "Swimwear" ,                            
                                                          "T-shirts" ,                            
                                                          "Underwear"  ),
                                        ReduceExclude = 1000,
                                        EnvExclude = "other",
                                        MaterialType = "micro"){
  
  PlotClothingMicro <-
    MeasuresClothingStatsL |> 
    filter(statistics == "p25_t") |> 
    mutate(statistics = "zero",
           `Reduced MassFlow (t)` = 0,
           `Measure MassFlow (t)` =0,
           `Baseline MassFlow (t)` =0) |> rbind(MeasuresClothingStatsL) |> 
    ungroup() |> 
    filter(`Environmental Compartment`!=EnvExclude,
           Material_Type %in% MaterialType,
           Scale == selScale,
           From_compartment %in% SelTextSources,
           Measure == SelMeasure) |> 
    # select(Type, Scale, Polymer, From_compartment, `Environmental Compartment`, Year,diff_statistics,scenario,`DiffMassFlow (t)`, Measure) |>
    group_by(across(-c(Polymer,To_compartment,Material_Type, data_source, To_Compartment, `Environmental Compartment`,iD_source, `Reduced MassFlow (t)`,`Measure MassFlow (t)`,`Baseline MassFlow (t)`))) |> 
    summarise(across(`Reduced MassFlow (t)`:`Baseline MassFlow (t)`,sum)) |> 
    filter(statistics %in% PlotStats,
           Year == selYear,
           `Reduced MassFlow (t)` <= ReduceExclude) |> 
    mutate(`Emission reduction (%)` = -100*(`Reduced MassFlow (t)`/`Baseline MassFlow (t)`)) |>
    mutate(
      `Emission reduction (%)` = replace_na(`Emission reduction (%)`, 0)
    ) |> 
    # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
    ggplot(aes(x = `Emission reduction (%)`, y = (fct_reorder(From_compartment, (`Emission reduction (%)`), .fun = MeasOrdering)), fill = "black")) +
    # geom_point() +
    geom_line(linewidth = 2) +
    facet_wrap(~scenario) +
    # scale_x_continuous(expand = c(0,0))+
    plot_theme +
    labs(
      title = paste0(SelMeasure),
      # subtitle = "Maximum reduction environmental emissions",
      # x = "Emissions to environment (t)",
      y = ""
    ) +
    theme(legend.position = "none")
  return(PlotClothingMicro)
  
}


funPlotMeasureSpecificPercent <- function(MeasuresClothingStatsL,
                                  selYear = "2050",
                                  SelMeasure = "Vacuuming",
                                  PlotStats= c("p25_t","p50_t","p75_t","zero"),
                                  MeasOrdering = 'min',
                                  selScale = "NL",
                                  SelTextSources=c( "Apparel accessories",
                                                    "Jackets and coats",                    
                                                    "Leggings stockings tights and socks",  
                                                    "Sweaters and midlayers"  ,  
                                                    "Dresses skirts and jumpsuits"   ,              
                                                    "Pants and shorts"    ,                 
                                                    "Shirts and blouses"     ,               
                                                    "Swimwear" ,                            
                                                    "T-shirts" ,                            
                                                    "Underwear"  ),
                                  ReduceExclude = 1000,
                                  EnvExclude = "other",
                                  MaterialType = "micro"){
  
  PlotClothingMicro <-
    MeasuresClothingStatsL |> 
    filter(statistics == "p25_t") |> 
    mutate(statistics = "zero",
           `Reduced MassFlow (t)` = 0,
           `Measure MassFlow (t)` =0,
           `Baseline MassFlow (t)` =0) |> rbind(MeasuresClothingStatsL) |> 
    ungroup() |> 
    filter(`Environmental Compartment`!=EnvExclude,
           Material_Type %in% MaterialType,
           Scale == selScale,
           From_compartment %in% SelTextSources,
           Measure == SelMeasure) |> 
    # select(Type, Scale, Polymer, From_compartment, `Environmental Compartment`, Year,diff_statistics,scenario,`DiffMassFlow (t)`, Measure) |>
    group_by(across(-c(Polymer,To_compartment,Material_Type, data_source, To_Compartment,iD_source, `Reduced MassFlow (t)`,`Measure MassFlow (t)`,`Baseline MassFlow (t)`))) |> 
    summarise(across(`Reduced MassFlow (t)`:`Baseline MassFlow (t)`,sum)) |> 
    filter(statistics %in% PlotStats,
           Year == selYear,
           `Reduced MassFlow (t)` <= ReduceExclude) |> 
    mutate(`Emission reduction (%)` = -100*(`Reduced MassFlow (t)`/`Baseline MassFlow (t)`)) |>
    mutate(
      `Emission reduction (%)` = replace_na(`Emission reduction (%)`, 0)
    ) |> 
    # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
    ggplot(aes(x = `Emission reduction (%)`, y = (fct_reorder(From_compartment, (`Emission reduction (%)`), .fun = MeasOrdering)), fill = "black")) +
    # geom_point() +
    geom_line(linewidth = 2) +
    facet_wrap(scenario~`Environmental Compartment`) +
    # scale_x_continuous(expand = c(0,0))+
    plot_theme +
    labs(
      title = paste0(SelMeasure),
      # subtitle = "Maximum reduction environmental emissions",
      # x = "Emissions to environment (t)",
      y = ""
    ) +
    theme(legend.position = "none")
  return(PlotClothingMicro)
  
}

PlottingMeasureOverview <- function(MeasuresClothingStatsL,
                                    selYear = "2050",
                                    PlotStats= c("p25_t","p50_t","p75_t","zero"),
                                    MeasOrdering = 'min',
                                    selScale = "NL",
                                    SelTextSources=c( "Apparel accessories",
                                                      "Jackets and coats",                    
                                                      "Leggings stockings tights and socks",  
                                                      "Sweaters and midlayers"  ,  
                                                      "Dresses skirts and jumpsuits"   ,              
                                                      "Pants and shorts"    ,                 
                                                      "Shirts and blouses"     ,               
                                                      "Swimwear" ,                            
                                                      "T-shirts" ,                            
                                                      "Underwear"  ),
                                    ReduceExclude = 1000,
                                    EnvExclude = "other",
                                    MaterialType = "micro"){
  
  PlotClothingMicro <-
    MeasuresClothingStatsL |> 
    filter(statistics == "p25_t") |> 
    mutate(statistics = "zero",
           `Reduced MassFlow (t)` = 0,
           `Measure MassFlow (t)` =0,
           `Baseline MassFlow (t)` =0) |> rbind(MeasuresClothingStatsL) |> 
    ungroup() |> 
    filter(`Environmental Compartment`!=EnvExclude,
           Material_Type %in% MaterialType,
           Scale == selScale,
           From_compartment %in% SelTextSources) |> 
    # select(Type, Scale, Polymer, From_compartment, `Environmental Compartment`, Year,diff_statistics,scenario,`DiffMassFlow (t)`, Measure) |>
    group_by(across(-c(Polymer,To_compartment,Material_Type, data_source, To_Compartment, From_compartment, `Environmental Compartment`,iD_source, `Reduced MassFlow (t)`,`Measure MassFlow (t)`,`Baseline MassFlow (t)`))) |> 
    summarise(across(`Reduced MassFlow (t)`:`Baseline MassFlow (t)`,sum)) |> 
    filter(statistics %in% PlotStats,
           Year == selYear,
           `Reduced MassFlow (t)` <= ReduceExclude) |> 
    # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
    ggplot(aes(x = `Reduced MassFlow (t)`, y = (fct_reorder(Measure, (`Reduced MassFlow (t)`), .fun = MeasOrdering)), fill = "black")) +
    # geom_point() +
    geom_line(linewidth = 2) +
    facet_wrap(~scenario) +
    # scale_x_continuous(expand = c(0,0))+
    plot_theme +
    labs(
      # title = paste0("Reduction environmental emissions"),
      # subtitle = "Maximum reduction environmental emissions",
      # x = "Emissions to environment (t)",
      y = ""
    ) +
    theme(legend.position = "none")
  return(PlotClothingMicro)
  
}

PlottingMeasureOverviewPercent <- function(MeasuresClothingStatsL,
                                    selYear = "2050",
                                    PlotStats= c("p25_t","p50_t","p75_t","zero"),
                                    MeasOrdering = 'min',
                                    selScale = "NL",
                                    SelTextSources=c( "Apparel accessories",
                                                      "Jackets and coats",                    
                                                      "Leggings stockings tights and socks",  
                                                      "Sweaters and midlayers"  ,  
                                                      "Dresses skirts and jumpsuits"   ,              
                                                      "Pants and shorts"    ,                 
                                                      "Shirts and blouses"     ,               
                                                      "Swimwear" ,                            
                                                      "T-shirts" ,                            
                                                      "Underwear"  ),
                                    EnvExclude = "other",
                                    MaterialType = "micro",
                                    ReduceExclude = 0){ # exclude reduced mass flows that are positive
  
  PlotClothingMicro <-
    MeasuresClothingStatsL |> 
    filter(statistics == "p25_t") |> 
    mutate(statistics = "zero",
           `Reduced MassFlow (t)` = 0,
           `Measure MassFlow (t)` =0,
           `Baseline MassFlow (t)` =0) |> rbind(MeasuresClothingStatsL) |> 
    ungroup() |> 
    filter(`Environmental Compartment`!=EnvExclude,
           Material_Type == MaterialType,
           Scale == Scale,
           From_compartment %in% SelTextSources) |> 
    # select(Type, Scale, Polymer, From_compartment, `Environmental Compartment`, Year,diff_statistics,scenario,`DiffMassFlow (t)`, Measure) |>
    group_by(across(-c(Polymer,To_compartment, data_source, To_Compartment, From_compartment, `Environmental Compartment`,iD_source, `Reduced MassFlow (t)`,`Measure MassFlow (t)`,`Baseline MassFlow (t)`))) |> 
    summarise(across(`Reduced MassFlow (t)`:`Baseline MassFlow (t)`,sum)) |> 
    filter(statistics %in% PlotStats,
           Year ==  selYear,
           Scale == selScale,
           `Reduced MassFlow (t)` <= ReduceExclude) |> 
    mutate(`Emission reduction (%)` = -100*(`Reduced MassFlow (t)`/`Baseline MassFlow (t)`)) |>
    mutate(
      `Emission reduction (%)` = replace_na(`Emission reduction (%)`, 0)
    ) |> 
    # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
    ggplot(aes(x = `Emission reduction (%)`, 
               y = (fct_reorder(Measure, (`Emission reduction (%)`), .fun = MeasOrdering)), fill = "black")) +
    # geom_point() +
    geom_line(linewidth = 2) +
    facet_wrap(~scenario) +
    # scale_x_continuous(expand = c(0,0))+
    plot_theme +
    labs(
      # title = paste0("Reduction environmental emissions"),
      # subtitle = "Maximum reduction environmental emissions",
      # x = "Potential Emission reduction (%)",
      y = ""
    ) +
    theme(legend.position = "none")
  return(PlotClothingMicro)
  
}


######## OBSOLETE #############


# Function that uses as input the prepare statistics output file from Calculated Mass output from DPMFA
# This function is specific for summing up the micro and macro masses before further analysis

# funMakeClothStatsMat <- function(Clothing_data_statistics){
#   Clothing_data_statistics <-
#     Clothing_data_statistics |> 
#     ungroup() |> 
#     group_by(Type, Scale, Polymer, From_compartment, To_Compartment, data_source, Year) |> 
#     summarise(
#       across(Mean_mass_t:n, sum)
#     )
#   
#   MeasuresClothingStats <- Clothing_data_statistics |> 
#     filter(data_source == "Baseline") |>
#     rename_with(~paste0("baseline_", .),
#                 -c(Type, Scale, Polymer, From_compartment, To_Compartment, Year)
#     ) |> right_join(Clothing_data_statistics ) |> filter(data_source != "Baseline") |> ungroup() |> 
#     select(-baseline_data_source)
#   
#   # Calculate prevented emissions
#   MeasuresClothingStats <- MeasuresClothingStats |>
#     mutate(
#       diff_Mean_mass_t = Mean_mass_t - baseline_Mean_mass_t,
#       diff_min_t = min_t - baseline_min_t,
#       diff_p5_t = p5_t - baseline_p5_t,
#       diff_p25_t = p25_t - baseline_p25_t,
#       diff_p50_t = p50_t - baseline_p50_t,
#       diff_p75_t = p75_t - baseline_p75_t,
#       diff_p95_t = p95_t - baseline_p95_t,
#       diff_max_t = max_t - baseline_max_t
#     ) 
#   
#   
#   # MeasuresClothingStats |> distinct(To_Compartment) |> pull()
#   soil_compartments <- c("Agricultural soil", "Natural soil", "Residential soil", "Road side soil", "Sub-surface soil")
#   water_compartments <- c("Surface water", "Sea water")
#   air_compartments <- c("Outdoor air")
#   anthropogenic <- c("Elimination"     ,         "Export"             ,      "Landfill",  "Secondary material reuse" )
#   
#   MeasuresClothingStats <- 
#     MeasuresClothingStats |>  mutate(
#       `Environmental Compartment` = case_when(
#         To_Compartment %in% soil_compartments ~ "soil",
#         To_Compartment %in% water_compartments ~ "water",
#         To_Compartment %in% air_compartments ~ "air",
#         .default = "other"
#       )
#     )
#   
#   MeasuresClothingStats <-
#     MeasuresClothingStats |> mutate(
#       scenario = case_when(
#         grepl("high", data_source, ignore.case = TRUE) ~ "high",
#         grepl("low", data_source, ignore.case = TRUE) ~ "low",
#         TRUE ~ NA_character_  # of bijvoorbeeld "other"
#       ),
#       Measure = str_trim(str_remove(data_source, regex(" high| low", ignore_case = TRUE)))
#     )
#   
#   subDiff <- MeasuresClothingStats  %>%
#     select(!c(starts_with("baseline"),Mean_mass_t:n)) |> 
#     pivot_longer(
#       cols = starts_with("diff"),
#       names_to = "statistics",
#       values_to = "Reduced MassFlow (t)",
#       names_transform = list(statistics = ~sub("^(diff_)","", .x))
#     ) #|> 
#   #mutate(Calculation = "MeasureDiff")
#   
#   subMeasure <- MeasuresClothingStats  %>%
#     select(!c(starts_with("baseline"),starts_with("diff"),n)) |> 
#     pivot_longer(
#       cols =  c(Mean_mass_t:max_t),
#       names_to = "statistics",
#       values_to = "Measure MassFlow (t)"
#     ) #|> 
#   #mutate(Calculation = "Measure")
#   
#   
#   subBaseline <- MeasuresClothingStats  %>%
#     select(!c(starts_with("diff"),Mean_mass_t:n,baseline_n)) |> 
#     pivot_longer(
#       cols = starts_with("baseline"),
#       names_to = "statistics",
#       values_to = "Baseline MassFlow (t)",
#       names_transform = list(statistics = ~sub("^(baseline_)","", .x))
#     )# |> 
#   # mutate(Calculation = "Baseline")
#   
#   MeasuresClothingStatsL <- 
#     subDiff |> 
#     full_join(subMeasure) |> 
#     full_join(subBaseline)
#   
#   return(MeasuresClothingStatsL)
# }
# funPlotMeasureOverview <- function(MeasuresClothingStatsM,
#                                    Scale = "NL",
#                                    PlotStats = c("p25_t","p50_t","p75_t","zero"),
#                                    Year = "2050",
#                                    SourceAggr = "Clothing (product sector)",
#                                    MeasOrdering = 'median'){
#   Plot <-
#     MeasuresClothingStatsM |> 
#     filter(statistics == "p25_t") |> 
#     mutate(statistics = "zero",
#            `Reduced MassFlow (t)` = 0,
#            `Measure MassFlow (t)` =0,
#            `Baseline MassFlow (t)` =0) |> rbind(MeasuresClothingStatsM) |> 
#     ungroup() |> 
#     filter(`Environmental Compartment`!="other",
#            Scale == Scale) |> 
#     
#     # select(Type, Scale, Polymer, From_compartment, `Environmental Compartment`, Year,diff_statistics,scenario,`DiffMassFlow (t)`, Measure) |>
#     group_by(across(-c(Polymer,To_Compartment,`Environmental Compartment`, `Reduced MassFlow (t)`,`Measure MassFlow (t)`,`Baseline MassFlow (t)`))) |> 
#     summarise(across(`Reduced MassFlow (t)`:`Baseline MassFlow (t)`,sum)) |> 
#     filter(statistics %in% PlotStats,
#            Year == Year,
#            From_compartment == SourceAggr) |> 
#     # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
#     ggplot(aes(x = `Reduced MassFlow (t)`, y = (fct_reorder(Measure, (`Reduced MassFlow (t)`), .fun = MeasOrdering)), fill = "black")) +
#     geom_line(linewidth = 2) + 
#     facet_wrap(~scenario) +
#     # scale_x_continuous(expand = c(0,0))+
#     plot_theme +
#     labs(
#       # title = paste0("Reduction environmental emissions"),
#       # subtitle = "Maximum reduction environmental emissions",
#       # x = "Emissions to environment (t)",
#       y = ""
#     ) +
#     theme(legend.position = "none")
#   return(Plot)
# }
