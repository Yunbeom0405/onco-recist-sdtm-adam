/*******************************************************************************
Program : tu.sas
Purpose : Create SDTM TU
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\sdtm\setup.sas";

%getsrc(tu_onco)

proc sql;
  create table tu0 as
  select a.*, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from tu_onco a left join sdtm.dm d on a.usubjid = d.usubjid;
quit;

data tu1;
  set tu0;
  length tulobxfl $1;
  call missing(tulobxfl);
  _row = _n_;
  %predose(tudtc)
  %fepoch(tudtc)
  %dy(tudtc, tudy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    tuseq    = 'Sequence Number'
    tulnkid  = 'Link ID'
    tutestcd = 'Tumor/Lesion ID Short Name'
    tutest   = 'Tumor/Lesion ID Test Name'
    tuorres  = 'Tumor/Lesion ID Result'
    tustresc = 'Tumor/Lesion ID Result Std. Format'
    tuloc    = 'Location of the Tumor/Lesion'
    tumethod = 'Method of Identification'
    tulobxfl = 'Last Observation Before Exposure Flag'
    tueval   = 'Evaluator'
    tuevalid = 'Evaluator Identifier'
    tuacptfl = 'Accepted Record Flag'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    epoch    = 'Epoch'
    tudtc    = 'Date/Time of Tumor/Lesion Identification'
    tudy     = 'Study Day of Tumor/Lesion Identification';
run;

%lobxfl(tu1, tulobxfl, by=tulnkid tutestcd tueval tuevalid, res=tuorres, dtc=tudtc)

%finalize(tu1, tu, Tumor/Lesion Identification,
  vars=STUDYID DOMAIN USUBJID TUSEQ TULNKID TUTESTCD TUTEST TUORRES TUSTRESC TULOC TUMETHOD TULOBXFL TUEVAL TUEVALID TUACPTFL VISITNUM VISIT EPOCH TUDTC TUDY,
  keys=STUDYID USUBJID TUEVAL TUEVALID TULNKID)
