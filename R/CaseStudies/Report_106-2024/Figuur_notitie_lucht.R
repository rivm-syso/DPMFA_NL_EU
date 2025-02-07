############################# Make PMFA report figures ##############################

# Initialize
library(ggplot2)
library(tidyverse)
library(scales)
library(openxlsx)

################################ Load data #####################################
# when working from DWO, we can use:

data_folder <-  "/rivm/r/E121554 LEON-T/03 - uitvoering WP3/DPMFA_output"

#"R:/Projecten/E121554 LEON-T/03 - uitvoering WP3/DPMFA_output"
ModelRun = "Baseline_PMFA_NL"

load(file = paste0(data_folder,"/",ModelRun,".RData"))  # (D)PMFA_inflow is read in

############################### inflows to long ################################

# Be careful, this makes a very big tibble
# TODO figure out how to use the nested tibble for making graphs
data_long <- 
  DPMFA_inflow |> unnest(Mass_Polymer_kt, keep_empty = TRUE) |> 
  pivot_longer(cols=-c(Type, Scale, Source, Polymer, To_Compartment, Material_Type, iD_source, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt")
data_long |> distinct(Material_Type)
###################### Dataframe manipulation for plots ########################

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
  ungroup() |> group_by(Source,Scale) |> summarise(TotalSinks = mean(totalout))

data_Year_sep_macro <- 
  data_Year |> filter(Material_Type == "micro") |> full_join(
    data_Year |> 
      filter(Material_Type == "macro") |> 
      ungroup() |> 
      group_by(Type   ,
               Scale,
               Polymer,
               To_Compartment,
               Material_Type,
               RUN,
               Year,
               Environmental_compartment) |> 
      summarise(Mass_Polymer_t = sum(Mass_Polymer_t),
                n=n(),
                IenW_Source = "Macroplastic",
                Source = "Macroplastic")
  )

# Figure of only macroplastics to see contributions from which sources.

############################# Prepare recycling data ###########################

outflow_data <- 
  DPMFA_outflow |> unnest(Mass_Polymer_kt, keep_empty = TRUE) |> 
  pivot_longer(cols=-c(Type, Scale, Source, Polymer, From_compartment, To_compartment, iD_source, RUN),
               names_to = "Year",
               values_to = "Mass_Polymer_kt")

# Create a dataframe for just 2019
data_Year_outflow <- outflow_data |>
  filter(Year == SelectYear) |>
  mutate(Mass_Polymer_t = Mass_Polymer_kt * 1000, .keep = "unused") |> # conert kt to ton
  mutate(IenW_Source = # aggregate inputs to the Major sources classes the study focusses on
           case_when(
             str_detect(Source, 'Clothing') ~ "Textile",
             str_detect(Source, 'Household textiles') ~ "Textile",
             str_detect(Source, 'Technical textiles') ~ "Textile", 
             str_detect(Source, 'Import of primary plastics') ~ "Pre-production pellets",
             str_detect(Source, 'Domestic primary plastic production') ~ "Pre-production pellets",
             .default = Source
           ))

# # Sum over polymers
# outflow_all_mat <- data_Year_outflow |>
#   group_by(Type, Scale, IenW_Source, Source, From_compartment, To_compartment, Year, RUN) |>
#   summarise(Mass_Polymer_t = sum(Mass_Polymer_t))

# Get the rows that contain recycling in the from compartment, all to_compartments coming from recycling are sinks
Recycling_data_subset <- data_Year_outflow |>
  filter(grepl("recycling", From_compartment)) |>
  mutate(IenW_Source = "Pre-production pellets")

# Group the recycling data together (so from comp is recycling, to is environmental compartments)
Recycling_data_grouped <- Recycling_data_subset |>
  group_by(Type, Scale, To_compartment, Year, RUN) |>
  summarise(Mass_Polymer_t = sum(Mass_Polymer_t)) |>
  mutate(From_compartment = "Recycling") 

# Make a table to save, by calculating the mean over runs
table <- Recycling_data_subset |>
  group_by(Type, Scale, From_compartment, To_compartment,Year) |>
  summarise(Mass_Polymer_t = mean(Mass_Polymer_t))

Recycling <- data_Year_outflow |>
  filter(grepl("recycling", To_compartment)) |>
  group_by(Type, Scale, From_compartment, To_compartment, Year, RUN) |>
  summarise(Mass_Polymer_t = sum(Mass_Polymer_t)) |> # sum over polymers for table
  ungroup() |>
  group_by(Type, Scale, From_compartment, To_compartment,Year) |> # sum over runs for table
  summarise(Mass_Polymer_t = mean(Mass_Polymer_t))

Recycling <-rbind(table, Recycling)

write.xlsx(Recycling, paste0(data_folder, "/Output_tables/Recycling_", ModelRun, ".xlsx"))

# Get other data, without the recycling data
non_recycling_data <- data_Year_outflow |>
  filter(!grepl("recycling", From_compartment)) 

# Make a df where the recycling emissions are attributed to pre-production pellets
#Recycling_data <- rbind(Recycling_data_grouped, non_recycling_data)

Recycling_data <- rbind(Recycling_data_subset, non_recycling_data)

# Get only the sink compartments
Recycling_data <- Recycling_data |>
  filter(To_compartment %in% unique(DPMFA_sink$To_Compartment)) |>
  mutate(`Environmental_compartment` = # make column indicating of this an air, water or soil sink.
           case_when(
             str_detect(To_compartment, 'water') ~ "water",
             str_detect(To_compartment, 'air') ~ "air",
             str_detect(To_compartment, 'soil') ~ "soil",
             .default = "none"
           )) |> filter(`Environmental_compartment` != "none") |> # remove sinks that are not environmental 
  separate_wider_delim(cols = To_compartment,
                       names = c("To_compartment", "Material_Type"),
                       delim = " (",
                       too_few = "align_start",
                       too_many = "merge",
                       cols_remove = FALSE) |> 
  mutate(Material_Type = str_remove(Material_Type , "\\)")) |>
  mutate(Material_Type = case_when(Material_Type %in% c('macro', 'micro') ~ as.character(Material_Type),
                                   TRUE ~ NA_character_))

################################### Figures ####################################
# Create a theme for the plots
plot_theme = theme(
  axis.title.x = element_text(size = 16),
  axis.text = element_text(size = 16), 
  axis.title.y = element_text(size = 16),
  axis.text.y = element_text(size = 16),
  axis.text.x = element_text(size = 16),
  axis.text.y.right =  element_text(size = 16),
  plot.background = element_rect(fill = 'white'),
  panel.background = element_rect(fill = 'white'),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  axis.line = element_line(color='black'),
  plot.margin = margin(2, 4, 2, 2, "cm")
  #panel.grid.major = element_line(colour = "grey",size=0.25)
)

# Define colors for groups
source_colors <- c(
  "Agriculture" = "#F8766D",
  "Clothing and home textiles" = "#E58700",
  "Intentionally produced microparticles" = "#C99800",
  "Macroplastic" = "#A3A500",
  "Packaging" = "#619cff",
  "Paint" = "#00BA38",
  "Pre-production pellets" = "#00C0AF",
  "Technical textiles" = "#00B0F6",
  "Textile" = "#B983FF",
  "Tyre wear" = "#ff67a4"
)

sink_colors <- c(
  "water" = "dodgerblue4",
  "air" = "slategray3",
  "soil" = "darkgoldenrod"
)

#### Make figure

Source_polymer_plastics_air <-
  data_Year_sep_macro |> 
  mutate(Source = case_when(
    Source == "Technical textiles" ~ "Textile",
    Source == "Household textiles (product sector)" ~ "Textile",
    Source == "Clothing (product sector)" ~ "Textile",
    TRUE ~ Source
  )) |>
  filter(To_Compartment == "Outdoor air (micro)") |>
  ungroup() |> 
  group_by(Scale, Polymer, Source, RUN, Year, Type, To_Compartment) |> 
  summarise(Mass_Polymer_t = sum(Mass_Polymer_t),
            countTest = n()) |> mutate(yfactor = paste(Source,Polymer,sep=".")) 


Source_emissions_plot <- ggplot(Source_polymer_plastics_air, aes(x = reorder(yfactor, Mass_Polymer_t), y = Mass_Polymer_t, fill=Polymer)) +
  geom_violin() +
  theme(legend.position="none")+
  scale_y_log10(labels = scales::number_format())+
  geom_text(aes(y=0.001, label = Polymer), vjust = "left")+
  labs(x = "Polymer", y = "Total plastic emissions (ton)") +                   # Adjust labels
  coord_flip() +
  plot_theme +
  
  facet_grid(vars(reorder(Source, -Mass_Polymer_t)),vars(),space = "free",scales="free")+
  theme(strip.text.y = element_text(angle = 0),
        panel.grid.major.x = element_line(colour = "black"),
        panel.grid.minor.x = element_line(colour = "grey",
                                          linetype = 1),
        panel.grid.major.y = element_line(colour = "grey",
                                          linetype = 2),
        axis.text.y=element_blank(),axis.ticks.y=element_blank()) +
  ggtitle("Emissions to outdoor air (micro)")

print(Source_emissions_plot)

ggsave(paste0("/Figures/Plots/",ModelRun,"source_polymer_emissions_air_",SelectYear,format(Sys.time(),'%Y%m%d'),".png"),
       path = data_folder,
       width = 15, height = 10)
