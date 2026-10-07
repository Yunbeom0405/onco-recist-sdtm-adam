# Program : t_14_2_01.R
# Purpose : Table 14-2.01 Best Overall Response and Objective Response Rate

source("r/tlf/setup.R")

bor <- read_adam("adrs") |>
  filter(PARAMCD == "BOR") |>
  mutate(TRT01P = factor(TRT01P, levels = trt_levels))

grp <- c(split(bor, bor$TRT01P), list(Total = bor))
N <- sapply(grp, nrow)

cats <- c("CR", "PR", "SD", "PD", "NE", "MISSING")
cnt <- t(sapply(cats, \(a) sapply(grp, \(d) sum(d$AVALC == a))))
resp <- sapply(grp, \(d) sum(d$AVALC %in% c("CR", "PR")))
ci <- sapply(seq_along(grp), \(j) {
  x <- binom.test(resp[[j]], N[[j]])$conf.int * 100
  paste0(f(x[1], 1), "; ", f(x[2], 1))
})

lab <- c("Best overall response (unconfirmed), n (%)", "Complete response (CR)", "Partial response (PR)",
         "Stable disease (SD)", "Progressive disease (PD)", "Not evaluable (NE)", "Missing (no assessment)",
         "Objective response (CR or PR), n (%)", "95% CI (Clopper-Pearson)")
col <- function(j) c("", npct(cnt[, j], N[[j]], 1), npct(resp[[j]], N[[j]], 1), ci[j])

df <- tibble(
  ROW = 1:9, LABEL = lab, INDENT = c(0L, rep(1L, 6), 0L, 1L),
  C1 = col(1), C2 = col(2), C3 = col(3), C4 = col(4)
)

save_df(df, "t_14_2_01", "Table 14-2.01 Best Overall Response and Objective Response Rate",
  paste0(c(trt_levels, "Total"), " (N=", N, ")"),
  c("Population: Intent-to-Treat. RECIST 1.1 by Radiologist 1. Responses are unconfirmed; assessments after the first PD are not used.",
    "SD requires study day 42 or later; earlier SD counts as NE. Missing: no tumor assessment."))
