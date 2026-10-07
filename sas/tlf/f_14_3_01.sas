/*******************************************************************************
Program : f_14_3_01.sas
Purpose : Figure 14-3.01 Kaplan-Meier: Progression-Free Survival
          (+ statistics table f_14_3_01_stats for QC)
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

ods listing close;
ods rtf file="&out/f_14_3_01.rtf" style=journal bodytitle;
ods graphics on / width=9in height=5.5in;
title1 j=l 'Protocol: CDISCPILOT01';
title2 'Figure 14-3.01 Kaplan-Meier: Progression-Free Survival by Treatment Group';
footnote1 j=l 'Population: Intent-to-Treat. Event: first progressive disease or death.';
footnote2 j=l 'Censored at last tumor assessment or at randomization. Source: sas/tlf/f_14_3_01.sas';

ods output Quartiles=q ProductLimitEstimates=pl CensoredSummary=cs;
proc lifetest data=tte plots=survival(atrisk=0 to 210 by 30) timelist=30 60 90 120 150 180 reduceout;
  time aval * cnsr(1);
  strata col;
  format col col.;
run;

ods rtf close;
ods graphics off;
ods listing;
title;
footnote;

/* statistics for QC: N, events, censored, median (95% CI), KM estimates */
data stats;
  length label $200 val $40;
  set cs(in=a) q(where=(percent = 50) in=b) pl(in=c);
  if missing(stratum) then delete;
  column = whichc(strip(vvalue(col)), 'Placebo', 'Xanomeline Low Dose', 'Xanomeline High Dose');
  if a then do;
    ord = 1; label = 'N'; val = cats(total); output;
    ord = 2; label = 'Events'; val = cats(failed); output;
    ord = 3; label = 'Censored'; val = cats(censored); output;
  end;
  else if b then do;
    ord = 4; label = 'Median (95% CI)';
    if estimate = . then val = 'NE';
    else val = cat(%f(estimate, 1), ' (', coalescec(%f(lowerlimit, 1), 'NE'), ';', coalescec(%f(upperlimit, 1), 'NE'), ')');
    output;
  end;
  else do;
    ord = 4 + timelist / 30; label = catx(' ', 'Progression-free at Day', timelist); val = coalescec(%f(survival, 3), 'NE');
    output;
  end;
  keep column ord label val;
run;

proc sort data=stats;
  by ord label column;
run;

proc transpose data=stats out=f_14_3_01_stats(drop=_name_) prefix=c;
  by ord label;
  id column;
  var val;
run;

data f_14_3_01_stats;
  set f_14_3_01_stats;
  row = _n_;
  indent = 0;
run;

%report(f_14_3_01_stats, f_14_3_01_stats, Figure 14-3.01 Statistics: Progression-Free Survival,
  cols=c1 c2 c3,
  heads=Placebo|(N=&n1)#Xanomeline|Low Dose|(N=&n2)#Xanomeline|High Dose|(N=&n3),
  foot1=Population: Intent-to-Treat. Kaplan-Meier estimates%str(,) 95% CI with log-log transformation.,
  foot2=NE: not estimable.)
