# 13 okt. 2025
# Joris Quik
library(tidyverse)

data_folder_2024 <- "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_output/"
data_folder_2025 <- "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Output/"

BaselineFile2024 <- "Baseline_mitigation.RData"
BaselineFile2024 <- "Baseline_PMFA_NL.RData"
BaselineFile2025 <- "DPMFA_calculated_mass_flows_Baseline_NL_v3_years_of_interest.RData"

load(paste0(data_folder_2024,  BaselineFile2024))

##### 2024 model ####

# Be careful, this makes a very big tibble
# TODO figure out how to use the nested tibble for making graphs
data_long <- 
  DPMFA_inflow |> unnest(Mass_Polymer_kt, keep_empty = TRUE) |> 
  pivot_longer(cols=-c(Type, Scale, Source, Polymer, To_Compartment, Material_Type, iD_source, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt")
data_long |> distinct(Material_Type)

Years_available <- unique(data_long$Year)

SelectYear = 2019

# Create a dataframe for just 2020
data_Year <- data_long |>
  filter(Year == SelectYear) |>
  mutate(Mass_Polymer_t = Mass_Polymer_kt * 1000, .keep = "unused") |> # conert kt to ton
  filter(To_Compartment %in% unique(DPMFA_sink$To_Compartment) & Type == "Inflow") |> # only sinks
  mutate(`Environmental_compartment` = # make column indicating of this an air, water or soil sink.
           case_when(
             str_detect(To_Compartment, 'water') ~ "water",
             str_detect(To_Compartment, 'air') ~ "air",
             str_detect(To_Compartment, 'soil') ~ "soil",
             .default = "none"
           )) |> filter(`Environmental_compartment` != "none") |> # remove sinks that are not environmental
  mutate(IenW_Source = # aggregate inputs to the Major sources classes the study focusses on
           case_when(
             str_detect(Source, 'Clothing') ~ "Textile",
             str_detect(Source, 'Household textiles') ~ "Textile",
             str_detect(Source, 'Technical textiles') ~ "Textile", 
             str_detect(Source, 'Import of primary plastics') ~ "Pre-production pellets",
             str_detect(Source, 'Domestic primary plastic production') ~ "Pre-production pellets",
             .default = Source
           )) 

data_Year |> ungroup() |> 
  group_by(Source,Scale,RUN) |>
  summarise(totalout = sum(Mass_Polymer_t)) |> 
  ungroup() |> group_by(Source,Scale) |> 
  summarise(AvgSinks = mean(totalout),
            p25 = quantile(totalout,.25),
            p50 = quantile(totalout,.50),
            p75 = quantile(totalout,.75))




# data_Year_sep_macro <- 
#   data_Year |> filter(Material_Type == "micro") |> full_join(
#     data_Year |> 
#       filter(Material_Type == "macro") |> 
#       ungroup() |> 
#       group_by(Type   ,
#                Scale,
#                Polymer,
#                To_Compartment,
#                Material_Type,
#                RUN,
#                Year,
#                Environmental_compartment) |> 
#       summarise(Mass_Polymer_t = sum(Mass_Polymer_t),
#                 n=n(),
#                 IenW_Source = "Macroplastic",
#                 Source = "Macroplastic")
#   )

#### 2025 model ####
load(paste0(data_folder_2025,  BaselineFile2025 ))

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

Baseline_2025 <- DPMFA_years_of_interest |>
  mutate(data_source = "Baseline")

Baseline_2025 <- Baseline_2025 |>
  filter(From_compartment %in% source_compartments) |>
  filter(To_Compartment %in% sink_compartments)



Baseline_2025 <- Baseline_2025 %>%
  mutate(
    Mass_Polymer_kt = map(Mass_Polymer_kt, ~
                            .x %>%
                            as.data.frame() %>%
                            mutate(RUN = row_number())
    )
  )


Baseline_2025 <- 
  Baseline_2025 |> unnest(Mass_Polymer_kt, keep_empty = TRUE) |> 
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, 
                       To_compartment, iD_source, RUN,data_source),
               names_to = "Year",
               values_to = "Mass_Polymer_kt")
SelectYear <- 2022
anthropogenic <- c("Elimination"     ,         "Export"             ,      "Landfill",  "Secondary material reuse", "Textile reuse" )
ClothingSources <- c( "Apparel accessories",
                      "Jackets and coats",                    
                      "Leggings stockings tights and socks",  
                      "Sweaters and midlayers"  ,  
                      "Dresses skirts and jumpsuits"   ,              
                      "Pants and shorts"    ,                 
                      "Shirts and blouses"     ,               
                      "Swimwear" ,                            
                      "T-shirts" ,                            
                      "Underwear"  )

