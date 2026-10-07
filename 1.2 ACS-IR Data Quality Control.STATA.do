/*******************************************************************************
*
*  PROJECT      : ACS-IR Data Quality Control
*  FILE         : BDF_ACS_QC.do
*  AUTHOR       : Aurangzeb
*  PURPOSE      : Flag data anomalies, inconsistencies and missing values
*                 across BDF and ACS forms for monthly QC review
*  SECTIONS     : A1–A14  BDF Form checks
*                 B1–B4   ACS Form checks
*  NOTES        : All YYYY == 2026 filters are for current-year review only.
*                 Remove or adjust when running historical checks.
*  LAST REVISED : August 31, 2026
*

* Change Log
  * Added the MNFU Checks
  * 2026-08-31: Added ARM SCOPE block -- the whole battery is now run once per
    study arm (Intervention vs Control), not pooled, so QC review and any
    downstream exports separate cleanly into two workbooks per arm.
********************************************************************************/


*===============================================================================
* SETUP
*===============================================================================

set more off
clear all

clear
cd "E:\ACSIR Data Management\Phase 2\WHO Monitoring"

use "Full_database_analysis_P2_LONG_M_PK.dta"

* Drop excluded clusters
drop if inlist(CLUST_NUM, 5, 9, 11, 12)

*===============================================================================
* ARM SCOPE -- run this whole file once per arm, not pooled.
*    CLUSTER_TYPE: 1 = Intervention (CLUST_NUM 2,3,7,13)
*                  2 = Control      (CLUST_NUM 4,6,8,10)
*    Every check below inherits this scope automatically (they all operate on
*    whatever is currently in memory) -- set target_arm and rerun the whole
*    do-file to get that arm's QC review. Run it twice (once per arm) to keep
*    Intervention and Control results as two separate outputs, never pooled.
*===============================================================================
local target_arm = 1   // 1 = Intervention, 2 = Control

keep if CLUSTER_TYPE == `target_arm'

* M3H = Mansehra, Mandi Bahauddin, Malakand, Hafizabad (Intervention)
* CNAK = Chiniot, Nankana Sahib, Attock, Khairpur (Control)
if `target_arm' == 1 local arm_label "M3H (Intervention)"
else                  local arm_label "CNAK (Control)"

di as text _n "{hline 78}" _n "QC RUN SCOPED TO: `arm_label' clusters (CLUSTER_TYPE==`target_arm')" _n "{hline 78}"


********************************************************************************
*
*   SECTION A : BDF FORM
*
********************************************************************************

global bdf_id  DIST_NAME HOSPITAL_NAME_BDF RA_NAME MM PID
global acs_id  DIST_NAME_ACS HOSPITAL_NAME_ACS RA_NAME MM_ACS PID
global mnfu_id DIST_NAME HOSPITAL_NAME_BDF RA_NAME YYYYMM_MNFU PID

* Monitoring window — edit these two lines each month to roll the window forward
global win_start = ym(2026,5)   // May 2026
global win_end   = ym(2026,7)   // July 2026

* Preterm/LBW
global preterm_lbw "GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000"

*===============================================================================
* A1. TIME & DATES
*===============================================================================

*-------------------------------------------------------------------------------
* A1a. Date-order flags
*-------------------------------------------------------------------------------

gen flag_bdf_order = .
label variable flag_bdf_order "BDF date-order anomaly flag"

replace flag_bdf_order = 1 if !missing(BDF_DT_EARLY_USG) ///
    & (BDF_DT_EARLY_USG - BDF_DT_ADM) > 2 & (FORM_BDF==1 | STATUS==1)

replace flag_bdf_order = 2 if BDF_DT_ADM > BDF_DT_DELIVERY ///
    & !missing(BDF_DT_ADM, BDF_DT_DELIVERY) & (FORM_BDF==1 | STATUS==1)

replace flag_bdf_order = 3 if BDF_DT_EARLY_USG > BDF_DT_DELIVERY ///
    & !missing(BDF_DT_EARLY_USG) & (FORM_BDF==1 | STATUS==1)

label define bdf_order_lbl ///
    1 "USG >2 days after admission" ///
    2 "Admission after delivery"    ///
    3 "USG scan after delivery"
label values flag_bdf_order bdf_order_lbl

*-------------------------------------------------------------------------------
* A1b. Combined datetime variables for time-level checks
*-------------------------------------------------------------------------------

gen BDF_ADM_DT_TM = BDF_DT_ADM * 1440 ///
    + BDF_TM_ADM_HH * 60 + BDF_TM_ADM_MM ///
    if !missing(BDF_DT_ADM, BDF_TM_ADM_HH, BDF_TM_ADM_MM) & (FORM_BDF==1 | STATUS==1)
label variable BDF_ADM_DT_TM "Admission datetime (minutes)"

gen BDF_DEL_DT_TM = BDF_DT_DELIVERY * 1440 ///
    + BDF_TM_DELIVERY_HH * 60 + BDF_TM_DELIVERY_MM ///
    if !missing(BDF_DT_DELIVERY, BDF_TM_DELIVERY_HH, BDF_TM_DELIVERY_MM) & (FORM_BDF==1 | STATUS==1)
label variable BDF_DEL_DT_TM "Delivery datetime (minutes)"

gen flag_adm_after_del_time = (BDF_ADM_DT_TM > BDF_DEL_DT_TM) ///
    if !missing(BDF_ADM_DT_TM, BDF_DEL_DT_TM)
label variable flag_adm_after_del_time "Admission datetime after delivery datetime"

*-------------------------------------------------------------------------------
* A1c. Labour duration flags
*-------------------------------------------------------------------------------

gen LABOUR_MINS = BDF_DEL_DT_TM - BDF_ADM_DT_TM ///
    if !missing(BDF_ADM_DT_TM, BDF_DEL_DT_TM)
label variable LABOUR_MINS "Labour duration (minutes)"

gen LABOUR_HRS   = LABOUR_MINS / 60
label variable LABOUR_HRS "Labour duration (hours)"

gen LABOUR_DAYS  = LABOUR_MINS / 1440
label variable LABOUR_DAYS "Labour duration (days)"

gen flag_labour_duration = .
replace flag_labour_duration = 0 if !missing(LABOUR_MINS) & inrange(LABOUR_MINS, 10, 2880)
replace flag_labour_duration = 1 if LABOUR_MINS < 10   & LABOUR_MINS > 0
replace flag_labour_duration = 2 if LABOUR_MINS > 2880 & !missing(LABOUR_MINS)
label variable flag_labour_duration "Labour duration category"
label define labour_dur_lbl 0 "Normal (10 min-48 hrs)" 1 "< 10 minutes" 2 "> 48 hours"
label values flag_labour_duration labour_dur_lbl

*-------------------------------------------------------------------------------
* A1d. Missing date flags
*-------------------------------------------------------------------------------

gen bdf_missing_date = .
label variable bdf_missing_date "Missing BDF date flag"
replace bdf_missing_date = 1 if missing(BDF_DT_ADM)      & (FORM_BDF==1 | STATUS==1)
replace bdf_missing_date = 2 if missing(BDF_DT_DELIVERY) & (FORM_BDF==1 | STATUS==1)
replace bdf_missing_date = 3 if missing(BDF_DT_ADM) & missing(BDF_DT_DELIVERY) & (FORM_BDF==1 | STATUS==1)

*-------------------------------------------------------------------------------
* A1e. Missing time flags
*-------------------------------------------------------------------------------

gen bdf_missing_time = .
label variable bdf_missing_time "Missing BDF time flag"
replace bdf_missing_time = 1 if missing(BDF_TM_ADM_HH,      BDF_TM_ADM_MM)      & (FORM_BDF==1 | STATUS==1)
replace bdf_missing_time = 2 if missing(BDF_TM_DELIVERY_HH, BDF_TM_DELIVERY_MM) & (FORM_BDF==1 | STATUS==1)

*-------------------------------------------------------------------------------
* A1f. Checking output (all restricted to genuine BDF records)
*-------------------------------------------------------------------------------

count if FORM_BDF==1 | STATUS==1                          // base N for this section

tab flag_bdf_order        if FORM_BDF==1 | STATUS==1, missing
tab bdf_missing_date       if FORM_BDF==1 | STATUS==1, missing
tab bdf_missing_time       if FORM_BDF==1 | STATUS==1, missing
tab flag_adm_after_del_time if FORM_BDF==1 | STATUS==1, missing
tab flag_labour_duration  if FORM_BDF==1 | STATUS==1, missing

** Missing dates
br $bdf_id BDF_DT_ADM BDF_DT_DELIVERY ///
    if bdf_missing_date == 3 & (FORM_BDF==1 | STATUS==1)

br $bdf_id  BDF_DT_ADM ///
    if bdf_missing_date == 1 & (FORM_BDF==1 | STATUS==1)

br $bdf_id BDF_DT_DELIVERY ///
    if bdf_missing_date == 2 & (FORM_BDF==1 | STATUS==1)

** Missing times
br $bdf_id  BDF_TM_ADM_HH BDF_TM_ADM_MM ///
    if bdf_missing_time == 1 & (FORM_BDF==1 | STATUS==1)

br $bdf_id  BDF_TM_DELIVERY_HH BDF_TM_DELIVERY_MM ///
    if bdf_missing_time == 2 & (FORM_BDF==1 | STATUS==1)

** Admission datetime after delivery datetime
br $bdf_id BDF_DT_ADM BDF_TM_ADM_HH BDF_TM_ADM_MM ///
    BDF_DT_DELIVERY BDF_TM_DELIVERY_HH BDF_TM_DELIVERY_MM ///
    if flag_adm_after_del_time == 1 & (FORM_BDF==1 | STATUS==1)
	

** Implausible labour duration (extremely long cases, >=8 days)
br $bdf_id LABOUR_DAYS ///
     ADM_DT DEL_DT Submit_BDF  ///
    if !missing(flag_labour_duration) & LABOUR_DAYS >= 8 & (FORM_BDF==1 | STATUS==1) 

** Date-order anomalies
br $bdf_id BDF_DT_ADM BDF_DT_EARLY_USG BDF_DT_DELIVERY ///
    if flag_bdf_order == 1 & (FORM_BDF==1 | STATUS==1)               // USG after admission (>2 days)

br $bdf_id BDF_DT_ADM BDF_DT_DELIVERY ///
    if flag_bdf_order == 2 & (FORM_BDF==1 | STATUS==1)                             // Admission after delivery

br $bdf_id BDF_DT_EARLY_USG BDF_DT_DELIVERY ///
    if flag_bdf_order == 3                               // USG scan after delivery

** Minute distributions (data entry habit check)
histogram BDF_TM_ADM_MM if APP == "P2B" & (FORM_BDF==1 | STATUS==1), percent by(DIST_NAME) ///
    title("Admission Time Minute Distribution", size(small))

histogram BDF_TM_DELIVERY_MM if APP == "P2B" & (FORM_BDF==1 | STATUS==1), percent by(DIST_NAME) ///
    title("Delivery Time Minute Distribution", size(small))



*===============================================================================
* A2. CONSENT: BDF, ACS AND MNFU
*===============================================================================

*--- BDF & ACS consent:
tab BDF_CONSENT   if FORM_BDF==1  | STATUS==1
tab ACS_CONSENT1  if FORM_ACS1==1

*--- MNFU consent: the actionable one — not filtered at import ----------------
tab BDF_MNFU_CONSENT YYYYMM if (FORM_BDF==1 | STATUS==1) & BDF_VITAL_STATUS ==1

tab YYYYMM DIST_NAME if BDF_MNFU_CONSENT==2 & YYYY==2026 & (FORM_BDF==1 | STATUS==1) & BDF_VITAL_STATUS ==1

br $bdf_id BDF_MNFU_CONSENT ///
    if BDF_MNFU_CONSENT==2 & (FORM_BDF==1 | STATUS==1) & BDF_VITAL_STATUS ==1


*===============================================================================
* A3. PATIENT AGE & PREVIOUS DELIVERIES
*===============================================================================

