# Program : tr.R
# Purpose : SDTM TR, independent of the SAS program

source("r/sdtm/setup.R")
source("r/sdtm/derive.R")

tr <- read_src("tr_onco") |>
  visitfix("TRDTC", c(9.2, 9.2)) |>
  left_join(dm_ref, by = "USUBJID") |>
  mutate(
    .row = row_number(),
    .pre = predose(TRDTC, VISITNUM, RFXSTDTC),
    EPOCH = fepoch(TRDTC, .pre, RFXSTDTC, RFXENDTC),
    TRDY = study_day(TRDTC, RFSTDTC)
  )
tr$TRLOBXFL <- lobxfl(tr, "TRORRES", "TRDTC", c("TRLNKID", "TRTESTCD", "TREVAL", "TREVALID"))

finalize(tr, "tr", "Tumor/Lesion Results")
