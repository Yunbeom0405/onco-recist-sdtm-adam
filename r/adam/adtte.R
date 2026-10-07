# Program : adtte.R
# Purpose : Create ADaM ADTTE ({admiral}), independent of the SAS program

source("r/adam/setup.R")

adsl <- read_adam("adsl") |> filter(ITTFL == "Y")
adrs <- read_adam("adrs")

pd_event <- event_source(
  dataset_name = "adrs", filter = PARAMCD == "PD", date = ADT,
  set_values_to = exprs(EVNTDESC = "PROGRESSIVE DISEASE", SRCDOM = "RS", SRCVAR = "RSORRES")
)
death_event <- event_source(
  dataset_name = "adsl", filter = !is.na(DTHDT), date = DTHDT,
  set_values_to = exprs(EVNTDESC = "DEATH", SRCDOM = "DM", SRCVAR = "DTHDTC")
)
last_assess <- censor_source(
  dataset_name = "adrs", filter = PARAMCD == "OVR" & ANL01FL == "Y", date = ADT, censor = 1,
  set_values_to = exprs(CNSDTDSC = "LAST TUMOR ASSESSMENT", SRCDOM = "RS", SRCVAR = "RSDTC")
)
rand_censor <- censor_source(
  dataset_name = "adsl", date = RANDDT, censor = 1,
  set_values_to = exprs(CNSDTDSC = "RANDOMIZATION", SRCDOM = "ADSL", SRCVAR = "RANDDT")
)
alive_censor <- censor_source(
  dataset_name = "adsl", date = LSTALVDT, censor = 1,
  set_values_to = exprs(CNSDTDSC = "LAST KNOWN ALIVE DATE", SRCDOM = "ADSL", SRCVAR = "LSTALVDT")
)

pfs <- derive_param_tte(
  dataset_adsl = adsl,
  source_datasets = list(adsl = adsl, adrs = adrs),
  start_date = RANDDT,
  event_conditions = list(pd_event, death_event),
  censor_conditions = list(last_assess, rand_censor),
  set_values_to = exprs(PARAMCD = "PFS", PARAM = "Progression-Free Survival", PARAMN = 1)
)
os <- derive_param_tte(
  dataset_adsl = adsl,
  source_datasets = list(adsl = adsl),
  start_date = RANDDT,
  event_conditions = list(death_event),
  censor_conditions = list(alive_censor),
  set_values_to = exprs(PARAMCD = "OS", PARAM = "Overall Survival", PARAMN = 2)
)

adtte <- bind_rows(pfs, os) |>
  select(-any_of(c("TRT01P", "TRT01PN", "TRT01A", "TRT01AN", "TRTSDT", "ITTFL"))) |>
  left_join(select(adsl, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, ITTFL), by = "USUBJID") |>
  mutate(AVAL = as.numeric(ADT - STARTDT) + 1, AVALU = "DAYS")

finalize(adtte, "adtte", keys = c("USUBJID", "PARAMCD"))
