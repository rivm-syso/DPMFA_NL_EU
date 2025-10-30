library(tidyverse)
library(ggplot2)
library(openxlsx)

# Create a theme for the plots
plot_theme = theme(
  axis.title.x = element_text(size = 16),
  axis.text = element_text(size = 14),
  axis.title.y = element_text(size = 16),
  plot.background = element_rect(fill = 'white'),
  panel.background = element_rect(fill = 'white'),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  axis.line = element_line(color = 'black'),
  plot.margin = margin(1, 4, 2, 2, "cm")
  #panel.grid.major = element_line(colour = "grey",size=0.25)
)

plot_theme2 = theme(
  axis.title.x = element_text(size = 14),
  axis.text = element_text(size = 10),
  axis.title.y = element_text(size = 14),
  plot.background = element_rect(fill = 'white'),
  panel.background = element_rect(fill = 'white'),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  axis.line = element_line(color = 'black'),
  plot.margin = margin(2, 4, 2, 2, "cm")
)

# figure_folder <- "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Figures/Mitigation_measures"
# # figure_folder <- "Figures"
# Analysistag <- "20250922"
# Clothing_data_statistics <- readRDS("20250922_ClothingDataSummary.rds")
source("Mitigation_measures/HelperFunctions.R")


MeasuresClothingStatsL <- funMakeClothStats(Clothing_data_statistics)
MeasuresClothingStatsL <-
  MeasuresClothingStatsL |>
  mutate(Material_Type = replace_na(Material_Type, "other")) |>
  filter(Measure != "Indoor air filter")

rm(Clothing_data_statistics)

NotSource <- c(
  "Clothing (product sector)",
  "Clothing waste collection",
  "Home textile waste collection",
  "Household textiles (product sector)",
  "Manufacturing of clothing",
  "Technical textile waste collection",
  "Technical textiles",
  "Textile recycling",
  "Wastewater (micro)",
  "Wastewater (macro)",
  "Footwear waste collection"
)


# ProductSector <- "Clothing (product sector)" # Don't use!
ClothingSources <- c(
  "Apparel accessories",
  "Jackets and coats",
  "Leggings stockings tights and socks",
  "Sweaters and midlayers"  ,
  "Dresses skirts and jumpsuits"   ,
  "Pants and shorts"    ,
  "Shirts and blouses"     ,
  "Swimwear" ,
  "T-shirts" ,
  "Underwear"
)

ShoesSources <- c("Open-toed shoes"   , "Boots"        , "Closed-toed shoes")



# SelMeasure = Measures[7]
# PlotStats = c("p25_t","p50_t","p75_t","zero")
# Year = "2050"

# MeasuresClothingStatsM,
# SelMeasure = "Vacuuming"
# Scale = "NL"
# MeasOrdering = 'min'


### CLOTHING
######## Clothing figure 4 ###################
Figure4 <- PlottingMeasureOverviewPercent(
  MeasuresClothingStatsL = MeasuresClothingStatsL,
  SelTextSources = ClothingSources,
  ReduceExclude = 0,
  MeasOrdering = 'max',
  PlotStats = c("p25_t", "p50_t", "p75_t", "zero"),
  MaterialType = c("micro", "macro")
)
ggsave(
  paste0(Analysistag, "Figure4_ClothingEmissionReductionPercent.png"),
  plot = Figure4,
  path = figure_folder,
  width = 12,
  height = 6
)

Figure4b <- PlottingMeasureOverviewPercent(
  MeasuresClothingStatsL = MeasuresClothingStatsL,
  SelTextSources = ClothingSources,
  ReduceExclude = 0,
  MeasOrdering = 'max',
  PlotStats = c("p25_t", "p50_t", "p75_t", "zero"),
  MaterialType = c("micro")
)
ggsave(
  paste0(
    Analysistag,
    "Figure4b_ClothingEmissionReductionPercent_micro.png"
  ),
  plot = Figure4b,
  path = figure_folder,
  width = 12,
  height = 6
)
######## Clothing figure 5 ###################
Figure5 <- PlottingMeasureOverview(
  MeasuresClothingStatsL = MeasuresClothingStatsL,
  SelTextSources = ClothingSources,
  ReduceExclude = 0,
  MeasOrdering = 'min',
  PlotStats = c("p25_t", "p50_t", "p75_t"),
  MaterialType = c("micro", "macro")
)

