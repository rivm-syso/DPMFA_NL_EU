## Load the import, export and production data
read_data <- function(filename){
  
  # Read the data
  col_names <- read.csv(file = filename, nrows = 1, header = FALSE, stringsAsFactors = FALSE)
  df <- read.csv(file = filename, skip = 1, header = FALSE, stringsAsFactors = FALSE)
  colnames(df) <- col_names
  
  # Prepare the data by removing uneccesary columns
  df <- df |>
    select(decl, prccode, TIME_PERIOD, OBS_VALUE) |>
    rename(Region = decl) |>
    rename(Year = TIME_PERIOD) |>
    rename(Value = OBS_VALUE) |>
    mutate(Region = str_replace(Region, ".*?:", "")) |>
    separate(prccode, into = c("Prodcom code", "Product_description"), sep = ":")
  
  return(df)
}
