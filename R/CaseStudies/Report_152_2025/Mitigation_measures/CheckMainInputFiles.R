
## Joris Quik 1 okt 2025

library(tidyverse)

# MainInputFile used for previous baseline (EU diff only)
# MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_NL_EU/MainInputFile_22_7_2025.xlsx"
# MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx"
# MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v2.xlsx"

#### Function for comparing xlsx sheets and find differences ####
DiffxlSheets <- function(MainIMeasurePath =
                           "C:/Users/quikj/OneDrive - rivm.nl/Environmental modelling/2025 Prioritering bron Textiel/Maatregelen/Maininputfiles maatregelen/",
                         MainInputFile = 
                           "C:/Users/quikj/OneDrive - rivm.nl/Environmental modelling/2025 Prioritering bron Textiel/Model/MainInputFile_texile_new.xlsx",
                         MeasureName,
                         Sheet = "Transfer coefficients",
                         Scenario = "low",
                         AddBaseName = TRUE){
  
  TC_measure <- readxl::read_excel(path = paste0(MainIMeasurePath,MeasureName,"_",Scenario,".xlsx"),
                                   sheet = Sheet)
    TC_Main <- readxl::read_excel(path = paste0(MainInputFile),
                                sheet = Sheet)
  
  diffMeasMain <- anti_join(TC_measure, TC_Main) |> 
    mutate(MeasFile = MeasureName)
  
  if(AddBaseName == TRUE){
  diffMainMeas <- anti_join(TC_Main,TC_measure) |> 
    mutate(Source = "baseline") |> 
    mutate(MeasFile = "Baseline")
  } else {diffMainMeas <- anti_join(TC_Main,TC_measure) |> 
    mutate(MeasFile = "Baseline")
  }
  
  return(bind_rows(diffMeasMain,diffMainMeas))
}

