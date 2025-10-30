library(readxl)
library(tidyverse)
library(openxlsx)

input_data_source <- "https://ec.europa.eu/eurostat/databrowser/view/DS-056120__custom_15192557/default/table?lang=en"

low_scenario_min <- 0.000006
low_scenario_max <- 0.009508

high_scenario_min <- 0.375
high_scenario_max <- 0.5

clothing_converted <- readRDS("Textile_input_update/clothing_converted.RDS")

input_data_folder <- "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Input_update/"

# Read and transpose the fractions for apparel
apparel_mat_fractions <- read_excel(paste0(input_data_folder, "Material_composition_Quantis.xlsx"), sheet = 1) |>
  slice(3:n()) |>
  pivot_longer(-`List of materials`, names_to = "Category", values_to = "Fraction") |>
  pivot_wider(names_from = `List of materials`, values_from = "Fraction") |>
  mutate(Trims_PES = Trims/3,
         Trims_PET = Trims/3,
         Trims_metal = Trims/3)  |> # From PEFCR 2021
  select(-Trims)
colnames(apparel_mat_fractions) <- colnames(apparel_mat_fractions) |>
  str_replace_all(" ", "_") |>
  str_replace_all("/", "_")

# Calculate fraction of clothing that is industrial/occupational wear
occcupational_clothing <- clothing_converted |>
  mutate(occupational = case_when(
    startsWith(`Prodcom code`, "1412") ~ TRUE,
    TRUE ~ FALSE
  )) 

# Read in the material categories for apparel
apparel_mat_categories <- read_excel(paste0(input_data_folder, "Apparel_material_categories.xlsx"))  
  
# Make a separate df containing only apparel
apparel <- occcupational_clothing |>
  filter(category == "Apparel") |>
  left_join(apparel_mat_categories, by = c("Prodcom code", "Product_description")) |>
  group_by(Region, Year, category, Category, occupational)|>
  summarise(Import_kg = sum(Import_kg),
            Export_kg = sum(Export_kg),
            Production_kg = sum(Production_kg)) |>
  ungroup()

occupational_fractions <- apparel |>
  filter(occupational)

occupational_categories <- unique(occupational_fractions$Category)

occupational_sums <- apparel |>
  filter(Category %in% occupational_categories) |>
  group_by(Region, Year, category, Category) |>
  summarise(Import_kg_sum = sum(Import_kg),
            Export_kg_sum = sum(Export_kg),
            Production_kg_sum = sum(Production_kg))

occupational_fractions <- apparel |>
  filter(Category %in% occupational_categories) |>
  left_join(occupational_sums, by = c("Region", "Year", "category", "Category")) |>
  mutate(Import_frac_occupational = Import_kg/Import_kg_sum,
         Export_frac_occupational = Export_kg/Export_kg_sum,
         Production_frac_occupational = Production_kg/Production_kg_sum) |>
  filter(occupational) |>
  filter(Region == "Netherlands") |>
  mutate(Region = "NL") |>
  select(Region, Year, Category, Import_frac_occupational, Export_frac_occupational)

write.xlsx(occupational_fractions,  "Textile_input_update/Occupational_clothing_fractions.xlsx")

# Calculate input masses 

# Make a separate df containing only apparel
apparel <- clothing_converted |>
  filter(category == "Apparel") |>
  left_join(apparel_mat_categories, by = c("Prodcom code", "Product_description")) |>
  group_by(Region, Year, category, Category)|>
  summarise(Import_kg = sum(Import_kg),
            Export_kg = sum(Export_kg),
            Production_kg = sum(Production_kg)) |>
  ungroup() |>
  left_join(apparel_mat_fractions, by = "Category") 

# Read and transpose the fractions for footwear
footwear_mat_fractions <- read_excel(paste0(input_data_folder, "Material_composition_Quantis.xlsx"), sheet = 2) |>
  slice(3:n()) |>
  pivot_longer(-`List of materials`, names_to = "Category", values_to = "Fraction") |>
  pivot_wider(names_from = `List of materials`, values_from = "Fraction") |>
  mutate(Trims_PES = Trims/3,
         Trims_PET = Trims/3,
         Trims_metal = Trims/3)  |> # From PEFCR 2021
  select(-Trims)

colnames(footwear_mat_fractions) <- colnames(footwear_mat_fractions) |>
  str_replace_all(" ", "_") |>
  str_replace_all("/", "_")

# Read in the material categories for footwear
footwear_mat_categories <- read_excel(paste0(input_data_folder, "Footwear_material_categories.xlsx"))

# Make a separate df containing only footwear
footwear <- clothing_converted |>
  filter(category == "Footwear") |>
  left_join(footwear_mat_categories, by = c("Prodcom code", "Product_description")) |>
  group_by(Region, Year, category, Category)|>
  summarise(Import_kg = sum(Import_kg),
            Export_kg = sum(Export_kg),
            Production_kg = sum(Production_kg)) |>
  ungroup() |>
  left_join(footwear_mat_fractions, by = "Category") 