*-------------------------------------------------------------------------------
* A3a. Age categories
*   NOTE: Recode starts at 15 (protocol minimum). Align underage browse
*         to the same cutoff — use BDF_AGE < 15.
*-------------------------------------------------------------------------------

recode BDF_AGE (15/19 = 1 "15-19 years") (20/24 = 2 "20-24 years") ///
               (25/29 = 3 "25-29 years") (30/34 = 4 "30-34 years") ///
               (35/39 = 5 "35-39 years") (40/max = 6 "40+ years"), gen(WOMEN_AGE)

label define AGELABEL1 ///
    1 "15-19 years" 2 "20-24 years" 3 "25-29 years" ///
    4 "30-34 years" 5 "35-39 years" 6 "40+ years"
label values WOMEN_AGE AGELABEL1

graph bar (count), over(WOMEN_AGE, gap(5)) blabel(bar, format(%9.0g)) ///
    title("Distribution of Mother's Age") ytitle("Count") legend(off)

** Missing age
br $bdf_id BDF_AGE BDF_NUM_PRV_DEL ///
    if (FORM_BDF==1 | STATUS==1) & missing(BDF_AGE) | inlist(BDF_AGE, ., 88, 99) 

** Underage mothers (below protocol minimum of 15)
br $bdf_id BDF_AGE BDF_NUM_PRV_DEL ///
    if BDF_AGE < 15 & !missing(BDF_AGE)

** Very old mothers
br $bdf_id BDF_AGE BDF_NUM_PRV_DEL ///
    if BDF_AGE >= 50 & !missing(BDF_AGE) & BDF_NUM_PRV_DEL<5

*-------------------------------------------------------------------------------
* A3b. Previous deliveries
*-------------------------------------------------------------------------------

recode BDF_NUM_PRV_DEL ///
    (0      = 1 "1st delivery")    (1/2  = 2 "1-2 deliveries") ///
    (3/4    = 3 "3-4 deliveries")  (5/6  = 4 "5-6 deliveries") ///
    (7/9    = 5 "7-9 deliveries")  (10/80 = 6 "10+ deliveries") ///
    (else   = 8 "NK"),             gen(BDF_CAT_PREVIOUS_DELIVERIES)

label define PREVDELLABEL ///
    1 "1st delivery"    2 "1-2 deliveries" 3 "3-4 deliveries" ///
    4 "5-6 deliveries"  5 "7-9 deliveries" 6 "10+ deliveries" 8 "NK"
label values BDF_CAT_PREVIOUS_DELIVERIES PREVDELLABEL

graph bar (count), over(BDF_CAT_PREVIOUS_DELIVERIES, gap(5)) ///
    blabel(bar, format(%9.0g)) ///
    title("Number of Previous Deliveries") ytitle("Count") legend(off)

** Missing or extreme deliveries
br  $bdf_id BDF_DT_DELIVERY BDF_NUM_PRV_DEL ///
    if inlist(BDF_NUM_PRV_DEL, ., 88, 99) | BDF_NUM_PRV_DEL > 80

br  $bdf_id BDF_DT_DELIVERY BDF_AGE BDF_NUM_PRV_DEL ///
    if BDF_NUM_PRV_DEL > 10 & BDF_NUM_PRV_DEL < 80 & YYYY == 2026

*-------------------------------------------------------------------------------
* A3c. Age × parity cross-checks
*-------------------------------------------------------------------------------

tab WOMEN_AGE BDF_CAT_PREVIOUS_DELIVERIES

scatter BDF_NUM_PRV_DEL BDF_AGE if BDF_AGE < 80 & BDF_NUM_PRV_DEL < 80, ///
    mcolor(blue) msymbol(circle) legend(off) ///
    title("Mother's Age vs. Number of Previous Deliveries") ///
    xlabel(14(2)50) ylabel(0(2)15) ///
    xtitle("Mother's Age") ytitle("Number of previous deliveries")

** Suspicious parity patterns
br $bdf_id BDF_AGE BDF_NUM_PRV_DEL ///
    if BDF_AGE <= 18 & BDF_NUM_PRV_DEL >= 2

br $bdf_id BDF_AGE BDF_NUM_PRV_DEL ///
    if inrange(BDF_AGE, 19, 22) & BDF_NUM_PRV_DEL >= 5

br $bdf_id BDF_AGE BDF_NUM_PRV_DEL ///
    if BDF_AGE >= 50 & BDF_NUM_PRV_DEL <= 3


*===============================================================================
* A4. ANC VISITS | TRIMESTER | EARLIEST USG SCAN
*===============================================================================

*--- A4a. ANC visits ---
tab DIST_NAME BDF_NUM_ANT_VISITS_CAT if FORM_BDF==1 | STATUS==1, row nofreq

br $bdf_id BDF_DT_DELIVERY BDF_NUM_ANT_VISITS ///
    if BDF_NUM_ANT_VISITS_CAT == 8 & (FORM_BDF==1 | STATUS==1)

graph bar (count) if FORM_BDF==1 | STATUS==1, over(BDF_NUM_ANT_VISITS_CAT, sort(ascending)) ///
    blabel(bar, format(%9.0g)) ///
    title("Number of ANC Visits during Current Pregnancy") ytitle("Count") legend(off)

scatter BDF_NUM_ANT_VISITS_CAT BDF_TRIM_1STANC_VISIT ///
    if BDF_TRIM_1STANC_VISIT < 4 & BDF_NUM_ANT_VISITS_CAT != 8, ///
    mcolor(blue) msymbol(circle) legend(off) ///
    title("Trimester of 1st ANC vs Total ANC Visits") ///
    xtitle("Trimester of 1st ANC Visit") ytitle("Total ANC Visits") ///
    xlabel(1(1)3) ylabel(0(1)4)

tab BDF_TRIM_1STANC_VISIT DIST_NAME if FORM_BDF==1 | STATUS==1, col nofreq

*--- A4b. ANC quality flags ---
br $bdf_id BDF_NUM_ANT_VISITS_CAT BDF_TRIM_1STANC_VISIT ///
    if BDF_NUM_ANT_VISITS_CAT == 3 & BDF_TRIM_1STANC_VISIT == 3                                              // 8+ ANC visits but in T3

br $bdf_id BDF_NUM_ANT_VISITS_CAT BDF_TRIM_1STANC_VISIT ///
    if inlist(BDF_NUM_ANT_VISITS_CAT, 1, 2, 3) & (BDF_TRIM_1STANC_VISIT==8 | missing(BDF_TRIM_1STANC_VISIT))  // Missing Trimester dates

*--- A4c. Earliest USG ---
tab DIST_NAME EUSG_AVAIL if FORM_BDF==1 | STATUS==1, row                                                     // USG coverage 

graph bar (count) if FORM_BDF==1 | STATUS==1, over(EARLYUSG_BDF_24, sort(ascending)) ///
    blabel(bar, format(%9.0g)) legend(off) ///
    title("Earliest USG Coverage (<24 weeks)", size(medium)) ytitle("Number of Deliveries")

histogram BDF_GA_EARLYUSG_WKS if BDF_GA_EARLYUSG_WKS > 10 & BDF_GA_EARLYUSG_WKS < 45, ///
    discrete percent by(DIST_NAME) title("Earliest Ultrasound Weeks Distribution", size(small))

br $bdf_id BDF_NUM_ANT_VISITS_CAT BDF_DT_EARLY_USG BDF_ANC_PATIENT_STATUS ///
    if BDF_NUM_ANT_VISITS_CAT == 0 & EUSG_AVAIL == 1 & USG_TO_ADM >= 1                                    // USG available withount any ANC visits

br $bdf_id BDF_NUM_ANT_VISITS_CAT BDF_DT_EARLY_USG BDF_DT_ADM ///
    if USG_TO_ADM < 0 & YYYY == 2026                                                                      // EUSG done after admission

br $bdf_id BDF_NUM_ANT_VISITS_CAT BDF_DT_EARLY_USG ///
    if BDF_NUM_ANT_VISITS_CAT >= 2 & EUSG_BDF_AVAIL == 0                                                 // ANC visits are more than 8 but USG is missing

br $bdf_id BDF_NUM_ANT_VISITS_CAT USG_TO_ADM_GROUP ///
    if USG_TO_ADM_GROUP >= 4 & BDF_NUM_ANT_VISITS_CAT == 0 & EUSG_BDF_AVAIL == 1                         // USG Done 10 days prior but ANC is 0

* USG done on EITHER the admission date OR the delivery date
gen flag_usg_at_admission = ///
    (BDF_DT_EARLY_USG == BDF_DT_DELIVERY | BDF_DT_EARLY_USG == BDF_DT_ADM) & EUSG_BDF_AVAIL == 1
label variable flag_usg_at_admission "USG obtained on admission or delivery date (not a true early USG)"

br $bdf_id BDF_DT_EARLY_USG BDF_DT_ADM BDF_DT_DELIVERY if flag_usg_at_admission == 1

tab BDF_NUM_ANT_VISITS_CAT USG_TO_ADM_GROUP if FORM_BDF==1 | STATUS==1, row

*===============================================================================
* A5. BOOKED VS UNBOOKED
*===============================================================================

tab BDF_ANC_PATIENT_STATUS

graph bar (count), over(BDF_ANC_PATIENT_STATUS, sort(ascending)) ///
    blabel(bar, format(%9.0g)) legend(off) ///
    title("Booked vs Unbooked", size(medium)) ytitle("Count")

tab BDF_NUM_ANT_VISITS_CAT BDF_ANC_PATIENT_STATUS

tab YYYYMM BDF_ANC_PATIENT_STATUS, row nofreq

* Flag 1: Missing/invalid ANC patient status when ANC visits are present (2026)
br $bdf_id BDF_NUM_ANT_VISITS_CAT BDF_ANC_PATIENT_STATUS ///
    if (missing(BDF_ANC_PATIENT_STATUS) | BDF_ANC_PATIENT_STATUS >= 8) ///
    & inlist(BDF_NUM_ANT_VISITS_CAT,1,2,3) & YYYY == 2026

* Flag 2: No ANC visits but patient marked as booked
br $bdf_id BDF_ANC_PATIENT_STATUS BDF_NUM_ANT_VISITS ///
    if inlist(BDF_NUM_ANT_VISITS_CAT, 0, 8) & BDF_ANC_PATIENT_STATUS == 1 & YYYY == 2026

* Flag 3: ANC visits but Patient status is NA (all years — fixed duplicate variable)
br $bdf_id BDF_NUM_ANT_VISITS_CAT BDF_ANC_PATIENT_STATUS ///
  if inlist(BDF_NUM_ANT_VISITS_CAT,1,2,3) & BDF_ANC_PATIENT_STATUS==9


*===============================================================================
* A6. ACS COVERAGE IN BDF
*===============================================================================

tab BDF_ACS_RECEIVED YYYYMM
tab DIST_NAME YYYYMM if BDF_ACS_RECEIVED == 1 & YYYY== 2026
tab BDF_ACS_RECEIVED GA_BIRTH_CAT, col                        // Provider's GA 
tab DIST_NAME GA_BIRTH_CAT if BDF_ACS_RECEIVED == 1, row      // Provider's GA by cluster

    graph bar (count) if inlist(BDF_ACS_RECEIVED,1,2) & (FORM_BDF==1 | STATUS==1), ///
    over(BDF_ACS_RECEIVED, label(angle(45))) ///
    over(GEST_CAT_4, gap(20)) ///
    asyvars stack ///
    bar(1, color(orange)) ///
    bar(2, color(forest_green)) ///
    title("Distribution of ACS by GA Category") ///
    legend(label(1 "ACS Received") label(2 "No ACS")) ///
    ytitle("Number of Deliveries")

br $bdf_id BDF_ACS_RECEIVED ///
    if (missing(BDF_ACS_RECEIVED) | inlist(BDF_ACS_RECEIVED, 8, 9)) & (FORM_BDF==1 | STATUS==1)

* Flag 1: ACS place recorded as unknown when ACS was given
br $bdf_id DEL_DT BDF_ACS_RECEIVED BDF_PLACE_ACS ///
    if BDF_ACS_RECEIVED == 1 & BDF_PLACE_ACS >= 8

