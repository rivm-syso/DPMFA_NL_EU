# Read all the runs via the xlsx files:
MitigationMeasureRuns <- list.files(path = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures",
           pattern = ".xlsx")

# Some stray Runs may exist, or ones not needed to recalculate
ExcludeRuns <- c("Indoor air","uncertainty","EU.xlsx","NL_v2.xlsx","Replace")

# Clean Runs
MitigationMeasureRuns <- 
  MitigationMeasureRuns [!str_detect(MitigationMeasureRuns, paste(ExcludeRuns, collapse = "|"))]

MitigationMeasureRuns <- gsub("\\.xlsx", "", MitigationMeasureRuns)

JobCommands <- paste0("bsub -n 1 -W 1200 -M 60G -R 'rusage[mem=4G]' -o CalcMassFlowOut.txt -e CalcMassFLowRrr.txt",
                     " python Calculate_mass_flows_",
                     MitigationMeasureRuns,
                     ".py")
JobCommand <- paste(JobCommands, collapse = " & ")
write(JobCommand, file = "/rivm/biogrid/hidsa/GitHub/DPMFA_Analysis/DPMFA_Analysis/DPMFA_NL_EU_measures/HPC_CalculateMassFlows.txt")

