/*******************************************************************************
Program : ex.sas
Purpose : Create SDTM EX
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\sdtm\setup.sas";

%getsrc(ex)

proc sql;
  create table ex0 as
  select a.*, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from ex a left join sdtm.dm d on a.usubjid = d.usubjid;
quit;

data ex1;
  set ex0;
  %epoch(exstdtc)
  %dy(exstdtc, exstdy)
  %dy(exendtc, exendy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    exseq    = 'Sequence Number'
    extrt    = 'Name of Treatment'
    exdose   = 'Dose'
    exdosu   = 'Dose Units'
    exdosfrm = 'Dose Form'
    exdosfrq = 'Dosing Frequency per Interval'
    exroute  = 'Route of Administration'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    visitdy  = 'Planned Study Day of Visit'
    epoch    = 'Epoch'
    exstdtc  = 'Start Date/Time of Treatment'
    exendtc  = 'End Date/Time of Treatment'
    exstdy   = 'Study Day of Start of Treatment'
    exendy   = 'Study Day of End of Treatment';
run;

%finalize(ex1, ex, Exposure,
  vars=STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSU EXDOSFRM EXDOSFRQ EXROUTE VISITNUM VISIT VISITDY EPOCH EXSTDTC EXENDTC EXSTDY EXENDY,
  keys=STUDYID USUBJID EXTRT EXSTDTC)
