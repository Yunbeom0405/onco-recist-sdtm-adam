# Program : adsl.R
# Purpose : Create ADaM ADSL, independent of the SAS program

source("r/adam/setup.R")

dm <- read_sdtm("dm")
ds <- read_sdtm("ds")
ex <- read_sdtm("ex")
sv <- read_sdtm("sv")
tr <- read_sdtm("tr")
rs <- read_sdtm("rs")

trtn <- c("Placebo" = 0, "Xanomeline Low Dose" = 54, "Xanomeline High Dose" = 81)

rand <- ds |> filter(DSDECOD == "RANDOMIZED") |> select(USUBJID, RANDDTC = DSSTDTC)
eos <- ds |> filter(DSCAT == "DISPOSITION EVENT") |> select(USUBJID, EOSDECOD = DSDECOD, EOSDTC = DSSTDTC)

# latest complete date seen for the subject, death records excluded
lstalv <- bind_rows(
  sv |> select(USUBJID, D = SVSTDTC),
  sv |> select(USUBJID, D = SVENDTC),
  ex |> select(USUBJID, D = EXSTDTC),
  ex |> select(USUBJID, D = EXENDTC),
  tr |> select(USUBJID, D = TRDTC),
  rs |> select(USUBJID, D = RSDTC),
  ds |> filter(DSDECOD != "DEATH") |> select(USUBJID, D = DSSTDTC),
  dm |> select(USUBJID, D = RFXSTDTC)
) |>
  mutate(D = to_date(D)) |>
  filter(!is.na(D)) |>
  group_by(USUBJID) |>
  summarise(LSTALVDT = max(D))

adsl <- dm |>
  left_join(rand, by = "USUBJID") |>
  left_join(eos, by = "USUBJID") |>
  left_join(lstalv, by = "USUBJID") |>
  mutate(
    TRT01P = ARM,
    TRT01A = ACTARM,
    TRT01PN = unname(trtn[TRT01P]),
    TRT01AN = unname(trtn[TRT01A]),
    AGEGR1 = case_when(AGE < 65 ~ "<65", AGE <= 80 ~ "65-80", AGE > 80 ~ ">80"),
    AGEGR1N = case_when(AGE < 65 ~ 1, AGE <= 80 ~ 2, AGE > 80 ~ 3),
    RANDDT = to_date(RANDDTC),
    TRTSDT = to_date(RFXSTDTC),
    TRTEDT = to_date(coalesce(RFXENDTC, RFENDTC)),
    DTHDT = to_date(DTHDTC),
    ITTFL = if_else(!is.na(RANDDTC), "Y", "N"),
    SAFFL = if_else(ITTFL == "Y" & USUBJID %in% ex$USUBJID, "Y", "N"),
    EOSSTT = if_else(EOSDECOD == "COMPLETED", "COMPLETED", "DISCONTINUED"),
    EOSDT = to_date(EOSDTC),
    DCSREAS = if_else(EOSSTT == "DISCONTINUED", EOSDECOD, NA_character_)
  )

finalize(adsl, "adsl", keys = "USUBJID")
