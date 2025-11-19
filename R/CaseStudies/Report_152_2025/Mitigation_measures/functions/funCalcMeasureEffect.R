CalcClothOverviewEffect <- function(ClothingStatsOverview,
                                    AggrComponents = c("Scale")){
  # browser()
  
  MeasuresClothingStats <- ClothingStatsOverview |>
    filter(data_source == "Baseline") |>
    rename_with(~paste0("baseline_", .),
                -all_of(AggrComponents)
    ) |> right_join(ClothingStatsOverview ) |> filter(data_source != "Baseline") |> ungroup() |> 
    select(-baseline_data_source)
  
  # Calculate prevented emissions
  MeasuresClothingStats <- MeasuresClothingStats |>
    mutate(
      diff_Mean_mass_t = Mean_mass_t - baseline_Mean_mass_t,
      diff_min_t = min_t - baseline_min_t,
      diff_p5_t = p5_t - baseline_p5_t,
      diff_p25_t = p25_t - baseline_p25_t,
      diff_p50_t = p50_t - baseline_p50_t,
      diff_p75_t = p75_t - baseline_p75_t,
      diff_p95_t = p95_t - baseline_p95_t,
      diff_max_t = max_t - baseline_max_t
    ) 
  
  MeasuresClothingStats <-
    MeasuresClothingStats |> mutate(
      scenario = case_when(
        grepl("high", data_source, ignore.case = TRUE) ~ "high",
        grepl("low", data_source, ignore.case = TRUE) ~ "low",
        TRUE ~ NA_character_  # of bijvoorbeeld "other"
      ),
      Measure = str_trim(str_remove(data_source, regex(" high| low", ignore_case = TRUE)))
    )
  
  subDiff <- MeasuresClothingStats  %>%
    select(!c(starts_with("baseline"),Mean_mass_t:n)) |> 
    pivot_longer(
      cols = starts_with("diff"),
      names_to = "statistics",
      values_to = "Reduced MassFlow (t)",
      names_transform = list(statistics = ~sub("^(diff_)","", .x))
    ) #|> 
  #mutate(Calculation = "MeasureDiff")
  
  subMeasure <- MeasuresClothingStats  %>%
    select(!c(starts_with("baseline"),starts_with("diff"),n)) |> 
    pivot_longer(
      cols =  c(Mean_mass_t:max_t),
      names_to = "statistics",
      values_to = "Measure MassFlow (t)"
    ) #|> 
  #mutate(Calculation = "Measure")
  
  subBaseline <- MeasuresClothingStats  %>%
    select(!c(starts_with("diff"),Mean_mass_t:n,baseline_n)) |> 
    pivot_longer(
      cols = starts_with("baseline"),
      names_to = "statistics",
      values_to = "Baseline MassFlow (t)",
      names_transform = list(statistics = ~sub("^(baseline_)","", .x))
    )# |> 
  # mutate(Calculation = "Baseline")
  
  MeasuresClothingStatsL <- 
    subDiff |> 
    full_join(subMeasure) |> 
    full_join(subBaseline)
  
  return(MeasuresClothingStatsL)
}
