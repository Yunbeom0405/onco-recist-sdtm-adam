/*******************************************************************************
Program : ds.sas
Purpose : Create SDTM DS
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\sdtm\setup.sas";

%getsrc(ds)

proc sql;
  create table ds0 as
  select a.*, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from ds a left join sdtm.dm d on a.usubjid = d.usubjid;
quit;

data ds1;
  set ds0;
  dsspid = left(dsspid);
  %epoch(dsstdtc)
  if dscat = 'PROTOCOL MILESTONE' then epoch = 'SCREENING';
  %dy(dsstdtc, dsstdy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    dsseq    = 'Sequence Number'
    dsspid   = 'Sponsor-Defined Identifier'
    dsterm   = 'Reported Term for the Disposition Event'
    dsdecod  = 'Standardized Disposition Term'
    dscat    = 'Category for Disposition Event'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    epoch    = 'Epoch'
    dsdtc    = 'Date/Time of Collection'
    dsstdtc  = 'Start Date/Time of Disposition Event'
    dsstdy   = 'Study Day of Start of Disposition Event';
run;

%finalize(ds1, ds, Disposition,
  vars=STUDYID DOMAIN USUBJID DSSEQ DSSPID DSTERM DSDECOD DSCAT VISITNUM VISIT EPOCH DSDTC DSSTDTC DSSTDY,
  keys=STUDYID USUBJID DSDECOD DSSTDTC)
