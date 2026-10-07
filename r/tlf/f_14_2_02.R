# Program : f_14_2_02.R
# Purpose : Figure 14-2.02 Waterfall: Best Percent Change in Sum of Target Lesion Diameters
#           (+ statistics table f_14_2_02_stats and bar values f_14_2_02_bars for QC)
source("r/tlf/setup.R")
library(ggplot2)

adtr <- read_adam("adtr") |>
  filter(PARAMCD == "SUMDIAM", ITTFL == "Y") |>
  mutate(TRT01P = factor(TRT01P, levels = trt_levels))

bars <- adtr |>
  filter(ANL02FL == "Y") |>
  arrange(desc(PCHG), USUBJID) |>
  mutate(ROW = row_number())

write_csv(
  transmute(bars, ROW, USUBJID, ARM = as.character(TRT01P), PCHG = f(PCHG, 1)),
  file.path(out_dir, "f_14_2_02_bars.csv")
)

# statistics by arm
nbase <- adtr |> distinct(USUBJID, TRT01P) |> count(TRT01P, .drop = FALSE) |> pull(n)
st <- bars |>
  group_by(TRT01P, .drop = FALSE) |>
  summarise(n = n(), med = median(PCHG), mn = min(PCHG), mx = max(PCHG),
            n30 = sum(PCHG <= -30), n20 = sum(PCHG >= 20))

df <- tibble(
  LABEL = c("Subjects with a baseline assessment", "Subjects with a post-baseline assessment",
            "Median best change, %", "Minimum, %", "Maximum, %",
            "Best change <= -30%, n (%)", "Best change >= +20%, n (%)"),
  C1 = c(nbase[1], st$n[1], f(st$med[1], 1), f(st$mn[1], 1), f(st$mx[1], 1), npct(st$n30[1], st$n[1]), npct(st$n20[1], st$n[1])),
  C2 = c(nbase[2], st$n[2], f(st$med[2], 1), f(st$mn[2], 1), f(st$mx[2], 1), npct(st$n30[2], st$n[2]), npct(st$n20[2], st$n[2])),
  C3 = c(nbase[3], st$n[3], f(st$med[3], 1), f(st$mn[3], 1), f(st$mx[3], 1), npct(st$n30[3], st$n[3]), npct(st$n20[3], st$n[3]))
) |>
  mutate(ROW = row_number(), INDENT = 0L, across(C1:C3, as.character)) |>
  relocate(ROW)

save_df(df, "f_14_2_02_stats", "Figure 14-2.02 Statistics: Best Percent Change in Sum of Target Lesion Diameters",
  trt_levels,
  c("Population: Intent-to-Treat. Percent change from baseline, lowest value before or at first progression.",
    "Percentages use subjects with a post-baseline assessment."),
  src = "f_14_2_02")

p <- ggplot(bars, aes(ROW, PCHG, fill = TRT01P)) +
  geom_col(width = 0.8) +
  geom_hline(yintercept = c(20, -30), linetype = "dashed") +
  scale_fill_manual(values = c("#7F7F7F", "#0072B2", "#D55E00")) +
  scale_y_continuous(breaks = seq(-100, 125, 25)) +
  labs(
    title = "Figure 14-2.02 Best Percent Change from Baseline in Sum of Target Lesion Diameters",
    x = "Subjects", y = "Best percent change from baseline (%)", fill = NULL,
    caption = paste("Population: Intent-to-Treat, subjects with a post-baseline assessment. Dashed lines: +20% and -30%.",
                    "Source: r/tlf/f_14_2_02.R", sep = "\n")
  ) +
  theme_bw() +
  theme(legend.position = "bottom", axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        panel.grid.major.x = element_blank())

ggsave(file.path(out_dir, "f_14_2_02.png"), p, width = 9, height = 5.5, dpi = 150)
