# Function for processing data

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

sink_Environmental <- c("Agricultural soil",
                        "Natural soil",
                        "Residential soil",
                        "Road side soil",
                        "Surface water",
                        "Outdoor air",
                        "Sub-surface soil",
                        "Sea water")

SelectionSources = ClothingSources
SelectionSinks = sink_Environmental

FunPrepStats <- function(Clothing_data_all,
                         SelectionSources,
                         SelectionSinks,
                         SelectYear){
  return(  
    Clothing_data_all |>
      filter(Year == SelectYear) |> # check, will be different
      mutate(Mass_Polymer_t = Mass_Polymer_kt * 1000, .keep = "unused") |> # conert kt to ton
      filter(To_Compartment %in% SelectionSinks) |> # only environmental sinks
      # mutate(`Environmental_compartment` = # make column indicating of this an air, water or soil sink.
      #          case_when(
      #            str_detect(To_Compartment, 'water') ~ "water",
      #            str_detect(To_Compartment, 'air') ~ "air",
      #            str_detect(To_Compartment, 'soil') ~ "soil",
      #            .default = "none"
      #          )) |> 
      filter(`Environmental_compartment` != "none",
             From_compartment %in% c(SelectionSources)) |> 
      ungroup() |> 
      group_by(Scale,data_source,RUN) |>
      summarise(totalout = sum(Mass_Polymer_t)) |> 
      ungroup() |> group_by(Scale) |> 
      summarise(Mean_mass_t = mean(totalout),
                min_t = min(totalout),
                p5_t =quantile(totalout,probs = 0.05),
                p25_t =quantile(totalout,probs = 0.25),
                p50_t =quantile(totalout,probs = 0.50),
                p75_t =quantile(totalout,probs = 0.75),
                p95_t =quantile(totalout,probs = 0.95),
                max_t = max(totalout),
                n = n())
  )
  
}

