library(readxl)
library(tidyverse)
library(openxlsx)

input_data_source <- "https://ec.europa.eu/eurostat/databrowser/view/DS-056120__custom_15192557/default/table?lang=en"

low_scenario_min <- 0.000006
low_scenario_max <- 0.009508

high_scenario_min <- 0.75
high_scenario_max <- 1

# Get the mass per year per scale per category
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

# Read in the material categories for apparel
apparel_mat_categories <- read_excel(paste0(input_data_folder, "Apparel_material_categories.xlsx"))

# Read in the material categories for footwear
footwear_mat_categories <- read_excel(paste0(input_data_folder, "Footwear_material_categories.xlsx"))

# Add a column to the clothing_converted df to specify if the category is apparel or footwear
clothing_converted <- clothing_converted |>
  mutate(`Prodcom code` = as.character(`Prodcom code`)) |>
  mutate(category = case_when(
    str_starts(`Prodcom code`, '152') ~ "Footwear",
    TRUE ~ "Apparel"
  ))

saveRDS(clothing_converted, "Textile_input_update/clothing_converted.RDS")

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

#####
trims_mass_per_category <- bind_rows(apparel, footwear) |>
  select(
    Region, Year, Category, Trims_PET.Import, Trims_PET.Export, Trims_PES.Import, Trims_PES.Export
  ) |>
  mutate(
    Trims_PET.Import = Trims_PET.Import / 1e6,
    Trims_PET.Export = Trims_PET.Export / 1e6,
    Trims_PES.Import = Trims_PES.Import / 1e6,
    Trims_PES.Export = Trims_PES.Export / 1e6
  ) |>
  mutate(
    Region = case_when(
      Region == "Netherlands" ~ "NL",
      TRUE ~ "EU"
    )
  ) |>
  pivot_longer(
    cols = starts_with("Trims_"),
    names_to = "data",
    values_to = "Mass_kt"
  ) |>
  mutate(Material = case_when(
    str_detect(data, "PET") ~ "PET",
    TRUE ~ "OTHER"
  )) |>
  mutate(data = case_when(
    str_detect(data, "Import") ~ "Trims_Import_kt",
    TRUE ~ "Trims_Export_kt"
  )) |>
  pivot_wider(names_from = data, values_from = Mass_kt)

trims_frac_of_mat <- All_import_export_production |>
  filter(Year %in% 2011:2022) |>
  filter(Material %in% c("OTHER", "PET"))|>
  left_join(trims_mass_per_category, by = c("Region", "Year", "Category", "Material")) |>
  filter(Region == "NL") |>
  select(-c(Export_kt, Trims_Export_kt, Production_kt)) |>
  mutate(fraction = Trims_Import_kt/Import_kt)

write.xlsx(trims_frac_of_mat, "Textile_input_update/Measure_1.xlsx")

##### Calculate input and TCs for low scenario
trims_frac_of_mat_low <- trims_frac_of_mat |>
  mutate(fraction_min = fraction*low_scenario_min,
         fraction_max = fraction*low_scenario_max) |>
  select(Region, Category, Material, fraction_min, fraction_max, Year)

All_import_export_production_low <- All_import_export_production|>
  left_join(trims_frac_of_mat_low) |>
  mutate(fraction_max = replace_na(fraction_max, 0),
         fraction_min = replace_na(fraction_min, 0)) |>
  mutate(fraction_max = 1-fraction_max,
         fraction_min = 1-fraction_min) |>
  mutate(Import_kt_min = fraction_min*Import_kt,
         Import_kt_max = fraction_max*Import_kt) 

##### Calculate fractions of import of clothing from inside and outside the EU + domestic production in NL
production_fraction_EU <- All_import_export_production_low |>
  filter(Region == "EU") |>
  group_by(Region, Year, Material) |>
  summarise(Import_kt= sum(Import_kt),
            Export_kt = sum(Export_kt), 
            Production_kt = sum(Production_kt)) |>
  mutate(production_fraction = Production_kt/(Production_kt + Import_kt))|>
  ungroup() |>
  select(Material, Year, production_fraction)