ShoesSources <- c("Open-toed shoes"   ,  
                  "Boots"        ,                         
                  "Closed-toed shoes")

# test <- 
#   Baseline_2025 |>
#   filter(Year == SelectYear) |>
#   mutate(Mass_Polymer_t = Mass_Polymer_kt * 1000, .keep = "unused") |> # conert kt to ton
#   filter(!To_Compartment %in% anthropogenic) |> # only sinks
#   mutate(`Environmental_compartment` = # make column indicating of this an air, water or soil sink.
#            case_when(
#              str_detect(To_Compartment, 'water') ~ "water",
#              str_detect(To_Compartment, 'air') ~ "air",
#              str_detect(To_Compartment, 'soil') ~ "soil",
#              .default = "none"
#            )) |> filter(`Environmental_compartment` != "none") |> 
#   ungroup() |> 
#   group_by(From_compartment,Scale,RUN) |>
#   summarise(totalout = sum(Mass_Polymer_t)) |> 
#   ungroup() |> group_by(From_compartment,Scale) |> 
#   summarise(AvgSinks = mean(totalout),
#             p25 = quantile(totalout,.25),
#             p50 = quantile(totalout,.50),
#             p75 = quantile(totalout,.75))

Baseline_2025_Textile <- 
  Baseline_2025 |>
  filter(Year == SelectYear) |>
  mutate(Mass_Polymer_t = Mass_Polymer_kt * 1000, .keep = "unused") |> # conert kt to ton
  filter(!To_Compartment %in% anthropogenic) |> # only sinks
  mutate(`Environmental_compartment` = # make column indicating of this an air, water or soil sink.
           case_when(
             str_detect(To_Compartment, 'water') ~ "water",
             str_detect(To_Compartment, 'air') ~ "air",
             str_detect(To_Compartment, 'soil') ~ "soil",
             .default = "none"
           )) |> filter(`Environmental_compartment` != "none",
                        From_compartment %in% c(ClothingSources,ShoesSources)) |> 
  ungroup() |> 
  group_by(Scale,RUN) |>
  summarise(totalout = sum(Mass_Polymer_t)) |> 
  ungroup() |> group_by(Scale) |> 
  summarise(AvgSinks = mean(totalout),
            p25 = quantile(totalout,.25),
            p50 = quantile(totalout,.50),
            p75 = quantile(totalout,.75))

Baseline_2025_Clothing <- 
  Baseline_2025 |>
  filter(Year == SelectYear) |>
  mutate(Mass_Polymer_t = Mass_Polymer_kt * 1000, .keep = "unused") |> # conert kt to ton
  filter(!To_Compartment %in% anthropogenic) |> # only sinks
  mutate(`Environmental_compartment` = # make column indicating of this an air, water or soil sink.
           case_when(
             str_detect(To_Compartment, 'water') ~ "water",
             str_detect(To_Compartment, 'air') ~ "air",
             str_detect(To_Compartment, 'soil') ~ "soil",
             .default = "none"
           )) |> filter(`Environmental_compartment` != "none",
                        From_compartment %in% c(ClothingSources)) |> 
  ungroup() |> 
  group_by(Scale,RUN) |>
  summarise(totalout = sum(Mass_Polymer_t)) |> 
  ungroup() |> group_by(Scale) |> 
  summarise(AvgSinks = mean(totalout),
            p25 = quantile(totalout,.25),
            p50 = quantile(totalout,.50),
            p75 = quantile(totalout,.75))
Baseline_2025_Footwear <- 
  Baseline_2025 |>
  filter(Year == SelectYear) |>
  mutate(Mass_Polymer_t = Mass_Polymer_kt * 1000, .keep = "unused") |> # conert kt to ton
  filter(!To_Compartment %in% anthropogenic) |> # only sinks
  mutate(`Environmental_compartment` = # make column indicating of this an air, water or soil sink.
           case_when(
             str_detect(To_Compartment, 'water') ~ "water",
             str_detect(To_Compartment, 'air') ~ "air",
             str_detect(To_Compartment, 'soil') ~ "soil",
             .default = "none"
           )) |> filter(`Environmental_compartment` != "none",
                        From_compartment %in% c(ShoesSources)) |> 
  ungroup() |> 
  group_by(Scale,RUN) |>
  summarise(totalout = sum(Mass_Polymer_t)) |> 
  ungroup() |> group_by(Scale) |> 
  summarise(AvgSinks = mean(totalout),
            p25 = quantile(totalout,.25),
            p50 = quantile(totalout,.50),
            p75 = quantile(totalout,.75))




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
Baseline_2025_2 <- DPMFA_years_of_interest |>
  mutate(data_source = "Baseline")

