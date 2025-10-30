# Load libraries
library(tidyverse)
library(ggplot2)
library(readxl)
library(writexl)

# Set working directory
setwd("/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Input_update")

# Load functions
source('Input_update_functions.R')

# Specify uncertainty fraction for high/low estimates 
uncertainty_fraction <- 0.10 

# Specify the source 
input_data_source <- "https://ec.europa.eu/eurostat/databrowser/view/DS-056120__custom_15192557/default/table?lang=en"

#### Calculate the total textile consumption per year for NL and EU

# Read in the import, export, production and unit data
import <- read_data("PRODCOM/Import.csv") |>
  rename(Import = Value)
export <- read_data("PRODCOM/Export.csv") |>
  rename(Export = Value)
production <- read_data("PRODCOM/Production.csv") |>
  rename(Production = Value)
units <- read_data("PRODCOM/Units.csv") |>
  rename(Unit = Value)

st_kg <- read_excel("PRODCOM/ST_to_KG.xlsx")

# Merge the data into one df
clothing_merged <- import |>
  left_join(export, by = c("Region", "Prodcom code", "Product_description", "Year")) |>
  left_join(production, by = c("Region", "Prodcom code", "Product_description", "Year")) |>
  left_join(units, by = c("Region", "Prodcom code", "Product_description", "Year")) |>
  left_join(st_kg, by = c("Prodcom code"), relationship = "many-to-many") |>
  mutate(`Conversion factor to kg` = case_when(
    Unit == "kg" ~ 1,
    TRUE ~ `Conversion factor to kg`
  )) |>
  select(-`Product description`) |>
  rename(Conversion_factor = `Conversion factor to kg`)

# Check if prodcom units are the same in the prodcom data and the conversion table
unit_diff <- clothing_merged |>
  filter(Unit != `Prodcom unit`)

# Check if any conversion fractions are missing
conversion_na <- clothing_merged |>
  filter(is.na(Conversion_factor))

# Convert the Prodcom units to kg
clothing_converted <- clothing_merged |>
  mutate(
    Import = replace_na(Import, 0),
    Export = replace_na(Export, 0),
    Production = replace_na(Production, 0)
  ) |>
  mutate(
    Import_kg = Import * Conversion_factor,
    Export_kg = Export * Conversion_factor,
    Production_kg = Production * Conversion_factor
  ) |>
  select(Region, `Prodcom code`, Product_description, Year, Import_kg, Export_kg, Production_kg) |>
  mutate(Consumption_kg = Import_kg + Production_kg - Export_kg) |>
  mutate(Consumption_kg = if_else(Consumption_kg < 0, 0, Consumption_kg)) |>
  distinct()

#### Calculate the fraction of synthetic textiles from the total consumption

# Read and transpose the fractions for apparel
apparel_mat_fractions <- read_excel("Material_composition_Quantis.xlsx", sheet = 1) |>
  slice(3:n()) |>
  pivot_longer(-`List of materials`, names_to = "Category", values_to = "Fraction") |>
  pivot_wider(names_from = `List of materials`, values_from = "Fraction")

colnames(apparel_mat_fractions) <- colnames(apparel_mat_fractions) |>
  str_replace_all(" ", "_") 

# Read and transpose the fractions for footwear
footwear_mat_fractions <- read_excel("Material_composition_Quantis.xlsx", sheet = 2) |>
  slice(3:n()) |>
  pivot_longer(-`List of materials`, names_to = "Category", values_to = "Fraction") |>
  pivot_wider(names_from = `List of materials`, values_from = "Fraction")

colnames(footwear_mat_fractions) <- colnames(footwear_mat_fractions) |>
  str_replace_all(" ", "_") 

# Read in the material categories for apparel
apparel_mat_categories <- read_excel("Apparel_material_categories.xlsx")

# Read in the material categories for footwear
footwear_mat_categories <- read_excel("Footwear_material_categories.xlsx")

# Add a column to the clothing_converted df to specify if the category is apparel or footwear
clothing_converted <- clothing_converted |>
  mutate(`Prodcom code` = as.character(`Prodcom code`)) |>
  mutate(category = case_when(
    str_starts(`Prodcom code`, '152') ~ "Footwear",
    TRUE ~ "Apparel"
  ))

# Make a separate df containing only apparel
apparel <- clothing_converted |>
  filter(category == "Apparel") |>
  left_join(apparel_mat_categories, by = c("Prodcom code", "Product_description")) |>
  left_join(apparel_mat_fractions, by = "Category")

# Make a separate df containing only footwear
footwear <- clothing_converted |>
  filter(category == "Footwear") |>
  left_join(footwear_mat_categories, by = c("Prodcom code", "Product_description")) |>
  left_join(footwear_mat_fractions, by = "Category")

