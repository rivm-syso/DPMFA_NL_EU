PlotMeasureOverviewPercent <- function(MeasuresData,
                                       PlotStats= c("p25_t","p50_t","p75_t","zero"),
                                       MeasOrdering = 'min', # for order of bars in the plot
                                       ReduceExclude = 0, # for removing negative or positive data points
                                       plot_theme.=plot_theme, # adjust theme
                                       OutputData = FALSE, # output data instead of plot
                                       Scenario = NA, # output only for specific scenario (low or high)
                                       ErrorMargin = 0.75){ # plot grey area over error margin for this analysis
  
  # test <- MeasuresData
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
  
  
  
  
  if(is.na(Scenario)){
    
    PlotClothing =
      PlotData |> 
      # mutate(Measure = fct_reorder(Measure, `Reduced MassFlow (t)`, .fun = 'min')) |> 
      ggplot(aes(x = `Emission reduction (%)`, 
                 y = (fct_reorder(Measure, (`Emission reduction (%)`), .fun = MeasOrdering)), fill = "black")) +
      # geom_point() +
      geom_line(linewidth = 2) +
      facet_wrap(~scenario) +
      # scale_x_continuous(expand = c(0,0))+
      plot_theme. +
      labs(
        # title = paste0("Reduction environmental emissions"),
        # subtitle = "Maximum reduction environmental emissions",
        # x = "Potential Emission reduction (%)",
        y = ""
      ) +
      theme(legend.position = "none") +
      annotate(
        "rect",
        xmin = -ErrorMargin, xmax = ErrorMargin,     # X range for overlay
        ymin = -Inf, ymax = Inf, # Cover whole y range
        alpha = 0.2,             # Transparency (0 = fully transparent, 1 = solid)
        fill = "blue"            # Color of the overlay
      )
    
    if(OutputData == TRUE) return(PlotData) else return(PlotClothing)
    
  } else {
    PlotData <-
      PlotData |> 
      filter(scenario == Scenario)
    
    PlotClothing2 <-
      PlotData |> 
      ggplot(aes(x = `Emission reduction (%)`, 
                 y = (fct_reorder(Measure, (`Emission reduction (%)`), .fun = MeasOrdering)), fill = "black")) +
      # geom_point() +
      geom_line(linewidth = 2) +
      # facet_wrap(~scenario) +
      # scale_x_continuous(expand = c(0,0))+
      plot_theme. +
      labs(
        # title = paste0("Reduction environmental emissions"),
        # subtitle = "Maximum reduction environmental emissions",
        # x = "Potential Emission reduction (%)",
        y = ""
      ) +
      theme(legend.position = "none") +
      annotate(
        "rect",
        xmin = -ErrorMargin, xmax = ErrorMargin,     # X range for overlay
        ymin = -Inf, ymax = Inf, # Cover whole y range
        alpha = 0.2,             # Transparency (0 = fully transparent, 1 = solid)
        fill = "grey"            # Color of the overlay
      )
    if(OutputData == TRUE) return(PlotData) else return(PlotClothing2)
  }
  
  
}