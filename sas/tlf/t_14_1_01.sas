/*******************************************************************************
Program : t_14_1_01.sas
Purpose : Table 14-1.01 Summary of Populations and Study Disposition
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\tlf\setup.sas";

%bign(trt01p, where=%str(ittfl = 'Y'))

data pop;
  set adam.adsl(where=(ittfl = 'Y'));
  col = input(put(trt01p, $trtcol.), 1.);
  output;
  col = 4;
  output;
run;

proc sql;
  create table cnt as
  select col,
    sum(ittfl = 'Y') as r1, sum(saffl = 'Y') as r2,
    sum(eosstt = 'COMPLETED') as r3, sum(eosstt = 'DISCONTINUED') as r4,
    sum(dcsreas = 'ADVERSE EVENT') as r5, sum(dcsreas = 'DEATH') as r6,
    sum(dcsreas = 'LACK OF EFFICACY') as r7, sum(dcsreas = 'LOST TO FOLLOW-UP') as r8,
    sum(dcsreas = 'PHYSICIAN DECISION') as r9, sum(dcsreas = 'PROTOCOL VIOLATION') as r10,
    sum(dcsreas = 'STUDY TERMINATED BY SPONSOR') as r11, sum(dcsreas = 'WITHDRAWAL BY SUBJECT') as r12
  from pop
  group by col;
quit;

proc transpose data=cnt out=cnt2(rename=(_name_=stat)) prefix=n;
  id col;
run;

data t_14_1_01;
  set cnt2;
  length label $200 c1-c4 $40;
  array n{4} n1-n4;
  array c{4} c1-c4;
  array bign{4} _temporary_ (&n1 &n2 &n3 &n4);
  row = input(compress(stat, , 'kd'), best.);
  indent = (row >= 5);
  label = choosec(row, 'Randomized (ITT)', 'Safety', 'Completed study', 'Discontinued study',
    'Adverse event', 'Death', 'Lack of efficacy', 'Lost to follow-up', 'Physician decision',
    'Protocol violation', 'Study terminated by sponsor', 'Withdrawal by subject');
  do i = 1 to 4;
    c{i} = %npct(n{i}, bign{i});
  end;
  keep row indent label c1-c4;
run;

%report(t_14_1_01, t_14_1_01, Table 14-1.01 Summary of Populations and Study Disposition,
  cols=c1 c2 c3 c4,
  heads=Placebo|(N=&n1)#Xanomeline|Low Dose|(N=&n2)#Xanomeline|High Dose|(N=&n3)#Total|(N=&n4),
  foot1=Population: Intent-to-Treat (randomized). Percentages use N in the column header.,
  foot2=52 screen failures are not in this table. Reasons are for discontinuation from study.)