* Flag 2: ACS given at >=37 weeks (term delivery — not indicated)
br $bdf_id BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_ACS_RECEIVED ///
    if BDF_ACS_RECEIVED == 1 & GA_BIRTH_CAT > 2 & YYYY == 2026

	

*===============================================================================
* A7. FOETAL HEART RATE (FHS)
*===============================================================================

tab BDF_FHS

* Flag 1: FHS not documented
br $bdf_id DEL_DT BDF_FHS ///
    if BDF_FHS == 3

* Flag 2: FHS absent for livebirths
br $bdf_id DEL_DT BDF_FHS BDF_BIRTH_STATUS ///
    if BDF_FHS == 2 & BDF_BIRTH_STATUS == 1

* Flag 3: FHS absent for preterm livebirths specifically (subset of Flag 2, 2026 only)
br $bdf_id BDF_FHS BDF_BIRTH_STATUS GA_BIRTH_CAT ///
    if BDF_FHS == 2 & BDF_BIRTH_STATUS == 1 & GA_BIRTH_CAT <= 2 & YYYY == 2026

* Flag 4: Multiple fetuses — cross-check shared admission FHS against each baby's individual outcome
br $bdf_id BDF_FHS BDF_NUM_FETUS BDF_BIRTH_STATUS ///
    if BDF_NUM_FETUS > 1


*===============================================================================
* A8. GESTATIONAL AGE ASSESSMENT LOGIC
*===============================================================================

* Number of ANC Visists 
tab BDF_NUM_ANT_VISITS_CAT EUSG_BDF_AVAIL  if inrange(YYYYMM, $win_start, $win_end) 

* Flag 1: Invalid Scans GA>45 or GA<24 Weeks.
br $bdf_id BDF_DT_EARLY_USG ///
    BDF_GA_EARLYUSG_WKS BDF_GA_EARLYUSG_DAYS BDF_DT_DELIVERY INVALID_BDF_USG ///
    if !missing(INVALID_BDF_USG) & EUSG_BDF_AVAIL == 1 & inrange(YYYYMM, $win_start, $win_end)

* Flag 2: Weeks and days missing but date is available 
br $bdf_id BDF_DT_EARLY_USG ///
    BDF_GA_EARLYUSG_WKS BDF_GA_EARLYUSG_DAYS WEEKS_BDF_EUSG ///
    if missing(BDF_GA_EARLYUSG_WKS) & missing(BDF_GA_EARLYUSG_DAYS) ///
    & EUSG_BDF_AVAIL == 1 & inrange(YYYYMM, $win_start, $win_end)

* Flag 3: EUSG weeks available but days missing or zero
br $bdf_id BDF_DT_EARLY_USG ///
    BDF_GA_EARLYUSG_WKS BDF_GA_EARLYUSG_DAYS WEEKS_BDF_EUSG ///
    if (BDF_GA_EARLYUSG_DAYS == 0 | missing(BDF_GA_EARLYUSG_DAYS)) ///
    & !missing(BDF_GA_EARLYUSG_WKS) & EUSG_BDF_AVAIL == 1

* Tabulate zero-day entries by RA to detect default entry habit
tab DIST_NAME YYYYMM if BDF_GA_EARLYUSG_DAYS == 0 & EUSG_BDF_AVAIL == 1 & inrange(YYYYMM, $win_start, $win_end)

* Flag 4: Extremely early USG (<= 7 weeks — not clinically plausible for dating)
br $bdf_id BDF_DT_EARLY_USG BDF_DT_DELIVERY ///
    BDF_GA_EARLYUSG_WKS BDF_GA_EARLYUSG_DAYS ///
    if BDF_GA_EARLYUSG_WKS <= 7 & !missing(BDF_GA_EARLYUSG_WKS)


*===============================================================================
* A9. MISMATCHED GA (+/- 7 DAYS): PROVIDER VS EARLIEST USG
*===============================================================================

gen DIFF_EUSG_PROV_GA = GA_BIRTH - GA_BIRTH_EUSG if EUSG_BDF_AVAIL == 1
label variable DIFF_EUSG_PROV_GA "Difference (days): Provider GA - Earliest USG GA"

gen BDF_MISMATCHED_GA = (abs(DIFF_EUSG_PROV_GA) > 7) if EUSG_BDF_AVAIL == 1
label variable BDF_MISMATCHED_GA "Mismatched GA (> 7 days difference)"

gen GA_MISMATCH_DIR = .
replace GA_MISMATCH_DIR = 1 if DIFF_EUSG_PROV_GA >  7 & !missing(DIFF_EUSG_PROV_GA)
replace GA_MISMATCH_DIR = 2 if DIFF_EUSG_PROV_GA < -7 & !missing(DIFF_EUSG_PROV_GA)
label variable GA_MISMATCH_DIR "Direction of GA mismatch"
label define ga_dir_lbl 1 "Provider overestimates" 2 "Provider underestimates"
label values GA_MISMATCH_DIR ga_dir_lbl

tab DIST_NAME YYYYMM if BDF_MISMATCHED_GA == 1 


* RA-feedback version.
tab GA_MISMATCH_DIR  DIST_NAME if BDF_MISMATCHED_GA == 1 

br $bdf_id BDF_GA_WEEKS BDF_DT_EARLY_USG BDF_GA_EARLYUSG_WKS BDF_GA_EARLYUSG_DAYS ///
    WEEKS_BDF_EUSG DIFF_EUSG_PROV_GA ///
    if BDF_MISMATCHED_GA == 1

twoway scatter WEEKS_BDF_EUSG WEEKS_BDF_PROV ///
    if WEEKS_BDF_EUSG < 50 & WEEKS_BDF_PROV < 50, ///
    mcolor(black) msymbol(Oh) ///
    title("Gestational Age: Provider vs. Earliest USG") ///
    xtitle("Provider's GA (weeks)") ytitle("Earliest USG GA (weeks)") ///
    xlabel(20(5)45) ylabel(20(5)45) ///
    yline(37, lpattern(dash) lcolor(black)) ///
    xline(37, lpattern(dash) lcolor(black)) ///
    yline(34, lpattern(dash) lcolor(green)) ///
    xline(34, lpattern(dash) lcolor(green)) ///
    || function y = x, range(20 45) lcolor(blue) lpattern(dot) ///
    legend(off)

histogram DIFF_EUSG_PROV_GA if abs(DIFF_EUSG_PROV_GA) < 60, ///
    normal percent ///
    by(DIST_NAME, ///
        title("GA difference by district: Provider minus USG (days)") ///
        note("Red lines = +/-7 day threshold") ///
        rows(3) compact) ///
    xline(7,  lpattern(dash) lcolor(red)) ///
    xline(-7, lpattern(dash) lcolor(red))


*===============================================================================
* A10. WEIGHT-TO-GESTATIONAL AGE RATIO (WGA)
*===============================================================================
*===============================================================================
* WGA RATIO & BIRTHWEIGHT DISTRIBUTIONS — ALL CLUSTERS
* Three GA bands: EPT (<34w), LPT (34-36w), Term (37-45w)
*===============================================================================

*--- Compute WGA ratio  --------------------------
capture drop WGA_RATIO
gen   WGA_RATIO = floor(BDF_BIRTH_WEIGHT / WEEKS_BDF_EUSG) ///
    if !missing(BDF_BIRTH_WEIGHT) & !missing(WEEKS_BDF_EUSG) & WEEKS_BDF_EUSG > 0 ///
	& BDF_BIRTH_WEIGHT <8000
label variable WGA_RATIO "Weight-to-Gestational Age Ratio (grams/week)"

*--- Individual band flags ----------------------------------------------------
gen WGA_FLAG1 = (WGA_RATIO <  35 | WGA_RATIO > 100) ///
    if WEEKS_BDF_EUSG >= 24 & WEEKS_BDF_EUSG <  34  // EPT
gen WGA_FLAG2 = (WGA_RATIO <= 40 | WGA_RATIO >= 110) ///
    if WEEKS_BDF_EUSG >= 34 & WEEKS_BDF_EUSG <  37  // LPT
gen WGA_FLAG3 = (WGA_RATIO <= 70 | WGA_RATIO >= 120) ///
    if WEEKS_BDF_EUSG >= 37 & WEEKS_BDF_EUSG <= 45  // Term

*--- Combined WGA flag --------------------------------------------------------
gen     WGA_FLAG = .
replace WGA_FLAG = 1 if WGA_FLAG1 == 1   // EPT outlier
replace WGA_FLAG = 2 if WGA_FLAG2 == 1   // LPT outlier
replace WGA_FLAG = 3 if WGA_FLAG3 == 1   // Term outlier
label define WGAFLAG 1 "EPT outlier" 2 "LPT outlier" 3 "Term outlier", replace
label values   WGA_FLAG WGAFLAG
label variable WGA_FLAG "WGA outlier band"

*===============================================================================
* By() panel — all clusters in one graph per GA band (quickest)
*===============================================================================

*--- Define GA band conditions as locals (avoids repeating long conditions) ---
local ept_cond  "WEEKS_BDF_EUSG >= 24 & WEEKS_BDF_EUSG <  34"
local lpt_cond  "WEEKS_BDF_EUSG >= 34 & WEEKS_BDF_EUSG <  37"
local term_cond "WEEKS_BDF_EUSG >= 37 & WEEKS_BDF_EUSG <= 45"

local ept_label  "EPT (<34 weeks)"
local lpt_label  "LPT (34-36 weeks)"
local term_label "Term (37-45 weeks)"




