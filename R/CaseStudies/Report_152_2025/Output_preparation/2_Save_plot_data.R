library(tidyverse)
library(ggplot2)

data_folder <- "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Output/"
#data_folder <- "~/my_biogrid/Rdata_files"

selectyear <- 2022

# Define the names of the source compartments
source_compartments <- c(
  "Clothing (product sector)", # This compartment is not an input compartment, but gets inflow from import and production 
  "Intentionally produced microparticles",
  "Tyre wear",
  'Domestic primary plastic production', 
  'Import of primary plastics', 
  "Agriculture",
  "Paint",
  "Technical textiles",
  "Packaging",
  "Household textiles (product sector)")

# Define the names of clothing categories
clothing_category_compartments <- c(
  "Apparel accessories",
  "Boots",
  "Closed-toed shoes",
  "Dresses skirts and jumpsuits",
  "Jackets and coats",
  "Leggings stockings tights and socks",
  "Open-toed shoes",
  "Pants and shorts",
  "Shirts and blouses",
  "Sweaters and midlayers",
  "Swimwear",
  "T-shirts",
  "Underwear"
)

clothing <- c(
  "Apparel accessories",
  "Dresses skirts and jumpsuits",
  "Jackets and coats",
  "Leggings stockings tights and socks",
  "Pants and shorts",
  "Shirts and blouses",
  "Sweaters and midlayers",
  "Swimwear",
  "T-shirts",
  "Underwear"
)

footwear <- c(
  "Boots",
  "Closed-toed shoes",
  "Open-toed shoes"
)

# Define the names of recycling compartments
textile_recycling_compartments <- c(
  "Clothing waste collection",
  "Home textile waste collection",
  "Technical textile waste collection",
  "Footwear waste collection",
  "Manufacturing of clothing"
)

recycling_from_compartments <- c(
  "Agricultural plastic recycling",
  "Packaging recycling",
  "Textile recycling"
)

agricultural_waste_col_from_compartments <- c(
  "Agriculture",
  "Intentionally produced microparticles",
  "Technical textiles",
  "Packaging"
)

sink_compartments <- c("Agricultural soil",
                       "Natural soil",
                       "Residential soil",
                       "Road side soil",
                       "Surface water",
                       "Outdoor air",
                       "Sub-surface soil" )

##### Load data
data_date <- "2025_07_24"

load(paste0(data_folder, "/PMFA_calculated_mass_flows_NL", data_date, ".RData"))

PMFA_NL_new <- DPMFA_calculatedMassFlow |> 
  select(-iD_source) |>
  select(-To_compartment) |>
  distinct()

##### Divide emissions from textile recycling between clothing, home textiles and technical textiles

# Get the textile recycling data 
textile_waste_dist <- PMFA_NL_new |>
  filter(From_compartment %in% textile_recycling_compartments) |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt") |>
  filter(Year != 1950)

# Calculate the total mass to textile waste collection per RUN, Year and Polymer
textile_waste_total <- textile_waste_dist |>
  group_by(Type, Scale, Polymer, To_Compartment, Material_Type, RUN, Year) |>
  summarise(Mass_Polymer_kt = sum(Mass_Polymer_kt)) |>
  ungroup()

# Calculate the fraction that goes from a textile source to textile waste collection
textile_waste_fractions <- textile_waste_dist |>
  left_join(textile_waste_total, by = c("Type", "Scale", "Polymer", "To_Compartment", "Material_Type", "RUN", "Year")) |>
  mutate(Textile_waste_collection_frac = Mass_Polymer_kt.x/Mass_Polymer_kt.y) |>
  select(-Mass_Polymer_kt.x) |>
  select(-Mass_Polymer_kt.y) 

# Check if the fractions add up to 1
frac_check <- textile_waste_fractions |>
  group_by(Type, Scale, Polymer, To_Compartment, Material_Type, RUN, Year) |>
  summarise(Textile_waste_collection_frac = sum(Textile_waste_collection_frac))

if(any(round(frac_check$Textile_waste_collection_frac, 10) != 1)){
  warning("Not all fractions add up to 1")
}

