/*******************************************************************************
Program : dm.sas
Purpose : Create SDTM DM
*******************************************************************************/

%include "U:\My SAS Files\Portfolio2\sas\sdtm\setup.sas";

%getsrc(dm)

data dm1;
  set dm;
  /* screen failures: no arm */
  if armnrs ne '' then do;
    armcd = '';
    arm = '';
    actarmcd = '';
    actarm = '';
  end;
  %dy(dmdtc, dmdy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    subjid   = 'Subject Identifier for the Study'
    rfstdtc  = 'Subject Reference Start Date/Time'
    rfendtc  = 'Subject Reference End Date/Time'
    rfxstdtc = 'Date/Time of First Study Treatment'
    rfxendtc = 'Date/Time of Last Study Treatment'
    rficdtc  = 'Date/Time of Informed Consent'
    rfpendtc = 'Date/Time of End of Participation'
    dthdtc   = 'Date/Time of Death'
    dthfl    = 'Subject Death Flag'
    siteid   = 'Study Site Identifier'
    brthdtc  = 'Date/Time of Birth'
    age      = 'Age'
    ageu     = 'Age Units'
    sex      = 'Sex'
    race     = 'Race'
    ethnic   = 'Ethnicity'
    armcd    = 'Planned Arm Code'
    arm      = 'Description of Planned Arm'
    actarmcd = 'Actual Arm Code'
    actarm   = 'Description of Actual Arm'
    armnrs   = 'Reason Arm and/or Actual Arm is Null'
    actarmud = 'Description of Unplanned Actual Arm'
    country  = 'Country'
    dmdtc    = 'Date/Time of Collection'
    dmdy     = 'Study Day of Collection';
run;

%finalize(dm1, dm, Demographics,
  vars=STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DTHFL SITEID BRTHDTC AGE AGEU SEX RACE ETHNIC ARMCD ARM ACTARMCD ACTARM ARMNRS ACTARMUD COUNTRY DMDTC DMDY,
  keys=STUDYID USUBJID)
