# Program : t_14_1_01.R
# Purpose : Table 14-1.01 Summary of Populations and Study Disposition

source("r/tlf/setup.R")

adsl <- read_adam("adsl") |>
  filter(ITTFL == "Y") |>
  mutate(TRT01P = factor(TRT01P, levels = trt_levels))

grp <- c(split(adsl, adsl$TRT01P), list(Total = adsl))
N <- sapply(grp, nrow)

reasons <- c("ADVERSE EVENT", "DEATH", "LACK OF EFFICACY", "LOST TO FOLLOW-UP", "PHYSICIAN DECISION",
             "PROTOCOL VIOLATION", "STUDY TERMINATED BY SPONSOR", "WITHDRAWAL BY SUBJECT")
cnt <- rbind(
  sapply(grp, \(d) sum(d$ITTFL == "Y")),
  sapply(grp, \(d) sum(d$SAFFL == "Y")),
  sapply(grp, \(d) sum(d$EOSSTT == "COMPLETED")),
  sapply(grp, \(d) sum(d$EOSSTT == "DISCONTINUED")),
  t(sapply(reasons, \(r) sapply(grp, \(d) sum(d$DCSREAS %in% r))))
)

df <- tibble(
  ROW = 1:12,
  LABEL = c("Randomized (ITT)", "Safety", "Completed study", "Discontinued study",
            "Adverse event", "Death", "Lack of efficacy", "Lost to follow-up", "Physician decision",
            "Protocol violation", "Study terminated by sponsor", "Withdrawal by subject"),
  INDENT = c(0L, 0L, 0L, 0L, rep(1L, 8)),
  C1 = npct(cnt[, 1], N[[1]]), C2 = npct(cnt[, 2], N[[2]]),
  C3 = npct(cnt[, 3], N[[3]]), C4 = npct(cnt[, 4], N[[4]])
)

save_df(df, "t_14_1_01", "Table 14-1.01 Summary of Populations and Study Disposition",
  paste0(c(trt_levels, "Total"), " (N=", N, ")"),
  c("Population: Intent-to-Treat (randomized). Percentages use N in the column header.",
    "52 screen failures are not in this table. Reasons are for discontinuation from study."))
