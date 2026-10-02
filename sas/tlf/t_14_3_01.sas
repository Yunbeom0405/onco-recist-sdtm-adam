/*******************************************************************************
Program : t_14_3_01.sas
Purpose : Table 14-3.01 Progression-Free Survival
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\tlf\setup.sas";

%bign(trt01p, where=%str(ittfl = 'Y'))

data tte;
  set adam.adtte(where=(paramcd = 'PFS' and ittfl = 'Y'));
  col = input(put(trt01p, $trtcol.), 1.);
run;

proc format;
value col
  1 = 'Placebo'
  2 = 'Xanomeline Low Dose'
  3 = 'Xanomeline High Dose';
run;

/* Kaplan-Meier: median and rates at day 60, 120, 180 (log-log limits) */
ods exclude all;
ods output Quartiles=q;
proc lifetest data=tte timelist=60 120 180 reduceout conftype=loglog outsurv=os;
  time aval * cnsr(1);
  strata col;
  format col col.;
run;
ods exclude none;

proc sql;
  create table cnt as
  select col, count(*) as n,
    sum(cnsr = 0) as ev, sum(evntdesc = 'PROGRESSIVE DISEASE') as pd,
    sum(evntdesc = 'DEATH') as dth, sum(cnsr = 1) as cens
  from tte
  group by col;
quit;

data cntl;
  set cnt;
  length label $200 val $40;
  row = 1; indent = 0; label = 'Subjects, n'; val = cats(n); output;
  row = 2; indent = 0; label = 'Events, n (%)'; val = %npct(ev, n, d=1); output;
  row = 3; indent = 1; label = 'Progressive disease'; val = %npct(pd, n, d=1); output;
  row = 4; indent = 1; label = 'Death'; val = %npct(dth, n, d=1); output;
  row = 5; indent = 0; label = 'Censored, n (%)'; val = %npct(cens, n, d=1); output;
  keep col row indent label val;
run;

data medl;
  set q(where=(percent = 50));
  length label $200 val $40;
  col = whichc(strip(vvalue(col)), 'Placebo', 'Xanomeline Low Dose', 'Xanomeline High Dose');
  row = 6; indent = 0; label = 'Median (95% CI), days';
  if estimate = . then val = 'NE';
  else val = cat(%f(estimate, 1), ' (', coalescec(%f(lowerlimit, 1), 'NE'), '; ', coalescec(%f(upperlimit, 1), 'NE'), ')');
  keep col row indent label val;
run;

data ratel;
  set os;
  length label $200 val $40;
  if missing(timelist) then delete;
  row = 6 + timelist / 60; indent = 0; label = catx(' ', 'PFS rate at Day', timelist, '(95% CI)');
  if missing(survival) then val = 'NE';
  else val = cat(%f(survival, 3), ' (', coalescec(%f(sdf_lcl, 3), 'NE'), '; ', coalescec(%f(sdf_ucl, 3), 'NE'), ')');
  keep col row indent label val;
run;

/* hazard ratio (Cox, Efron ties, Wald limits) and log-rank test against placebo */
%macro cmp(k);
  data sub;
    set tte(where=(col in (1, &k)));
    ind = (col = &k);
  run;

  ods exclude all;
  ods output ParameterEstimates=pe;
  proc phreg data=sub;
    model aval * cnsr(1) = ind / ties=efron risklimits;
  run;
  ods output HomTests=ht;
  proc lifetest data=sub;
    time aval * cnsr(1);
    strata ind / test=logrank;
  run;
  ods exclude none;

  data cmp&k;
    length label $200 val $40;
    col = &k; indent = 0;
    set pe(keep=hazardratio hrlowercl hruppercl);
    row = 10; label = 'Hazard ratio vs Placebo (95% CI)';
    val = cat(%f(hazardratio, 3), ' (', %f(hrlowercl, 3), '; ', %f(hruppercl, 3), ')');
    output;
    set ht(where=(test = 'Log-Rank') keep=test probchisq);
    row = 11; label = 'Log-rank p-value vs Placebo';
    val = %pv(probchisq);
    output;
    keep col row indent label val;
  run;
%mend cmp;
%cmp(2)
%cmp(3)

data blank;
  length label $200 val $40;
  col = 1; indent = 0; val = '';
  row = 10; label = 'Hazard ratio vs Placebo (95% CI)'; output;
  row = 11; label = 'Log-rank p-value vs Placebo'; output;
run;

data long;
  set cntl medl ratel cmp2 cmp3 blank;
  /* the format of COL from PROC LIFETEST would name the transposed columns */
  format col;
run;

proc sort data=long;
  by row label indent col;
run;

proc transpose data=long out=t_14_3_01(drop=_name_) prefix=c;
  by row label indent;
  id col;
  var val;
run;

%report(t_14_3_01, t_14_3_01, Table 14-3.01 Progression-Free Survival,
  cols=c1 c2 c3,
  heads=Placebo|(N=&n1)#Xanomeline|Low Dose|(N=&n2)#Xanomeline|High Dose|(N=&n3),
  foot1=Population: Intent-to-Treat. Event: first progressive disease or death. Censored at last tumor assessment or at randomization.,
  foot2=Kaplan-Meier%str(,) 95% CI log-log. Hazard ratio: Cox model%str(,) Efron ties. NE: not estimable.)
