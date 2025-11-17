library(readxl)
library(tidyverse)
library(openxlsx)

input_data_source <- "https://ec.europa.eu/eurostat/databrowser/view/DS-056120__custom_15192557/default/table?lang=en"

low_scenario_min <- 0.000006
low_scenario_max <- 0.009508

high_scenario_min <- 0.75
high_scenario_max <- 1

# Get the mass per year per scale per category
All_import_export_production <- readRDS("Mass_per_category.RDS")

# Get the lifetimes
lifetimes <- read_xlsx("Calculated_input_and_TCs.xlsx", sheet = "Lifetimes") |>
  mutate(Years_extended = Years + 1) |>
  select(-Source)

footwear_import_export <- All_import_export_production |>
  filter(Region == "NL") |>
  filter(Category %in% c("Boots", "Open-toed shoes", "Closed-toed shoes")) |>
  mutate(source = "min") |>
  bind_rows(
    All_import_export_production |>
      filter(Region == "NL",
             Category %in% c("Boots", "Open-toed shoes", "Closed-toed shoes")) |>
      mutate(source = "max")
  )

apparel_import_export <- All_import_export_production |>
  filter(Region == "NL") |>
  filter(!Category %in% unique(footwear_import_export$Category))

apparel_import_export_EU <- All_import_export_production |>
  filter(Region == "EU") |>
  mutate(source = "min") |>
  bind_rows(
    All_import_export_production |>
      filter(Region == "EU") |>
      mutate(source = "max")
  )

###################################### Low #####################################

# Recalculate the input, by dividing the input by the new number of years times the old number of years. 
All_import_export_production_low <- apparel_import_export |>
  left_join(lifetimes, by = "Category") |>
  mutate(Import_min = Import_kt-((Import_kt/Years_extended)*low_scenario_min),
         Import_max = Import_kt-((Import_kt/Years_extended)*low_scenario_max),
         Export_min = Export_kt-((Export_kt/Years_extended)*low_scenario_min),
         Export_max = Export_kt-((Export_kt/Years_extended)*low_scenario_max)) |>
  select(Region, Year, Category, Material, Import_min, Import_max, Export_min, Export_max, Production_kt)

All_import_export_production_low_long <- All_import_export_production_low %>%
  pivot_longer(
    cols = c(Import_min, Import_max, Export_min, Export_max),
    names_to = c(".value", "source"),
    names_pattern = "(Import|Export)_(min|max)"
  ) |>
  rename(
    Import_kt = Import,
    Export_kt = Export
  ) |>
  distinct()

All_import_export_production_low <- bind_rows(footwear_import_export, All_import_export_production_low_long, apparel_import_export_EU)

##### Calculate fractions of import of clothing from inside and outside the EU + domestic production in NL
production_fraction_EU <- All_import_export_production_low |>
  filter(Region == "EU") |>
  group_by(Region, Year, Material) |>
  summarise(Import_kt = sum(Import_kt),
            Export_kt = sum(Export_kt), 
            Production_kt = sum(Production_kt)) |>
  mutate(production_fraction = Production_kt/(Production_kt + Import_kt))|>
  ungroup() |>
  select(Material, Year, production_fraction)

# Apply the calculated fractions to the NL import data
Import_NL <- All_import_export_production_low |>
  group_by(Region, Year, Material, source) |>
  summarise(Import_kt = sum(Import_kt),
            Production_kt = sum(Production_kt),
            Export_kt = sum(Export_kt)) |>
  filter(Region == "NL") |>
  left_join(production_fraction_EU, by = c("Material", "Year")) |>
  filter(!is.na(production_fraction)) |>
  mutate(`Import of clothing (EU)` = Import_kt*production_fraction,
         `Import of clothing (Global)` = Import_kt*(1-production_fraction)) |>
  select(Region, Year, Material, `Import of clothing (EU)`, `Import of clothing (Global)`, source) 

# Save Import/Export/Production data
Import_Export_Production_NL <- All_import_export_production_low |>
  group_by(Region, Year, Material, source) |>
  summarise(Import_kt = sum(Import_kt),
            Production_kt = sum(Production_kt),
            Export_kt = sum(Export_kt)) |>
  #mutate(Export_kt = Export_kt*-1) |>
  filter(Region == "NL") |>
  left_join(production_fraction_EU, by = c("Material", "Year")) |>
  ungroup()|>
  mutate(Import_from_EU = Import_kt*production_fraction,
         Import_from_outside_EU = Import_kt-Import_from_EU) |>
  select(-production_fraction)

########################### Calculate production and import for EU
Import_Export_Production_EU <- All_import_export_production_low |>
  filter(Region == "EU") |>
  group_by(Region, Year, Material) |>
  summarise(`Import (Global)` = sum(Import_kt),
            Export_kt = sum(Export_kt), 
            Production = sum(Production_kt)) 