# Calculate the masses of each material per category

# Define the material columns and weight columns
apparel_material_columns <- colnames(apparel_mat_fractions)[2:20]
weight_columns <- c("Import_kg", "Export_kg", "Production_kg")

# Calculate the masses of each material per category for each weight column
apparel <- apparel |>
  rowwise() |>
  mutate(across(all_of(apparel_material_columns), 
                .fns = list(
                  Import = ~ . * Import_kg,
                  Export = ~ . * Export_kg,
                  Production = ~ . * Production_kg
                ),
                .names = "{col}.{fn}")) |>
  ungroup()

# Define the material columns and weight columns
footwear_material_columns <- colnames(footwear_mat_fractions)[2:20]

weight_columns <- c("Import_kg", "Export_kg", "Production_kg")

# Calculate the masses of each material per category for each weight column
footwear <- footwear |>
  rowwise() |>
  mutate(across(all_of(footwear_material_columns), 
                .fns = list(
                  Import = ~ . * Import_kg,
                  Export = ~ . * Export_kg,
                  Production = ~ . * Production_kg
                ),
                .names = "{col}.{fn}")) |>
  ungroup()

apparel_colnames <- colnames(apparel)[27:83]

apparel_synthetic_materials <- c("Acrylic", "Elastane", "Polyamide", "Polyamide_recycled", "Polyester_and_other_synthetics", "Polyester_recycled", "PFTE", "Trims_PES", "Trims_PET")

# Calculate Import, Export and Production in kt per material and category
apparel_import_export_production_categories <- apparel |>
  select(-all_of(apparel_material_columns)) |>
  select(-c("Import_kg", "Export_kg", "Production_kg")) |>
  pivot_longer(cols = all_of(apparel_colnames),
               names_to = c("Material", "Weight_Type"),
               names_sep = "\\.(?=[^.]+$)",
               values_to = "Mass") |>
  pivot_wider(names_from = "Weight_Type", values_from = "Mass") |>
  filter(Material %in% apparel_synthetic_materials) |>
  mutate(Region = case_when(
    Region == "Netherlands" ~ "NL",
    TRUE ~ "EU"
  )) |>
  mutate(Import_kt = Import/1000000,
         Export_kt = Export/1000000,
         Production_kt = Production/1000000) |>
  select(-c("Import", "Export", "Production"))

footwear_colnames <- colnames(footwear)[27:83]
footwear_synthetic_materials <- c("EVA", "Polyamide", "Polyamide_recycled", "Polyester_and_other_synthetics", "Polyester_recycled", "Polyurethane", "PVC", "Rubber_synthetic", "Thermoplastic_polyurethane", "Trims_PES", "Trims_PET")

# Calculate Import, Export and Production in kt per material and category
footwear_import_export_production_categories <- footwear |>
  select(-all_of(footwear_material_columns)) |>
  select(-c("Import_kg", "Export_kg", "Production_kg")) |>
  pivot_longer(cols = all_of(footwear_colnames),
               names_to = c("Material", "Weight_Type"),
               names_sep = "\\.(?=[^.]+$)",
               values_to = "Mass") |>
  pivot_wider(names_from = "Weight_Type", values_from = "Mass") |>
  filter(Material %in% footwear_synthetic_materials) |>
  mutate(Region = case_when(
    Region == "Netherlands" ~ "NL",
    TRUE ~ "EU"
  )) |>
  mutate(Import_kt = Import/1000000,
         Export_kt = Export/1000000,
         Production_kt = Production/1000000) |>
  select(-c("Import", "Export", "Production"))

All_import_export_production <- bind_rows(apparel_import_export_production_categories, footwear_import_export_production_categories) |>
  filter(Year %in% 2011:2023) |>
  mutate(Material = case_when(
    Material == "Acrylic" ~ "Acryl",
    Material == "Elastane" ~ "OTHER",
    Material == "Polyamide" ~ "PA",
    Material == "Polyamide_recycled" ~ "PA",
    Material == "Polyester_and_other_synthetics" ~ "PET",
    Material == "Polyester_recycled" ~ "PET",
    Material == "PFTE" ~ "OTHER",
    Material == "EVA" ~ "OTHER",
    Material == "Polyamide" ~ "PA",
    Material == "Polyamide_recycled" ~ "PA",
    Material == "Polyurethane" ~ "PUR",
    Material == "Rubber_synthetic" ~ "RUBBER",
    Material == "Thermoplastic_polyurethane" ~ "PUR",
    Material == "Trims_PES" ~ "OTHER",
    Material == "Trims_PET" ~ "PET",
    TRUE ~ Material
  )) |>
  group_by(Region, Year, Category, Material) |>
  summarise(Import_kt = sum(Import_kt),
            Export_kt = sum(Export_kt), 
            Production_kt = sum(Production_kt)) 

