/*******************************************************************************
Program : adtte.sas
Purpose : Create ADaM ADTTE
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\adam\setup.sas";

proc sql;
  create table pdd as
  select usubjid, adt as pddt format=date9. from adam.adrs where paramcd = 'PD' order by usubjid;

  create table lastass as
  select usubjid, max(adt) as lastdt format=date9.
  from adam.adrs where paramcd = 'OVR' and anl01fl = 'Y'
  group by usubjid order by usubjid;

  create table itt as
  select studyid, usubjid, trt01p, trt01pn, trt01a, trt01an, trtsdt, ittfl,
    randdt, dthdt, lstalvdt
  from adam.adsl where ittfl = 'Y' order by usubjid;
quit;

data base;
  merge itt(in=_in) pdd lastass;
  by usubjid;
  if _in;
  length avalu $8 evntdesc cnsdtdsc $40 srcdom srcvar $8;
  avalu = 'DAYS';
  startdt = randdt;
  format startdt adt date9.;
run;

data pfs;
  set base;
  length paramcd $8 param $40;
  paramcd = 'PFS';
  param = 'Progression-Free Survival';
  paramn = 1;
  if pddt ne . and (dthdt = . or pddt <= dthdt) then do;
    adt = pddt; cnsr = 0; evntdesc = 'PROGRESSIVE DISEASE'; srcdom = 'RS'; srcvar = 'RSORRES';
  end;
  else if dthdt ne . then do;
    adt = dthdt; cnsr = 0; evntdesc = 'DEATH'; srcdom = 'DM'; srcvar = 'DTHDTC';
  end;
  else if lastdt ne . then do;
    adt = lastdt; cnsr = 1; cnsdtdsc = 'LAST TUMOR ASSESSMENT'; srcdom = 'RS'; srcvar = 'RSDTC';
  end;
  else do;
    adt = startdt; cnsr = 1; cnsdtdsc = 'RANDOMIZATION'; srcdom = 'ADSL'; srcvar = 'RANDDT';
  end;
run;

data os;
  set base;
  length paramcd $8 param $40;
  paramcd = 'OS';
  param = 'Overall Survival';
  paramn = 2;
  if dthdt ne . then do;
    adt = dthdt; cnsr = 0; evntdesc = 'DEATH'; srcdom = 'DM'; srcvar = 'DTHDTC';
  end;
  else do;
    adt = lstalvdt; cnsr = 1; cnsdtdsc = 'LAST KNOWN ALIVE DATE'; srcdom = 'ADSL'; srcvar = 'LSTALVDT';
  end;
run;

data adtte1;
  set pfs os;
  aval = adt - startdt + 1;
  label
    studyid  = 'Study Identifier'
    usubjid  = 'Unique Subject Identifier'
    trt01p   = 'Planned Treatment for Period 01'
    trt01pn  = 'Planned Treatment for Period 01 (N)'
    trt01a   = 'Actual Treatment for Period 01'
    trt01an  = 'Actual Treatment for Period 01 (N)'
    trtsdt   = 'Date of First Exposure to Treatment'
    ittfl    = 'Intent-to-Treat Population Flag'
    paramcd  = 'Parameter Code'
    param    = 'Parameter'
    paramn   = 'Parameter (N)'
    aval     = 'Analysis Value'
    avalu    = 'Analysis Value Unit'
    startdt  = 'Time to Event Origin Date for Subject'
    adt      = 'Analysis Date'
    cnsr     = 'Censor'
    evntdesc = 'Event or Censoring Description'
    cnsdtdsc = 'Censor Date Description'
    srcdom   = 'Source Data'
    srcvar   = 'Source Variable';
run;

%finalize(adtte1, adtte, Time to Event Analysis Dataset, lib=adam,
  vars=STUDYID USUBJID TRT01P TRT01PN TRT01A TRT01AN TRTSDT ITTFL PARAMCD PARAM PARAMN AVAL AVALU
    STARTDT ADT CNSR EVNTDESC CNSDTDSC SRCDOM SRCVAR,
  keys=STUDYID USUBJID PARAMCD)
