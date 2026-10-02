/*******************************************************************************
Program : adrs.sas
Purpose : Create ADaM ADRS
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\adam\setup.sas";

proc format;
invalue avalrs
'CR' = 1
'PR' = 2
'SD' = 3
'NON-CR/NON-PD' = 4
'PD' = 5
'NE' = 6
'MISSING' = 7;
run;

/* overall response by visit: accepted records (Radiologist 1) with a result */
data ovr0;
  set sdtm.rs(where=(rstestcd = 'OVRLRESP' and rsacptfl = 'Y' and rsorres ne ''));
  length paramcd srcdom srcvar $8 param avisit $40 avalc $20;
  paramcd = 'OVR';
  param = 'Overall Response by Visit';
  paramn = 1;
  avalc = rsorres;
  aval = input(avalc, avalrs.);
  %dt(rsdtc, adt)
  avisit = visit;
  avisitn = visitnum;
  srcdom = 'RS';
  srcvar = 'RSORRES';
  srcseq = rsseq;
  keep usubjid paramcd param paramn avalc aval adt avisit avisitn srcdom srcvar srcseq;
run;

%addadsl(ovr0, ovr1, studyid trt01p trt01pn trt01a trt01an trtsdt ittfl)

proc sql;
  create table pdd as
  select usubjid, min(adt) as pddt format=date9. from ovr1 where avalc = 'PD' group by usubjid;
quit;

proc sort data=ovr1;
  by usubjid adt;
run;

/* records after the first PD are not analyzed */
data ovr;
  merge ovr1(in=_in where=(ittfl = 'Y')) pdd;
  by usubjid;
  if _in;
  length anl01fl $1;
  if pddt = . or adt <= pddt then anl01fl = 'Y';
  %ady(adt, ady)
  drop pddt;
run;

/* PD: first progression */
data pdrec;
  set ovr(where=(avalc = 'PD'));
  by usubjid;
  if first.usubjid;
  paramcd = 'PD';
  param = 'Disease Progression';
  paramn = 2;
  avalc = 'Y';
  aval = 1;
  anl01fl = '';
run;

/* BOR: unconfirmed, SD needs study day 42 */
data bor0;
  set ovr(where=(anl01fl = 'Y'));
  length bor $20;
  if avalc in ('CR', 'PR') then bor = avalc;
  else if avalc = 'SD' and ady >= 42 then bor = 'SD';
  else if avalc = 'PD' then bor = 'PD';
  else bor = 'NE';
  rank = whichc(bor, 'CR', 'PR', 'SD', 'PD', 'NE');
run;

proc sort data=bor0;
  by usubjid rank adt;
run;

data bor1;
  set bor0;
  by usubjid;
  if first.usubjid;
  avalc = bor;
  keep usubjid avalc adt ady avisit avisitn srcdom srcvar srcseq;
run;

proc sql;
  create table itt as
  select studyid, usubjid, trt01p, trt01pn, trt01a, trt01an, trtsdt, ittfl
  from adam.adsl where ittfl = 'Y' order by usubjid;
quit;

data borrec;
  length paramcd srcdom srcvar $8 param $40 avalc $20 anl01fl $1;
  merge itt(in=_a) bor1(in=_b);
  by usubjid;
  if _a;
  paramcd = 'BOR';
  param = 'Best Overall Response';
  paramn = 3;
  if not _b then avalc = 'MISSING';
  aval = input(avalc, avalrs.);
run;

data rsprec;
  set borrec;
  paramcd = 'RSP';
  param = 'Objective Response (BOR CR or PR)';
  paramn = 4;
  avalc = ifc(avalc in ('CR', 'PR'), 'Y', 'N');
  aval = (avalc = 'Y');
run;

data adrs0;
  length paramcd srcdom srcvar $8 param avisit $40 avalc $20 anl01fl $1;
  set ovr pdrec borrec rsprec;
run;

proc sort data=adrs0;
  by usubjid paramn adt avisitn;
run;

data adrs1;
  set adrs0;
  by usubjid;
  if first.usubjid then aseq = 0;
  aseq + 1;
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
    avalc    = 'Analysis Value (C)'
    aval     = 'Analysis Value'
    adt      = 'Analysis Date'
    ady      = 'Analysis Relative Day'
    avisit   = 'Analysis Visit'
    avisitn  = 'Analysis Visit (N)'
    aseq     = 'Analysis Sequence Number'
    anl01fl  = 'Analysis Flag 01'
    srcdom   = 'Source Data'
    srcvar   = 'Source Variable'
    srcseq   = 'Source Sequence Number';
run;

%finalize(adrs1, adrs, Response Analysis Dataset, lib=adam,
  vars=STUDYID USUBJID TRT01P TRT01PN TRT01A TRT01AN TRTSDT ITTFL PARAMCD PARAM PARAMN AVALC AVAL
    ADT ADY AVISIT AVISITN ASEQ ANL01FL SRCDOM SRCVAR SRCSEQ,
  keys=STUDYID USUBJID PARAMCD ADT)
