# Program : ds.R
# Purpose : SDTM DS, independent of the SAS program

source("r/sdtm/setup.R")
source("r/sdtm/derive.R")

ds <- read_src("ds") |>
  left_join(dm_ref, by = "USUBJID") |>
  mutate(
    DSSPID = trimws(DSSPID),
    EPOCH = if_else(DSCAT == "PROTOCOL MILESTONE", "SCREENING", epoch(DSSTDTC, RFXSTDTC, RFXENDTC)),
    DSSTDY = study_day(DSSTDTC, RFSTDTC)
  )

finalize(ds, "ds", "Disposition")