# Apply the calculated fractions to the NL import data
Import_NL <- All_import_export_production_low |>
  group_by(Region, Year, Material) |>
  summarise(Import_kt_min = sum(Import_kt_min),
            Import_kt_max = sum(Import_kt_max),
            Production_kt = sum(Production_kt),
            Export_kt = sum(Export_kt)) |>
  filter(Region == "NL") |>
  left_join(production_fraction_EU, by = c("Material", "Year")) |>
  filter(!is.na(production_fraction)) |>
  mutate(`Import of clothing (EU) min` = Import_kt_min*production_fraction,
         `Import of clothing (Global) min` = Import_kt_min*(1-production_fraction),
         `Import of clothing (EU) max` = Import_kt_max*production_fraction,
         `Import of clothing (Global) max` = Import_kt_max*(1-production_fraction)) |>
  select(Region, Year, Material, `Import of clothing (EU) min`, `Import of clothing (Global) min`,`Import of clothing (EU) max`, `Import of clothing (Global) max`) 

# Save Import/Export/Production data
Import_Export_Production_NL <- All_import_export_production_low |>
  group_by(Region, Year, Material) |>
  summarise(Import_kt_min = sum(Import_kt_min),
            Import_kt_max = sum(Import_kt_max),
            Production_kt = sum(Production_kt),
            Export_kt = sum(Export_kt)) |>
  #mutate(Export_kt = Export_kt*-1) |>
  filter(Region == "NL") |>
  left_join(production_fraction_EU, by = c("Material", "Year")) |>
  ungroup()|>
  mutate(Import_from_EU_min = Import_kt_min*production_fraction,
         Import_from_outside_EU_min = Import_kt_min-Import_from_EU_min,
         Import_from_EU_max = Import_kt_max*production_fraction,
         Import_from_outside_EU_max = Import_kt_max-Import_from_EU_max) |>
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
  mutate(Import_Production_kt_min = Import_kt_min + Production_kt,
         Import_Production_kt_max = Import_kt_max + Production_kt) |>
  filter(Year == 2022) |>
  filter(Region == "NL") |>
  group_by(Region, Year, Material) |>
  summarise(Import_Production_kt_min_sum = sum(Import_Production_kt_min),
            Import_Production_kt_max_sum = sum(Import_Production_kt_max))

material_fractions_source <- "https://eeb.org/library/draft-product-environmental-footprint-category-rules-pefcr-apparel-and-footwear/"

Consumption_to_categories_TCs_NL <- All_import_export_production_low |>
  mutate(
    Import_Production_kt_min = Import_kt_min + Production_kt,
    Import_Production_kt_max = Import_kt_max + Production_kt
  ) |>
  filter(Region == "NL", Year == 2022) |>
  left_join(total_import_production_mats, by = c("Region", "Year", "Material")) |>
  mutate(
    Mat_TC_min = Import_Production_kt_min / Import_Production_kt_min_sum,
    Mat_TC_max = Import_Production_kt_max / Import_Production_kt_max_sum
  ) |>
  pivot_longer(
    cols = c(Mat_TC_min, Mat_TC_max),
    names_to = "extreme",
    values_to = "Data"
  ) |>
  mutate(
    From = "Consumption",
    To = Category,
    `Geo NL` = 2,
    `Geo EU` = NA,
    Temp = 2,
    Mat = 1,
    Tech = 2,
    Rel = 3,
    Priority = 1,
    Scale = Region,
    Source = paste0(material_fractions_source, " - ", ifelse(extreme == "Mat_TC_min", "min", "max")),
    Comments = ""
  ) |>
  select(
    From, To, Scale, Material, Data, Priority, Source, `Geo NL`, `Geo EU`,
    Temp, Mat, Tech, Rel, Comments
  )

Categories_to_export_TCS <- All_import_export_production_low |>
  mutate(
    Import_Production_kt_min = Import_kt_min + Production_kt,
    Import_Production_kt_max = Import_kt_max + Production_kt
  ) |>
  filter(Region == "NL", Year == 2022) |>
  group_by(Region, Year, Category) |>
  summarise(
    Import_Production_kt_min = sum(Import_Production_kt_min, na.rm=TRUE),
    Import_Production_kt_max = sum(Import_Production_kt_max, na.rm=TRUE),
    Export_kt = sum(Export_kt, na.rm=TRUE)
  ) |>
  ungroup() |>
  mutate(
    Export_TC_min = Export_kt / Import_Production_kt_min,
    Export_TC_max = Export_kt / Import_Production_kt_max
  ) |>
  pivot_longer(
    cols = c(Export_TC_min, Export_TC_max),
    names_to = "extreme",
    values_to = "Data"
  ) |>
  mutate(
    From = Category,
    To = "Export",
    Material = "any",
    `Geo NL` = 1,
    `Geo EU` = NA,
    Temp = 1,
    Mat = 2,
    Tech = 2,
    Rel = 2,
    Scale = Region,
    Priority = 1,
    Source = paste0(input_data_source, " - ", ifelse(extreme == "Export_TC_min", "min", "max")),
    Comments = "TCs calculated for 2022 (most recent year with complete data)"
  ) |>
  select(
    From, To, Scale, Material, Data, Priority, Source, `Geo NL`, `Geo EU`,
    Temp, Mat, Tech, Rel, Comments
  )