ggsave(
  paste0(Analysistag, "Figure5_ClothingEmissionReduction.png"),
  plot = Figure5,
  path = figure_folder,
  width = 12,
  height = 6
)
Figure5b <- PlottingMeasureOverview(
  MeasuresClothingStatsL = MeasuresClothingStatsL,
  SelTextSources = ClothingSources,
  ReduceExclude = 0,
  MeasOrdering = 'min',
  PlotStats = c("p25_t", "p50_t", "p75_t"),
  MaterialType = c("micro")
)

ggsave(
  paste0(Analysistag, "Figure5b_ClothingEmissionReduction_micro.png"),
  plot = Figure5b,
  path = figure_folder,
  width = 12,
  height = 6
)


######### fig 8 SHOES ##############

ShoesReductionPercentage <- PlottingMeasureOverviewPercent(
  MeasuresClothingStatsL = MeasuresClothingStatsL,
  SelTextSources =
    ShoesSources,
  ReduceExclude = 0,
  MeasOrdering = 'max',
  PlotStats = c("p25_t", "p50_t", "p75_t", "zero"),
  MaterialType = c("micro", "macro")
)
ggsave(
  paste0(Analysistag, "Figure8_ShoesReductionPercentage.png"),
  plot = ShoesReductionPercentage,
  path = figure_folder,
  width = 12,
  height = 6
)

######### fig 9 SHOES ##############
ShoesReduction <- PlottingMeasureOverview(
  MeasuresClothingStatsL = MeasuresClothingStatsL,
  SelTextSources = ShoesSources,
  ReduceExclude = 0,
  MeasOrdering = 'min',
  PlotStats = c("p25_t", "p50_t", "p75_t"),
  MaterialType = c("micro", "macro")
)
ggsave(
  paste0(Analysistag, "Figure9_ShoesReduction.png"),
  plot = ShoesReduction,
  path = figure_folder,
  width = 12,
  height = 6
)




### Product sector ERROR!
# NO don't use product sector from calculate mass flows!!!!
######## Product sector percent ###################
# FigProdPercent <- PlottingMeasureOverviewPercent(MeasuresClothingStatsL=MeasuresClothingStatsL,
#                                                  SelTextSources=ProductSector,
#                                                  ReduceExclude = 0,
#                                                  MeasOrdering = 'max',
#                                                  PlotStats= c("p25_t","p50_t","p75_t","zero"),
#                                                  selYear = "2030")
# ggsave(paste0(Analysistag,"EmissionReductionProductionPercent.png"),
#        plot = FigProdPercent,
#        path = figure_folder,
#        width = 12, height = 6)
# ######## Product sector mass ###################

# FigProdSector <- PlottingMeasureOverview(MeasuresClothingStatsL=MeasuresClothingStatsL,
#                         SelTextSources=ProductSector,
#                         ReduceExclude = 0,
#                         MeasOrdering = 'min',
#                         PlotStats= c("p25_t","p50_t","p75_t"))
# ggsave(paste0(Analysistag,"Other_EmissionReductionProductSector.png"),
#        plot = FigProdSector,
#        path = figure_folder,
#        width = 12, height = 6)




########### other Clothing ##################

############## CE ##########
CEMassFlow <- PlottingMeasureOverview(
  MeasuresClothingStatsL = MeasuresClothingStatsL,
  SelTextSources = ClothingSources,
  PlotStats = c("p25_t", "p50_t", "p75_t"),
  EnvExclude = "d",
  MaterialType = c("micro", "macro", "other")
)
ggsave(
  paste0(Analysistag, "Other_EmissionReductionCE.png"),
  plot = CEMassFlow,
  path = figure_folder,
  width = 12,
  height = 6
)

CE_massPrecent <- PlottingMeasureOverviewPercent(
  MeasuresClothingStatsL = MeasuresClothingStatsL,
  SelTextSources = ClothingSources,
  EnvExclude = "d",
  MeasOrdering = 'max',
  MaterialType = c("micro", "macro", "other")
)
ggsave(
  paste0(Analysistag, "Other_EmissionReductionPercentCE.png"),
  plot = CE_massPrecent,
  path = figure_folder,
  width = 12,
  height = 6
)

############ Measure Specific ################
Measures <- MeasuresClothingStatsL |> distinct(Measure) |> pull()

