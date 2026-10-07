# Program : tu.R
# Purpose : SDTM TU, independent of the SAS program

source("r/sdtm/setup.R")
source("r/sdtm/derive.R")

tu <- read_src("tu_onco") |>
  left_join(dm_ref, by = "USUBJID") |>
  mutate(
    .row = row_number(),
    .pre = predose(TUDTC, VISITNUM, RFXSTDTC),
    EPOCH = fepoch(TUDTC, .pre, RFXSTDTC, RFXENDTC),
    TUDY = study_day(TUDTC, RFSTDTC)
  )
tu$TULOBXFL <- lobxfl(tu, "TUORRES", "TUDTC", c("TULNKID", "TUTESTCD", "TUEVAL", "TUEVALID"))

finalize(tu, "tu", "Tumor/Lesion Identification")