#### Low calculation
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
  filter(! Category %in% unique(footwear_import_export$Category))

apparel_import_export_EU <- All_import_export_production |>
  filter(Region == "EU") |>
  mutate(source = "min") |>
  bind_rows(
    All_import_export_production |>
      filter(Region == "EU") |>
      mutate(source = "max")
  )

All_import_export_production_low <- apparel_import_export  |>
  left_join(occupational_fractions, by = c("Category", "Region", "Year")) |>
  mutate(Import_frac_occupational = case_when(
    Material == "PA" ~ Import_frac_occupational,
    Material == "PET" ~ Import_frac_occupational,
    TRUE ~ 0
  )) |>
  mutate(Export_frac_occupational = case_when(
    Material == "PA" ~ Export_frac_occupational,
    Material == "PET" ~ Export_frac_occupational,
    TRUE ~ 0
  )) |>
  mutate(Import_frac_occupational = replace_na(Import_frac_occupational, 0)) |>
  mutate(Export_frac_occupational = replace_na(Export_frac_occupational, 0)) |>
  mutate(Import_min = case_when(
    Material %in% c("PA", "PET") ~ (Import_kt * (Import_frac_occupational)) +
                                   (Import_kt * (1 - Import_frac_occupational) * (1-low_scenario_min)),
    TRUE ~ Import_kt
  )) |>
  mutate(Import_max = case_when(
    Material %in% c("PA", "PET") ~ (Import_kt * Import_frac_occupational) + 
                                   (Import_kt * (1 - Import_frac_occupational) * (1-low_scenario_max)),
    TRUE ~ Import_kt
  )) |>
  mutate(Export_min = case_when(
    Material %in% c("PA", "PET") ~ (Export_kt * Export_frac_occupational) + 
                                   (Export_kt * (1 - Export_frac_occupational) * (1-low_scenario_min)),
    TRUE ~ Export_kt
  )) |>
  mutate(Export_max = case_when(
    Material %in% c("PA", "PET") ~ (Export_kt * Export_frac_occupational) + 
                                   (Export_kt * (1 - Export_frac_occupational) * (1-low_scenario_max)),
    TRUE ~ Export_kt
  )) |>
  select(-c(Import_kt, Export_kt, Production_kt, Import_frac_occupational, Export_frac_occupational))

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

Import_Export_Production_NL <- Import_Export_Production_NL |>
  filter(Material %in% c("PET", "PA")) |>
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








#### High calculation
All_import_export_production_high <- apparel_import_export  |>
  left_join(occupational_fractions, by = c("Category", "Region", "Year")) |>
  mutate(Import_frac_occupational = case_when(
    Material == "PA" ~ Import_frac_occupational,
    Material == "PET" ~ Import_frac_occupational,
    TRUE ~ 0
  )) |>
  mutate(Export_frac_occupational = case_when(
    Material == "PA" ~ Export_frac_occupational,
    Material == "PET" ~ Export_frac_occupational,
    TRUE ~ 0
  )) |>
  mutate(Import_frac_occupational = replace_na(Import_frac_occupational, 0)) |>
  mutate(Export_frac_occupational = replace_na(Export_frac_occupational, 0)) |>
  mutate(Import_min = case_when(
    Material %in% c("PA", "PET") ~ (Import_kt * (Import_frac_occupational)) +
      (Import_kt * (1 - Import_frac_occupational) * (1-high_scenario_min)),
    TRUE ~ Import_kt
  )) |>
  mutate(Import_max = case_when(
    Material %in% c("PA", "PET") ~ (Import_kt * Import_frac_occupational) + 
      (Import_kt * (1 - Import_frac_occupational) * (1-high_scenario_max)),
    TRUE ~ Import_kt
  )) |>
  mutate(Export_min = case_when(
    Material %in% c("PA", "PET") ~ (Export_kt * Export_frac_occupational) + 
      (Export_kt * (1 - Export_frac_occupational) * (1-high_scenario_min)),
    TRUE ~ Export_kt
  )) |>
  mutate(Export_max = case_when(
    Material %in% c("PA", "PET") ~ (Export_kt * Export_frac_occupational) + 
      (Export_kt * (1 - Export_frac_occupational) * (1-high_scenario_max)),
    TRUE ~ Export_kt
  )) |>
  select(-c(Import_kt, Export_kt, Production_kt, Import_frac_occupational, Export_frac_occupational))

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
  mutate(source = case_when(
    !Material %in% c("PA", "PET") ~ NA,
    TRUE ~ source
  )) |>
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
  filter(Material %in% c("PET", "PA")) |>
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
saveWorkbook(wb, "Textile_input_update/Calculated_input_and_TCs_Measure_2.xlsx", overwrite = TRUE)



