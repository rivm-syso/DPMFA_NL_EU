PlotMeasureComp <- function(MeasuresData,
                            PlotStats= c("p25_t","p50_t","p75_t","zero"),
                            MeasOrdering = 'min',
                            ReduceExclude = 100, # exclude reduced mass flows that are positive
                            plot_theme.=plot_theme,
                            OutputData = FALSE,
                            Scenario = NA,
                            ErrorMargin = 0.75){
  
  # test <- MeasuresData
  # browser()
  PlotData =
    MeasuresData |> 
    filter(statistics == c(MeasuresData |> distinct(statistics) |> pull())[1]) |> 
    mutate(statistics = "zero",
           `Reduced MassFlow (t)` = 0,
           `Measure MassFlow (t)` =0,
           `Baseline MassFlow (t)` =0) |> rbind(MeasuresData) |> 
    ungroup() |> 
    filter(statistics %in% PlotStats,
           `Reduced MassFlow (t)` <= ReduceExclude) |> 
    mutate(`Emission reduction (%)` = -100*(`Reduced MassFlow (t)`/`Baseline MassFlow (t)`)) |>
    mutate(
      `Emission reduction (%)` = replace_na(`Emission reduction (%)`, 0)
    )
  
  PlotClothing <-
    PlotData |> 
    # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
    ggplot(aes(x = `Reduced MassFlow (t)`, 
               y = (fct_reorder(Measure, (`Reduced MassFlow (t)`), .fun = MeasOrdering)), fill = "black")) +
    # geom_point() +
    geom_line(linewidth = 2) +
    facet_wrap(scenario~To_Compartment, ncol = 6) +
    # scale_x_continuous(expand = c(0,0))+
    plot_theme. +
    labs(
      # title = paste0("Reduction environmental emissions"),
      # subtitle = "Maximum reduction environmental emissions",
      # x = "Potential Emission reduction (%)",
      y = ""
    ) +
    theme(legend.position = "none")
  
  if(is.na(Scenario)){
    if(OutputData == TRUE) return(PlotData) else return(PlotClothing)
  } else {
    PlotData <-
      PlotData |> 
      filter(scenario == Scenario)
    
    PlotClothing2 <-
      PlotData |> 
      ggplot(aes(x = `Reduced MassFlow (t)`, 
                 y = (fct_reorder(Measure, (`Reduced MassFlow (t)`), .fun = MeasOrdering)), fill = "black")) +
      # geom_point() +
      geom_line(linewidth = 2) +
      facet_wrap(~To_Compartment) +
      # scale_x_continuous(expand = c(0,0))+
      plot_theme. +
      labs(
        # title = paste0("Reduction environmental emissions"),
        # subtitle = "Maximum reduction environmental emissions",
        # x = "Potential Emission reduction (%)",
        y = ""
      ) +
      theme(legend.position = "none")
    if(OutputData == TRUE) return(PlotData) else return(PlotClothing2)
  }
  
  
}