/*******************************************************************************
Program : adsl.sas
Purpose : Create ADaM ADSL
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\adam\setup.sas";

proc format;
invalue trtn
'Placebo' = 0
'Xanomeline Low Dose' = 54
'Xanomeline High Dose' = 81;
run;

proc sql;
  create table rand as
  select usubjid, dsstdtc as randdtc from sdtm.ds where dsdecod = 'RANDOMIZED';

  create table eos as
  select usubjid, dsdecod as eosdecod, dsstdtc as eosdtc
  from sdtm.ds where dscat = 'DISPOSITION EVENT';

  create table hasex as
  select distinct usubjid, 'Y' as hasex length=1 from sdtm.ex;

  /* latest complete date seen for the subject, death records excluded */
  create table lastdt as
  select usubjid, max(input(d, e8601da.)) as lstalvdt format=date9.
  from (
    select usubjid, substr(svstdtc, 1, 10) as d from sdtm.sv union all
    select usubjid, substr(svendtc, 1, 10) from sdtm.sv union all
    select usubjid, substr(exstdtc, 1, 10) from sdtm.ex union all
    select usubjid, substr(exendtc, 1, 10) from sdtm.ex union all
    select usubjid, substr(trdtc, 1, 10) from sdtm.tr union all
    select usubjid, substr(rsdtc, 1, 10) from sdtm.rs union all
    select usubjid, substr(dsstdtc, 1, 10) from sdtm.ds where dsdecod ne 'DEATH' union all
    select usubjid, substr(rfxstdtc, 1, 10) from sdtm.dm)
  where length(strip(d)) = 10
  group by usubjid;

  create table adsl0 as
  select m.*, r.randdtc, e.eosdecod, e.eosdtc, x.hasex, l.lstalvdt
  from sdtm.dm as m
  left join rand as r on m.usubjid = r.usubjid
  left join eos as e on m.usubjid = e.usubjid
  left join hasex as x on m.usubjid = x.usubjid
  left join lastdt as l on m.usubjid = l.usubjid;
quit;

data adsl1;
  set adsl0;
  length agegr1 $5 trt01p trt01a $40 trtedtc $20 ittfl saffl $1 eosstt $12 dcsreas $40;
  trt01p = arm;
  trt01a = actarm;
  if trt01p ne '' then trt01pn = input(trt01p, trtn.);
  if trt01a ne '' then trt01an = input(trt01a, trtn.);
  if age ne . then do;
    agegr1 = ifc(age < 65, '<65', ifc(age <= 80, '65-80', '>80'));
    agegr1n = ifn(age < 65, 1, ifn(age <= 80, 2, 3));
  end;
  %dt(randdtc, randdt)
  %dt(rfxstdtc, trtsdt)
  trtedtc = coalescec(rfxendtc, rfendtc);
  %dt(trtedtc, trtedt)
  %dt(dthdtc, dthdt)
  ittfl = ifc(randdtc ne '', 'Y', 'N');
  saffl = ifc(ittfl = 'Y' and hasex = 'Y', 'Y', 'N');
  eosstt = ifc(eosdecod = 'COMPLETED', 'COMPLETED', 'DISCONTINUED');
  if eosstt = 'DISCONTINUED' then dcsreas = eosdecod;
  %dt(eosdtc, eosdt)
  label
    studyid  = 'Study Identifier'
    usubjid  = 'Unique Subject Identifier'
    subjid   = 'Subject Identifier for the Study'
    siteid   = 'Study Site Identifier'
    age      = 'Age'
    agegr1   = 'Pooled Age Group 1'
    agegr1n  = 'Pooled Age Group 1 (N)'
    ageu     = 'Age Units'
    sex      = 'Sex'
    race     = 'Race'
    ethnic   = 'Ethnicity'
    arm      = 'Description of Planned Arm'
    actarm   = 'Description of Actual Arm'
    armnrs   = 'Reason Arm and/or Actual Arm is Null'
    trt01p   = 'Planned Treatment for Period 01'
    trt01pn  = 'Planned Treatment for Period 01 (N)'
    trt01a   = 'Actual Treatment for Period 01'
    trt01an  = 'Actual Treatment for Period 01 (N)'
    randdt   = 'Date of Randomization'
    trtsdt   = 'Date of First Exposure to Treatment'
    trtedt   = 'Date of Last Exposure to Treatment'
    ittfl    = 'Intent-to-Treat Population Flag'
    saffl    = 'Safety Population Flag'
    dthfl    = 'Subject Death Flag'
    dthdt    = 'Date of Death'
    lstalvdt = 'Date Last Known Alive'
    eosstt   = 'End of Study Status'
    eosdt    = 'End of Study Date'
    dcsreas  = 'Reason for Discontinuation from Study';
run;

%finalize(adsl1, adsl, Subject-Level Analysis Dataset, lib=adam,
  vars=STUDYID USUBJID SUBJID SITEID AGE AGEGR1 AGEGR1N AGEU SEX RACE ETHNIC ARM ACTARM ARMNRS
    TRT01P TRT01PN TRT01A TRT01AN RANDDT TRTSDT TRTEDT ITTFL SAFFL DTHFL DTHDT LSTALVDT
    EOSSTT EOSDT DCSREAS,
  keys=STUDYID USUBJID)
