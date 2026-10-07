# Program : derive.R
# Purpose : Helpers shared by the R SDTM programs after DM

dm_ref <- read_xpt(file.path(out_dir, "dm.xpt")) |>
  select(USUBJID, RFSTDTC, RFXSTDTC, RFXENDTC) |>
  mutate(across(where(is.character), \(x) na_if(x, "")))

# epoch from treatment dates; partial dates stay null
epoch <- function(dtc, rfxst, rfxen) {
  d <- substr(dtc, 1, 10)
  case_when(
    nchar(dtc) < 10 | is.na(dtc) ~ NA_character_,
    is.na(rfxst) | d < substr(rfxst, 1, 10) ~ "SCREENING",
    is.na(rfxen) | d <= substr(rfxen, 1, 10) ~ "TREATMENT",
    .default = "FOLLOW-UP"
  )
}

# pre-dose: before first dose, or baseline visit on the first-dose date or partial
predose <- function(dtc, visitnum, rfxst) {
  full <- !is.na(dtc) & nchar(dtc) >= 10
  part <- !is.na(dtc) & nchar(dtc) < 10
  d <- substr(dtc, 1, 10)
  r <- substr(rfxst, 1, 10)
  ok <- !is.na(rfxst) & nchar(rfxst) >= 10
  ok & ((full & d < r) | (visitnum == 3 & (part | (full & d == r))))
}

# findings epoch: complete pre-dose dates are SCREENING
fepoch <- function(dtc, pre, rfxst, rfxen) {
  if_else(pre & !is.na(dtc) & nchar(dtc) >= 10, "SCREENING", epoch(dtc, rfxst, rfxen))
}

# 'Y' on the last pre-dose record with a result, per subject and by-variables
lobxfl <- function(df, res, dtc, by) {
  last <- df |>
    filter(.pre, !is.na(.data[[res]])) |>
    arrange(USUBJID, across(all_of(by)), .data[[dtc]], VISITNUM, .row) |>
    group_by(USUBJID, across(all_of(by))) |>
    slice_tail(n = 1) |>
    pull(.row)
  if_else(df$.row %in% last, "Y", NA_character_)
}

# 01-711-1143: unscheduled visits renumbered, 9.1 is the planned WEEK 14 (T)
# (SV and TR/RS code the same dates differently in the source, see Methods MT.VISITFIX)
visitfix <- function(df, dtc, from) {
  one <- df$USUBJID == "01-711-1143"
  d <- substr(df[[dtc]], 1, 10)
  a <- one & d == "2013-09-22" & df$VISITNUM == from[2]
  b <- one & d == "2013-06-22" & df$VISITNUM == from[1]
  df$VISITNUM[a] <- 9.3; df$VISIT[a] <- "UNSCHEDULED 9.3"
  df$VISITNUM[b] <- 9.2; df$VISIT[b] <- "UNSCHEDULED 9.2"
  df
}
