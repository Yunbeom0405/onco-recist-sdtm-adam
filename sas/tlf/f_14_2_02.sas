/*******************************************************************************
Program : f_14_2_02.sas
Purpose : Figure 14-2.02 Waterfall: Best Percent Change in Sum of Target Lesion Diameters
          (+ statistics table f_14_2_02_stats and bar values f_14_2_02_bars for QC)
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\tlf\setup.sas";

data adtr;
  set adam.adtr(where=(paramcd = 'SUMDIAM' and ittfl = 'Y'));
  col = input(put(trt01p, $trtcol.), 1.);
run;

proc sort data=adtr(where=(anl02fl = 'Y')) out=bars;
  by descending pchg usubjid;
run;

data bars;
  set bars;
  rank = _n_;
  flag30 = (pchg <= -30);
  flag20 = (pchg >= 20);
run;

proc format;
value col
  1 = 'Placebo'
  2 = 'Xanomeline Low Dose'
  3 = 'Xanomeline High Dose';
run;

ods listing close;
ods rtf file="&out/f_14_2_02.rtf" style=journal bodytitle;
ods graphics on / width=9in height=5.5in;
title1 j=l 'Protocol: CDISCPILOT01';
title2 'Figure 14-2.02 Best Percent Change from Baseline in Sum of Target Lesion Diameters';
footnote1 j=l 'Population: Intent-to-Treat, subjects with a post-baseline assessment. Dashed lines: +20% and -30%.';
footnote2 j=l 'Source: sas/tlf/f_14_2_02.sas';

proc sgplot data=bars;
  styleattrs datacolors=(cx7F7F7F cx0072B2 cxD55E00);
  vbarparm category=rank response=pchg / group=col;
  refline 20 -30 / axis=y lineattrs=(pattern=dash);
  xaxis display=(noticks novalues) label='Subjects';
  yaxis label='Best percent change from baseline (%)' values=(-100 to 125 by 25);
  keylegend / title='';
  format col col.;
run;

ods rtf close;
ods graphics off;
ods listing;
title;
footnote;

/* bar values for QC */
data f_14_2_02_bars;
  set bars;
  row = rank;
  length arm $20 pchgc $12;
  arm = put(col, col.);
  pchgc = %f(pchg, 1);
run;

proc export data=f_14_2_02_bars(keep=row usubjid arm pchgc rename=(pchgc=pchg))
  outfile="&out/f_14_2_02_bars.csv" dbms=csv replace;
run;

/* statistics for QC */
proc sql;
  create table nbase as
  select col, count(distinct usubjid) as nbase from adtr group by col;
quit;

proc means data=bars noprint nway;
  class col;
  var pchg flag30 flag20;
  output out=m n(pchg)=n median(pchg)=med min(pchg)=mn max(pchg)=mx sum(flag30)=n30 sum(flag20)=n20;
run;

data stats;
  merge m nbase;
  by col;
  length label $60 val $40;
  ord = 1; label = 'Subjects with a baseline assessment'; val = cats(nbase); output;
  ord = 2; label = 'Subjects with a post-baseline assessment'; val = cats(n); output;
  ord = 3; label = 'Median best change, %'; val = %f(med, 1); output;
  ord = 4; label = 'Minimum, %'; val = %f(mn, 1); output;
  ord = 5; label = 'Maximum, %'; val = %f(mx, 1); output;
  ord = 6; label = 'Best change <= -30%, n (%)'; val = %npct(n30, n); output;
  ord = 7; label = 'Best change >= +20%, n (%)'; val = %npct(n20, n); output;
  keep col ord label val;
run;

proc sort data=stats;
  by ord label col;
run;

proc transpose data=stats out=f_14_2_02_stats(drop=_name_) prefix=c;
  by ord label;
  id col;
  var val;
run;

data f_14_2_02_stats;
  set f_14_2_02_stats;
  row = _n_;
  indent = 0;
run;

%report(f_14_2_02_stats, f_14_2_02_stats, Figure 14-2.02 Statistics: Best Percent Change in Sum of Target Lesion Diameters,
  cols=c1 c2 c3,
  heads=Placebo#Xanomeline|Low Dose#Xanomeline|High Dose,
  foot1=Population: Intent-to-Treat. Percent change from baseline%str(,) lowest value before or at first progression.,
  foot2=Percentages use subjects with a post-baseline assessment.)