foreach band in ept lpt term {

    * Histogram: WGA ratio
    histogram WGA_RATIO if ``band'_cond' &  BDF_BIRTH_WEIGHT <8000, ///
        normal percent ///
        by(DIST_NAME, ///
            title("WGA ratio — ``band'_label'") ///
            note("Normal curve overlaid") ///
            rows(3) compact) ///
        xtitle("WGA ratio (grams/week)") ytitle("Percent") ///
        name(wga_hist_`band'_panel, replace)

    * Boxplot: Birthweight
    graph box BDF_BIRTH_WEIGHT if ``band'_cond' & BDF_BIRTH_WEIGHT <8000, ///
        over(DIST_NAME, label(angle(45))) ///
        title("Birthweight distribution — ``band'_label'") ///
        note("One box per cluster") ///
        ytitle("Birthweight (grams)") ///
        name(bw_box_`band'_panel, replace)
}

/*
*===============================================================================
* DIRECTION FLAG (high vs low outlier within each band)
*           Tells you whether weight is implausibly HIGH or LOW for GA
*===============================================================================

gen     WGA_DIRECTION = .

* EPT: low < 35, high > 100
replace WGA_DIRECTION = 1 if WGA_FLAG == 1 & WGA_RATIO <  35
replace WGA_DIRECTION = 2 if WGA_FLAG == 1 & WGA_RATIO > 100

* LPT: low <= 40, high >= 110
replace WGA_DIRECTION = 1 if WGA_FLAG == 2 & WGA_RATIO <=  40
replace WGA_DIRECTION = 2 if WGA_FLAG == 2 & WGA_RATIO >= 110

* Term: low <= 70, high >= 120
replace WGA_DIRECTION = 1 if WGA_FLAG == 3 & WGA_RATIO <=  70
replace WGA_DIRECTION = 2 if WGA_FLAG == 3 & WGA_RATIO >= 120

label define WGA_DIR_LBL 1 "Low (weight too low for GA)" 2 "High (weight too high for GA)"
label values   WGA_DIRECTION WGA_DIR_LBL
label variable WGA_DIRECTION "Direction of WGA outlier"


*===============================================================================
*  SEVERITY SCORE
*   How far is the WGA ratio from the band midpoint?
*   Higher score = more extreme outlier
*===============================================================================

* Midpoints: EPT ~67, LPT ~75, Term ~95 (approximate centre of normal range)
gen     WGA_MIDPOINT = .
replace WGA_MIDPOINT = 67 if WEEKS_BDF_EUSG >= 24 & WEEKS_BDF_EUSG <  34
replace WGA_MIDPOINT = 75 if WEEKS_BDF_EUSG >= 34 & WEEKS_BDF_EUSG <  37
replace WGA_MIDPOINT = 95 if WEEKS_BDF_EUSG >= 37 & WEEKS_BDF_EUSG <= 45

gen     WGA_SEVERITY = abs(WGA_RATIO - WGA_MIDPOINT) if WGA_FLAG != .
label variable WGA_SEVERITY "Distance of WGA ratio from band midpoint (severity)"

* Severity category: moderate vs extreme
gen     WGA_SEVERITY_CAT = .
replace WGA_SEVERITY_CAT = 1 if WGA_SEVERITY >= 10  & WGA_SEVERITY <  30
replace WGA_SEVERITY_CAT = 2 if WGA_SEVERITY >= 30  & WGA_SEVERITY <  60
replace WGA_SEVERITY_CAT = 3 if WGA_SEVERITY >= 60  & !missing(WGA_SEVERITY)
label define SEV_LBL 1 "Moderate (10-29)" 2 "Severe (30-59)" 3 "Extreme (60+)"
label values   WGA_SEVERITY_CAT SEV_LBL
label variable WGA_SEVERITY_CAT "WGA outlier severity category"


*===============================================================================
* CROSS-CHECKS
*  Combine WGA flag with other data quality signals to identify
*  records most likely to be errors vs genuinely unusual babies
*===============================================================================

* Cross 1: WGA outlier AND birthweight is rounded (data entry suspect)
gen WGA_X_ROUNDED = (WGA_FLAG != . & WEIGHT_ACCURACY2 >= 3)
label variable WGA_X_ROUNDED "WGA outlier AND weight rounded to >=100g"

* Cross 2: WGA outlier AND GA mismatch > 7 days
gen WGA_X_GA_MISMATCH = (WGA_FLAG != . & BDF_MISMATCHED_GA == 1)
label variable WGA_X_GA_MISMATCH "WGA outlier AND provider-USG GA mismatch >7 days"

* Cross 3: WGA outlier AND sequential weight repeat by same RA
*          (requires WEIGHT_FREQ_RA from birthweight_repetition_check.do)
capture gen WGA_X_RA_REPEAT = (WGA_FLAG != . & flag_ra_weight_repeat == 1)
capture label variable WGA_X_RA_REPEAT "WGA outlier AND RA weight repetition flag"

* Cross 4: WGA outlier for a livebirth (stillbirths may have genuine extremes)
gen WGA_X_LIVEBIRTH = (WGA_FLAG != . & BDF_BIRTH_STATUS == 1)
label variable WGA_X_LIVEBIRTH "WGA outlier in a livebirth"


*===============================================================================
* STEP 5 — COMPOSITE SUSPICION SCORE (0–5)
*           Records scoring >=2 are priority for field verification
*===============================================================================
gen WGA_SUSPICION_SCORE = 0 if !missing(WGA_FLAG)

replace WGA_SUSPICION_SCORE = WGA_SUSPICION_SCORE + 1 if WGA_SEVERITY_CAT == 2  // severe
replace WGA_SUSPICION_SCORE = WGA_SUSPICION_SCORE + 2 if WGA_SEVERITY_CAT == 3  // extreme
replace WGA_SUSPICION_SCORE = WGA_SUSPICION_SCORE + 1 if WGA_X_ROUNDED     == 1
replace WGA_SUSPICION_SCORE = WGA_SUSPICION_SCORE + 1 if WGA_X_GA_MISMATCH == 1
capture replace WGA_SUSPICION_SCORE = WGA_SUSPICION_SCORE + 1 if WGA_X_RA_REPEAT == 1

label variable WGA_SUSPICION_SCORE "WGA composite suspicion score (0-5+)"


*===============================================================================
* OVERVIEW TABS
*===============================================================================

* Overall count by band and direction
tab WGA_FLAG    WGA_DIRECTION,    row nofreq
tab WGA_FLAG    WGA_SEVERITY_CAT, row nofreq


* By cluster
tab DIST_NAME   WGA_FLAG,         row nofreq
tab CLUST_NUM   WGA_SEVERITY_CAT if WGA_FLAG != ., row nofreq

* By month — is the problem getting better or worse over time?
tab YYYYMM      WGA_FLAG          if WGA_FLAG != ., row nofreq

* By RA — who is generating most outliers?
tab RA_NAME     WGA_FLAG          if WGA_FLAG != .

* Cross-check summary
tab WGA_FLAG WGA_X_ROUNDED,     row nofreq
tab WGA_FLAG WGA_X_GA_MISMATCH, row nofreq



*===============================================================================
*  TREND GRAPH: outlier rate over time by GA band
*===============================================================================

* Compute monthly outlier rate per GA band
preserve
    keep if !missing(WEEKS_BDF_EUSG) & !missing(BDF_BIRTH_WEIGHT)

    * Total births per band per month
    bysort YYYYMM: egen N_EPT_MO  = total(WEEKS_BDF_EUSG >= 24 & WEEKS_BDF_EUSG < 34)
    bysort YYYYMM: egen N_LPT_MO  = total(WEEKS_BDF_EUSG >= 34 & WEEKS_BDF_EUSG < 37)
    bysort YYYYMM: egen N_TERM_MO = total(WEEKS_BDF_EUSG >= 37 & WEEKS_BDF_EUSG <= 45)

    * Outlier births per band per month
    bysort YYYYMM: egen N_FLAG1_MO = total(WGA_FLAG == 1)
    bysort YYYYMM: egen N_FLAG2_MO = total(WGA_FLAG == 2)
    bysort YYYYMM: egen N_FLAG3_MO = total(WGA_FLAG == 3)

    * Outlier rate per band per month
    gen RATE_EPT_MO  = (N_FLAG1_MO / N_EPT_MO)  * 100 if N_EPT_MO  > 0
    gen RATE_LPT_MO  = (N_FLAG2_MO / N_LPT_MO)  * 100 if N_LPT_MO  > 0
    gen RATE_TERM_MO = (N_FLAG3_MO / N_TERM_MO)  * 100 if N_TERM_MO > 0

    duplicates drop YYYYMM, force
    sort YYYYMM

    twoway ///
        line RATE_EPT_MO  YYYYMM, lcolor(red)    lpattern(solid)  || ///
        line RATE_LPT_MO  YYYYMM, lcolor(orange) lpattern(dash)   || ///
        line RATE_TERM_MO YYYYMM, lcolor(blue)   lpattern(dot)    ///
        title("WGA outlier rate over time", size(medium)) ///
        ytitle("Outlier rate (%)") xtitle("Month") ///
        xlabel(, format(%tmMon-YY) angle(45) labsize(small)) ///
        legend(order(1 "EPT <34w" 2 "LPT 34-36w" 3 "Term 37-45w") ///
               position(1) ring(0) size(small)) ///
        yline(5, lpattern(dash) lcolor(gray)) ///
        note("Gray dashed line = 5% reference threshold")

    graph export "WGA_outlier_rate_trend.png", replace width(1600)
restore


*===============================================================================
* STEP 9 — CLUSTER-LEVEL SCATTER: outlier rate vs total births
*           Identifies clusters with both high volume AND high outlier rate
*===============================================================================

preserve
    keep if !missing(WGA_FLAG) | !missing(WEEKS_BDF_EUSG)

    bysort CLUST_NUM: egen CLUST_TOTAL    = count(PID)
    bysort CLUST_NUM: egen CLUST_OUTLIERS = total(WGA_FLAG != .)
    gen CLUST_OUTLIER_RATE = (CLUST_OUTLIERS / CLUST_TOTAL) * 100

    duplicates drop CLUST_NUM, force

    twoway scatter CLUST_OUTLIER_RATE CLUST_TOTAL, ///
        mlabel(DIST_NAME) mlabsize(vsmall) mlabposition(3) ///
        mcolor(blue) msymbol(circle) msize(medium) ///
        title("WGA outlier rate vs total births by cluster", size(medium)) ///
        ytitle("Outlier rate (%)") ///
        xtitle("Total births in cluster") ///
        yline(5, lpattern(dash) lcolor(gray)) ///
        note("Gray line = 5% reference. Labels = district name.")

    graph export "WGA_cluster_outlier_scatter.png", replace width(1400)
restore
*/

*-------------------------------------------------------------------------------
* A10d. Missing birthweights
*-------------------------------------------------------------------------------

* Missing weight for stillbirths
br $bdf_id DEL_SHIFT BDF_VITAL_STATUS BDF_GA_WEEKS ///
    if BDF_BIRTH_WEIGHT >= 8000 & YYYY == 2026 

* Summary of missing weights by cluster and month
tab DIST_NAME YYYYMM if BDF_BIRTH_WEIGHT >= 8000 & YYYY == 2026 

* Summary of missing livebirth weights by cluster and month [STILLBIRTHS]
* tab DIST_NAME YYYYMM if BDF_BIRTH_WEIGHT == . & BDF_BIRTH_STATUS == 2

* Birthweight < 500g for a livebirth — almost certainly erroneous [NEW]
br $bdf_id DEL_SHIFT BDF_VITAL_STATUS BDF_BIRTH_WEIGHT WEEKS_BDF_EUSG ///
    if BDF_BIRTH_WEIGHT < 500 

/*******************************************************************************
*
*  FILE         : birthweight_repetition_check.do
*  PURPOSE      : Detect suspicious birthweight repetition patterns
*                 by hospital, cluster, and enumerator (RA)
*  APPROACH     : Four detection layers:
*                   1. Raw frequency of top repeated weights
*                   2. Facility-level repetition concentration
*                   3. RA-level repetition fingerprint
*                   4. Statistical flags (Benford, digit preference index)
*
********************************************************************************/

*===============================================================================
* W1 — BUILD A WEIGHT FREQUENCY TABLE PER FACILITY
*           Which specific gram values are overrepresented WHERE?
*===============================================================================

* Overall top-20 most repeated weights (baseline — what you already have)
tab BDF_BIRTH_WEIGHT if BDF_BIRTH_WEIGHT < 2000, sort // <2000
tab BDF_BIRTH_WEIGHT if BDF_BIRTH_WEIGHT > 2000 & BDF_BIRTH_WEIGHT < 3000, sort // 2000-3000
tab BDF_BIRTH_WEIGHT if BDF_BIRTH_WEIGHT > 3000 & BDF_BIRTH_WEIGHT < 5000, sort //3000-500

*-------------------------------------------------------------------------------
* For each hospital: show the top repeated weights
* This immediately tells you if 3000g appears 80 times in one hospital vs spread
*-------------------------------------------------------------------------------

* Create a frequency variable: how many times does this exact weight appear
* in the entire dataset?
bysort BDF_BIRTH_WEIGHT: gen WEIGHT_FREQ_GLOBAL = _N
label var WEIGHT_FREQ_GLOBAL "Global frequency of this exact birthweight value"

* Flag weights that appear more than a threshold number of times overall
* Adjust threshold (50) based on your total N
gen flag_high_freq_weight = (WEIGHT_FREQ_GLOBAL >= 50) & !missing(BDF_BIRTH_WEIGHT) &  BDF_BIRTH_WEIGHT != 8888
label var flag_high_freq_weight "Weight value appears ≥50 times in full dataset"

* For flagged weights: show their distribution across hospitals
tab HOSPITAL_NAME_BDF if flag_high_freq_weight == 1 &  BDF_BIRTH_WEIGHT != 8888, sort

preserve
    keep if flag_high_freq_weight == 1
    bysort DIST_NAME HOSPITAL_NAME_BDF RA_NAME BDF_BIRTH_WEIGHT: gen RA_WEIGHT_FREQ = _N
    duplicates drop DIST_NAME HOSPITAL_NAME_BDF RA_NAME BDF_BIRTH_WEIGHT, force
    gsort DIST_NAME HOSPITAL_NAME_BDF RA_NAME -RA_WEIGHT_FREQ
    asdoc list DIST_NAME HOSPITAL_NAME_BDF RA_NAME BDF_BIRTH_WEIGHT RA_WEIGHT_FREQ WEIGHT_FREQ_GLOBAL, sep(0)
restore



*===============================================================================
* W2 — CONCENTRATION INDEX PER FACILITY
*           Is one hospital responsible for most of a repeated weight?
*===============================================================================

* For each hospital-weight combination: count occurrences
bysort HOSPITAL_NAME_BDF BDF_BIRTH_WEIGHT: gen WEIGHT_FREQ_HOSP = _N
label var WEIGHT_FREQ_HOSP "Frequency of this weight within this hospital"

* Flag: same weight appearing ≥10 times within a single hospital
gen flag_hosp_weight_cluster = (WEIGHT_FREQ_HOSP >= 10) & !missing(BDF_BIRTH_WEIGHT)
label var flag_hosp_weight_cluster "Same weight ≥10 times in one hospital"

* Review: which hospital-weight combos are most suspicious
br DIST_NAME HOSPITAL_NAME_BDF RA_NAME PID BDF_BIRTH_WEIGHT WEIGHT_FREQ_HOSP ///
    if flag_hosp_weight_cluster == 1 ///
    & BDF_BIRTH_WEIGHT > 500 & BDF_BIRTH_WEIGHT < 5000 ///
    & BDF_VITAL_STATUS == 1                               // livebirths only

* Tabulate count of flagged cases per hospital
tab HOSPITAL_NAME_BDF if flag_hosp_weight_cluster == 1, sort

* Trend: is hospital-level clustering getting worse over time?
tab HOSPITAL_NAME_BDF YYYYMM  if flag_hosp_weight_cluster == 1



*===============================================================================
* W3 — WITHIN-SHIFT REPETITION
*           Same weight appearing multiple times on same shift in same hospital
*           More targeted than global frequency
*===============================================================================

* For each hospital-shift-weight combination
bysort HOSPITAL_NAME_BDF DEL_SHIFT YYYYMM BDF_BIRTH_WEIGHT: gen WEIGHT_FREQ_SHIFT = _N
label var WEIGHT_FREQ_SHIFT "Frequency of this weight in this hospital-shift-month"

* Flag: same weight ≥5 times in one hospital shift
gen flag_shift_weight_repeat = (WEIGHT_FREQ_SHIFT >= 5) & !missing(BDF_BIRTH_WEIGHT)
label var flag_shift_weight_repeat "Same weight ≥5 times in one hospital-shift-month"

br DIST_NAME HOSPITAL_NAME_BDF DEL_SHIFT YYYYMM BDF_BIRTH_WEIGHT WEIGHT_FREQ_SHIFT RA_NAME ///
    if flag_shift_weight_repeat == 1 


*===============================================================================
* W5 — DIGIT PREFERENCE INDEX (DPI) BY HOSPITAL
*           Formal measure: what % of weights end in each digit?
*           A uniform distribution = 10% each. Spikes indicate preference.
*===============================================================================

* Extract last digit of birthweight
gen WEIGHT_LAST_DIGIT = mod(BDF_BIRTH_WEIGHT, 10)
label var WEIGHT_LAST_DIGIT "Last digit of birthweight"

* Extract second-to-last digit (tens place)
gen WEIGHT_TENS_DIGIT = mod(floor(BDF_BIRTH_WEIGHT / 10), 10)
label var WEIGHT_TENS_DIGIT "Tens digit of birthweight"

* Overall last-digit distribution (should be ~10% each if unbiased)
tab WEIGHT_LAST_DIGIT, gen(ld_)

* Last-digit distribution BY HOSPITAL — see which hospitals deviate most
tab HOSPITAL_NAME_BDF WEIGHT_LAST_DIGIT if inrange(YYYYMM, $win_start, $win_end) & (WEIGHT_LAST_DIGIT != 0 | WEIGHT_LAST_DIGIT !=5)


*===============================================================================
* W6 — GRAPHICAL DETECTION (most powerful visual tool)
*           Spike plots by hospital — gaps and spikes reveal fabrication
*===============================================================================

* Overall spike plot — you can see 2810, 3000 etc. as tall spikes
twoway histogram BDF_BIRTH_WEIGHT ///
    if BDF_BIRTH_WEIGHT > 1500 & BDF_BIRTH_WEIGHT < 4500, ///
    discrete freq ///
    title("Birthweight distribution — all hospitals", size(medium)) ///
    xtitle("Birthweight (grams)") ytitle("Frequency") ///
    xlabel(1500(100)4500, labsize(tiny) angle(45))

*-------------------------
* Heaping * BY RA — 
*-------------------------

* Core Facility - an RA-level fabrication will show even more concentrated spikes
twoway histogram BDF_BIRTH_WEIGHT ///
    if BDF_BIRTH_WEIGHT > 1500 & BDF_BIRTH_WEIGHT < 4500 ///
    & YYYY == 2026 & ACS_IF==1 , ///
    discrete freq by(RA_NAME, rows(4) note("")) ///
    title("Birthweight distribution by RA", size(small)) ///
    xtitle("Birthweight (grams)") ytitle("Frequency") ///
    xlabel(1500(500)4500, labsize(tiny))

* Peripheral Facility - an RA-level fabrication will show even more concentrated spikes
twoway histogram BDF_BIRTH_WEIGHT ///
    if BDF_BIRTH_WEIGHT > 1500 & BDF_BIRTH_WEIGHT < 4500 ///
    & YYYY == 2026 & ACS_IF==2 , ///
    discrete freq by(RA_NAME, rows(4) note("")) ///
    title("Birthweight distribution by RA", size(small)) ///
    xtitle("Birthweight (grams)") ytitle("Frequency") ///
    xlabel(1500(500)4500, labsize(tiny))
	
*-------------------------
* Heaping * Facility
*-------------------------
* Cluster - Core Facility 
twoway histogram BDF_BIRTH_WEIGHT ///
    if BDF_BIRTH_WEIGHT > 1500 & BDF_BIRTH_WEIGHT < 4500 ///
    & YYYY == 2026 & ACS_IF==1 , ///
    discrete freq by(HOSPITAL_NAME_BDF, rows(4) note("")) ///
    title("Birthweight distribution by Cluster- Core Facility", size(small)) ///
    xtitle("Birthweight (grams)") ytitle("Frequency") ///
    xlabel(1500(500)4500, labsize(tiny))

* Peripheral Facility
twoway histogram BDF_BIRTH_WEIGHT ///
    if BDF_BIRTH_WEIGHT > 1500 & BDF_BIRTH_WEIGHT < 4500 ///
    & YYYY == 2026 & ACS_IF==2 , ///
    discrete freq by(HOSPITAL_NAME_BDF, rows(4) note("")) ///
    title("Birthweight distribution by Cluster- Core Facility", size(small)) ///
    xtitle("Birthweight (grams)") ytitle("Frequency") ///
    xlabel(1500(500)4500, labsize(tiny))
	
*===============================================================================
* A11. ACUTE BACTERIAL INFECTION & PRETERM BIRTH INDICATIONS
*===============================================================================

*-------------------------------------------------------------------------------
* A11a. Acute bacterial infection
*-------------------------------------------------------------------------------


tab BDF_ACUTE_BACT_INF GA_BIRTH_CAT

* Missing ABI for preterm or LBW deliveries
br $bdf_id DEL_SHIFT BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_ACUTE_BACT_INF ///
    if (GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000)  ///
    & (missing(BDF_ACUTE_BACT_INF) | BDF_ACUTE_BACT_INF > 2) & YYYY == 2026

* mistaken for a confirmed term delivery
br $bdf_id BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_ACUTE_BACT_INF ///
    if GA_BIRTH_CAT == 3 & BDF_BIRTH_WEIGHT > 2000  ///
    & BDF_ACUTE_BACT_INF <= 2 & YYYY == 2026

tab DIST_NAME YYYYMM ///
    if (GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000)  ///
    & (missing(BDF_ACUTE_BACT_INF) | BDF_ACUTE_BACT_INF > 2)


*-------------------------------------------------------------------------------
* A11c. Preterm birth indication
*-------------------------------------------------------------------------------

tab BDF_PT_BIRTH_INDICTN if GA_BIRTH_CAT <= 2

* Flag 1: Preterm/LBW but indication recorded as NA
br $bdf_id BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_PT_BIRTH_INDICTN ///
    if (GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000) & APP == "P2B" ///
    & BDF_PT_BIRTH_INDICTN == 9 & YYYY == 2026

* FIXED: GA_BIRTH_CAT>2 -> ==3 (excludes "no provider estimate", code 9)
* Flag 2: Term/normal weight but preterm indication filled
br $bdf_id BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_PT_BIRTH_INDICTN ///
    if GA_BIRTH_CAT == 3 & BDF_BIRTH_WEIGHT > 2000  ///
    & BDF_PT_BIRTH_INDICTN <= 2 & YYYY == 2026

*-------------------------------------------------------------------------------
* A11c. Preterm birth indication
*-------------------------------------------------------------------------------

tab BDF_PT_BIRTH_INDICTN if GA_BIRTH_CAT <= 2 

* Flag 1: Preterm/LBW but indication recorded as NA
br DIST_NAME RA_NAME HOSPITAL_NAME_BDF MM PID BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_PT_BIRTH_INDICTN ///
    if (GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000)  ///
    & BDF_PT_BIRTH_INDICTN == 9 & YYYY == 2026

* Flag 2: Term/normal weight but preterm indication filled
br DIST_NAME RA_NAME HOSPITAL_NAME_BDF MM PID BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_PT_BIRTH_INDICTN ///
    if GA_BIRTH_CAT > 2 & BDF_BIRTH_WEIGHT > 2000  ///
    & BDF_PT_BIRTH_INDICTN <= 2 & YYYY == 2026

*-------------------------------------------------------------------------------
* A11d. Antibiotics
*-------------------------------------------------------------------------------

br $bdf_id BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_ANTIBIOTICS ///
    if (GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000) ///
    & (missing(BDF_ANTIBIOTICS) | BDF_ANTIBIOTICS > 2) & YYYY == 2026


*-------------------------------------------------------------------------------
* A11e. Magnesium sulphate (MgSO4)
*-------------------------------------------------------------------------------

br $bdf_id BDF_GA_WEEKS BDF_BIRTH_WEIGHT BDF_MAGNESIUM_SUL ///
    if (GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000)  ///
    & (missing(BDF_MAGNESIUM_SUL) | BDF_MAGNESIUM_SUL > 2) & YYYY == 2026


* MgSO4 given to term delivery — not indicated
br $bdf_id BDF_GA_WEEKS BDF_MAGNESIUM_SUL ///
    if BDF_MAGNESIUM_SUL == 1 & GA_BIRTH_CAT == 3 & YYYY == 2026


*-------------------------------------------------------------------------------
* A11f. Tocolytics
*-------------------------------------------------------------------------------

tab DIST_NAME YYYYMM ///
    if (GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000) & BDF_TOCOLYTICS == 1

br $bdf_id BDF_GA_WEEKS BDF_TOCOLYTICS ///
    if (GA_BIRTH_CAT <= 2 | BDF_BIRTH_WEIGHT <= 2000) & BDF_TOCOLYTICS == 1 
	
* Across ACS form for the same admission
gen SAME_DAY_ACS_DEL = (dofc(ACS_DT) == BDF_DT_DELIVERY) if !missing(ACS_DT, BDF_DT_DELIVERY)
label variable SAME_DAY_ACS_DEL "ACS Dose 1 (course 1) given same calendar day as delivery"

tab DIST_NAME_ACS SAME_DAY_ACS_DEL if BDF_TOCOLYTICS == 1 & ACS_TOCOLYTICS1 == 2 & ($preterm_lbw)

br $acs_id ACS_DT BDF_DT_DELIVERY DAYS_FROM_DOSE1_TO_DEL BDF_GA_WEEKS BDF_BIRTH_WEIGHT ///
    if ACS_TOCOLYTICS1 == 1 & SAME_DAY_ACS_DEL == 1 & ($preterm_lbw)

*--- Consistency check: BDF says tocolytics given, does ACS1 agree? ------------
gen byte FLAG_TOCO_BDF_NOT_ACS1 = (BDF_TOCOLYTICS == 1 & ACS_TOCOLYTICS1 != 1) if FORM_ACS1 == 1
label variable FLAG_TOCO_BDF_NOT_ACS1 "BDF says tocolytics given, but ACS1 does not confirm Yes"

br $acs_id  BDF_TOCOLYTICS ACS_TOCOLYTICS1 ///
    if FLAG_TOCO_BDF_NOT_ACS1 == 1

*===============================================================================
* A12. MODE OF DELIVERY
*===============================================================================

tab DIST_NAME BDF_MODE_DELIVERY if inrange(YYYYMM, $win_start, $win_end)
tab HOSPITAL_NAME_BDF BDF_MODE_DELIVERY
tab BDF_MODE_DELIVERY BDF_NUM_FETUS
tab YYYYMM BDF_MODE_DELIVERY, row nofreq

* FIXED: added FORM_BDF guard (explicit missing() check needs it)
br $bdf_id BDF_MODE_DELIVERY ///
    if (inlist(BDF_MODE_DELIVERY, 8, 9) | missing(BDF_MODE_DELIVERY)) & (FORM_BDF==1 | STATUS==1)

* VBAC flag — pending clarification, see note above
 br $bdf_id BDF_MODE_DELIVERY BDF_NUM_PRV_DEL BDF_PT_BIRTH_INDICTN ///
     if BDF_MODE_DELIVERY == 1 & BDF_PT_BIRTH_INDICTN == 4



*===============================================================================
* A13. RESUSCITATION
*===============================================================================

gen BDF_RESUSCITATION1 = (BDF_RESUSCITATION == 1) if !missing(BDF_RESUSCITATION)
label variable BDF_RESUSCITATION1 "Resuscitation performed (binary)"

tabstat FORM_BDF BDF_RESUSCITATION1, by(DIST_NAME) stat(sum)

tab DIST_NAME GA_BIRTH_CAT      if BDF_RESUSCITATION1 == 1 & YYYY == 2026   // provider GA
tab DIST_NAME GA_BIRTH_EUSG_BW  if BDF_RESUSCITATION1 == 1 & YYYY == 2026   // EUSG GA
tab DIST_NAME BDF_PT_BIRTH_INDICTN if BDF_RESUSCITATION1 == 1 & YYYY == 2026

br $bdf_id WEEKS_BDF_PROV WEEKS_BDF_EUSG BDF_BIRTH_WEIGHT BDF_PT_BIRTH_INDICTN ///
    if BDF_RESUSCITATION1 == 1 & YYYY == 2026

* Resuscitation in term baby of normal weight — anomaly
br $bdf_id BDF_BIRTH_WEIGHT WEEKS_BDF_PROV BDF_RESUSCITATION ///
    if BDF_RESUSCITATION1 == 1 & GA_BIRTH_CAT == 3 & BDF_BIRTH_WEIGHT >= 2500 & YYYY == 2026

/* Blinded variable
*===============================================================================
* A14. STATUS OF BABY WHEN MOTHER LEAVES FACILITY
*===============================================================================

tab DIST_NAME BDF_LEFT_STATUS if YYYY == 2026 & MM == 02

* NOC facility — should not have NICU referrals
br DIST_NAME RA_NAME HOSPITAL_NAME_BDF MM PID BDF_LEFT_STATUS ///
    if BDF_LEFT_STATUS == 2 & FAC_BDF == "NOC Facility"
*/

*===============================================================================
* A15. DATA TIMELINESS: DELIVERY -> SUBMISSION -> EXPORT, BY RA
*===============================================================================

*--- Continuous timing variables ------------------------------------------------
gen DAYS_DEL_TO_SUBMIT = (Submit_BDF - DEL_DT) / (1000*60*60*24) if !missing(Submit_BDF, DEL_DT)
label variable DAYS_DEL_TO_SUBMIT "Days from delivery to BDF submission"

gen DAYS_SUBMIT_TO_TRANSFER = (Transfer_BDF - Submit_BDF) / (1000*60*60*24) if !missing(Transfer_BDF, Submit_BDF)
label variable DAYS_SUBMIT_TO_TRANSFER "Days from submission to transfer/export"

gen DAYS_DEL_TO_TRANSFER = (Transfer_BDF - DEL_DT) / (1000*60*60*24) if !missing(Transfer_BDF, DEL_DT)
label variable DAYS_DEL_TO_TRANSFER "Days from delivery to transfer/export"

*--- Same-calendar-day indicators -----------------------------------------------
gen SAME_DAY_DEL_SUBMIT = (dofc(Submit_BDF) == BDF_DT_DELIVERY) if !missing(Submit_BDF, BDF_DT_DELIVERY)
label variable SAME_DAY_DEL_SUBMIT "BDF submitted same calendar day as delivery"

gen SAME_DAY_SUBMIT_TRANSFER = (dofc(Transfer_BDF) == dofc(Submit_BDF)) if !missing(Transfer_BDF, Submit_BDF)
label variable SAME_DAY_SUBMIT_TRANSFER "BDF transferred same calendar day as submission"

*--- Overview ---------------------------------------------------------------------
sum DAYS_DEL_TO_SUBMIT DAYS_SUBMIT_TO_TRANSFER DAYS_DEL_TO_TRANSFER, detail
	
*--- By-RA summary: N, mean, median, worst-case + same-day rate -----------------
tabstat DAYS_DEL_TO_SUBMIT DAYS_SUBMIT_TO_TRANSFER, by(RA_NAME) stat(n mean p50 max)
tabstat SAME_DAY_DEL_SUBMIT SAME_DAY_SUBMIT_TRANSFER, by(RA_NAME) stat(mean n)

*--- Flag 1: Submitted BEFORE delivery was recorded (implausible / date error) ---
br $bdf_id BDF_DT_DELIVERY Submit_BDF DAYS_DEL_TO_SUBMIT ///
    if DAYS_DEL_TO_SUBMIT < 0 & !missing(DAYS_DEL_TO_SUBMIT)

*--- Flag 2: Slow submission (>7 days delivery -> submit) -----------------------
br $bdf_id BDF_DT_DELIVERY Submit_BDF DAYS_DEL_TO_SUBMIT ///
    if DAYS_DEL_TO_SUBMIT > 7 & !missing(DAYS_DEL_TO_SUBMIT)

*--- Flag 3: Slow export (>2 days submit -> transfer) ----------------------------
br $bdf_id Submit_BDF Transfer_BDF DAYS_SUBMIT_TO_TRANSFER ///
    if DAYS_SUBMIT_TO_TRANSFER > 2 & !missing(DAYS_SUBMIT_TO_TRANSFER)

********************************************************************************
*
*   SECTION B : ACS FORM
*
********************************************************************************

*===============================================================================
* B1. ACS DATES & TIMES
*===============================================================================

gen flag_acs_order = .
replace flag_acs_order = 1 if ACS_DT_EARLY_USG1 > ACS_DOSE1_DATE1 ///
    & !missing(ACS_DT_EARLY_USG1)
label variable flag_acs_order "ACS date-order anomaly"

gen acs_missing = ""
replace acs_missing = "ACS Dose missing" ///
    if missing(ACS_DOSE1_DATE1) & acs_missing == "" & FORM_ACS1 == 1

tab acs_missing DIST_NAME_ACS

br $acs_id GA_ACS_EUSG ACS_DT_EARLY_USG1 ACS_DOSE1_DATE1 ///
    if flag_acs_order == 1 & !missing(ACS_DT_EARLY_USG1) & FORM_ACS1 == 1

br $acs_id ACS_DOSE1_DATE1 BDF_DT_DELIVERY ///
    if ACS_DOSE1_DATE1 > BDF_DT_DELIVERY & !missing(ACS_DOSE1_DATE1)

* FIXED: FORM_BDF==0 -> missing(FORM_BDF), see note above (needs confirming via count)
tab DIST_NAME_ACS YYYYMM_ACS ///
    if FORM_ACS1 == 1 & missing(FORM_BDF)



*===============================================================================
* B2. ACS — EARLIEST USG
*===============================================================================

tab DIST_NAME EUSG_ACS_AVAIL

* EUSG available in ACS but not in BDF — possible data entry inconsistency
br $acs_id EUSG_ACS_AVAIL EUSG_BDF_AVAIL EUSG_AVAIL ///
    if FORM_ACS1 == 1 & EUSG_BDF_AVAIL == 0 & EUSG_ACS_AVAIL == 1

* Same earliest-USG DATE recorded on both BDF and ACS forms, but a DIFFERENT
* GA-in-weeks recorded at that same scan -- if it's really the same USG visit,
* the weeks should match; a mismatch here means one form mistyped the weeks
* (or the two forms are actually referencing two different scans that just
* happen to share a date)
br $acs_id BDF_DT_EARLY_USG ACS_DT_EARLY_USG1 BDF_GA_EARLYUSG_WKS ACS_GA_EARLYUSG_WKS1 ///
    if BDF_DT_EARLY_USG == ACS_DT_EARLY_USG1 & BDF_GA_EARLYUSG_WKS != ACS_GA_EARLYUSG_WKS1 & FORM_ACS1 == 1



*===============================================================================
* B3. ACS — GA MISMATCH (PROVIDER VS EARLIEST USG)
*===============================================================================

gen DIFF_ACS_EUSG_PROV_GA = GA_ACS_DAY - GA_ACS_EUSG if EUSG_ACS_AVAIL == 1
label variable DIFF_ACS_EUSG_PROV_GA "Difference (days): Provider GA - Earliest USG GA (ACS)"

gen ACS_MISMATCHED_GA = (abs(DIFF_ACS_EUSG_PROV_GA) > 7) if EUSG_ACS_AVAIL == 1
label variable ACS_MISMATCHED_GA "ACS: Mismatched GA (> 7 days difference)"

* FIXED: aligned with A9's windowed version for consistency
tab DIST_NAME YYYYMM_ACS if ACS_MISMATCHED_GA == 1 & inrange(YYYYMM_ACS, $win_start, $win_end)

br $acs_id ACS_DT_EARLY_USG1 ACS_GA_EARLYUSG_WKS1 ACS_GA_EARLYUSG_DAYS1 ///
    ACS_GA_ADM_WEEKS1 ACS_GA_ADM_DAYS1 DIFF_ACS_EUSG_PROV_GA ///
    if ACS_MISMATCHED_GA == 1

* Invalid GA entries (<=24 or >=45 weeks) — confirm this boundary convention is intentional
br $acs_id ACS_GA_ADM_WEEKS1 ACS_DT_EARLY_USG1 ACS_GA_EARLYUSG_WKS1 ///
    ACS_GA_EARLYUSG_DAYS1 WEEKS_ACS_EUSG ///
    if !missing(GA_ACS_EUSG) & (WEEKS_ACS_EUSG <= 24 | WEEKS_ACS_EUSG >= 45)



*===============================================================================
* B4. ACS — CLINICAL ASSESSMENT AT ADMISSION
*===============================================================================

tab DIST_NAME ACS_PRIM_DIAGN1 if FORM_ACS1 == 1

* FIXED: ACS_to_del_hours is clipped (negative gaps forced to 0) in the main
* do-file — added DAYS_ACS_TO_DEL>=0 so ACS-given-after-delivery cases aren't
* silently counted as "<6 hours before delivery"
br $acs_id ACS_FHS1 BDF_FHS ACS_to_del_hours DAYS_ACS_TO_DEL ///
    if FORM_ACS1 == 1 & FORM_BDF == 1 ///
    & ACS_FHS1 == 1 & BDF_FHS == 2 & ACS_to_del_hours < 6 & DAYS_ACS_TO_DEL >= 0

* FHS discordant on same delivery date (unaffected — date-level, not clipped)
br $acs_id ACS_FHS1 BDF_FHS ///
    if FORM_ACS1 == 1 & FORM_BDF == 1 ///
    & ACS_FHS1 != BDF_FHS & ACS_DOSE1_DATE1 == BDF_DT_DELIVERY

* FIXED: same clipping issue as the FHS check above
br $acs_id ACS_SIGNS_ACUTE_INFECTION1 BDF_ACUTE_BACT_INF ACS_to_del_hours DAYS_ACS_TO_DEL ///
    if FORM_ACS1 == 1 & FORM_BDF == 1 ///
    & ACS_SIGNS_ACUTE_INFECTION1 == 1 & BDF_ACUTE_BACT_INF == 2 & ACS_to_del_hours < 12 & DAYS_ACS_TO_DEL >= 0



*===============================================================================
* B5. ACS DOSE DETAILS
*===============================================================================

* ACS datetime after delivery datetime
br $acs_id ACS_DT DEL_DT ///
    if FORM_ACS1 == 1 & !missing(DAYS_FROM_DOSE1_TO_DEL) & DAYS_FROM_DOSE1_TO_DEL < 0


* Delivery more than 14 days after ACS dose
br $acs_id ACS_DOSE1_DATE1 ACS_DOSE1_HH1 ACS_DOSE1_MM1 ///
    BDF_DT_DELIVERY BDF_TM_DELIVERY_HH BDF_TM_DELIVERY_MM DAYS_FROM_DOSE1_TO_DEL ///
    if FORM_ACS1 == 1 & !missing(DAYS_FROM_DOSE1_TO_DEL) & DAYS_FROM_DOSE1_TO_DEL > 14

* Dose amount other than  06,08,12,24 mg
br $acs_id ACS_DOSE_MG1 ACS_DOSES_TOTAL1 ACS_DOSE_INTERVAL1 ///
    if !inlist(ACS_DOSE_MG1,6,8,12,24) & FORM_ACS1==1
	

* Added ACS_DOSES_TOTAL1>1 defensively — confirm whether it changes the count
br $acs_id ACS_DOSE_MG1 ACS_DOSES_TOTAL1 ACS_DOSE_INTERVAL1 ///
    if ACS_DOSE_INTERVAL1 < 6 & ACS_DOSES_TOTAL1 > 1

* Inter-dose interval > 36 hours [NEW]
br $acs_id ACS_DOSE_INTERVAL1 ACS_DOSES_TOTAL1 ///
    if ACS_DOSE_INTERVAL1 > 36 & !missing(ACS_DOSE_INTERVAL1) & ACS_DOSE_INTERVAL1 < 80 & ACS_DOSES_TOTAL1 > 1

* Inconsistent ACS dosage 
gen byte NONSTD_DOSE = !inlist(ACS_DOSE_MG1, 6,8, 12,24) & !missing(ACS_DOSE_MG1)
tab DIST_NAME_ACS if NONSTD_DOSE == 1, missing

br $acs_id ACS_DOSE_MG1 ACS_DOSES_TOTAL1 MM_ACS if NONSTD_DOSE == 1 & YYYYMM_ACS==2026 // 2026 ONLY 

********************************************************************************
*
*   MNFU DATA QUALITY CHECKS
*
********************************************************************************

*===============================================================================
* MN0. SKIP-LOGIC CONSISTENCY
*===============================================================================

*--- Rule 1: BDF_CONSENT==2 (no consent) -> MNFU should never be generated ----
*    FIXED 2026-08-31: this filter only checked STATUS, never FORM_NFU -- so it
*    flagged every consent-refused record regardless of whether a follow-up
*    actually existed. Verified against August 2026 data: FORM_NFU was blank
*    for 100% of the ~91 "flagged" cases (0 real violations), i.e. the check
*    was reporting correct behavior as a data-quality problem. FORM_NFU==1 is
*    now required so this only fires on a genuine violation.
tab STATUS if BDF_MNFU_CONSENT == 2

br $bdf_id BDF_MNFU_CONSENT FORM_NFU NFU_DT_FILL ///
    if BDF_MNFU_CONSENT == 2 & FORM_NFU == 1

*--- Rule 2: NFU_INTERVIEW_DONE==2 (interview not done) -> everything downstream
*    should carry the skip code, not a real answer.
*    RESOLVED: checked actual data -- NFU_TYPE_INTERVIEW and NFU_INFORMANT never
*    use 8/88/888. Skip code is 7 ("Missing") for current records, plus a legacy
*    9 code on 97 older records from before the project switched from 9 to 7
*    (see main do-file changelog, 2025-09-11 vs 2025-12-10 entries). Both 7 and 9
*    occur only when NFU_INTERVIEW_DONE==2, confirming they're the same skip
*    concept under two conventions, not distinct real answers.
*    NFU_MOTHER_ALIVE/NFU_MOTHER_READMIT/NFU_VITAL_STATUS were NOT re-checked --
*    left on 8/88/888 pending the same verification.
br $mnfu_id NFU_TYPE_INTERVIEW NFU_INFORMANT NFU_MOTHER_ALIVE NFU_MOTHER_READMIT NFU_VITAL_STATUS ///
    if NFU_INTERVIEW_DONE == 2 & ( ///
         (!inlist(NFU_TYPE_INTERVIEW, 7, 9)        & !missing(NFU_TYPE_INTERVIEW))  | ///
         (!inlist(NFU_INFORMANT,      7, 9)        & !missing(NFU_INFORMANT))       | ///
         (!inlist(NFU_MOTHER_ALIVE,   8, 88, 888)  & !missing(NFU_MOTHER_ALIVE))    | ///
         (!inlist(NFU_MOTHER_READMIT, 8, 88, 888)  & !missing(NFU_MOTHER_READMIT))  | ///
         (!inlist(NFU_VITAL_STATUS,   8, 88, 888)  & !missing(NFU_VITAL_STATUS)) )

*--- Reverse case: interview WAS done (==1) but a field still shows a skip
*    code instead of a real answer -- incomplete/improperly-skipped form -----
br $mnfu_id NFU_TYPE_INTERVIEW NFU_INFORMANT NFU_MOTHER_ALIVE ///
    if NFU_INTERVIEW_DONE == 1 & ( ///
         inlist(NFU_TYPE_INTERVIEW, 7, 9) | ///
         inlist(NFU_INFORMANT,      7, 9) | ///
         inlist(NFU_MOTHER_ALIVE,   8, 88, 888) )


*===============================================================================
* MN1. ELIGIBILITY & CONSENT
*===============================================================================
tab NEEDS_NFU
* NOTE: NEEDS_NFU_BABY not found in current compiled dataset -- guarded with
* capture so it doesn't halt the rest of the QC file. Needs investigation:
* variable may have been renamed/removed in a recent compilation pipeline change.
capture tab NEEDS_NFU_MOTHER NEEDS_NFU_BABY
if _rc != 0 di as error "SKIPPED: NEEDS_NFU_BABY not found in dataset (rc=`_rc')"
tab ELIGIBLE_MNFU DIST_NAME, row nofreq


*===============================================================================
* MN2. STATUS TRACKING
*===============================================================================
tab MNFUS_STATUS DIST_NAME, col nofreq
tab MNFU_STATUS_60 DIST_NAME, row nofreq
tab LOST_TFU DIST_NAME, row nofreq
tab MNFU_PENDING_TIME DIST_NAME if MNFU_PENDING_TIME == 4, row nofreq

* By RA — who has the most pending/lost cases
tab RA_NAME MNFUS_STATUS if inlist(MNFUS_STATUS,1,3,4,5)


*===============================================================================
* MN3. INTERVIEW QUALITY
*===============================================================================
tab DIST_NAME YYYYMM_MNFU if AGE_NFU<=28 & NFU_DT_FILL>mdy(6,10,2026)
br $mnfu_id BDF_DT_DELIVERY NFU_DT_FILL AGE_NFU ///
    if AGE_NFU<=28 & NFU_DT_FILL>mdy(6,10,2026)

tab DIST_NAME NFU_TYPE_INTERVIEW if NFU_INTERVIEW_DONE == 1, row nofreq
tab DIST_NAME if NFU_TYPE_INTERVIEW == 8

tab DIST_NAME NFU_INFORMANT if NFU_INTERVIEW_DONE == 1, row nofreq
br $mnfu_id NFU_TYPE_INTERVIEW NFU_INFORMANT ///
    if NFU_INFORMANT != 1 & inlist(NFU_TYPE_INTERVIEW,2,3)


*===============================================================================
* MN4. MATERNAL OUTCOMES
*===============================================================================
tab Maternal_status DIST_NAME, col nofreq

br $bdf_id NFU_MOTHER_ALIVE ///
    if FORM_NFU==1 & (missing(NFU_MOTHER_ALIVE) | NFU_MOTHER_ALIVE==8)

tab DIST_NAME NFU_MOTHER_READMIT_RSN if NFU_MOTHER_READMIT == 1

capture drop AGE_READMISSION_MOTHER
gen AGE_READMISSION_MOTHER = NFU_MOTHER_READMIT_DT - BDF_DT_DELIVERY if !missing(NFU_MOTHER_READMIT_DT, BDF_DT_DELIVERY)
br $bdf_id NFU_MOTHER_READMIT BDF_DT_DELIVERY NFU_MOTHER_READMIT_DT AGE_READMISSION_MOTHER ///
    if NFU_MOTHER_READMIT == 1 & (AGE_READMISSION_MOTHER < 1 | NFU_MOTHER_READMIT_DT < mdy(1,1,2025))


*===============================================================================
* MN5. NEONATAL OUTCOMES
*===============================================================================
tab ANY_BABY_DEATH DIST_NAME, col nofreq
tab NNM DIST_NAME, col nofreq
tab PNM DIST_NAME, col nofreq
capture tab NFU_DEATH_PLACE DIST_NAME, col nofreq
if _rc != 0 di as error "SKIPPED: NFU_DEATH_PLACE not found (rc=`_rc')"

br $bdf_id VITAL_STATUS_3 NFU_VITAL_STATUS AGE_DEATH ///
    if VITAL_STATUS_3 == 9


********************************************************************************
*
*   SECTION F : FREQUENCY CHECKS (FOR MANUAL REVIEW)
*
*   PURPOSE: plain `tab ..., missing` for every coded/categorical field worth
*   periodically eyeballing by hand. Not an automated flag -- just a fast way
*   to scan for: a code that shouldn't exist (e.g. a stray 9 where the
*   codebook only defines 1/2/3/7), a blank/unlabeled value showing up in the
*   table, or a distribution that's oddly skewed. Several entries below exist
*   BECAUSE we found a real issue there this cycle -- worth checking every
*   time you get fresh data, not just once.
*
*   HOW TO USE: run this section on its own (select F1-F6 and run), scan each
*   table for anything that doesn't match what you expect from the codebook.
*
********************************************************************************

