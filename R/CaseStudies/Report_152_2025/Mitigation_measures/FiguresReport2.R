library(tidyverse)
library(ggplot2)

#### SHOES ####

ShoesStatsOverview <- FunPrepStatsALL(Clothing_data_all = Clothing_data_all, # Full tibble/data frame with DPMFA output from PrepData
                                         SelectionSources = ShoesSources, # The Sources in the data frame to consider (e.g. clothingsource only or also Footwear)
                                         SelectionEnvSinks = c("air","water","soil"), # Options are "water, air, soil and none"
                                         SelectYear = 2050)


Figure6 <- 
  PlotMeasureOverviewPercent(
    MeasuresData = funCalcClothOverviewEffect(ShoesStatsOverview),
    ReduceExclude = 100,
    MeasOrdering = 'max',
    PlotStats = c("Mean_mass_t", "zero"),
    OutputData = FALSE,
    Scenario = "high",
    ErrorMargin = 1
  )

Figure6Data <- 
  PlotMeasureOverviewPercent(
    MeasuresData = funCalcClothOverviewEffect(ShoesStatsOverview),
    ReduceExclude = 100,
    MeasOrdering = 'max',
    PlotStats = c("Mean_mass_t", "zero"),
    OutputData = TRUE,
    Scenario = "high",
    ErrorMargin = 1
  )
ggsave(
  paste0(Analysistag, "Figure6_ShoesEmissionReductionPercentHigh.png"),
  plot = Figure6,
  path = figure_folder,
  width = 10,
  height = 6
)

Figure8 <-
  PlotMeasureOverviewPercent(
    MeasuresData = funCalcClothOverviewEffect(ShoesStatsOverview),
    ReduceExclude = 100,
    MeasOrdering = 'max',
    PlotStats = c("p25_t","p75_t","zero"),
    OutputData = FALSE,
    Scenario = "low",
    ErrorMargin = 1
  )
Figure8Data <-
  PlotMeasureOverviewPercent(
    MeasuresData = funCalcClothOverviewEffect(ShoesStatsOverview),
    ReduceExclude = 100,
    MeasOrdering = 'max',
    PlotStats = c("p25_t","p75_t"),
    OutputData = TRUE,
    Scenario = "low",
    ErrorMargin = 1
  )
ggsave(
  paste0(Analysistag, "Figure8_ShoesEmissionReductionPercentLow.png"),
  plot = Figure8,
  path = figure_folder,
  width = 10,
  height = 6
)


Figure7 <-
  PlotMeasureOverview(
    MeasuresData = funCalcClothOverviewEffect(ShoesStatsOverview),
    ReduceExclude = -15,
    MeasOrdering = 'min',
    PlotStats = c("p25_t","p75_t"),
    OutputData = FALSE,
    Scenario = "high"
  )

Figure7data <- 
  PlotMeasureOverview(
    MeasuresData = funCalcClothOverviewEffect(ShoesStatsOverview),
    ReduceExclude = -15,
    MeasOrdering = 'min',
    PlotStats = c("p25_t","p75_t"),
    OutputData = TRUE,
    Scenario = "high"
  )

Figure7data |> ungroup() |> 
  group_by(scenario,statistics) |> 
  summarise(Reduced = sum(`Reduced MassFlow (t)`))

ggsave(
  paste0(Analysistag, "Figure7_ShoesEmissionReductionPercent.png"),
  plot = Figure7,
  path = figure_folder,
  width = 13,
  height = 6
)

Figure9DataIn <- funCalcClothOverviewEffect(ShoesStatsOverview) |> 
  filter(Measure %in% c("Production method finishes",
                        "Replace",
                        "External filter",
                        "Lifetime"))

Figure9 <-
  PlotMeasureOverview(
    MeasuresData = Figure9DataIn,
    ReduceExclude = 0,
    MeasOrdering = 'max',
    PlotStats = c("p25_t","p75_t"),
    OutputData = FALSE,
    Scenario = "low"
  )
Figure9Data <-
  PlotMeasureOverview(
    MeasuresData = Figure9DataIn,
    ReduceExclude = 0,
    MeasOrdering = 'max',
    PlotStats = c("p25_t","p75_t"),
    OutputData = TRUE,
    Scenario = "low"
  )
Figure9Data |> ungroup() |> 
  group_by(scenario,statistics) |> 
  summarise(Reduced = sum(`Reduced MassFlow (t)`))

ggsave(
  paste0(Analysistag, "Figure9_ShoesEmissionReductionPercentLow.png"),
  plot = Figure9,
  path = figure_folder,
  width = 10,
  height = 4
)