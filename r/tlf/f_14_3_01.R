# Program : f_14_3_01.R
# Purpose : Figure 14-3.01 Kaplan-Meier: Progression-Free Survival
#           (+ statistics table f_14_3_01_stats for QC)

source("r/tlf/setup.R")
suppressPackageStartupMessages({
  library(survival)
  library(ggplot2)
})

tte <- read_adam("adtte") |>
  filter(PARAMCD == "PFS", ITTFL == "Y") |>
  mutate(TRT01P = factor(TRT01P, levels = trt_levels), EVENT = 1 - CNSR)

# log-log confidence intervals, as SAS PROC LIFETEST
fit <- survfit(Surv(AVAL, EVENT) ~ TRT01P, data = tte, conf.type = "log-log")

times <- seq(30, 180, by = 30)
est <- km_at(fit, tte, times)
med <- quantile(fit, probs = 0.5)
med_txt <- ifelse(is.na(med$quantile), "NE",
  paste0(f(med$quantile, 1), " (", ifelse(is.na(med$lower), "NE", f(med$lower, 1)), ";",
         ifelse(is.na(med$upper), "NE", f(med$upper, 1)), ")"))

n <- table(tte$TRT01P)
events <- tapply(tte$EVENT, tte$TRT01P, sum)
km <- matrix(ifelse(is.na(est$surv), "NE", f(est$surv, 3)), nrow = length(times))

df <- tibble(
  LABEL = c("N", "Events", "Censored", "Median (95% CI)", paste("Progression-free at Day", times)),
  C1 = c(n[1], events[1], n[1] - events[1], med_txt[1], km[, 1]),
  C2 = c(n[2], events[2], n[2] - events[2], med_txt[2], km[, 2]),
  C3 = c(n[3], events[3], n[3] - events[3], med_txt[3], km[, 3])
) |>
  mutate(ROW = row_number(), INDENT = 0L, across(C1:C3, as.character)) |>
  relocate(ROW)

save_df(df, "f_14_3_01_stats", "Figure 14-3.01 Statistics: Progression-Free Survival",
  paste0(trt_levels, " (N=", n, ")"),
  c("Population: Intent-to-Treat. Kaplan-Meier estimates, 95% CI with log-log transformation.", "NE: not estimable."),
  src = "f_14_3_01")

# Kaplan-Meier plot
curve <- tibble(time = fit$time, surv = fit$surv, strata = rep(trt_levels, fit$strata)) |>
  bind_rows(tibble(time = 0, surv = 1, strata = trt_levels)) |>
  arrange(strata, time)

p <- ggplot(curve, aes(time, surv, colour = factor(strata, levels = trt_levels))) +
  geom_step() +
  scale_x_continuous(breaks = seq(0, 210, 30)) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(
    title = "Figure 14-3.01 Kaplan-Meier: Progression-Free Survival by Treatment Group",
    x = "Days from randomization", y = "Probability of progression-free survival", colour = NULL,
    caption = "Population: Intent-to-Treat. Event: first progressive disease or death. Source: r/tlf/f_14_3_01.R"
  ) +
  theme_bw() +
  theme(legend.position = "bottom")

ggsave(file.path(out_dir, "f_14_3_01.png"), p, width = 9, height = 5.5, dpi = 150)
