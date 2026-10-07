/*******************************************************************************
Program : sv.sas
Purpose : Create SDTM SV
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\sdtm\setup.sas";

%getsrc(sv)

/* unscheduled visits renumbered: 9.1 is the planned WEEK 14 (T) */
data sv;
  set sv;
  if usubjid = '01-711-1143' then do;
    if svstdtc = '2013-09-22' and visitnum = 9.2 then do;
      visitnum = 9.3;
      visit = 'UNSCHEDULED 9.3';
    end;
    else if svstdtc = '2013-06-22' and visitnum = 9.1 then do;
      visitnum = 9.2;
      visit = 'UNSCHEDULED 9.2';
    end;
  end;
run;

proc sql;
  create table sv0 as
  select a.*, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from sv a left join sdtm.dm d on a.usubjid = d.usubjid;
quit;

data sv1;
  set sv0;
  /* planned visit: not an unscheduled one */
  if substr(visit, 1, 11) ne 'UNSCHEDULED' then do;
    svpresp = 'Y';
    svoccur = 'Y';
  end;
  %epoch(svstdtc)
  %dy(svstdtc, svstdy)
  %dy(svendtc, svendy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    svpresp  = 'Pre-specified'
    svoccur  = 'Occurrence'
    visitdy  = 'Planned Study Day of Visit'
    epoch    = 'Epoch'
    svstdtc  = 'Start Date/Time of Observation'
    svendtc  = 'End Date/Time of Observation'
    svstdy   = 'Study Day of Start of Observation'
    svendy   = 'Study Day of End of Observation';
run;

%finalize(sv1, sv, Subject Visits,
  vars=STUDYID DOMAIN USUBJID VISITNUM VISIT SVPRESP SVOCCUR VISITDY EPOCH SVSTDTC SVENDTC SVSTDY SVENDY,
  keys=STUDYID USUBJID VISITNUM)