*===============================================================================
* F1. BDF FORM -- consent, timing, clinical
*===============================================================================
tab BDF_CONSENT, missing
tab BDF_MNFU_CONSENT, missing
tab BDF_ANC_PATIENT_STATUS, missing
tab BDF_TRIM_1STANC_VISIT, missing
tab BDF_NUM_ANT_VISITS_CAT, missing
tab BDF_ACS_RECEIVED, missing
tab BDF_PLACE_ACS, missing
tab BDF_FHS, missing
tab ADM_SHIFT, missing
tab DEL_SHIFT, missing

*===============================================================================
* F2. BDF FORM -- delivery & baby outcome
*===============================================================================
tab BDF_MODE_DELIVERY, missing
tab BDF_VITAL_STATUS, missing
tab BDF_SEX, missing
tab BDF_RESUSCITATION, missing
tab BDF_LEFT_STATUS, missing
tab BDF_ACUTE_BACT_INF, missing
tab BDF_PT_BIRTH_INDICTN, missing
tab BDF_ANTIBIOTICS, missing
tab BDF_MAGNESIUM_SUL, missing
tab BDF_TOCOLYTICS, missing

*===============================================================================
* F3. GESTATIONAL AGE / BIRTHWEIGHT CATEGORICALS
*===============================================================================
tab GA_BIRTH_CAT, missing
tab GA_BIRTH_CATU, missing
tab GEST_CAT_4, missing
tab GA_BIRTH_CAT_BW, missing
tab INVALID_BDF_USG, missing
tab INVALID_ACS_USG, missing
tab BW, missing
tab weight_level, missing
tab WEIGHT_ACCURACY2, missing
tab EXCLUDE, missing          // NOTE: computed but not currently used to drop anything -- see earlier finding
tab DGABW_QUERY, missing

