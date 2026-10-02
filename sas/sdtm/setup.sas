/*******************************************************************************
Program : setup.sas
Purpose : Paths, source import, shared macros for the SDTM programs
*******************************************************************************/

%let root = U:\My SAS Files\Portfolio2;
%let src  = &root/data/source;
%let xpt  = &root/data/derived/sdtm;

options validvarname=upcase dlcreatedir compress=yes;
libname sdtm "&xpt";

/* read one source xpt into work */
%macro getsrc(name);
libname _src xport "&src/&name..xpt";
proc copy in=_src out=work memtype=data;
run;
libname _src clear;
%mend getsrc;

/* study day, complete dates only; needs rfstdtc on the record */
%macro dy(dtc, out);
&out = .;
if length(&dtc) >= 10 and length(rfstdtc) >= 10 then do;
  &out = input(substr(&dtc, 1, 10), e8601da.) - input(substr(rfstdtc, 1, 10), e8601da.);
  &out = &out + (&out >= 0);
end;
%mend dy;

/* epoch from treatment dates; partial dates stay null */
%macro epoch(dtc);
if length(&dtc) >= 10 then do;
  if missing(rfxstdtc) or substr(&dtc, 1, 10) < substr(rfxstdtc, 1, 10) then epoch = 'SCREENING';
  else if missing(rfxendtc) or substr(&dtc, 1, 10) <= substr(rfxendtc, 1, 10) then epoch = 'TREATMENT';
  else epoch = 'FOLLOW-UP';
end;
%mend epoch;

/* pre-dose: before first dose, or baseline visit on the first-dose date or partial */
%macro predose(dtc);
_pre = length(rfxstdtc) >= 10 and
  ((length(&dtc) >= 10 and substr(&dtc, 1, 10) < substr(rfxstdtc, 1, 10)) or
  (visitnum = 3 and not missing(&dtc) and
  (length(&dtc) < 10 or substr(&dtc, 1, 10) = substr(rfxstdtc, 1, 10))));
%mend predose;

/* pre-dose records are SCREENING, also on the first-dose date */
%macro fepoch(dtc);
if _pre and length(&dtc) >= 10 then epoch = 'SCREENING';
else %epoch(&dtc)
%mend fepoch;

/* flag last pre-dose record with a result, per subject and &by */
%macro lobxfl(in, flag, by=, res=, dtc=);
proc sort data=&in(where=(_pre and not missing(&res))) out=_lobx(keep=_row usubjid &by &dtc visitnum);
  by usubjid &by &dtc visitnum;
run;

data _lobx;
  set _lobx;
  by usubjid &by;
  if last.%scan(&by, -1);
  keep _row;
run;

proc sort data=_lobx;
  by _row;
run;

proc sort data=&in;
  by _row;
run;

data &in;
  merge &in _lobx(in=_hit);
  by _row;
  length &flag $1;
  if _hit then &flag = 'Y';
run;
%mend lobxfl;

%include "&root/sas/macros/finalize.sas";