########################### Calculate the TCs from production to categories  
total_import_production_mats <- All_import_export_production_low |>
  mutate(Production_kt = replace_na(Production_kt, 0)) |>
  mutate(Import_Production_kt = Import_kt + Production_kt) |>
  filter(Year == 2022) |>
  filter(Region == "NL") |>
  group_by(Region, Year, Material, source) |>
  summarise(Import_Production_kt_sum = sum(Import_Production_kt))

material_fractions_source <- "https://eeb.org/library/draft-product-environmental-footprint-category-rules-pefcr-apparel-and-footwear/"

Consumption_to_categories_TCs_NL <- All_import_export_production_low |>
  mutate(Production_kt = replace_na(Production_kt, 0)) |>
  mutate(Import_Production_kt = Import_kt + Production_kt) |>
  filter(Region == "NL")|>
  filter(Year == 2022) |>
  left_join(total_import_production_mats, by = c("Region", "Year", "Material", "source")) |>
  mutate(Mat_TC = Import_Production_kt/Import_Production_kt_sum) |>
  ungroup()|>
  mutate(From = "Consumption",
         To = Category,
         `Geo NL` = 2,
         `Geo EU` = NA,
         Temp = 2,
         Mat = 1,
         Tech = 2,
         Rel = 3,
         Data = Mat_TC,
         Scale = Region,
         Priority = 1,
         Source = source,
         Comments = "") |>
  select(From, To, Scale, Material, Data, Priority, Source, `Geo NL`, `Geo EU`, Temp, Mat, Tech, Rel, Comments)

total_import_production_mats <- All_import_export_production_low |>
  mutate(Production_kt = replace_na(Production_kt, 0)) |>
  mutate(Import_Production_kt = Import_kt + Production_kt) |>
  filter(Year == 2022) |>
  filter(Region == "EU") |>
  group_by(Region, Year, Material, source) |>
  summarise(Import_Production_kt_sum = sum(Import_Production_kt))

wb <- createWorkbook()

# Add worksheets to the workbook
addWorksheet(wb, "TCs_low")
addWorksheet(wb, "Input_low")
addWorksheet(wb, "Lifetimes")

Import_Export_Production_NL <- Import_Export_Production_NL |>
  filter(Year != 2023) |>
  select(-c(Production_kt, Import_kt)) |>
  pivot_wider(
    values_from = c(Import_from_EU, Import_from_outside_EU, Export_kt),
    names_from = source,
    names_glue = "{.value}_{source}"
  ) |>
  select(Region, Year, Material, Export_kt_min, Export_kt_max, Import_from_EU_min, Import_from_outside_EU_min, Import_from_EU_max, Import_from_outside_EU_max)


# Write the dataframes to the respective worksheets
writeData(wb, sheet = "TCs_low", Consumption_to_categories_TCs_NL)
writeData(wb, sheet = "Input_low", Import_Export_Production_NL)
writeData(wb, sheet = "Lifetimes", lifetimes)

##################################### High #####################################

# Recalculate the input, by dividing the input by the new number of years times the old number of years. 
All_import_export_production_high <- apparel_import_export |>
  left_join(lifetimes, by = "Category") |>
  mutate(Import_min = Import_kt-((Import_kt/Years_extended)*high_scenario_min),
         Import_max = Import_kt-((Import_kt/Years_extended)*high_scenario_max),
         Export_min = Export_kt-((Export_kt/Years_extended)*high_scenario_min),
         Export_max = Export_kt-((Export_kt/Years_extended)*high_scenario_max)) |>
  select(Region, Year, Category, Material, Import_min, Import_max, Export_min, Export_max, Production_kt)

All_import_export_production_high_long <- All_import_export_production_high %>%
  pivot_longer(
    cols = c(Import_min, Import_max, Export_min, Export_max),
    names_to = c(".value", "source"),
    names_pattern = "(Import|Export)_(min|max)"
  ) |>
  rename(
    Import_kt = Import,
    Export_kt = Export
  ) |>
  distinct()

All_import_export_production_high <- bind_rows(footwear_import_export, All_import_export_production_high_long, apparel_import_export_EU)

##### Calculate fractions of import of clothing from inside and outside the EU + domestic production in NL
production_fraction_EU <- All_import_export_production_high |>
  filter(Region == "EU") |>
  group_by(Region, Year, Material) |>
  summarise(Import_kt = sum(Import_kt),
            Export_kt = sum(Export_kt), 
            Production_kt = sum(Production_kt)) |>
  mutate(production_fraction = Production_kt/(Production_kt + Import_kt))|>
  ungroup() |>
  select(Material, Year, production_fraction)

