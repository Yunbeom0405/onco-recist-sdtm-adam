# Program : setup.R
# Purpose : Packages, paths, shared helpers for the R SDTM programs
# Run from the P2 project root, e.g. source("r/sdtm/dm.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(haven)
})

src_dir <- "data/source"
out_dir <- "data/derived/sdtm-r"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

spec_vars <- read_excel("specs/sdtm-spec.xlsx", sheet = "Variables")

# read source xpt, blank character NA
read_src <- function(name) {
  read_xpt(file.path(src_dir, paste0(name, ".xpt"))) |>
    mutate(across(where(is.character), \(x) na_if(x, "")))
}

# study day, complete dates only
study_day <- function(dtc, ref) {
  ok <- nchar(dtc) >= 10 & nchar(ref) >= 10
  d <- as.integer(as.Date(substr(dtc, 1, 10), "%Y-%m-%d") - as.Date(substr(ref, 1, 10), "%Y-%m-%d"))
  if_else(ok, d + (d >= 0), NA_integer_)
}

# order and label variables from the spec, write xpt
finalize <- function(df, domain, label) {
  sv <- spec_vars |> filter(Dataset == toupper(domain)) |> arrange(Order)
  df <- df[, sv$Variable]
  for (i in seq_len(nrow(sv))) attr(df[[sv$Variable[i]]], "label") <- sv$Label[i]
  write_xpt(df, file.path(out_dir, paste0(domain, ".xpt")), version = 5,
            name = domain, label = label)
  invisible(df)
}