#### Prewashing ####
# based on local
testMesl <-   DiffxlSheets(MeasureName = "Prewashing",
                     Scenario = "low",
                     Sheet = "Transfer coefficients",
                     MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
               MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Prewashing",
                          Scenario = "high",
                          Sheet = "Transfer coefficients",
                          MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                          MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

# testMesh <-   DiffxlSheets(MeasureName = "Prewashing",
#                            Scenario = "high",
#                            Sheet = "Transfer coefficients",
#                            MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
#                            MainInputFile = "/rivm/biogrid/quikj/Temp/MainInputFile_texile_new.xlsx")

testMes2 <-
  testMesl |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

#### Recycing ####
## Some issues with differences in rest which are note likely to be required as measure dif.
testMesl <-   DiffxlSheets(MeasureName = "Recycling",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Recycling",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  filter(Data != "rest") |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`, MeasFile, Comments,
            `Geo NL`,`Geo EU`)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  filter(From != "Textile recycling") |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  filter(Data != "rest") |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`, MeasFile, Comments,
            `Geo NL`,`Geo EU`)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  # filter(From != "Textile recycling") |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3) |> filter(relDifmin >0)

#### Vacuuming ####
testMesl <-   DiffxlSheets(MeasureName = "Vacuuming",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Vacuuming",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  # filter(Data != "rest") |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

#### Replace ####
testMesl <-   DiffxlSheets(MeasureName = "Replace",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Replace",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile, `Geo EU`)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

## Waarschijnlijk wel ok, maar in high scenario staan niet alle min/max aangegeven

testMes3 <-
  testMesh |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile, `Geo EU`)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

testMesInl <-   DiffxlSheets(MeasureName = "Replace",
                             Scenario = "low",
                             Sheet = "Input_NL",
                             AddBaseName = FALSE,
                             MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                             MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesInh <-   DiffxlSheets(MeasureName = "Replace",
                             Scenario = "high",
                             Sheet = "Input_NL",
                             AddBaseName = FALSE,
                             MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                             MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesIn2 <-
  testMesInl |> 
  mutate(Data = as.numeric(`Data (kt)`)) |> 
  filter(Year == 2022) |> 
  mutate(Source = case_when(
    str_detect(Source, "Low") ~ "min",
    str_detect(Source, "High") ~ "max",
    TRUE ~ Source
  )) |> 
  select(-c(`Spread`, `Data (kt)`)) |>
  pivot_wider(names_from = c(Source,MeasFile),
              values_from = Data)  
  # mutate(relDifmin = -100*(1-min_Replace/min_Baseline)) |> 
  # mutate(relDifmax = -100*(1-max_Replace/max_Baseline))|>
  # mutate(Scenario = "low")

testMesIn2 <-
  testMesIn2 |>
  summarise(across(min_Replace:max_Baseline, ~ sum(.x))) |> 
  mutate(relDifmin = -100*(1-min_Replace/min_Baseline)) |> 
  mutate(relDifmax = -100*(1-max_Replace/max_Baseline))|>
  mutate(Scenario = "low")

testMesIn3 <-
  testMesInh |> 
  mutate(Data = as.numeric(`Data (kt)`)) |> 
  filter(Year == 2022) |> 
  mutate(Source = case_when(
    str_detect(Source, "Low") ~ "min",
    str_detect(Source, "High") ~ "max",
    TRUE ~ Source
  )) |> 
  select(-c(`Spread`, `Data (kt)`)) |>
  pivot_wider(names_from = c(Source,MeasFile),
              values_from = Data) 

testMesIn3 <-
  testMesIn3 |>
  summarise(across(min_Replace:max_Baseline, ~ sum(.x))) |> 
  mutate(relDifmin = -100*(1-min_Replace/min_Baseline)) |> 
  mutate(relDifmax = -100*(1-max_Replace/max_Baseline))|>
  mutate(Scenario = "high")

#### Production_method_finishes ####
testMesl <-   DiffxlSheets(MeasureName = "Production_method_finishes",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Production_method_finishes",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  # filter(Data != "rest") |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

#### Lifetime ####
testRec <- 
  DiffxlSheets(MeasureName = "Lifetime",
               Scenario = "low",
               Sheet = "Transfer coefficients",
               MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
               MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testRec2 <-
  testRec |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  unnest(c(min,max,baseline)) |> 
  filter(!is.na(baseline)) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testRecAll <- bind_rows(testRec2, testRec3)

testMesInl <-   DiffxlSheets(MeasureName = "Lifetime",
                             Scenario = "low",
                             Sheet = "Input_NL",
                             AddBaseName = FALSE,
                             MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                             MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesInh <-   DiffxlSheets(MeasureName = "Lifetime",
                             Scenario = "high",
                             Sheet = "Input_NL",
                             AddBaseName = FALSE,
                             MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                             MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesIn2 <-
  testMesInl |> 
  mutate(Data = as.numeric(`Data (kt)`)) |> 
  filter(Year == 2022) |> 
  mutate(Source = case_when(
    str_detect(Source, "Low") ~ "min",
    str_detect(Source, "High") ~ "max",
    TRUE ~ Source
  )) |> 
  select(-c(`Spread`, `Data (kt)`)) |>
  pivot_wider(names_from = c(Source,MeasFile),
              values_from = Data)  |> 
  # small error min and max switched
  rename(max_Lifetime = min_Lifetime,
         min_Lifetime = max_Lifetime)

# mutate(relDifmin = -100*(1-min_Replace/min_Baseline)) |> 
# mutate(relDifmax = -100*(1-max_Replace/max_Baseline))|>
# mutate(Scenario = "low")

testMesIn2 <-
  testMesIn2 |>
  summarise(across(min_Lifetime:max_Baseline, ~ sum(.x))) |> 
  mutate(relDifmin = -100*(1-min_Lifetime/min_Baseline)) |> 
  mutate(relDifmax = -100*(1-max_Lifetime/max_Baseline))|>
  mutate(Scenario = "low")

testMesIn3 <-
  testMesInh |> 
  mutate(Data = as.numeric(`Data (kt)`)) |> 
  filter(Year == 2022) |> 
  mutate(Source = case_when(
    str_detect(Source, "Low") ~ "min",
    str_detect(Source, "High") ~ "max",
    TRUE ~ Source
  )) |> 
  select(-c(`Spread`, `Data (kt)`)) |>
  pivot_wider(names_from = c(Source,MeasFile),
              values_from = Data)   |> 
  # small error min and max switched
  rename(max_Lifetime = min_Lifetime,
         min_Lifetime = max_Lifetime)

testMesIn3 <-
  testMesIn3 |>
  summarise(across(min_Lifetime:max_Baseline, ~ sum(.x))) |> 
  mutate(relDifmin = -100*(1-min_Lifetime/min_Baseline)) |> 
  mutate(relDifmax = -100*(1-max_Lifetime/max_Baseline))|>
  mutate(Scenario = "high")


#### Fringes ####
testMesl <-   DiffxlSheets(MeasureName = "Fringes",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Fringes",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile, `Geo EU`)) |>
  filter(Scale == "NL") |> 
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile, `Geo EU`)) |>
  filter(Scale == "NL") |> 
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

testMesInl <-   DiffxlSheets(MeasureName = "Fringes",
                           Scenario = "low",
                           Sheet = "Input_NL",
                           AddBaseName = FALSE,
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesInh <-   DiffxlSheets(MeasureName = "Fringes",
                           Scenario = "high",
                           Sheet = "Input_NL",
                           AddBaseName = FALSE,
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesIn2 <-
  testMesInl |> 
  mutate(Data = as.numeric(`Data (kt)`)) |> 
  filter(Year == 2022) |> 
  select(-c(`Spread`,`Data (kt)`)) |>
   mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    str_detect(Source, "High") ~ "max",
    str_detect(Source, "Low") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = c(Source,MeasFile),
              values_from = Data) 

testMesIn2 <-
  testMesIn2 |>
  summarise(across(min_Fringes:max_Baseline, ~ sum(.x))) |> 
  mutate(relDifmin = -100*(1-min_Fringes/min_Baseline)) |> 
  mutate(relDifmax = -100*(1-max_Fringes/max_Baseline))|>
  mutate(Scenario = "low")

testMesIn3 <-
  testMesInh |> 
  mutate(Data = as.numeric(`Data (kt)`)) |> 
  filter(Year == 2022) |> 
  select(-c(`Spread`,`Data (kt)`)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    str_detect(Source, "High") ~ "max",
    str_detect(Source, "Low") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = c(Source,MeasFile),
              values_from = Data) 

testMesIn3 <-
  testMesIn3 |>
  summarise(across(min_Fringes:max_Baseline, ~ sum(.x))) |> 
  mutate(relDifmin = -100*(1-min_Fringes/min_Baseline)) |> 
  mutate(relDifmax = -100*(1-max_Fringes/max_Baseline))|>
  mutate(Scenario = "high")

#### External filter ####
testMesl <-   DiffxlSheets(MeasureName = "External_filter",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "External_filter",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> mutate(ProbDiff = rep(c("min","max"),2)) |> 
  select(-Source) |> 
  pivot_wider(names_from = c(ProbDiff,MeasFile),
              values_from = Data) |> 
  mutate(Difmin = 100*(min_External_filter-min_Baseline)) |> 
  mutate(Difmax = 100*(max_External_filter-max_Baseline))|> 
  mutate(relDifmin = -100*(1-min_External_filter/min_Baseline)) |> 
  mutate(relDifmax = -100*(1-max_External_filter/max_Baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> mutate(ProbDiff = rep(c("min","max"),2)) |> 
  select(-Source) |> 
  pivot_wider(names_from = c(ProbDiff,MeasFile),
              values_from = Data) |> 
  mutate(Difmin = 100*(min_External_filter-min_Baseline)) |> 
  mutate(Difmax = 100*(max_External_filter-max_Baseline))|> 
  mutate(relDifmin = -100*(1-min_External_filter/min_Baseline)) |> 
  mutate(relDifmax = -100*(1-max_External_filter/max_Baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

#### Delicate washing cycle ####
testMesl <-   DiffxlSheets(MeasureName = "Delicate_washing_cycle",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Delicate_washing_cycle",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  # filter(Data != "rest") |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)
#### Clean dryer filter ####
testMesl <-   DiffxlSheets(MeasureName = "Clean_dryer_filter",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Clean_dryer_filter",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  # filter(Data != "rest") |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  filter(Data != "rest") |>
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)


#### Clothesline_instead_of_dryer ####
testMesl <-   DiffxlSheets(MeasureName = "Clothesline_instead_of_dryer",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Clothesline_instead_of_dryer",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  filter(Data != "rest") |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile, `Geo EU`)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

#### Washer_dryer_filters ####
## new compartments, so check below does not work fully (needs specific adaption, but all seems ok)
testMesl <-   DiffxlSheets(MeasureName = "Washer_dryer_filters",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Washer_dryer_filters",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  filter(Data != "rest") |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile,
            `Geo NL`,`Geo EU`, Temp, Mat, Tech, Rel)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

#### Wastewater ####
testMesl <-   DiffxlSheets(MeasureName = "Wastewater",
                           Scenario = "low",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")
testMesh <-   DiffxlSheets(MeasureName = "Wastewater",
                           Scenario = "high",
                           Sheet = "Transfer coefficients",
                           MainIMeasurePath = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/",
                           MainInputFile = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/Baseline_NL_v3.xlsx")

testMes2 <-
  testMesl |> 
  # filter(Data != "rest") |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "low")

testMes3 <-
  testMesh |> 
  # mutate(Data = as.numeric(Data)) |> 
  select(-c(`Spread NL` ,`Spread EU`,MeasFile)) |>
  mutate(Source = case_when(
    str_detect(Source, "- max") ~ "max",
    str_detect(Source, "- min") ~ "min",
    TRUE ~ Source
  )) |> 
  pivot_wider(names_from = Source,
              values_from = Data) |> 
  mutate(across(c(min,max, baseline), ~ as.numeric(.x))) |> 
  mutate(relDifmin = -100*(1-min/baseline)) |> 
  mutate(relDifmax = -100*(1-max/baseline))|> 
  mutate(Scenario = "high")
SumMeas <- bind_rows(testMes2, testMes3)