# Filter the emissions from recycling compartments to sinks from the original dataset
recycling_emissions <- PMFA_NL_new |>
  filter(From_compartment %in% recycling_from_compartments) |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(
    cols = -c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
    names_to = "Year",
    values_to = "Mass_Polymer_kt"
  ) |>
  filter(Year != 1950)

# Join the Textile recycling masses to sinks to the fractions calculated earlier per textile type
textile_recycling_emissions <- recycling_emissions |>
  filter(From_compartment == "Textile recycling") 

textile_recycling_emissions_joined <- textile_recycling_emissions |>
  left_join(
    textile_waste_fractions,
    by = c("Type", "Scale", "Polymer", "From_compartment" = "To_Compartment", 
            "RUN", "Year")
    , relationship = "many-to-many") |>
  rename(Textile_compartment = From_compartment.y,
         Material_Type = Material_Type.x) |>
  mutate(Mass_Polymer_kt = Mass_Polymer_kt*Textile_waste_collection_frac) |>
  mutate(From_compartment = case_when(
    Textile_compartment == "Clothing waste collection" ~ "Clothing recycling",
    Textile_compartment == "Home textile waste collection" ~ "Home textile recycling",
    Textile_compartment == "Technical textile waste collection" ~ "Technical textile recycling",
    Textile_compartment == "Footwear waste collection" ~ "Footwear recycling"
  )) |>
  select(-Textile_compartment) |>
  select(-Textile_waste_collection_frac) |>
  select(-Material_Type.y)

# Make a df with the other emissions originating from recycling
agriculture_and_packaging_recycling <- recycling_emissions |>
  filter(From_compartment != "Textile recycling")

# Bind all recycling data back into one dataframe
textile_recycling_emissions <- textile_recycling_emissions_joined |>
  mutate(From_compartment = case_when(
    From_compartment == "Clothing recycling" ~ "Clothing (product sector)",
    From_compartment == "Home textile recycling" ~ "Home textiles (product sector)",
    From_compartment == "Technical textile recycling" ~ "Technical textiles",
    From_compartment == "Footwear recycling" ~ "Clothing (product sector)", 
    TRUE ~ From_compartment
  )) |>
  rename(Recycling_mass_kt = Mass_Polymer_kt)

##### Divide emissions from agricultural plastic recycling between agriculture, packaging, intentionally produced microparticles and technical textiles
# Step 1: Filter for relevant data related to agricultural plastic recycling
agricultural_data <- PMFA_NL_new |>
  filter(From_compartment %in% agricultural_waste_col_from_compartments) |>
  filter(To_Compartment == "Agricultural plastic recycling") |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(
    cols = -c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
    names_to = "Year",
    values_to = "Mass_Polymer_kt"
  ) |>
  filter(Year != 1950)

# Step 2: Calculate the total mass polymer for each group and determine the fraction
agricultural_with_fractions <- agricultural_data |>
  group_by(Scale, To_Compartment, Polymer, RUN, Year, Material_Type) |>
  mutate(
    Mass_Polymer_kt_total = sum(Mass_Polymer_kt, na.rm = TRUE),
    contribution_fraction = Mass_Polymer_kt / Mass_Polymer_kt_total  # Calculate fraction
  ) |>
  ungroup()

# Step 3: Validate if contribution fractions add up to 1
# Summing up fractions for each group to check if they equal 1
contribution_validation <- agricultural_with_fractions |>
  group_by(Scale, To_Compartment, Polymer, RUN, Year, Material_Type) |>
  summarise(contribution_fraction_sum = sum(contribution_fraction, na.rm = TRUE)) |>
  ungroup()

# Check if any group fails the condition (fractions not summing to 1)
failed_fractions <- contribution_validation |>
  filter(abs(contribution_fraction_sum - 1) > 1e-15)  # Use tolerance for floating-point comparisons

# Print a warning if any group has issues
if (nrow(failed_fractions) > 0) {
  warning("Some contribution fractions do not add up to 1!")
  print(failed_fractions)  # Print the problematic groups
}