calculated_TCs <- bind_rows(Consumption_to_categories_TCs_NL, Categories_to_export_TCS)

wb <- createWorkbook()

# Add worksheets to the workbook
addWorksheet(wb, "Calculated_TCs_NL_low")
addWorksheet(wb, "Import_export_production_NL_low")

Import_Export_Production_NL <- Import_Export_Production_NL |>
  filter(Material %in% c("OTHER", "PET"))

# Write the dataframes to the respective worksheets
writeData(wb, sheet = "Calculated_TCs_NL_low", Consumption_to_categories_TCs_NL)
writeData(wb, sheet = "Import_export_production_NL_low", Import_Export_Production_NL)

##### Calculate input and TCs for high scenario
trims_frac_of_mat_high <- trims_frac_of_mat |>
  mutate(fraction_min = fraction*high_scenario_min,
         fraction_max = fraction*high_scenario_max) |>
  select(Region, Category, Material, fraction_min, fraction_max, Year)

All_import_export_production_high <- All_import_export_production|>
  left_join(trims_frac_of_mat_high) |>
  mutate(fraction_max = replace_na(fraction_max, 0),
         fraction_min = replace_na(fraction_min, 0)) |>
  mutate(fraction_max = 1-fraction_max,
         fraction_min = 1-fraction_min) |>
  mutate(Import_kt_min = fraction_min*Import_kt,
         Import_kt_max = fraction_max*Import_kt) 

##### Calculate fractions of import of clothing from inside and outside the EU + domestic production in NL
production_fraction_EU <- All_import_export_production_high |>
  filter(Region == "EU") |>
  group_by(Region, Year, Material) |>
  summarise(Import_kt= sum(Import_kt),
            Export_kt = sum(Export_kt), 
            Production_kt = sum(Production_kt)) |>
  mutate(production_fraction = Production_kt/(Production_kt + Import_kt))|>
  ungroup() |>
  select(Material, Year, production_fraction)

# Apply the calculated fractions to the NL import data
Import_NL <- All_import_export_production_high |>
  group_by(Region, Year, Material) |>
  summarise(Import_kt_min = sum(Import_kt_min),
            Import_kt_max = sum(Import_kt_max),
            Production_kt = sum(Production_kt),
            Export_kt = sum(Export_kt)) |>
  filter(Region == "NL") |>
  left_join(production_fraction_EU, by = c("Material", "Year")) |>
  filter(!is.na(production_fraction)) |>
  mutate(`Import of clothing (EU) min` = Import_kt_min*production_fraction,
         `Import of clothing (Global) min` = Import_kt_min*(1-production_fraction),
         `Import of clothing (EU) max` = Import_kt_max*production_fraction,
         `Import of clothing (Global) max` = Import_kt_max*(1-production_fraction)) |>
  select(Region, Year, Material, `Import of clothing (EU) min`, `Import of clothing (Global) min`,`Import of clothing (EU) max`, `Import of clothing (Global) max`) 

# Save Import/Export/Production data
Import_Export_Production_NL <- All_import_export_production_high |>
  group_by(Region, Year, Material) |>
  summarise(Import_kt_min = sum(Import_kt_min),
            Import_kt_max = sum(Import_kt_max),
            Production_kt = sum(Production_kt),
            Export_kt = sum(Export_kt)) |>
  #mutate(Export_kt = Export_kt*-1) |>
  filter(Region == "NL") |>
  left_join(production_fraction_EU, by = c("Material", "Year")) |>
  ungroup()|>
  mutate(Import_from_EU_min = Import_kt_min*production_fraction,
         Import_from_outside_EU_min = Import_kt_min-Import_from_EU_min,
         Import_from_EU_max = Import_kt_max*production_fraction,
         Import_from_outside_EU_max = Import_kt_max-Import_from_EU_max) |>
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
  mutate(Import_Production_kt_min = Import_kt_min + Production_kt,
         Import_Production_kt_max = Import_kt_max + Production_kt) |>
  filter(Year == 2022) |>
  filter(Region == "NL") |>
  group_by(Region, Year, Material) |>
  summarise(Import_Production_kt_min_sum = sum(Import_Production_kt_min),
            Import_Production_kt_max_sum = sum(Import_Production_kt_max))

