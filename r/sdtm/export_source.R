# Export pharmaversesdtm domains to XPT for the SAS server
library(haven)
library(pharmaversesdtm)

doms <- c("dm", "ds", "ex", "sv", "tu_onco", "tr_onco", "rs_onco")
for (d in doms) {
  df <- get(d, asNamespace("pharmaversesdtm"))
  if (is.null(df)) df <- get(d)
  write_xpt(df, file.path("data/source", paste0(d, ".xpt")), version = 5, name = d)
  cat(d, nrow(df), "x", ncol(df), "\n")
}
