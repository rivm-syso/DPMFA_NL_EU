PrepStatsEnvComp <- function(Clothing_data_all, # Full tibble/data frame with DPMFA output from PrepData
                                SelectionSources = ClothingSources, # The Sources in the data frame to consider (e.g. clothingsource only or also Footwear)
                                SelectionEnvSinks = c("air","water","soil"), # Options are "water, air, soil and none"
                                SelectYear = 2050){ # The year to provide the stats for
  ClothingYearSelect <- 
    c(names(Clothing_data_all)[!names(Clothing_data_all) %in% 
                                 c(names(Clothing_data_all) |> 
                                     as.numeric() |> 
                                     na.omit())],SelectYear)
  return(
    Clothing_data_all |>
      select(all_of(ClothingYearSelect)) |> 
      rename(Mass_Polymer_kt = paste0(SelectYear)) |> 
      mutate(Mass_Polymer_t = Mass_Polymer_kt * 1000, .keep = "unused") |> # conert kt to ton
      # filter(To_Compartment %in% SelectionSinks) |> # only environmental sinks
      mutate(`Environmental_compartment` = # make column indicating of this an air, water or soil sink.
               case_when(
                 str_detect(To_Compartment, 'water') ~ "water",
                 str_detect(To_Compartment, 'air') ~ "air",
                 str_detect(To_Compartment, 'soil') ~ "soil",
                 .default = "none"
               )) |>
      filter(`Environmental_compartment` %in% SelectionEnvSinks,
             From_compartment %in% c(SelectionSources)) |> 
      ungroup() |> 
      group_by(Scale,data_source,RUN,To_Compartment) |>
      summarise(totalout = sum(Mass_Polymer_t)) |> 
      ungroup() |> group_by(Scale,data_source,To_Compartment) |> 
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