material_fractions_source <- "https://eeb.org/library/draft-product-environmental-footprint-category-rules-pefcr-apparel-and-footwear/"

Consumption_to_categories_TCs_NL <- All_import_export_production_high |>
  mutate(
    Import_Production_kt_min = Import_kt_min + Production_kt,
    Import_Production_kt_max = Import_kt_max + Production_kt
  ) |>
  filter(Region == "NL", Year == 2022) |>
  left_join(total_import_production_mats, by = c("Region", "Year", "Material")) |>
  mutate(
    Mat_TC_min = Import_Production_kt_min / Import_Production_kt_min_sum,
    Mat_TC_max = Import_Production_kt_max / Import_Production_kt_max_sum
  ) |>
  pivot_longer(
    cols = c(Mat_TC_min, Mat_TC_max),
    names_to = "extreme",
    values_to = "Data"
  ) |>
  mutate(
    From = "Consumption",
    To = Category,
    `Geo NL` = 2,
    `Geo EU` = NA,
    Temp = 2,
    Mat = 1,
    Tech = 2,
    Rel = 3,
    Priority = 1,
    Scale = Region,
    Source = paste0(material_fractions_source, " - ", ifelse(extreme == "Mat_TC_min", "min", "max")),
    Comments = ""
  ) |>
  select(
    From, To, Scale, Material, Data, Priority, Source, `Geo NL`, `Geo EU`,
    Temp, Mat, Tech, Rel, Comments
  )

Categories_to_export_TCS <- All_import_export_production_high |>
  mutate(
    Import_Production_kt_min = Import_kt_min + Production_kt,
    Import_Production_kt_max = Import_kt_max + Production_kt
  ) |>
  filter(Region == "NL", Year == 2022) |>
  group_by(Region, Year, Category) |>
  summarise(
    Import_Production_kt_min = sum(Import_Production_kt_min, na.rm=TRUE),
    Import_Production_kt_max = sum(Import_Production_kt_max, na.rm=TRUE),
    Export_kt = sum(Export_kt, na.rm=TRUE)
  ) |>
  ungroup() |>
  mutate(
    Export_TC_min = Export_kt / Import_Production_kt_min,
    Export_TC_max = Export_kt / Import_Production_kt_max
  ) |>
  pivot_longer(
    cols = c(Export_TC_min, Export_TC_max),
    names_to = "extreme",
    values_to = "Data"
  ) |>
  mutate(
    From = Category,
    To = "Export",
    Material = "any",
    `Geo NL` = 1,
    `Geo EU` = NA,
    Temp = 1,
    Mat = 2,
    Tech = 2,
    Rel = 2,
    Scale = Region,
    Priority = 1,
    Source = paste0(input_data_source, " - ", ifelse(extreme == "Export_TC_min", "min", "max")),
    Comments = "TCs calculated for 2022 (most recent year with complete data)"
  ) |>
  select(
    From, To, Scale, Material, Data, Priority, Source, `Geo NL`, `Geo EU`,
    Temp, Mat, Tech, Rel, Comments
  )
calculated_TCs <- bind_rows(Consumption_to_categories_TCs_NL, Categories_to_export_TCS)

# Add worksheets to the workbook
addWorksheet(wb, "Calculated_TCs_NL_high")
addWorksheet(wb, "Import_export_production_NL_h")

Import_Export_Production_NL <- Import_Export_Production_NL |>
  filter(Material %in% c("OTHER", "PET"))

# Write the dataframes to the respective worksheets
writeData(wb, sheet = "Calculated_TCs_NL_high", Consumption_to_categories_TCs_NL)
writeData(wb, sheet = "Import_export_production_NL_h", Import_Export_Production_NL)

# Save the workbook to a file
saveWorkbook(wb, "Textile_input_update/Calculated_input_and_TCs_Measure_1.xlsx", overwrite = TRUE)

