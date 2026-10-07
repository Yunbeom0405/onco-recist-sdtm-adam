/*******************************************************************************
Program : rs.sas
Purpose : Create SDTM RS
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\sdtm\setup.sas";

%getsrc(rs_onco)

proc sql;
  create table rs0 as
  select a.*, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from rs_onco a left join sdtm.dm d on a.usubjid = d.usubjid;
quit;

data rs1;
  set rs0;
  /* 2013-09-22 unscheduled visit is 9.3; 9.1 is the planned WEEK 14 (T) */
  if usubjid = '01-711-1143' and rsdtc =: '2013-09-22' and visitnum = 9.2 then do;
    visitnum = 9.3;
    visit = 'UNSCHEDULED 9.3';
  end;
  /* placeholder value in source, not a response */
  if rsorres = 'CHECK' then do;
    rsorres = '';
    rsstresc = '';
    rsstat = 'NOT DONE';
    rsreasnd = 'SOURCE VALUE CHECK';
  end;
  /* not evaluable is a result, the assessment was done */
  if rsorres = 'NE' then do;
    rsstat = '';
    rsreasnd = '';
  end;
  %predose(rsdtc)
  %fepoch(rsdtc)
  %dy(rsdtc, rsdy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    rsseq    = 'Sequence Number'
    rslnkgrp = 'Link Group ID'
    rstestcd = 'Assessment Short Name'
    rstest   = 'Assessment Name'
    rscat    = 'Category for Assessment'
    rsorres  = 'Result or Finding in Original Units'
    rsstresc = 'Character Result/Finding in Std Format'
    rsstat   = 'Completion Status'
    rsreasnd = 'Reason Not Done'
    rseval   = 'Evaluator'
    rsevalid = 'Evaluator Identifier'
    rsacptfl = 'Accepted Record Flag'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    epoch    = 'Epoch'
    rsdtc    = 'Date/Time of Assessment'
    rsdy     = 'Study Day of Assessment';
run;

%finalize(rs1, rs, Disease Response and Clin Classification,
  vars=STUDYID DOMAIN USUBJID RSSEQ RSLNKGRP RSTESTCD RSTEST RSCAT RSORRES RSSTRESC RSSTAT RSREASND RSEVAL RSEVALID RSACPTFL VISITNUM VISIT EPOCH RSDTC RSDY,
  keys=STUDYID USUBJID RSEVAL RSEVALID RSTESTCD VISITNUM)
