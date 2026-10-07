/*******************************************************************************
Program : t_14_2_01.sas
Purpose : Table 14-2.01 Best Overall Response and Objective Response Rate
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\tlf\setup.sas";

%bign(trt01p, where=%str(ittfl = 'Y'))

data pop;
  set adam.adrs(where=(paramcd = 'BOR'));
  col = input(put(trt01p, $trtcol.), 1.);
  output;
  col = 4;
  output;
run;

proc sql;
  create table cnt as
  select col, count(*) as n,
    sum(avalc = 'CR') as r1, sum(avalc = 'PR') as r2, sum(avalc = 'SD') as r3,
    sum(avalc = 'PD') as r4, sum(avalc = 'NE') as r5, sum(avalc = 'MISSING') as r6,
    sum(avalc in ('CR', 'PR')) as x
  from pop
  group by col;
quit;

data long;
  set cnt;
  length label $200 val $40;
  array r{6} r1-r6;
  row = 1; indent = 0; label = 'Best overall response (unconfirmed), n (%)'; val = ''; output;
  do i = 1 to 6;
    row = i + 1; indent = 1;
    label = choosec(i, 'Complete response (CR)', 'Partial response (PR)', 'Stable disease (SD)',
      'Progressive disease (PD)', 'Not evaluable (NE)', 'Missing (no assessment)');
    val = %npct(r{i}, n, d=1);
    output;
  end;
  row = 8; indent = 0; label = 'Objective response (CR or PR), n (%)'; val = %npct(x, n, d=1); output;
  /* Clopper-Pearson exact limits */
  if x = 0 then lo = 0; else lo = betainv(0.025, x, n - x + 1);
  if x = n then up = 1; else up = betainv(0.975, x + 1, n - x);
  row = 9; indent = 1; label = '95% CI (Clopper-Pearson)'; val = cat(%f(lo * 100, 1), '; ', %f(up * 100, 1)); output;
  keep col row indent label val;
run;

proc sort data=long;
  by row label indent;
run;

proc transpose data=long out=t_14_2_01(drop=_name_) prefix=c;
  by row label indent;
  id col;
  var val;
run;

%report(t_14_2_01, t_14_2_01, Table 14-2.01 Best Overall Response and Objective Response Rate,
  cols=c1 c2 c3 c4,
  heads=Placebo|(N=&n1)#Xanomeline|Low Dose|(N=&n2)#Xanomeline|High Dose|(N=&n3)#Total|(N=&n4),
  foot1=Population: Intent-to-Treat. RECIST 1.1 by Radiologist 1. Responses are unconfirmed; assessments after the first PD are not used.,
  foot2=SD requires study day 42 or later; earlier SD counts as NE. Missing: no tumor assessment.)
