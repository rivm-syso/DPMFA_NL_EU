#### Calculation of effect ####


#### Plot main overview ####



#### Plot per compartment ####




#### OLD ####

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

