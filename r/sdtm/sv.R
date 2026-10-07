# Program : sv.R
# Purpose : SDTM SV, independent of the SAS program

source("r/sdtm/setup.R")
source("r/sdtm/derive.R")

sv <- read_src("sv") |>
  visitfix("SVSTDTC", c(9.1, 9.2)) |>
  left_join(dm_ref, by = "USUBJID") |>
  mutate(
    # planned visit: not an unscheduled one
    SVPRESP = if_else(startsWith(VISIT, "UNSCHEDULED"), NA_character_, "Y"),
    SVOCCUR = SVPRESP,
    EPOCH = epoch(SVSTDTC, RFXSTDTC, RFXENDTC),
    SVSTDY = study_day(SVSTDTC, RFSTDTC),
    SVENDY = study_day(SVENDTC, RFSTDTC)
  )

finalize(sv, "sv", "Subject Visits")
