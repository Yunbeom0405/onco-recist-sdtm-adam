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

While writing R for TU/TR/RS, `as.Date()` failed on partial dates (`2014-01`); fixed with an explicit format and all domains re-compared (Language, R wrong).

Trial design datasets (TA, TE, TV, TI, TS) are not part of this project, so only the 7 domains above are compared. SVPRESP no longer uses TV; same result.

## Data note

4 EX records (01-704-1233, 01-705-1031, 01-705-1303, 01-705-1377) have no EXENDTC and start the day after RFXENDTC, so EPOCH is FOLLOW-UP. This follows the epoch rule; the source dates themselves disagree.

## After P21

DS (DSSPID leading blank), RS (NE with NOT DONE) and SV (unscheduled visits of 01-711-1143 renumbered 9.2 and 9.3, also in TR and RS) changed in both SAS and R after the first P21 run. SAS vs R compared again with the rerun outputs: all 12 domains match.
