# QC Log

SAS is the production program, R the independent QC program written from the spec. SDTM outputs are compared by key with {diffdf} (`r/sdtm/compare.R`, report in `output/validation/sdtm-r-vs-sas.txt`).

| Domain | Result | Findings |
|---|---|---|
| DM | Match | none |
| DS | Match | none |
| EX | Match | none |
| SV | Match | none |
| TU | Match | none |
| TR | Match | none |
| RS | Match | none |
| ADSL | Match | none |
| ADRS | Match | none |
| ADTTE | Match | none (SAS hand-coded, R `derive_param_tte()`) |
| ADTR | Match | none |

While writing R for TU/TR/RS, `as.Date()` failed on partial dates (`2014-01`); fixed with an explicit format and all domains re-compared (Language, R wrong).

Trial design datasets (TA, TE, TV, TI, TS) are not part of this project, so only the 7 domains above are compared. SVPRESP no longer uses TV; same result.

ADaM spec fixes after the first P21 run (labels, codelists) were made in both programs and the three datasets compared again.

## TLF

| Output | Result |
|---|---|
| Table 14-1.01 populations and disposition | Match |
| Table 14-2.01 best overall response, ORR | Match |
| Table 14-3.01 progression-free survival | Match after SAS fixes |
| Figure 14-3.01 statistics | Match after R fix |
| Figure 14-2.02 statistics and bar values | Match |

Findings so far:
- Figure 14-3.01 statistics, PFS rate at day 180 for Placebo: SAS left it missing, R gave 0.031. The last Placebo observation is censored before day 180, so the Kaplan-Meier estimate is undefined there. R `summary(extend = TRUE)` carries the last value forward. R changed to return NE; SAS now prints NE too (Language, R wrong).
- Table 14-3.01 in SAS: `HomTests` was not created because one `ods output` statement covered two procedures, and the confidence limit variable names were guessed. Fixed by one `ods output` per procedure and `OUTSURV=` for the rates (Bug, SAS, found by SAS log).
- Table 14-3.01 in SAS: the `col.` format of the stacked data named the transposed columns, so `c1` to `c3` were missing. Fixed by clearing the format (Bug, SAS, found by SAS log).
- Figure 14-2.02 in SAS: `%str(,)` inside a quoted footnote was printed literally in the figure. Fixed by a plain comma (Bug, SAS, found by reading the RTF; macro quoting only works in macro arguments).

## Data note

4 EX records (01-704-1233, 01-705-1031, 01-705-1303, 01-705-1377) have no EXENDTC and start the day after RFXENDTC, so EPOCH is FOLLOW-UP. This follows the epoch rule; the source dates themselves disagree.

## After P21

DS (DSSPID leading blank), RS (NE with NOT DONE) and SV (unscheduled visits of 01-711-1143 renumbered 9.2 and 9.3, also in TR and RS) changed in both SAS and R after the first P21 run. SAS vs R compared again with the rerun outputs: all 12 domains match.
