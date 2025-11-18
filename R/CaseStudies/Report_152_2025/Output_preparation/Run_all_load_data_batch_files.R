library(parallel)

# Zet het aantal cores
num_cores <- 4

# Haal alle script-bestanden op
script_files <- list.files("Output_analysis/batch_load_data_scripts", pattern = "\\.R$", full.names = TRUE)

# Functie om scripts veilig te runnen, met output logging
run_script_safe <- function(script_file) {
  tryCatch({
    # Logbestand per script
    log_file <- paste0(script_file, ".log")
    # Vang alle console output op
    out <- capture.output({
      # Optioneel: setwd naar werkdirectory (indien nodig)
      # setwd("/pad/naar/jouw/project")
      source(script_file, echo = TRUE)
    })
    # Schrijf output naar logbestand
    writeLines(out, log_file)
    return(list(file = script_file, success = TRUE))
  }, error = function(e) {
    write(
      paste(Sys.time(), "FAILED:", script_file, "Error:", e$message),
      file = "failed_scripts.txt",
      append = TRUE
    )
    return(list(file = script_file, success = FALSE, error = e$message))
  })
}

# Start cluster
cl <- makeCluster(num_cores)

# Zorg dat de workers in de juiste directory zitten
clusterExport(cl, "run_script_safe")
clusterEvalQ(cl, setwd(getwd()))

# Laad hier eventueel packages die je scripts nodig hebben:
# clusterEvalQ(cl, { library(dplyr); library(readr) })

# Run de scripts
results <- parLapply(cl, script_files, run_script_safe)

# Stop cluster
stopCluster(cl)

# Resultaten verwerken
success_list <- Filter(function(x) x$success, results)
fail_list    <- Filter(function(x) !x$success, results)

cat("Succesvol:", sapply(success_list, `[[`, "file"), sep = "\n")
cat("Mislukt:", sapply(fail_list, `[[`, "file"), sep = "\n")
