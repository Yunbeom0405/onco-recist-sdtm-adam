# Pinnacle 21 review

P21 Community, engine FDA 2508.1, SDTMIG 3.4, CT 2026-03-27 (engine built-in; the spec uses CT 2026-09-25). MedDRA and SNOMED not configured (licensed).

## SDTM

Fourth run, 7 domains with `define/sdtm/define.xml` (Define-XML 2.1, built by `python/make_define.py`): 0 errors, 951 warnings, 1 reject (no TS). Report: `output/validation/p21/p21-sdtm-define.xlsx`; the data-only run is `p21-sdtm.xlsx` (2 rejects). The first run had 1,286 warnings (with trial design datasets copied from P1); SD1021, SD1123 and SD0051 were fixed, then the trial design datasets were removed. Report: `output/validation/p21/p21-sdtm.xlsx`.

| Rule | Found | Domain | Cause | Decision |
|---|---|---|---|---|
| DD0101 | 0 | Global | Fixed (1 before): define.xml added | Done |
| SD1106, SD1107, SD1108, SD1111 | 4 | Global | No AE, LB, VS or SE dataset | Out of scope |
| SD1115 | 1 | Global | No TS dataset (reject) | Out of scope, see below |
| SD1112, SD1113 | 2 | Global | No TA or TE dataset | Out of scope, see below |
| SD1210, SD1240 | 612 | DM | No informed consent date or consent record in the source | Keep |
| SD1149 | 2 | DM | RFICDTC and ACTARMUD empty for all subjects | Keep |
| SD1209 | 2 | DM | No last dose date | Keep |
| SD2236, SD2237 | 24 | DM | ACTARM differs from ARM for 12 subjects | Keep, as collected |
| CT2005 | 290 | DS | FINAL LAB VISIT and FINAL RETRIEVAL VISIT not in OTHEVENT | Keep, extensible codelist |
| SD1021 | 0 | DS | Fixed: leading blank in DSSPID (` 7`) removed (58 before) | Done |
| SD1076, SD1083 | 3 | DS, EX | Optional variable added; DSDY not populated | Keep |
| SD0021 | 6 | EX | No EXENDTC | Keep, as collected |
| SD1206 | 4 | EX | EXSTDTC after RFXENDTC (see QC-LOG) | Keep |
| SD1123 | 0 | RS | Fixed (242 before): RSORRES = NE with RSSTAT = NOT DONE; NE is a result of a completed assessment, RSSTAT and RSREASND set null | Done |
| SD0051 | 0 | SV | Fixed (1 before): VISITNUM 9.1 had two VISIT names; unscheduled visits of 01-711-1143 renumbered 9.2 and 9.3 | Done |

TU, TR, RS and SV have no findings.

## Trial design

TA, TE, TV, TI and TS are not part of this project. The synthetic tumor data have no protocol of their own, and the only trial design source in {pharmaversesdtm} (TS) describes the original Alzheimer's study. The TS reject and the TA and TE warnings stay open on purpose.

## ADaM

P21 Community, engine FDA 2508.1, ADaM-IG 1.3, with `define/adam/define.xml` and the SDTM datasets (needed for the traceability rules). ADSL, ADRS, ADTTE, ADTR: 0 errors, 0 warnings. Report: `output/validation/p21/p21-adam-define.xlsx`. The 5 remaining warnings (AD9999, one per SDTM dataset) only say that the SDTM datasets are not checked by ADaM rules.

The first run had 1,931 warnings, all from the spec: a codelist on PARAM, no `N` in the No Yes codelist, and two labels that differ from the standard (ITTFL, STARTDT). Fixed in the spec and in both programs.