# Step 4: Join fractions back with the emissions data and calculate recycling emissions
agricultural_recycling_emissions <- agricultural_with_fractions |>
  left_join(
    agriculture_and_packaging_recycling |> 
      filter(From_compartment == "Agricultural plastic recycling"),
    by = c(
      "Type" = "Type",
      "Scale" = "Scale",
      "To_Compartment" = "From_compartment",
      "Polymer" = "Polymer",
      "Material_Type" = "Material_Type",
      "RUN" = "RUN",
      "Year" = "Year"
    ), relationship = "many-to-many"
  ) |>
  # Step 5: Reallocate the emissions based on the contribution fraction
  mutate(Recycling_mass_kt = contribution_fraction * Mass_Polymer_kt.y) |>
  select(-c(To_Compartment, Mass_Polymer_kt.y, Mass_Polymer_kt.x, Mass_Polymer_kt_total, contribution_fraction)) |>
  rename(To_Compartment = To_Compartment.y)

##### Divide emissions from agricultural plastic recycling between agriculture, intentionally produced microparticles and technical textiles
agricultural_recycling_dist <- PMFA_NL_new |> 
  filter(From_compartment %in% agricultural_waste_col_from_compartments) |> 
  filter(To_Compartment == "Agricultural plastic recycling")|> 
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN), names_to = "Year", values_to = "Mass_Polymer_kt") |>
  filter(Year != 1950)

agricultural_recycling_total <- agricultural_recycling_dist |> 
  group_by(Scale, To_Compartment, Polymer, RUN, Year, Material_Type) |> 
  summarise(Mass_Polymer_kt_total = sum(Mass_Polymer_kt)) 

agricultural_recycling_joined <- agricultural_recycling_dist |> 
  left_join(agricultural_recycling_total, by = c("Scale", "To_Compartment", "Polymer", "Material_Type", "RUN", "Year")) |>
  mutate(contribution_fraction = Mass_Polymer_kt/Mass_Polymer_kt_total) |>
  select(-Mass_Polymer_kt) |> 
  select(-Mass_Polymer_kt_total) 

agricultural_plastic_recycling_emissions <- agriculture_and_packaging_recycling |> 
  filter(From_compartment == "Agricultural plastic recycling") 

agricultural_recycling_emissions <- agricultural_plastic_recycling_emissions |> 
  left_join(agricultural_recycling_joined, by = c(
    "Type" = "Type", 
    "Scale" = "Scale",
    "From_compartment" = "To_Compartment", 
    "Polymer" = "Polymer", 
    "RUN" = "RUN", 
    "Year" = "Year" ), relationship = "many-to-many"
  ) |>
  mutate(Mass_Polymer_kt = contribution_fraction * Mass_Polymer_kt) |> 
  select(-From_compartment) |> 
  rename(From_compartment = From_compartment.y) |> 
  select(-contribution_fraction)|> 
  rename(Recycling_mass_kt = Mass_Polymer_kt) |>
  select(-Material_Type.y) |>
  rename(Material_Type = Material_Type.x)

##### Packaging recycling emissions
packaging_recycling_emissions <- agriculture_and_packaging_recycling |>
  filter(From_compartment == "Packaging recycling")|>
  rename(Recycling_mass_kt = Mass_Polymer_kt) |>
  mutate(From_compartment = "Packaging")

##### Bind all emissions from recycling together again
all_recycling_emissions <- rbind(textile_recycling_emissions, agricultural_recycling_emissions, packaging_recycling_emissions)

##### Get the sources to sinks data

source_to_sinks_NL_new <- PMFA_NL_new |>
  filter(From_compartment %in% source_compartments) |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt") |>
  #filter(Year == selectyear) |>
  mutate(From_compartment = case_when(
    From_compartment == 'Domestic primary plastic production' ~ "Pre-production pellets",
    From_compartment == 'Import of primary plastics' ~ "Pre-production pellets",
    TRUE ~ From_compartment
  )) |>
  group_by(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, Year, RUN) |>
  summarise(Mass_Polymer_kt = sum(Mass_Polymer_kt)) |>
  filter(Year != 1950)

##### Assign emissions during recycling to pre-production pellets and subtract them from original sources

# Sum recycling data and emissions per source over polymers
source_to_sinks_data <- source_to_sinks_NL_new |>
  group_by(Type, Scale, From_compartment, To_Compartment, Material_Type, Year, RUN) |>
  summarise(Mass_Polymer_kt = sum(Mass_Polymer_kt)) |>
  ungroup()