# Calculate the masses of each material per category
apparel <- apparel |>
  mutate(Acryl_kg                          = Consumption_kg * Acrylic,
         Cashmere_and_camel_hair_kg        = Consumption_kg * Cashmere_and_camel_hair,
         Cotton_kg                         = Consumption_kg * Cotton,
         Duck_down_kg                      = Consumption_kg * Duck_down,
         Elastane_kg                       = Consumption_kg * Elastane,
         Fur_kg                            = Consumption_kg * Fur,
         Leather_kg                        = Consumption_kg * Leather,
         Linen_kg                          = Consumption_kg * Linen,
         Polyamide_kg                      = Consumption_kg * Polyamide,
         Polyamide_recycled_kg             = Consumption_kg * Polyamide_recycled,
         Polyester_and_other_synthetics_kg = Consumption_kg * Polyester_and_other_synthetics,
         Polyester_recycled_kg             = Consumption_kg * Polyester_recycled,
         PFTE_kg                           = Consumption_kg * PFTE,
         Silk_kg                           = Consumption_kg * Silk,
         Viscose_modal_lyocell_kg          = Consumption_kg * `Viscose/Modal/Lyocell`,
         Wool_kg                           = Consumption_kg * Wool,
         Trims_kg                          = Consumption_kg * Trims
  )

footwear <- footwear |>
  mutate(Cork_kg                           = Consumption_kg * Cork,
         Cotton_kg                         = Consumption_kg * Cotton,
         EVA_kg                            = Consumption_kg * EVA,
         Leather_kg                        = Consumption_kg * Leather,
         Metal_kg                          = Consumption_kg * Metal,
         Polyamide_kg                      = Consumption_kg * Polyamide,
         Polyester_and_other_synthetics_kg = Consumption_kg * Polyester_and_other_synthetics,
         Polyester_recycled_kg             = Consumption_kg * Polyester_recycled,
         Polyurethane_kg                   = Consumption_kg * Polyurethane,
         PVC_kg                            = Consumption_kg * PVC,
         Rubber_natural_kg                 = Consumption_kg * Rubber_natural,
         Rubber_synthetic_kg               = Consumption_kg * Rubber_synthetic,
         Thermoplastic_polyurethane_kg     = Consumption_kg * Thermoplastic_polyurethane,
         Viscose_modal_kg                  = Consumption_kg * `Viscose/Modal`,
         Wool_kg                           = Consumption_kg * Wool,
         Trims_kg                          = Consumption_kg * Trims
  )

# Summarise the data for each category and material
apparel_grouped <- apparel |>
  group_by(Region, Year, Category) |>
  summarise(Acryl_kg = sum(Acryl_kg),
            Cashmere_and_camel_hair_kg = sum(Cashmere_and_camel_hair_kg),
            Cotton_kg = sum(Cotton_kg),
            Duck_down_kg = sum(Duck_down_kg),
            Elastane_kg = sum(Elastane_kg),
            Fur_kg = sum(Fur_kg),
            Leather_kg = sum(Leather_kg),
            Linen_kg = sum(Linen_kg),
            Polyamide_kg = sum(Polyamide_kg),
            Polyamide_recycled_kg = sum(Polyamide_recycled_kg),
            Polyester_and_other_synthetics_kg = sum(Polyester_and_other_synthetics_kg),
            Polyester_recycled_kg = sum(Polyester_recycled_kg),
            PFTE_kg = sum(PFTE_kg),
            Silk_kg = sum(Silk_kg),
            Viscose_modal_lyocell_kg = sum(Viscose_modal_lyocell_kg),
            Wool_kg = sum(Wool_kg),
            Trims_kg = sum(Trims_kg))

footwear_grouped <- footwear |>
  group_by(Region, Year, Category) |>
  summarise(Cork_kg                           = sum(Cork_kg),
            Cotton_kg                         = sum(Cotton_kg),
            EVA_kg                            = sum(EVA_kg),
            Leather_kg                        = sum(Leather_kg),
            Metal_kg                          = sum(Metal_kg),
            Polyamide_kg                      = sum(Polyamide_kg),
            Polyester_and_other_synthetics_kg = sum(Polyester_and_other_synthetics_kg),
            Polyester_recycled_kg             = sum(Polyester_recycled_kg),
            Polyurethane_kg                   = sum(Polyurethane_kg),
            PVC_kg                            = sum(PVC_kg),
            Rubber_natural_kg                 = sum(Rubber_natural_kg),
            Rubber_synthetic_kg               = sum(Rubber_synthetic_kg),
            Thermoplastic_polyurethane        = sum(Thermoplastic_polyurethane_kg),
            Viscose_modal_kg                  = sum(Viscose_modal_kg),
            Wool_kg                           = sum(Wool_kg),
            Trims_kg                          = sum(Trims)
  )

# Format the data for the Maininputfile
apparel_mats <- colnames(apparel_grouped)
apparel_mats <- apparel_mats[4:20]

