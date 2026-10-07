# Program : dm.R
# Purpose : SDTM DM, independent of the SAS program

source("r/sdtm/setup.R")

dm <- read_src("dm") |>
  mutate(
    # screen failures: no arm
    across(c(ARMCD, ARM, ACTARMCD, ACTARM), \(x) if_else(is.na(ARMNRS), x, NA_character_)),
    DMDY = study_day(DMDTC, RFSTDTC)
  )

finalize(dm, "dm", "Demographics")