all_recycling <- all_recycling_emissions |>
  group_by(Type, Scale, From_compartment, To_Compartment, Material_Type, Year, RUN) |>
  summarise(Recycling_mass_kt = sum(Recycling_mass_kt)) |>
  ungroup()

# Subtract the recycling emission from the emissions of their original compartments
source_to_sinks_data_joined <- source_to_sinks_data |>
  left_join(all_recycling, by = c("Type", "Scale", "From_compartment", "To_Compartment", "Material_Type", "RUN", "Year")) |>
  mutate(Recycling_mass_kt = replace_na(Recycling_mass_kt, 0)) |>
  mutate(Corrected_mass_Polymer_kt = Mass_Polymer_kt - Recycling_mass_kt) |>
  select(-Mass_Polymer_kt) |>
  select(-Recycling_mass_kt) |>
  rename(Mass_Polymer_kt = Corrected_mass_Polymer_kt)

# Check for any negative masses 
sts_below_zero <- source_to_sinks_data_joined |>
  filter(round(Mass_Polymer_kt, 10) < 0)

if(!nrow(sts_below_zero) == 0){
  warning("Some contribution masses are negative! Please check.")
  print(sts_below_zero)
}

# Sum all recycling emissions together 
total_recycling <- all_recycling |>
  group_by(Type, Scale, To_Compartment, Material_Type, Year, RUN) |>
  summarise(Mass_Polymer_kt = sum(Recycling_mass_kt)) |>
  mutate(From_compartment = "Pre-production pellets")

data_relocated_recycling <- rbind(source_to_sinks_data_joined, total_recycling) |>
  group_by(Type, Scale, From_compartment, To_Compartment, Material_Type, Year, RUN) |>
  summarise(Mass_Polymer_kt = sum(Mass_Polymer_kt)) |>
  mutate(From_compartment = case_when(
    From_compartment == "Clothing (product sector)" ~ "Clothing and footwear",
    From_compartment == "Household textiles (product sector)" ~ "Home textiles",
    TRUE ~ From_compartment
  )) 

sources_to_sinks <- data_relocated_recycling |>
  filter(To_Compartment %in% sink_compartments)

##### Emissions from clothing categories without recycling emissions
 
clothing_compartments_to_sinks <- PMFA_NL_new |>
  filter(From_compartment %in% clothing_category_compartments) |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt") |>
  filter(To_Compartment %in% sink_compartments) |>
  filter(Year != 1950)

##### Clothing
clothing_product_sector_to_clothing_categories <- PMFA_NL_new |>
  filter(From_compartment == "Clothing (product sector)") |>
  filter(To_Compartment %in% clothing) |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt") |>
  filter(Year != 1950)

clothing_total <- PMFA_NL_new |>
  filter(From_compartment == "Clothing (product sector)") |>
  filter(To_Compartment %in% clothing) |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt") |>
  group_by(From_compartment, RUN, Year, Scale, Type, Material_Type, Polymer) |>
  summarise(Total_mass_Polymer_kt = sum(Mass_Polymer_kt))|>
  filter(Year != 1950)

clothing_categories_fractions <- clothing_product_sector_to_clothing_categories |>
  left_join(clothing_total, by = c("Type", "Scale", "From_compartment", "Material_Type", "RUN", "Year", "Polymer")) |>
  mutate(recycling_emission_fraction = Mass_Polymer_kt/Total_mass_Polymer_kt) |>
  mutate(From_compartment = "Clothing recycling") |>
  select(-c(Mass_Polymer_kt, Total_mass_Polymer_kt)) |>
  rename(Category = To_Compartment) |>
  select(-Material_Type) 

clothing_recycling_emissions <- textile_recycling_emissions_joined |>
  filter(From_compartment == "Clothing recycling") |>
  left_join(clothing_categories_fractions, by = c("Type", "Scale", "From_compartment", "RUN", "Polymer", "Year"), relationship = "many-to-many") |>
  mutate(Mass_Polymer_kt = Mass_Polymer_kt * recycling_emission_fraction) |>
  rename(Emission_from = From_compartment,
         From_compartment = Category)

