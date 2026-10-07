/*******************************************************************************
Program : tr.sas
Purpose : Create SDTM TR
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\sdtm\setup.sas";

%getsrc(tr_onco)

proc sql;
  create table tr0 as
  select a.*, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from tr_onco a left join sdtm.dm d on a.usubjid = d.usubjid;
quit;

data tr1;
  set tr0;
  length trlobxfl $1;
  call missing(trlobxfl);
  _row = _n_;
  /* 2013-09-22 unscheduled visit is 9.3; 9.1 is the planned WEEK 14 (T) */
  if usubjid = '01-711-1143' and trdtc =: '2013-09-22' and visitnum = 9.2 then do;
    visitnum = 9.3;
    visit = 'UNSCHEDULED 9.3';
  end;
  %predose(trdtc)
  %fepoch(trdtc)
  %dy(trdtc, trdy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    trseq    = 'Sequence Number'
    trgrpid  = 'Group ID'
    trlnkid  = 'Link ID'
    trlnkgrp = 'Link Group'
    trtestcd = 'Tumor/Lesion Assessment Short Name'
    trtest   = 'Tumor/Lesion Assessment Test Name'
    trorres  = 'Result or Finding in Original Units'
    trorresu = 'Original Units'
    trstresc = 'Character Result/Finding in Std Format'
    trstresn = 'Numeric Result/Finding in Standard Units'
    trstresu = 'Standard Units'
    trstat   = 'Completion Status'
    trreasnd = 'Reason Not Done'
    trmethod = 'Method Used to Identify the Tumor/Lesion'
    trlobxfl = 'Last Observation Before Exposure Flag'
    treval   = 'Evaluator'
    trevalid = 'Evaluator Identifier'
    tracptfl = 'Accepted Record Flag'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    epoch    = 'Epoch'
    trdtc    = 'Date/Time of Tumor/Lesion Measurement'
    trdy     = 'Study Day of Tumor/Lesion Measurement';
run;

%lobxfl(tr1, trlobxfl, by=trlnkid trtestcd treval trevalid, res=trorres, dtc=trdtc)

%finalize(tr1, tr, Tumor/Lesion Results,
  vars=STUDYID DOMAIN USUBJID TRSEQ TRGRPID TRLNKID TRLNKGRP TRTESTCD TRTEST TRORRES TRORRESU TRSTRESC TRSTRESN TRSTRESU TRSTAT TRREASND TRMETHOD TRLOBXFL TREVAL TREVALID TRACPTFL VISITNUM VISIT EPOCH TRDTC TRDY,
  keys=STUDYID USUBJID TREVAL TREVALID TRLNKID TRTESTCD VISITNUM)