*===============================================================================
* F4. ACS FORM (course 1) -- consent, clinical, dosing
*===============================================================================
tab ACS_CONSENT1, missing
tab ACS_PRIM_DIAGN1, missing
tab ACS_FHS1, missing
tab ACS_SIGNS_ACUTE_INFECTION1, missing
tab ACS_TOCOLYTICS1, missing
tab ACS_OUTCOME_ADM1, missing
tab ACS_DOSES_TOTAL1, missing
tab GA_ACS_CAT, missing
tab GA_ACS_CATU, missing
tab ACS_ACROSS, missing
tab ACS_IF, missing
tab TRIAL_PERIOD, missing

* Dose amount and interval are continuous-ish; use a coarse tab to sanity check
* the range rather than expecting a clean small set of categories
tab ACS_DOSE_MG1 if ACS_DOSE_MG1 < 20, missing
tab ACS_DOSE_INTERVAL1 if ACS_DOSE_INTERVAL1 < 30, missing

*===============================================================================
* F5. MNFU FORM -- interview logistics & consent
*===============================================================================
tab NFU_INTERVIEW_DONE, missing
tab NFU_TYPE_INTERVIEW, missing      // codebook: 1/2/3/7(+legacy 9) -- flag anything else
tab NFU_INFORMANT, missing           // codebook: 1/2/3/7(+legacy 9) -- flag anything else
tab NFU_MOTHER_ALIVE, missing
tab NFU_MOTHER_READMIT, missing
tab NFU_MOTHER_READMIT_RSN, missing
tab NFU_KMC, missing
tab NFU_KMC_FAC, missing
tab NFU_BREASTFED, missing
tab NFU_BREASTFED_FAC, missing