Apparel_formatted <- apparel_grouped |>
  pivot_longer(cols = apparel_mats, names_to = "Material", values_to = "Data (kg)") |>
  mutate(Material = str_remove(Material, "_kg")) |>
  filter(Material %in% c("Acryl", "Elastane", "Polyamide", "Polyamide_recycled", "Polyester_and_other_synthetics", "Polyester_recycled", "PFTE")) |>
  mutate(Material = case_when(
    Material == "Acryl" ~ "Acryl",
    Material == "Elastane" ~ "OTHER",
    Material == "Polyamide" ~ "PA",
    Material == "Polyamide_recycled" ~ "PA",
    Material == "Polyester_and_other_synthetics" ~ "PET",
    Material == "Polyester_recycled" ~ "PET",
    Material == "PFTE" ~ "OTHER",
    TRUE ~ Material
  )) |>
  mutate(Region = case_when(
    Region == "Netherlands" ~ "NL",
    TRUE ~ "EU"
  )) |>
  group_by(Region, Year, Material) |>
  summarise(`Data (kg)` = sum(`Data (kg)`)) |>
  mutate(`Data (kt)` = `Data (kg)`/1000000) |>
  select(-`Data (kg)`)

footwear_mats <- colnames(footwear_grouped)
footwear_mats <- footwear_mats[4:19]

footwear_formatted <- footwear_grouped |>
  pivot_longer(cols = footwear_mats, names_to = "Material", values_to = "Data (kg)") |>
  mutate(Material = str_remove(Material, "_kg")) |>
  filter(Material %in% c("EVA", "Polyamide", "Polyamide_recycled", "Polyester_and_other_synthetics", "Polyester_recycled", "Polyurethane", "PVC", "Rubber_synthetic", "Thermoplastic_polyurethane")) |>
  mutate(Material = case_when(
    Material == "EVA" ~ "OTHER",
    Material == "Polyamide" ~ "PA",
    Material == "Polyamide_recycled" ~ "PA",
    Material == "Polyester_and_other_synthetics" ~ "PET",
    Material == "Polyester_recycled" ~ "PET",
    Material == "Polyurethane" ~ "PUR",
    Material == "Rubber_synthetic" ~ "RUBBER",
    Material == "Thermoplastic_polyurethane" ~ "PUR",
    TRUE ~ Material
  )) |>
  mutate(Region = case_when(
    Region == "Netherlands" ~ "NL",
    TRUE ~ "EU"
  )) |>
  group_by(Region, Year, Material) |>
  summarise(`Data (kg)` = sum(`Data (kg)`)) |>
  mutate(`Data (kt)` = `Data (kg)`/1000000) |>
  select(-`Data (kg)`)

# Calculate high and low estimates for apparel and footwear 
Apparel_estimated <- Apparel_formatted |>
  mutate(HIGH = `Data (kt)`*(1+uncertainty_fraction)) |>
  mutate(LOW = `Data (kt)`*(1-uncertainty_fraction)) |>
  select(-`Data (kt)`) |>
  pivot_longer(cols = c("HIGH", "LOW"), names_to = "estimate", values_to = "Data (kt)") |>
  mutate(Source = paste0(estimate, " - ", input_data_source)) |>
  mutate(Compartment = "Clothing (product sector)",
         Geo = 1,
         Temp = 1,
         Tech = 2,
         Mat = 2,
         Rel = 2) |>
  select(Region, Compartment, Year, Material, `Data (kt)`, Source, Geo, Temp, Mat, Tech, Rel)

Footwear_estimated <- footwear_formatted |>
  mutate(HIGH = `Data (kt)`*(1+uncertainty_fraction)) |>
  mutate(LOW = `Data (kt)`*(1-uncertainty_fraction)) |>
  select(-`Data (kt)`) |>
  pivot_longer(cols = c("HIGH", "LOW"), names_to = "estimate", values_to = "Data (kt)") |>
  mutate(Source = paste0(estimate, " - ", input_data_source)) |>
  mutate(Compartment = "Clothing (product sector)",
         Geo = 1,
         Temp = 1,
         Tech = 2,
         Mat = 2,
         Rel = 2) |>
  select(Region, Compartment, Year, Material, `Data (kt)`, Source, Geo, Temp, Mat, Tech, Rel)

intersected_colnames <- intersect(colnames(Apparel_estimated), colnames(Footwear_estimated))
by_colnames <- setdiff(intersected_colnames, "Data (kt)")

# Make 1 df for Apparel + footwear
All_clothing <- Apparel_estimated |>
  left_join(Footwear_estimated, by = by_colnames) |>
  mutate(`Data (kt).x` = replace_na(`Data (kt).x`, 0)) |>
  mutate(`Data (kt).y` = replace_na(`Data (kt).y`, 0)) |>
  mutate(`Data (kt)` = `Data (kt).x` + `Data (kt).y`) |>
  select(Region, Compartment, Year, Material, `Data (kt)`, Source, Geo, Temp, Mat, Tech, Rel)

# Download the data to excel files
write_xlsx(Apparel_estimated, "Clothing_maininput.xlsx")
write_xlsx(Footwear_estimated, "Footwear_maininput.xlsx")
write_xlsx(All_clothing, "Clothing_plus_footwear_maininput.xlsx")

### Make figure comparing input methods
app_2019 <- Apparel_formatted |>
  filter(Year == 2019)

footwear_2019 <- footwear_formatted |>
  filter(Year == 2019) 

New_2019 <- bind_rows(app_2019, footwear_2019) |>
  group_by(Region, Year) |>
  summarise(`Data (kt)` = sum(`Data (kt)`)) |>
  mutate()