# Apply the calculated fractions to the NL import data
Import_NL <- All_import_export_production_high |>
  group_by(Region, Year, Material, source) |>
  summarise(Import_kt = sum(Import_kt),
            Production_kt = sum(Production_kt),
            Export_kt = sum(Export_kt)) |>
  filter(Region == "NL") |>
  left_join(production_fraction_EU, by = c("Material", "Year")) |>
  filter(!is.na(production_fraction)) |>
  mutate(`Import of clothing (EU)` = Import_kt*production_fraction,
         `Import of clothing (Global)` = Import_kt*(1-production_fraction)) |>
  select(Region, Year, Material, `Import of clothing (EU)`, `Import of clothing (Global)`, source) 

# Save Import/Export/Production data
Import_Export_Production_NL <- All_import_export_production_high |>
  group_by(Region, Year, Material, source) |>
  summarise(Import_kt = sum(Import_kt),
            Production_kt = sum(Production_kt),
            Export_kt = sum(Export_kt)) |>
  #mutate(Export_kt = Export_kt*-1) |>
  filter(Region == "NL") |>
  left_join(production_fraction_EU, by = c("Material", "Year")) |>
  ungroup()|>
  mutate(Import_from_EU = Import_kt*production_fraction,
         Import_from_outside_EU = Import_kt-Import_from_EU) |>
  select(-production_fraction)

########################### Calculate production and import for EU
Import_Export_Production_EU <- All_import_export_production_high |>
  filter(Region == "EU") |>
  group_by(Region, Year, Material) |>
  summarise(`Import (Global)` = sum(Import_kt),
            Export_kt = sum(Export_kt), 
            Production = sum(Production_kt)) 

########################### Calculate the TCs from production to categories  
total_import_production_mats <- All_import_export_production_high |>
  mutate(Production_kt = replace_na(Production_kt, 0)) |>
  mutate(Import_Production_kt = Import_kt + Production_kt) |>
  filter(Year == 2022) |>
  filter(Region == "NL") |>
  group_by(Region, Year, Material, source) |>
  summarise(Import_Production_kt_sum = sum(Import_Production_kt))

material_fractions_source <- "https://eeb.org/library/draft-product-environmental-footprint-category-rules-pefcr-apparel-and-footwear/"

Consumption_to_categories_TCs_NL <- All_import_export_production_high |>
  mutate(Production_kt = replace_na(Production_kt, 0)) |>
  mutate(Import_Production_kt = Import_kt + Production_kt) |>
  filter(Region == "NL")|>
  filter(Year == 2022) |>
  left_join(total_import_production_mats, by = c("Region", "Year", "Material", "source")) |>
  mutate(Mat_TC = Import_Production_kt/Import_Production_kt_sum) |>
  ungroup()|>
  mutate(From = "Consumption",
         To = Category,
         `Geo NL` = 2,
         `Geo EU` = NA,
         Temp = 2,
         Mat = 1,
         Tech = 2,
         Rel = 3,
         Data = Mat_TC,
         Scale = Region,
         Priority = 1,
         Source = source,
         Comments = "") |>
  select(From, To, Scale, Material, Data, Priority, Source, `Geo NL`, `Geo EU`, Temp, Mat, Tech, Rel, Comments)

total_import_production_mats <- All_import_export_production_high |>
  mutate(Production_kt = replace_na(Production_kt, 0)) |>
  mutate(Import_Production_kt = Import_kt + Production_kt) |>
  filter(Year == 2022) |>
  filter(Region == "EU") |>
  group_by(Region, Year, Material, source) |>
  summarise(Import_Production_kt_sum = sum(Import_Production_kt))

# Add worksheets to the workbook
addWorksheet(wb, "TCs_high")
addWorksheet(wb, "Input_high")

Import_Export_Production_NL <- Import_Export_Production_NL |>
  filter(Year != 2023) |>
  select(-c(Production_kt, Import_kt)) |>
  pivot_wider(
    values_from = c(Import_from_EU, Import_from_outside_EU, Export_kt),
    names_from = source,
    names_glue = "{.value}_{source}"
  ) |>
  select(Region, Year, Material, Export_kt_min, Export_kt_max, Import_from_EU_min, Import_from_outside_EU_min, Import_from_EU_max, Import_from_outside_EU_max)


# Write the dataframes to the respective worksheets
writeData(wb, sheet = "TCs_high", Consumption_to_categories_TCs_NL)
writeData(wb, sheet = "Input_high", Import_Export_Production_NL)

# Save the workbook to a file
saveWorkbook(wb, "Calculated_input_and_TCs_measure_6.xlsx", overwrite = TRUE)