*===============================================================================
* F6. MNFU FORM -- vital status & program status
*===============================================================================
tab NFU_VITAL_STATUS, missing
tab NFU_DEATH_PLACE, missing
tab NFU_DEATH_LOCATION, missing
tab MNFUS_STATUS, missing
tab LOST_TFU, missing
tab MNFU_STATUS_35, missing
tab MNFU_STATUS_60, missing
tab Maternal_status, missing
tab NNM, missing
tab PNM, missing
tab ANY_BABY_DEATH, missing

*===============================================================================
* F7. SENTINEL / GARBAGE-VALUE SCAN (reusable block)
*    Same technique that found the 09aug1808 skip-logic sentinel in
*    NFU_MOTHER_READMIT_DT and ACS_OUTCOME_DT1. Re-run this any time you
*    suspect a new bad placeholder value has crept into a date field --
*    change `local sentinel` to whatever value you're checking for.
*===============================================================================
local sentinel = mdy(8,9,1808)   // change this to test a different suspected sentinel
di as text "Scanning all date-formatted variables for value: `sentinel'"
foreach v of varlist _all {
    capture confirm numeric variable `v'
    if _rc == 0 {
        local fmt : format `v'
        if strpos("`fmt'", "%td") > 0 | strpos("`fmt'", "%tC") > 0 | strpos("`fmt'", "%tc") > 0 {
            quietly count if `v' == `sentinel'
            if r(N) > 0 {
                di as error "`v' (format `fmt'): " r(N) " records with sentinel value"
            }
        }
    }
}

