/*******************************************************************************
Program : adtr.sas
Purpose : Create ADaM ADTR
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\adam\setup.sas";

proc sql;
  create table pdd as
  select usubjid, adt as pddt format=date9. from adam.adrs where paramcd = 'PD' order by usubjid;

  create table itt as
  select studyid, usubjid, trt01p, trt01pn, trt01a, trt01an, trtsdt, ittfl
  from adam.adsl where ittfl = 'Y' order by usubjid;
quit;

data sd0;
  set sdtm.tr(where=(trtestcd = 'SUMDIAM' and tracptfl = 'Y' and trstresn ne .));
  length paramcd srcdom srcvar $8 param avisit $40 ablfl $1;
  paramcd = 'SUMDIAM';
  param = 'Sum of Target Lesion Diameters (mm)';
  paramn = 1;
  aval = trstresn;
  if trlobxfl = 'Y' then ablfl = 'Y';
  %dt(trdtc, adt)
  avisit = visit;
  avisitn = visitnum;
  srcdom = 'TR';
  srcvar = 'TRSTRESN';
  srcseq = trseq;
  keep usubjid paramcd param paramn aval ablfl adt avisit avisitn srcdom srcvar srcseq;
run;

proc sort data=sd0;
  by usubjid;
run;

data sd1;
  merge itt(in=_i) sd0(in=_s) pdd;
  by usubjid;
  if _i and _s;
  %ady(adt, ady)
run;

proc sql;
  create table base as
  select usubjid, aval as base from sd1 where ablfl = 'Y';
quit;

proc sort data=sd1;
  by usubjid;
run;

data sd2;
  merge sd1(in=_a) base;
  by usubjid;
  if _a;
  length anl01fl $1;
  if ablfl ne 'Y' and base ne . then chg = aval - base;
  if chg ne . and base > 0 then pchg = chg / base * 100;
  if pchg ne . and (pddt = . or adt <= pddt) then anl01fl = 'Y';
run;

/* best percent change: lowest PCHG, earliest date if tied */
proc sort data=sd2 out=best(where=(anl01fl = 'Y'));
  by usubjid pchg adt;
run;

data best;
  set best;
  by usubjid;
  if first.usubjid;
  length anl02fl $1;
  anl02fl = 'Y';
  keep usubjid avisitn adt anl02fl;
run;

proc sort data=sd2;
  by usubjid adt avisitn;
run;

data adtr0;
  merge sd2(in=_a) best;
  by usubjid adt avisitn;
  if _a;
  label
    studyid  = 'Study Identifier'
    usubjid  = 'Unique Subject Identifier'
    trt01p   = 'Planned Treatment for Period 01'
    trt01pn  = 'Planned Treatment for Period 01 (N)'
    trt01a   = 'Actual Treatment for Period 01'
    trt01an  = 'Actual Treatment for Period 01 (N)'
    trtsdt   = 'Date of First Exposure to Treatment'
    ittfl    = 'Intent-To-Treat Population Flag'
    paramcd  = 'Parameter Code'
    param    = 'Parameter'
    paramn   = 'Parameter (N)'
    aval     = 'Analysis Value'
    base     = 'Baseline Value'
    chg      = 'Change from Baseline'
    pchg     = 'Percent Change from Baseline'
    ablfl    = 'Baseline Record Flag'
    adt      = 'Analysis Date'
    ady      = 'Analysis Relative Day'
    avisit   = 'Analysis Visit'
    avisitn  = 'Analysis Visit (N)'
    anl01fl  = 'Analysis Flag 01'
    anl02fl  = 'Analysis Flag 02'
    srcdom   = 'Source Data'
    srcvar   = 'Source Variable'
    srcseq   = 'Source Sequence Number';
run;

%finalize(adtr0, adtr, Tumor Results Analysis Dataset, lib=adam,
  vars=STUDYID USUBJID TRT01P TRT01PN TRT01A TRT01AN TRTSDT ITTFL PARAMCD PARAM PARAMN AVAL BASE CHG PCHG
    ABLFL ADT ADY AVISIT AVISITN ANL01FL ANL02FL SRCDOM SRCVAR SRCSEQ,
  keys=STUDYID USUBJID PARAMCD ADT)
