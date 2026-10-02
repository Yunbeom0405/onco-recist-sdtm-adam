# Program : ex.R
# Purpose : SDTM EX, independent of the SAS program

source("r/sdtm/setup.R")
source("r/sdtm/derive.R")

ex <- read_src("ex") |>
  left_join(dm_ref, by = "USUBJID") |>
  mutate(
    EPOCH = epoch(EXSTDTC, RFXSTDTC, RFXENDTC),
    EXSTDY = study_day(EXSTDTC, RFSTDTC),
    EXENDY = study_day(EXENDTC, RFSTDTC)
  )

finalize(ex, "ex", "Exposure")