*===============================================================================
* SECTION G : BDF vs SSNC CROSS-VALIDATION (same PID/BABY_NUM)
*    SSNC only applies to the subset of babies admitted for special newborn
*    care, so the comparable population is always much smaller than the full
*    BDF cohort -- that is expected, not a bug.
*===============================================================================

*--- G1. Neonates refered to SSNC -------------------------------------------------------------
tab DIST_NAME if FORM_BDF == 1 & FORM_SSNC == 1,sort m

*===============================================================================
* G2. WEIGHT: BDF_BIRTH_WEIGHT vs SSNC_ADM_WEIGHT
*    NOTE: excludes 8888/9999 sentinel (missing-weight placeholder) from BDF
*    side -- include it and the diffs below are meaningless outliers.
*===============================================================================
capture drop WEIGHT_DIFF
capture drop ABS_WEIGHT_DIFF
capture drop WEIGHT_DIFF_BUCKET
gen WEIGHT_DIFF = SSNC_ADM_WEIGHT - BDF_BIRTH_WEIGHT ///
    if FORM_BDF == 1 & FORM_SSNC == 1 ///
    & !missing(BDF_BIRTH_WEIGHT) & !inlist(BDF_BIRTH_WEIGHT, 8888, 9999) ///
    & !missing(SSNC_ADM_WEIGHT)  & !inlist(SSNC_ADM_WEIGHT, 8888, 9999)
label variable WEIGHT_DIFF "SSNC admission weight minus BDF birth weight (g)"

gen ABS_WEIGHT_DIFF = abs(WEIGHT_DIFF)

gen byte WEIGHT_DIFF_BUCKET = .
replace WEIGHT_DIFF_BUCKET = 0 if ABS_WEIGHT_DIFF == 0
replace WEIGHT_DIFF_BUCKET = 1 if inrange(ABS_WEIGHT_DIFF,   1,  50)
replace WEIGHT_DIFF_BUCKET = 2 if inrange(ABS_WEIGHT_DIFF,  51, 100)
replace WEIGHT_DIFF_BUCKET = 3 if inrange(ABS_WEIGHT_DIFF, 101, 300)
replace WEIGHT_DIFF_BUCKET = 4 if inrange(ABS_WEIGHT_DIFF, 301, 1000)
replace WEIGHT_DIFF_BUCKET = 5 if ABS_WEIGHT_DIFF > 1000 & !missing(ABS_WEIGHT_DIFF)
label define WEIGHT_DIFF_LBL 0 "Exact match" 1 "1-50g" 2 "51-100g" ///
    3 "101-300g" 4 "301-1000g" 5 ">1000g"
label values WEIGHT_DIFF_BUCKET WEIGHT_DIFF_LBL
label variable WEIGHT_DIFF_BUCKET "BDF vs SSNC weight -- absolute difference bucket"

tab WEIGHT_DIFF_BUCKET, missing
tab DIST_NAME WEIGHT_DIFF_BUCKET if WEIGHT_DIFF_BUCKET >= 4, missing

* Large discrepancy for manual review
br $bdf_id DIST_NAME HOSPITAL_NAME_BDF RA_NAME BDF_DT_DELIVERY ///
    BDF_BIRTH_WEIGHT SSNC_ADM_WEIGHT WEIGHT_DIFF ///
    if WEIGHT_DIFF_BUCKET >= 4 & !missing(WEIGHT_DIFF_BUCKET)

*===============================================================================
* G3. DATE SEQUENCE: SSNC admission should not precede delivery
*===============================================================================
capture drop DAYS_DEL_TO_SSNC_ADM
gen DAYS_DEL_TO_SSNC_ADM = SSNC_DT_ADM - BDF_DT_DELIVERY ///
    if FORM_BDF == 1 & FORM_SSNC == 1 & !missing(SSNC_DT_ADM, BDF_DT_DELIVERY)
label variable DAYS_DEL_TO_SSNC_ADM "Days from delivery to SSNC admission"

sum DAYS_DEL_TO_SSNC_ADM, detail

* Impossible: SSNC admission recorded before the delivery date
br $bdf_id BDF_DT_DELIVERY SSNC_DT_ADM DAYS_DEL_TO_SSNC_ADM ///
    if DAYS_DEL_TO_SSNC_ADM < 0 & !missing(DAYS_DEL_TO_SSNC_ADM)

* Outlier: admitted more than 2 days after delivery -- check this is plausible
br $bdf_id BDF_DT_DELIVERY SSNC_DT_ADM DAYS_DEL_TO_SSNC_ADM ///
    if DAYS_DEL_TO_SSNC_ADM > 2 & !missing(DAYS_DEL_TO_SSNC_ADM)

*===============================================================================
* G4. DATE SEQUENCE: SSNC outcome should not precede SSNC admission
*===============================================================================
capture drop DAYS_SSNC_ADM_TO_OUTCOME
gen DAYS_SSNC_ADM_TO_OUTCOME = SSNC_DT_OUTCOME - SSNC_DT_ADM ///
    if FORM_SSNC == 1 & !missing(SSNC_DT_OUTCOME, SSNC_DT_ADM)
label variable DAYS_SSNC_ADM_TO_OUTCOME "Days from SSNC admission to outcome"

br $bdf_id SSNC_DT_ADM SSNC_DT_OUTCOME DAYS_SSNC_ADM_TO_OUTCOME ///
    if DAYS_SSNC_ADM_TO_OUTCOME < 0 & !missing(DAYS_SSNC_ADM_TO_OUTCOME)

*===============================================================================
* SECTION H : ACS OUTCOME vs BDF CROSS-VALIDATION (same PID)
*    Rule: if ACS was given and the admission outcome is coded "Delivered"
*    (ACS_OUTCOME_ADM1==2), a BDF (delivery) form must exist for that PID.
*    Population: FORM_ACS1==1 only -- ACS_OUTCOME_ADM1 is not answered otherwise.
*
*    MUST run on the WIDE dataset (Full_integerated_database_analysis_P2.dta,
*    one row per PID), NOT the long/per-baby dataset this file otherwise uses.
*    The long dataset (Full_database_analysis_P2_LONG_M_PK.dta) is built by
*    `drop if FORM_BDF != 1` BEFORE the reshape long (see compilation do-file,
*    line ~1219) -- every no-BDF record is already gone by the time it's built,
*    so H1 checked against it will always silently return 0 regardless of the
*    true answer. preserve/restore here to borrow the wide file without
*    disturbing the long dataset the rest of this script depends on.
*===============================================================================

preserve
    use "Full_integerated_database_analysis_P2.dta", clear

    * This is a separately-loaded dataset (wide, one row per PID) -- it does
    * NOT inherit the ARM SCOPE filter applied to the long dataset above, so
    * both the cluster exclusion and the arm filter must be reapplied here or
    * Section H would silently pool both arms regardless of target_arm.
    drop if inlist(CLUST_NUM, 5, 9, 11, 12)
    keep if CLUSTER_TYPE == `target_arm'

    *--- H1. Outcome says "Delivered" but no BDF form exists -----------------
    capture drop FLAG_ACS_DEL_NO_BDF
    gen byte FLAG_ACS_DEL_NO_BDF = (ACS_OUTCOME_ADM1 == 2 & FORM_BDF != 1) if FORM_ACS1 == 1
    label variable FLAG_ACS_DEL_NO_BDF "ACS outcome = Delivered but no BDF form on file"

    tab FLAG_ACS_DEL_NO_BDF, missing
    tab DIST_NAME_ACS if FLAG_ACS_DEL_NO_BDF == 1, sort missing

    br PID DIST_NAME_ACS HOSPITAL_NAME_ACS RA_NAME_ACS YYYYMM_ACS ///
        if FLAG_ACS_DEL_NO_BDF == 1

    *--- H2. Reverse: BDF form exists but outcome NOT coded "Delivered" ------
    *    A delivery record existing is itself proof a delivery happened, so any
    *    other outcome code here (No delivery / Referred / Remained / NK) is a
    *    logical contradiction worth reviewing -- likely a stale/unedited ACS1
    *    outcome field left over from before the mother actually delivered.
    capture drop FLAG_BDF_NO_ACS_DEL
    gen byte FLAG_BDF_NO_ACS_DEL = (FORM_BDF == 1 & ACS_OUTCOME_ADM1 != 2 & !missing(ACS_OUTCOME_ADM1)) if FORM_ACS1 == 1
    label variable FLAG_BDF_NO_ACS_DEL "BDF form exists but ACS outcome is not coded Delivered"

    tab FLAG_BDF_NO_ACS_DEL, missing
    tab ACS_OUTCOME_ADM1 if FLAG_BDF_NO_ACS_DEL == 1, missing
    tab DIST_NAME_ACS if FLAG_BDF_NO_ACS_DEL == 1, sort missing

    br PID DIST_NAME_ACS HOSPITAL_NAME_ACS RA_NAME_ACS YYYYMM_ACS ACS_OUTCOME_ADM1 ///
        if FLAG_BDF_NO_ACS_DEL == 1
restore

