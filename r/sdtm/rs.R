# Program : rs.R
# Purpose : SDTM RS, independent of the SAS program

source("r/sdtm/setup.R")
source("r/sdtm/derive.R")

rs <- read_src("rs_onco") |>
  visitfix("RSDTC", c(9.2, 9.2)) |>
  left_join(dm_ref, by = "USUBJID") |>
  mutate(
    # placeholder value in source, not a response
    chk = RSORRES %in% "CHECK",
    RSORRES = if_else(chk, NA_character_, RSORRES),
    RSSTRESC = if_else(chk, NA_character_, RSSTRESC),
    RSSTAT = if_else(chk, "NOT DONE", RSSTAT),
    RSREASND = if_else(chk, "SOURCE VALUE CHECK", RSREASND),
    # not evaluable is a result, the assessment was done
    RSSTAT = if_else(RSORRES %in% "NE", NA_character_, RSSTAT),
    RSREASND = if_else(RSORRES %in% "NE", NA_character_, RSREASND),
    .pre = predose(RSDTC, VISITNUM, RFXSTDTC),
    EPOCH = fepoch(RSDTC, .pre, RFXSTDTC, RFXENDTC),
    RSDY = study_day(RSDTC, RFSTDTC)
  )

finalize(rs, "rs", "Disease Response and Clin Classification")