Baseline_2025_2 <- Baseline_2025_2 |>
  filter(From_compartment %in% source_compartments) |>
  filter(To_Compartment %in% sink_compartments)



Baseline_2025_2 <- Baseline_2025_2 %>%
  mutate(
    Mass_Polymer_kt = map(Mass_Polymer_kt, ~
                            .x %>%
                            as.data.frame() %>%
                            mutate(RUN = row_number())
    )
  )

Clothing_data_statistics <-
  Baseline_2025_2 %>%
  ungroup() |> 
  mutate(Aggr_t =  
           map(.x = Mass_Polymer_kt, .f = AggrF)) |>    
  mutate(Mass_Polymer_kt = NULL) |> 
  unnest(Aggr_t, keep_empty = TRUE)


# MeasuresClothingStats |> distinct(To_Compartment) |> pull()
soil_compartments <- c("Agricultural soil", "Natural soil", "Residential soil", "Road side soil", "Sub-surface soil")
water_compartments <- c("Surface water", "Sea water")
air_compartments <- c("Outdoor air")
anthropogenic <- c("Elimination"     ,         "Export"             ,      "Landfill",  "Secondary material reuse", "Textile reuse" )

Clothing_data_statistics <- 
  Clothing_data_statistics |>  mutate(
    `Environmental Compartment` = case_when(
      To_Compartment %in% soil_compartments ~ "soil",
      To_Compartment %in% water_compartments ~ "water",
      To_Compartment %in% air_compartments ~ "air",
      TRUE ~ "other"
    )
  )

ClothingSources <- c( "Apparel accessories",
                      "Jackets and coats",                    
                      "Leggings stockings tights and socks",  
                      "Sweaters and midlayers"  ,  
                      "Dresses skirts and jumpsuits"   ,              
                      "Pants and shorts"    ,                 
                      "Shirts and blouses"     ,               
                      "Swimwear" ,                            
                      "T-shirts" ,                            
                      "Underwear"  )

ShoesSources <- c("Open-toed shoes"   ,  
                  "Boots"        ,                         
                  "Closed-toed shoes")

Clothing_data_statistics |> distinct(Year)
Clothing_data_statistics |> distinct(From_compartment)

## Clothing
Clothing_data_statistics |> 
  filter(Year == 2022, 
         Scale == "NL",
         # statistics %in% c("p25_t","p50_t","p75_t"),
         From_compartment %in% ClothingSources,
         `Environmental Compartment` != "other") |> 
  ungroup() |> 
  group_by(Year) |> 
  summarise(across(c(Mean_mass_t:n), ~ sum(.x)))

## Clothing and Shoes
Clothing_data_statistics |> 
  filter(Year == 2022, 
         Scale == "NL",
         # statistics %in% c("p25_t","p50_t","p75_t"),
         From_compartment %in% c(ClothingSources, ShoesSources),
         `Environmental Compartment` != "other") |> 
  ungroup() |> 
  group_by(Year) |> 
  summarise(across(c(Mean_mass_t:n), ~ sum(.x)))

## Shoes
Clothing_data_statistics |> 
  filter(Year == 2022, 
         Scale == "NL",
         # statistics %in% c("p25_t","p50_t","p75_t"),
         From_compartment %in% c(ShoesSources),
         `Environmental Compartment` != "other") |> 
  ungroup() |> 
  group_by(Year) |> 
  summarise(across(c(Mean_mass_t:n), ~ sum(.x)))


## Clothing
Clothing_data_statistics |> 
  filter(Year == 2050, 
         Scale == "NL",
         # statistics %in% c("p25_t","p50_t","p75_t"),
         From_compartment %in% ClothingSources,
         `Environmental Compartment` != "other") |> 
  ungroup() |> 
  group_by(Year) |> 
  summarise(across(c(Mean_mass_t:n), ~ sum(.x)))

## Clothing and Shoes
Clothing_data_statistics |> 
  filter(Year == 2050, 
         Scale == "NL",
         # statistics %in% c("p25_t","p50_t","p75_t"),
         From_compartment %in% c(ClothingSources, ShoesSources),
         `Environmental Compartment` != "other") |> 
  ungroup() |> 
  group_by(Year) |> 
  summarise(across(c(Mean_mass_t:n), ~ sum(.x)))

## Shoes
Clothing_data_statistics |> 
  filter(Year == 2050, 
         Scale == "NL",
         # statistics %in% c("p25_t","p50_t","p75_t"),
         From_compartment %in% c(ShoesSources),
         `Environmental Compartment` != "other") |> 
  ungroup() |> 
  group_by(Year) |> 
  summarise(across(c(Mean_mass_t:n), ~ sum(.x)))