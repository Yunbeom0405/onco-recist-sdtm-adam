# SDTM Gap Analysis: pharmaversesdtm to SDTMIG v3.4

Input: `{pharmaversesdtm}` DM, DS, EX, SV, AE, TS, SUPPDM and the RECIST 1.1 oncology domains
`tu_onco`, `tr_onco`, `rs_onco` (254 subjects). Checked against SDTMIG v3.4 (2021-11-29) and
SDTM CT 2026-09-25.

The oncology domains are synthetic test data attached to the CDISC Pilot Alzheimer's population
(same DM, same Xanomeline/Placebo arms). This project upgrades them to v3.4; it does not
reproduce a real oncology study.

Labels and the absence of `--LOBXFL` (added in v3.3, IG p59) indicate the source follows an
older IG version.

## Structure

| Domain | Finding | IG reference | Action |
|---|---|---|---|
| DM | ARMNRS, ACTARMUD placed after DMDY; IG order puts them before COUNTRY | p62 | Reorder |
| DM | RFICDTC, ACTARMUD (Exp) all null | p62 | Keep null: consent date not in source; no unplanned arms |
| DM | 52 screen failures have ARMCD/ACTARMCD = `Scrnfail`, ARM/ACTARM = `Screen Failure` (pre-3.3 convention). In 3.4 these are null and the reason is in ARMNRS | p63 | Set null |
| SV | SVPRESP, SVOCCUR (Exp) missing | p86 | Add |
| SV | SVSTDTC, SVENDTC labels are old ("of Visit") | p86 | Relabel |
| EX | EXTRT, EXDOSE labels are old | p104 | Relabel |
| AE | 6 MedDRA code variables and AEACN (Exp) all null | p134 | Keep; MedDRA codes not in source. AEACN to review |
| TU | TULOBXFL (Exp) missing | p346 | Derive |
| TU | 7 labels say "Tumor" instead of "Tumor/Lesion" | p345 | Relabel |
| TR | TRLOBXFL (Exp) missing | p350 | Derive |
| TR | TRLNKGRP placed before TRLNKID | p350 | Reorder |
| TR | 6 labels are old | p350 | Relabel |
| RS | 9 labels are old | p329 | Relabel |
| TA, TE, TV, TI, TS | Not built: no protocol for the synthetic tumor data; the only trial design source (TS) describes the Alzheimer's study | - | Out of scope, stated in the spec (COM.TD) |
| All | EPOCH (Perm) not present | - | Decide in spec |

Not findings: VISITNUM, VISIT, VISITDY in DS and EX, and AEDTC in AE are not in the domain
tables, but any Timing variable is permissible in a general observation class domain unless a
domain assumption restricts it (IG p13). DS assumptions do not.

## Values

| # | Domain | Finding | Rows | Action |
|---|---|---|---|---|
| 1 | TU, TR, RS | `--DY` is a copy of the planned visit day (VISITDY), not the actual study day. Matches VISITDY in 100% of rows; matches the actual day in TU 98.7%, TR 37.2%, RS 11.6% | all | Recalculate from `--DTC` and RFSTDTC (IG p41) |
| 2 | TR, RS | `--DY` null at unscheduled visits (no VISITDY) although `--DTC` is complete | TR 756, RS 105 | Fixed by 1 |
| 3 | TU, TR | `--DY` populated when `--DTC` is a partial date (`2014-01`) | TU 5, TR 16 | Set null |
| 4 | RS | RSORRES/RSSTRESC = `CHECK` for OVRLRESP, subject 01-711-1143, 2013-06-22 (RSSEQ 19, 21, 23). Not in ONCRSR | 3 | Decided: RSORRES/RSSTRESC null, RSSTAT = NOT DONE, RSREASND states the source value. Not re-derived in SDTM |
| 5 | DS | DSDECOD `FINAL LAB VISIT`, `FINAL RETRIEVAL VISIT` (OTHER EVENT) not in OTHEVENT; codelist is extensible | 290 | Keep as extension, document in define.xml |

Checked and matching CT: TUTESTCD, TUTEST, TUORRES/TUSTRESC (TUIDRS), TULOC, TUMETHOD, TUEVAL,
TRTESTCD, TRTEST, TRORRESU, TRSTAT, RSTESTCD, RSTEST, RSCAT, RSEVAL, other RSORRES values, SEX,
AGEU, EXDOSU, EXDOSFRM, EXDOSFRQ, EXROUTE.

## Resolved

**RACE, ETHNIC codelist.** CT 2026-09-25 has no RACE (C74457) or ETHNIC (C66790) codelist,
only the as-collected RACEC (C128689) and ETHNICC (C128690). Same situation as P1 (Open Issue 5
there). Decision: keep C74457 / C66790 from CT 2025-09-26 and list that version as a second CT
standard in define.xml. All DM values are valid terms in both.

**Duplicate keys in TR and RS.** With the evaluator in the key (TREVAL/TREVALID, RSEVAL/RSEVALID:
investigator plus two independent radiologists, each with a full set of records), all
duplicates come from one cause:

| # | Domain | Finding | Rows | Action |
|---|---|---|---|---|
| 6 | SV, TR, RS | Subject 01-711-1143: SV numbers the 2013-06-22 unscheduled visit 9.1, which is the planned WEEK 14 (T) for other subjects; TR/RS code both unscheduled dates 9.2 | SV 2, TR 63, RS 9 | Decided: unscheduled visits get the next free number (9.2 and 9.3), as in P1 |

At 2013-06-22 this subject has TRGRESP but no NTRGRESP, and OVRLRESP is the `CHECK` value
(finding 4); non-target status was recorded in TR that day. The overall response is not
re-derived in SDTM.

**Baseline partial dates.** Subject 01-701-1015 has 16 TR and 5 TU baseline records dated
`2014-01` beside 47 TR records dated 2014-01-02. Not a key problem. Keep the partial date as
collected; `--DY` null (finding 3).

## For ADaM

- 49 subjects have TU/TR records but no RS records.
- All 15 RS records after RFENDTC belong to 01-711-1143 at 2013-09-22, the retrieval visit
  (= RFPENDTC). Post-treatment assessment, real data.
- DM has 52 screen failures (ARMNRS = SCREEN FAILURE); no TU/TR/RS records.
- Three evaluators per assessment. `--ACPTFL = Y` marks Radiologist 1 (independent assessor) in
  every TU, TR and RS record, so the accepted assessment is already defined. Which evaluator the
  primary analysis uses (independent review vs investigator) is an ADaM decision.
