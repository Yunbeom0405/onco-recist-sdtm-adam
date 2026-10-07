# Program : adtr.R
# Purpose : Create ADaM ADTR, independent SAS program
source("r/adam/setup.R")

adsl <- read_adam("adsl")
tr <- read_sdtm("tr")
adrs <- read_adam("adrs")

adsl_vars <- adsl |>
  filter(ITTFL == "Y") |>
  select(STUDYID, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, ITTFL)

# first progression date
pd <- adrs |>
  filter(PARAMCD == "PD") |>
  select(USUBJID, PDDT = ADT)

adtr <- tr |>
  filter(TRTESTCD == "SUMDIAM", TRACPTFL == "Y", !is.na(TRSTRESN)) |>
  transmute(
    USUBJID,
    PARAMCD = "SUMDIAM",
    PARAM = "Sum of Target Lesion Diameters (mm)",
    PARAMN = 1,
    AVAL = TRSTRESN,
    ABLFL = if_else(TRLOBXFL == "Y", "Y", NA_character_),
    ADT = to_date(TRDTC),
    AVISIT = VISIT,
    AVISITN = VISITNUM,
    SRCDOM = "TR",
    SRCVAR = "TRSTRESN",
    SRCSEQ = TRSEQ
  ) |>
  inner_join(adsl_vars, by = "USUBJID") |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ADT)) |>
  left_join(pd, by = "USUBJID") |>
  group_by(USUBJID) |>
  mutate(BASE = first(AVAL[ABLFL %in% "Y"], default = NA_real_)) |>
  ungroup() |>
  mutate(
    CHG = if_else(is.na(ABLFL) & !is.na(BASE), AVAL - BASE, NA_real_),
    PCHG = if_else(!is.na(CHG) & BASE > 0, CHG / BASE * 100, NA_real_),
    ANL01FL = if_else(!is.na(PCHG) & (is.na(PDDT) | ADT <= PDDT), "Y", NA_character_)
  ) |>
  # best percent change: lowest PCHG, earliest date if tied
  arrange(USUBJID, PCHG, ADT) |>
  group_by(USUBJID, ANL01FL) |>
  mutate(ANL02FL = if_else(!is.na(ANL01FL) & row_number() == 1, "Y", NA_character_)) |>
  ungroup()

finalize(adtr, "adtr", keys = c("USUBJID", "PARAMCD", "ADT"))