clothing_non_recycling_emissions <- clothing_compartments_to_sinks |>
  left_join(clothing_recycling_emissions, by = c("Type", "Scale", "From_compartment", "To_Compartment", "RUN", "Polymer", "Year", "Material_Type"), relationship = "many-to-many") |>
  mutate(Mass_Polymer_kt.y = replace_na(Mass_Polymer_kt.y, 0),
         recycling_emission_fraction = replace_na(recycling_emission_fraction,0)) |>
  mutate(Mass_Polymer_kt_recycling = Mass_Polymer_kt.y*recycling_emission_fraction) |>
  mutate(Mass_Polymer_kt_without_recycling = Mass_Polymer_kt.x-Mass_Polymer_kt_recycling)


# 
# summed_fractions_clothing <- clothing_recycling_emissions |>
#   group_by(Type, Scale, From_compartment, To_Compartment, RUN, Year, Polymer) |>
#   summarise(recycling_emission_fraction = sum(recycling_emission_fraction))

### Footwear
clothing_product_sector_to_footwear_categories <- PMFA_NL_new |>
  filter(From_compartment == "Clothing (product sector)") |>
  filter(To_Compartment %in% footwear) |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt")|>
  filter(Year != 1950)

footwear_total <- PMFA_NL_new |>
  filter(From_compartment == "Clothing (product sector)") |>
  filter(To_Compartment %in% footwear) |>
  unnest(cols = c(Mass_Polymer_kt)) |>
  pivot_longer(cols=-c(Type, Scale, Polymer, From_compartment, To_Compartment, Material_Type, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt") |>
  group_by(From_compartment, RUN, Year) |>
  summarise(Total_mass_Polymer_kt = sum(Mass_Polymer_kt))|>
  filter(Year != 1950)

footwear_categories_fractions <- clothing_product_sector_to_footwear_categories |>
  left_join(clothing_total, by = c("Type", "Scale", "From_compartment", "Material_Type", "RUN", "Year", "Polymer")) |>
  mutate(recycling_emission_fraction = Mass_Polymer_kt/Total_mass_Polymer_kt) |>
  mutate(From_compartment = "Footwear recycling") |>
  select(-c(Mass_Polymer_kt, Total_mass_Polymer_kt)) |>
  rename(Category = To_Compartment) |>
  select(-Material_Type)

footwear_recycling_emissions <- textile_recycling_emissions_joined |>
  filter(From_compartment == "Footwear recycling") |>
  left_join(footwear_categories_fractions, by = c("Type", "Scale", "From_compartment", "RUN", "Polymer", "Year"), relationship = "many-to-many") |>
  mutate(Mass_Polymer_kt = Mass_Polymer_kt * recycling_emission_fraction) |>
  rename(Emission_from = From_compartment,
         From_compartment = Category) 

#### Corrected emissions from clothing categories
all_clothing_recycling_emissions <- rbind(clothing_recycling_emissions, footwear_recycling_emissions) |>
  select(-recycling_emission_fraction)

clothing_category_emissions_corrected <- clothing_compartments_to_sinks |>
  left_join(all_clothing_recycling_emissions, by = c("Type", "Scale", "From_compartment", "To_Compartment", "Material_Type", "RUN", "Polymer", "Year"), suffix = c("_original", "_recycling")) |>
  mutate(Mass_Polymer_kt_recycling = replace_na(Mass_Polymer_kt_recycling, 0)) |>
  mutate(Mass_Polymer_kt = Mass_Polymer_kt_original-Mass_Polymer_kt_recycling)

clothing_below_zero <- clothing_category_emissions_corrected |>
  filter(Mass_Polymer_kt < 0)






data_folder <- "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_textiel/Output"

if (modeltype == "dpmfa"){
  save(sources_to_sinks, clothing_category_emissions_corrected, all_clothing_recycling_emissions,
       file = paste0(data_folder,"/DPMFA_plot_data_", region, format(ModelRunDate,"%Y_%m_%d"),".RData"),
       compress = "xz",
       compression_level = 9)   
} else {
  save(sources_to_sinks, clothing_category_emissions_corrected, all_clothing_recycling_emissions,
       file = paste0(data_folder,"/PMFA_plot_data_", region, format(ModelRunDate,"%Y_%m_%d"),".RData"),
       compress = "xz",
       compression_level = 9)  
}