for (i in 1:length(Measures)) {
  PlotMSS <- funPlotMeasureSourceSpecific(
    MeasuresClothingStatsL,
    SelMeasure = Measures[i],
    PlotStats = c("p25_t", "p50_t", "p75_t"),
    MeasOrdering = 'min',
    selScale = "NL",
    SelTextSources = c(
      "Apparel accessories",
      "Jackets and coats",
      "Leggings stockings tights and socks",
      "Sweaters and midlayers"  ,
      "Dresses skirts and jumpsuits"   ,
      "Pants and shorts"    ,
      "Shirts and blouses"     ,
      "Swimwear" ,
      "T-shirts" ,
      "Underwear"
    ),
    ReduceExclude = 1000,
    EnvExclude = "other",
    MaterialType = c("micro", "macro")
  )
  PlotMSS <- PlotMSS + ggtitle(Measures[i])
  ggsave(
    paste0(Analysistag, "_Measure_SourceSpecific_", Measures[i], ".png"),
    plot = PlotMSS,
    path = figure_folder,
    width = 12,
    height = 6
  )
  
  PlotMS <- funPlotMeasureSpecific(
    MeasuresClothingStatsL,
    SelMeasure = Measures[i],
    PlotStats = c("p25_t", "p50_t", "p75_t"),
    MeasOrdering = 'min',
    selScale = "NL",
    SelTextSources = c(
      "Apparel accessories",
      "Jackets and coats",
      "Leggings stockings tights and socks",
      "Sweaters and midlayers"  ,
      "Dresses skirts and jumpsuits"   ,
      "Pants and shorts"    ,
      "Shirts and blouses"     ,
      "Swimwear" ,
      "T-shirts" ,
      "Underwear"
    ),
    ReduceExclude = 1000,
    EnvExclude = "other",
    MaterialType = c("micro", "macro")
  )
  PlotMS <- PlotMS + ggtitle(Measures[i])
  ggsave(
    paste0(
      Analysistag,
      "_Measure_SourceSpecificEnv_",
      Measures[i],
      ".png"
    ),
    plot = PlotMS,
    path = figure_folder,
    width = 12,
    height = 6
  )
  
  ########### Measure Specific percentages ###############
  PlotMSS <- funPlotMeasureSourceSpecificPercent(
    MeasuresClothingStatsL,
    SelMeasure = Measures[i],
    PlotStats = c("p25_t", "p50_t", "p75_t", "zero"),
    MeasOrdering = 'max',
    selScale = "NL",
    SelTextSources = c(
      "Apparel accessories",
      "Jackets and coats",
      "Leggings stockings tights and socks",
      "Sweaters and midlayers"  ,
      "Dresses skirts and jumpsuits"   ,
      "Pants and shorts"    ,
      "Shirts and blouses"     ,
      "Swimwear" ,
      "T-shirts" ,
      "Underwear"
    ),
    ReduceExclude = 1000,
    EnvExclude = "other",
    MaterialType = c("micro", "macro")
  )
  PlotMSS <- PlotMSS + ggtitle(Measures[i])
  ggsave(
    paste0(
      Analysistag,
      "_Measure_SourceSpecificPercent_",
      Measures[i],
      ".png"
    ),
    plot = PlotMSS,
    path = figure_folder,
    width = 12,
    height = 6
  )
  
  PlotMS <- funPlotMeasureSpecificPercent(
    MeasuresClothingStatsL,
    SelMeasure = Measures[i],
    PlotStats = c("p25_t", "p50_t", "p75_t", "zero"),
    MeasOrdering = 'max',
    selScale = "NL",
    SelTextSources = c(
      "Apparel accessories",
      "Jackets and coats",
      "Leggings stockings tights and socks",
      "Sweaters and midlayers"  ,
      "Dresses skirts and jumpsuits"   ,
      "Pants and shorts"    ,
      "Shirts and blouses"     ,
      "Swimwear" ,
      "T-shirts" ,
      "Underwear"
    ),
    ReduceExclude = 1000,
    EnvExclude = "other",
    MaterialType = c("micro", "macro")
  )
  PlotMS <- PlotMS + ggtitle(Measures[i])
  ggsave(
    paste0(
      Analysistag,
      "_Measure_SourceSpecificEnvPercent_",
      Measures[i],
      ".png"
    ),
    plot = PlotMS,
    path = figure_folder,
    width = 12,
    height = 6
  )
  
}
