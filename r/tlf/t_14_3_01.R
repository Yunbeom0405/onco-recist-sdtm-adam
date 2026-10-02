# Program : t_14_3_01.R
# Purpose : Table 14-3.01 Progression-Free Survival

source("r/tlf/setup.R")
suppressPackageStartupMessages(library(survival))

tte <- read_adam("adtte") |>
  filter(PARAMCD == "PFS", ITTFL == "Y") |>
  mutate(TRT01P = factor(TRT01P, levels = trt_levels), EVENT = 1 - CNSR)

# log-log limits, as SAS PROC LIFETEST
fit <- survfit(Surv(AVAL, EVENT) ~ TRT01P, data = tte, conf.type = "log-log")
days <- c(60, 120, 180)
est <- summary(fit, times = days, extend = TRUE)
med <- quantile(fit, probs = 0.5)
med_txt <- ifelse(is.na(med$quantile), "NE",
  paste0(f(med$quantile, 1), " (", ifelse(is.na(med$lower), "NE", f(med$lower, 1)), "; ",
         ifelse(is.na(med$upper), "NE", f(med$upper, 1)), ")"))
rate <- matrix(
  paste0(f(est$surv, 3), " (", ifelse(is.na(est$lower), "NE", f(est$lower, 3)), "; ",
         ifelse(is.na(est$upper), "NE", f(est$upper, 3)), ")"),
  nrow = length(days))

n <- as.integer(table(tte$TRT01P))
ev <- as.integer(tapply(tte$EVENT, tte$TRT01P, sum))
pd <- as.integer(tapply(tte$EVNTDESC %in% "PROGRESSIVE DISEASE", tte$TRT01P, sum))
dth <- as.integer(tapply(tte$EVNTDESC %in% "DEATH", tte$TRT01P, sum))

# Cox model (Efron ties, Wald limits) and log-rank test against placebo
vs_placebo <- function(k) {
  d <- tte |>
    filter(TRT01P %in% trt_levels[c(1, k)]) |>
    mutate(IND = as.numeric(TRT01P == trt_levels[k]))
  cox <- coxph(Surv(AVAL, EVENT) ~ IND, data = d, ties = "efron")
  ci <- exp(confint(cox))
  c(paste0(f(exp(coef(cox)), 3), " (", f(ci[1], 3), "; ", f(ci[2], 3), ")"),
    pv(survdiff(Surv(AVAL, EVENT) ~ IND, data = d)$pvalue))
}
cmp <- cbind(c("", ""), vs_placebo(2), vs_placebo(3))

col <- function(j) c(n[j], npct(ev[j], n[j], 1), npct(pd[j], n[j], 1), npct(dth[j], n[j], 1),
                     npct(n[j] - ev[j], n[j], 1), med_txt[j], rate[, j], cmp[, j])

df <- tibble(
  ROW = 1:11,
  LABEL = c("Subjects, n", "Events, n (%)", "Progressive disease", "Death", "Censored, n (%)",
            "Median (95% CI), days", paste("PFS rate at Day", days, "(95% CI)"),
            "Hazard ratio vs Placebo (95% CI)", "Log-rank p-value vs Placebo"),
  INDENT = c(0L, 0L, 1L, 1L, rep(0L, 7)),
  C1 = col(1), C2 = col(2), C3 = col(3)
)

save_df(df, "t_14_3_01", "Table 14-3.01 Progression-Free Survival",
  paste0(trt_levels, " (N=", n, ")"),
  c("Population: Intent-to-Treat. Event: first progressive disease or death. Censored at last tumor assessment or at randomization.",
    "Kaplan-Meier, 95% CI log-log. Hazard ratio: Cox model, Efron ties. NE: not estimable."))
