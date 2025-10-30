## Initialize

# Load libraries
library(tidyverse)
library(ggplot2)
library(readxl)
library(openxlsx)

# Set working directory
input_data_folder <- "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Input_update/"

# Load functions
source('Textile_input_update/Input_update_functions.R')

# Specify uncertainty fraction for high/low estimates 
uncertainty_fraction <- 0.10 

# Specify the source 
input_data_source <- "https://ec.europa.eu/eurostat/databrowser/view/DS-056120__custom_15192557/default/table?lang=en"

#### Calculate the total textile consumption per year for NL and EU

# Read in the import, export, production and unit data
import <- read_data(paste0(input_data_folder, "PRODCOM_clothing/Import.csv")) |>
  rename(Import = Value)
export <- read_data(paste0(input_data_folder, "PRODCOM_clothing/Export.csv")) |>
  rename(Export = Value)
production <- read_data(paste0(input_data_folder, "PRODCOM_clothing/Production.csv")) |>
  rename(Production = Value)
units <- read_data(paste0(input_data_folder, "PRODCOM_clothing/Units.csv")) |>
  rename(Unit = Value)

st_kg <- read_excel(paste0(input_data_folder, "PRODCOM_clothing/ST_to_KG.xlsx"))

# Read and transpose the fractions for footwear
footwear_mat_fractions <- read_excel(paste0(input_data_folder, "Material_composition_Quantis.xlsx"), sheet = 2) |>
  slice(3:n()) |>
  pivot_longer(-`List of materials`, names_to = "Category", values_to = "Fraction") |>
  pivot_wider(names_from = `List of materials`, values_from = "Fraction")

footwear_mat_categories <- read_excel(paste0(input_data_folder, "Footwear_material_categories.xlsx"))

#####

# Merge the data into one df
Footwear_merged <- import |>
  left_join(export, by = c("Region", "Prodcom code", "Product_description", "Year")) |>
  left_join(production, by = c("Region", "Prodcom code", "Product_description", "Year")) |>
  left_join(units, by = c("Region", "Prodcom code", "Product_description", "Year")) |>
  left_join(st_kg, by = c("Prodcom code"), relationship = "many-to-many") |>
  mutate(`Conversion factor to kg` = case_when(
    Unit == "kg" ~ 1,
    TRUE ~ `Conversion factor to kg`
  )) |>
  select(-`Product description`) |>
  rename(Conversion_factor = `Conversion factor to kg`) |>
  mutate(`Prodcom code` = as.character(`Prodcom code`)) |>
  mutate(category = case_when(
    str_starts(`Prodcom code`, '152') ~ "Footwear",
    TRUE ~ "Apparel"
  )) |>
  filter(category == "Footwear") |>
  filter(Year == 2022) |>
  filter(Region == "Netherlands") |>
  mutate(Production = replace_na(Production, 0))

## Calculate number of consumed pairs of footwear per category in NL
footwear_consumption_total <- Footwear_merged |>
  filter(category == "Footwear") |>
  left_join(footwear_mat_categories, by = c("Prodcom code", "Product_description")) |>
  group_by(Region, Year, category, Category)|>
  summarise(Import = sum(Import),
            Export = sum(Export),
            Production = sum(Production)) |>
  mutate(Consumption = (Production + Import - Export)) |>
  ungroup() |>
  select(Region, Year, Category, Consumption)

print(footwear_consumption_total)

## Calculate material fractions of RUBBER, PUR and EVA
sole_material_fractions <- footwear_mat_fractions |>
  select(Category, EVA, Polyurethane, PVC, `Rubber natural`, `Rubber synthetic`, `Thermoplastic polyurethane`) |>
  mutate(EVA_frac = EVA,
         PUR_frac = Polyurethane + `Thermoplastic polyurethane`,
         RUBBER_frac = `Rubber natural` + `Rubber synthetic`,
         PVC_frac = PVC,
         summed_fracs = PVC + EVA_frac + PUR_frac + RUBBER_frac,
         EVA_norm = EVA/summed_fracs,
         PUR_norm = PUR_frac/summed_fracs,
         RUBBER_norm = RUBBER_frac/summed_fracs,
         PVC_norm = PVC_frac/summed_fracs) |>
  select(Category, RUBBER_norm, PUR_norm, EVA_norm,  PVC_norm)

## Calculate total kt of RUBBER, PUR and EVA
footwear_consumption <- Footwear_merged |>
  mutate(Consumption = (Import + Production) - Export,
         Consumption_kg = Consumption * Conversion_factor) |>
  left_join(footwear_mat_categories, by = c("Prodcom code", "Product_description")) |>
  group_by(Region, Year, category, Category) |>
  summarise(Consumption_kg = sum(Consumption_kg)) |>
  ungroup() |>
  left_join(footwear_mat_fractions, by = "Category") 

# Calculate the masses of each material per category for each weight column
footwear_material_columns <- colnames(footwear_mat_fractions)[2:18]

footwear_consumption <- footwear_consumption |>
  rowwise() |> 
  mutate(across(all_of(footwear_material_columns), 
                .fns = ~ . * Consumption_kg,  # Corrected function
                .names = "{.col}.Consumption")) |>  # Corrected naming syntax
  ungroup()
  
footwear_colnames <- colnames(footwear_consumption)[23:39]
footwear_synthetic_materials <- c("EVA", "Polyamide", "Polyamide recycled", "Polyester and other synthetics", "Polyester recycled", "Polyurethane", "PVC", "Rubber synthetic", "Thermoplastic polyurethane")

# Calculate Import, Export and Production in kt per material and category
footwear_consumption_categories <- footwear_consumption |>
  select(-all_of(footwear_material_columns)) |>
  select(-"Consumption_kg") |>
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
  mutate(Consumption = Consumption/1000000) |>
  mutate(Material = case_when(
    Material == "Acrylic" ~ "Acryl",
    Material == "Elastane" ~ "OTHER",
    Material == "Polyamide" ~ "PA",
    Material == "Polyamide recycled" ~ "PA",
    Material == "Polyester and other synthetics" ~ "PET",
    Material == "Polyester recycled" ~ "PET",
    Material == "PFTE" ~ "OTHER",
    Material == "EVA" ~ "EVA",
    Material == "Polyamide" ~ "PA",
    Material == "Polyamide recycled" ~ "PA",
    Material == "Polyurethane" ~ "PUR",
    Material == "Rubber synthetic" ~ "RUBBER",
    Material == "Thermoplastic polyurethane" ~ "PUR",
    TRUE ~ Material
  )) |>
  group_by(Region, Year, Category, Material) |>
  summarise(Consumption = sum(Consumption))

# Total consumption per polymer
footwear_consumption_material <- footwear_consumption_categories |>
  group_by(Region, Year, Material) |>
  summarise(Consumption = sum(Consumption))

