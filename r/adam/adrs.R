# Program : adrs.R
# Purpose : Create ADaM ADRS, independent of the SAS program

source("r/adam/setup.R")

adsl <- read_adam("adsl")
rs <- read_sdtm("rs")

adsl_vars <- adsl |> select(STUDYID, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, ITTFL)
avalc_n <- c("CR" = 1, "PR" = 2, "SD" = 3, "NON-CR/NON-PD" = 4, "PD" = 5, "NE" = 6, "MISSING" = 7)

# overall response by visit: accepted records (Radiologist 1) with a result
ovr <- rs |>
  filter(RSTESTCD == "OVRLRESP", RSACPTFL == "Y", !is.na(RSORRES)) |>
  transmute(
    USUBJID, PARAMCD = "OVR", PARAM = "Overall Response by Visit", PARAMN = 1,
    AVALC = RSORRES, ADT = to_date(RSDTC), AVISIT = VISIT, AVISITN = VISITNUM,
    SRCDOM = "RS", SRCVAR = "RSORRES", SRCSEQ = RSSEQ
  ) |>
  inner_join(filter(adsl_vars, ITTFL == "Y"), by = "USUBJID") |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ADT)) |>
  group_by(USUBJID) |>
  mutate(
    PDDT = suppressWarnings(min(ADT[AVALC == "PD"])),
    # records after the first PD are not analyzed
    ANL01FL = if_else(ADT <= PDDT | is.infinite(PDDT), "Y", NA_character_)
  ) |>
  ungroup() |>
  select(-PDDT)

# PD: first progression
pd <- ovr |>
  filter(AVALC == "PD") |>
  arrange(USUBJID, ADT) |>
  distinct(USUBJID, .keep_all = TRUE) |>
  mutate(PARAMCD = "PD", PARAM = "Disease Progression", PARAMN = 2, AVALC = "Y", ANL01FL = NA_character_)

# BOR: unconfirmed, SD needs study day 42
rank_order <- c("CR", "PR", "SD", "PD", "NE")
bor_src <- ovr |>
  filter(ANL01FL == "Y") |>
  mutate(
    BOR = case_when(
      AVALC %in% c("CR", "PR") ~ AVALC,
      AVALC == "SD" & ADY >= 42 ~ "SD",
      AVALC == "PD" ~ "PD",
      .default = "NE"
    ),
    RANK = match(BOR, rank_order)
  ) |>
  arrange(USUBJID, RANK, ADT) |>
  distinct(USUBJID, .keep_all = TRUE) |>
  select(USUBJID, BOR, ADT, ADY, AVISIT, AVISITN, SRCDOM, SRCVAR, SRCSEQ)

bor <- adsl_vars |>
  filter(ITTFL == "Y") |>
  left_join(bor_src, by = "USUBJID") |>
  mutate(
    PARAMCD = "BOR", PARAM = "Best Overall Response", PARAMN = 3,
    AVALC = coalesce(BOR, "MISSING")
  ) |>
  select(-BOR)

rsp <- bor |>
  mutate(
    PARAMCD = "RSP", PARAM = "Objective Response (BOR CR or PR)", PARAMN = 4,
    AVALC = if_else(AVALC %in% c("CR", "PR"), "Y", "N")
  )

adrs <- bind_rows(ovr, pd, bor, rsp) |>
  mutate(AVAL = if_else(PARAMCD %in% c("OVR", "BOR"), unname(avalc_n[AVALC]), as.numeric(AVALC == "Y"))) |>
  arrange(USUBJID, PARAMN, ADT, AVISITN) |>
  group_by(USUBJID) |>
  mutate(ASEQ = row_number()) |>
  ungroup()

finalize(adrs, "adrs", keys = c("USUBJID", "PARAMCD", "ADT"))
