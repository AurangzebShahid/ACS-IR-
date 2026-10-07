*
* * 
* * * 
* * * * 
* * * * * 
* * * * * *
* * * * * * * LONG FORMAT - KEY VARIABLES * * * * * * * * * * * * * * * * * * * * * * *

clear
use "Full_inteherated_database_analysis_PI.dta"
    
* Rename NFU variables to fit long format:
rename NFU_B1_VITAL_STATUS NFU_VITAL_STATUS1
rename NFU_B2_VITAL_STATUS NFU_VITAL_STATUS2
rename NFU_B3_VITAL_STATUS NFU_VITAL_STATUS3
rename NFU_B4_VITAL_STATUS NFU_VITAL_STATUS4
rename NFU_B5_VITAL_STATUS NFU_VITAL_STATUS5
rename NFU_B6_VITAL_STATUS NFU_VITAL_STATUS6

rename NFU_B1_DISCHARGED NFU_DISCHARGED1
rename NFU_B2_DISCHARGED NFU_DISCHARGED2
rename NFU_B3_DISCHARGED NFU_DISCHARGED3
rename NFU_B4_DISCHARGED NFU_DISCHARGED4
rename NFU_B5_DISCHARGED NFU_DISCHARGED5
rename NFU_B6_DISCHARGED NFU_DISCHARGED6

rename NFU_B1_DEATH_PLACE NFU_DEATH_PLACE1
rename NFU_B2_DEATH_PLACE NFU_DEATH_PLACE2
rename NFU_B3_DEATH_PLACE NFU_DEATH_PLACE3
rename NFU_B4_DEATH_PLACE NFU_DEATH_PLACE4
rename NFU_B5_DEATH_PLACE NFU_DEATH_PLACE5
rename NFU_B6_DEATH_PLACE NFU_DEATH_PLACE6

rename NFU_B1_DEATH_DATE NFU_DEATH_DATE1
rename NFU_B2_DEATH_DATE NFU_DEATH_DATE2
rename NFU_B3_DEATH_DATE NFU_DEATH_DATE3
rename NFU_B4_DEATH_DATE NFU_DEATH_DATE4
rename NFU_B5_DEATH_DATE NFU_DEATH_DATE5
rename NFU_B6_DEATH_DATE NFU_DEATH_DATE6

* Clean to fit variables
tostring BABY_ID4, replace format("%11.1f") force
tostring BABY_ID5, replace format("%11.1f") force
tostring BABY_ID6, replace format("%11.1f") force

* Reshape on baby variables. Generates variable BABY_NUM indicating each newborn as one line:
reshape long BABY_ID BDF_SEX BDF_BIRTH_WEIGHT BDF_BIRTH_STATUS ///
             NFU_VITAL_STATUS NFU_DISCHARGED NFU_DEATH_PLACE NFU_DEATH_DATE, ///
			 i(PID) j(BABY_NUM)

* Label long variables
label values NFU_VITAL_STATUS NFU_VITAL_STATUS
label values BDF_SEX SEX
label values NFU_DISCHARGED YESNONKNA
label values NFU_DEATH_PLACE NFU_DEATH_PLACE

* Drop non-babies 2-6 generated due to long format:
drop if FORM_BDF == 1 & BDF_BIRTH_STATUS == . & BDF_BIRTH_WEIGHT == .

* Drop babies without birth status (due to error in data collection)
drop if BDF_BIRTH_STATUS == 9

* Drop extra ACS/EHS/MIF generated due to long format (i.e., keep 1st instance a.k.a. BABY_NUM==1)
drop if FORM_BDF != 1 & FORM_ACS1 == 1 & BABY_NUM > 1
drop if FORM_BDF != 1 & FORM_EHS  == 1 & BABY_NUM > 1
drop if FORM_BDF != 1 & FORM_MFU1 == 1 & BABY_NUM > 1
drop if FORM_BDF != 1 & FORM_NFU  == 1 & BABY_NUM > 1

* Drop non-PID
drop if PID == ""

*
* *
* * * Gestation category based on corrected EUSG or, if EUSG missing, then birthweight

gen     GEST_CAT = .
replace GEST_CAT = 9 if FORM_BDF == 1
replace GEST_CAT = 1 if GA_BIRTH_CAT_COR == 1
replace GEST_CAT = 2 if GA_BIRTH_CAT_COR == 2
replace GEST_CAT = 3 if GA_BIRTH_CAT_COR == 3
replace GEST_CAT = 1 if GEST_CAT == 9 & BDF_BIRTH_WEIGHT  > 0    & BDF_BIRTH_WEIGHT < 1500
replace GEST_CAT = 2 if GEST_CAT == 9 & BDF_BIRTH_WEIGHT >= 1500 & BDF_BIRTH_WEIGHT < 2500
replace GEST_CAT = 3 if GEST_CAT == 9 & BDF_BIRTH_WEIGHT >= 2500 & BDF_BIRTH_WEIGHT < 7000

label define   GEST_CAT 1 "EPT" 2 "LPT" 3 "Term" 9 "NA: inviable GA / missing BW" 
label values   GEST_CAT GEST_CAT
label variable GEST_CAT "Gestation age category at birth using earliest USG or weight"

*
* *
* * * EPT (2a)

gen     EPT = .
replace EPT = 1 if GEST_CAT == 1
replace EPT = 0 if GEST_CAT != 1 & GEST_CAT != .

label variable EPT "EPT, binary using corrected EUSG or BW"

*
* *
* * * EEPT
gen     GA_CAT_4 = .
replace GA_CAT_4 = 9 if FORM_BDF == 1
replace GA_CAT_4 = 1 if GA_BIRTH_COR_EUSG >= 26*7 & GA_BIRTH_COR_EUSG < 28*7
replace GA_CAT_4 = 2 if GA_BIRTH_COR_EUSG >= 28*7 & GA_BIRTH_COR_EUSG < 34*7
replace GA_CAT_4 = 3 if GA_BIRTH_COR_EUSG >= 34*7 & GA_BIRTH_COR_EUSG < 37*7
replace GA_CAT_4 = 4 if GA_BIRTH_COR_EUSG >= 37*7 & GA_BIRTH_COR_EUSG < 45*7
replace GA_CAT_4 = 9 if GA_BIRTH_COR_EUSG  < 26*7
replace GA_CAT_4 = 9 if GA_BIRTH_COR_EUSG >= 45*7 
replace GA_CAT_4 = 9 if GA_BIRTH_COR_EUSG == . 
replace GA_CAT_4 = 1 if GA_CAT_4 == 9 & BDF_BIRTH_WEIGHT  > 0    & BDF_BIRTH_WEIGHT < 1000
replace GA_CAT_4 = 2 if GA_CAT_4 == 9 & BDF_BIRTH_WEIGHT >= 1000 & BDF_BIRTH_WEIGHT < 1500
replace GA_CAT_4 = 3 if GA_CAT_4 == 9 & BDF_BIRTH_WEIGHT >= 1500 & BDF_BIRTH_WEIGHT < 2500
replace GA_CAT_4 = 4 if GA_CAT_4 == 9 & BDF_BIRTH_WEIGHT >= 2500 & BDF_BIRTH_WEIGHT < 7000
replace GA_CAT_4 = . if FORM_BDF != 1

label define   GA_CAT_4 1 "EEPT" 2 "EPT" 3 "LPT" 4 "TERM" 9 "NA: inviable GA / missing BW" 
label values   GA_CAT_4 GA_CAT_4 
label variable GA_CAT_4 "Gestation age category with EEPT at birth using earliest USG or weight"

*
* * 
* * * COVERAGE
* OUT OF All live births (BDF_BIRTH_STATUS) <34 weeks (by earliest USG corrected or birthweight; GEST_CAT) in the network of care (NOC).

*
* * Received ACS anywhere (ACS_ADMINISTRATION) and had earliest USG (GA_BIRTH_CAT_COR):

gen     COVERAGE = .
replace COVERAGE = 0 if FORM_BDF == 1 & BDF_BIRTH_STATUS == 1 & GEST_CAT == 1 
replace COVERAGE = 1 if FORM_BDF == 1 & BDF_BIRTH_STATUS == 1 & GEST_CAT == 1 & GA_BIRTH_CAT_COR == 1 & ACS_ADMINISTRATION == 1

label variable COVERAGE "ACS coverage in liveborn EPT"

label define COVERAGE 0 "No ACS" 1 "ACS"
label values COVERAGE COVERAGE

*
* * Received ACS anywhere and had earliest USG and delivered in IF (ACS_IF):

gen     SAFE_COVERAGE = .
replace SAFE_COVERAGE = 0 if FORM_BDF == 1 & BDF_BIRTH_STATUS == 1 & GEST_CAT == 1 
replace SAFE_COVERAGE = 1 if FORM_BDF == 1 & BDF_BIRTH_STATUS == 1 & GEST_CAT == 1 & GA_BIRTH_CAT_COR == 1 & ACS_ADMINISTRATION == 1 & ACS_IF == 1

label variable SAFE_COVERAGE "ACS coverage in liveborn EPT"

label define SAFE_COVERAGE 0 "No ACS" 1 "ACS"
label values SAFE_COVERAGE SAFE_COVERAGE

*
* * Received ACS anywhere and had earliest USG and delivered in IF and received ACS ≥6 hours before delivery (DAYS_ACS_TO_DEL):

gen     OPTIMAL_SAFE_COVERAGE = SAFE_COVERAGE
replace OPTIMAL_SAFE_COVERAGE = 2 if SAFE_COVERAGE == 1 & DAYS_ACS_TO_DEL >= 6/24 & DAYS_ACS_TO_DEL != .

label variable OPTIMAL_SAFE_COVERAGE "Optimal ACS coverage in liveborn EPT (≥6 hrs from Dose 1 to delivery)"

label define OPTIMAL_SAFE_COVERAGE 0 "No Safe ACS" 1 "Safe ACS (delivery <6 hrs)" 2 "Safe ACS (delivery ≥6 hrs)" 
label values OPTIMAL_SAFE_COVERAGE OPTIMAL_SAFE_COVERAGE

*
* *
* * * SAFETY 1
*        All women who delivered in the NOC and received ACS in the NOC (FORM_ACS1) ≥34 weeks by earliest USG or without an earliest ultrasound (GA_ACS_CAT_COR).
* OUT OF All women who delivered in the NOC and received ACS in the NOC (FORM_ACS1). 

gen     SAFETY1 = .
replace SAFETY1 = 1 if FORM_BDF == 1 & BABY_NUM == 1 & ACS_ADMINISTRATION == 1 & FORM_ACS1 == 1
replace SAFETY1 = 0 if FORM_BDF == 1 & BABY_NUM == 1 & ACS_ADMINISTRATION == 1 & FORM_ACS1 == 1 & GA_ACS_CAT_COR == 1

label variable SAFETY1 "Safety 1: at time of ACS administration"

label define SAFETY1 0 "Safe ACS" 1 "Unsafe ACS"
label values SAFETY1 SAFETY1

*
* *
* * * SAFETY 2
*        All women who received ACS <34 weeks by earliest USG in the NOC and delivered in the NOC with earliest USG available and delivered ≥37 weeks by earliest USG.
* OUT OF All women who received ACS <34 weeks by earliest USG in the NOC and delivered in the NOC with earliest USG available.  

gen     SAFETY2 = .
replace SAFETY2 = 0 if FORM_BDF == 1 & BABY_NUM == 1 & ACS_ADMINISTRATION == 1 & FORM_ACS1 == 1 & GA_ACS_CAT_COR == 1 & (GA_BIRTH_CAT_COR == 1 | GA_BIRTH_CAT_COR == 2)
replace SAFETY2 = 1 if FORM_BDF == 1 & BABY_NUM == 1 & ACS_ADMINISTRATION == 1 & FORM_ACS1 == 1 & GA_ACS_CAT_COR == 1 &  GA_BIRTH_CAT_COR == 3

label variable SAFETY2 "Safety 2: at time of birth"

label define SAFETY2 0 "Safe ACS" 1 "Unsafe ACS"
label values SAFETY2 SAFETY2

*
* *
* * * MORTALITY

* Age at NFU
gen AGE_NFU = NFU_DT_FILL - BDF_DT_DELIVERY
label variable AGE_NFU "Age at NFU, days"

* Age (days) at death
gen AGE_DEATH = NFU_DEATH_DATE - BDF_DT_DELIVERY
label variable AGE_DEATH "Age at death, days"

* Neonatal mortality:
gen     NNM_STATUS_AT_28 = ""
replace NNM_STATUS_AT_28 = "Alive at 28 days" if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   >= 28 & NFU_VITAL_STATUS == 1 & AGE_NFU != .
replace NNM_STATUS_AT_28 = "Alive at 28 days" if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH >= 29 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace NNM_STATUS_AT_28 = "Dead at 28 days"  if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH <= 28 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace NNM_STATUS_AT_28 = "Dead at 28 days"  if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   <= 29 & NFU_VITAL_STATUS == 2 & AGE_NFU != .
replace NNM_STATUS_AT_28 = "Lost at the Follou-up"  if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & NFU_INTERVIEW_DONE==2 & AGE_NFU != .
label variable NNM_STATUS_AT_28 "Neonatal mortality: Liveborn, verified status at 28 days"

* Perinatal mortality:
gen     PNM_STATUS_AT_7 = ""
replace PNM_STATUS_AT_7 = "Alive 7d"   if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   >= 7 & NFU_VITAL_STATUS == 1 & AGE_NFU != .
replace PNM_STATUS_AT_7 = "Alive 7d"   if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH  > 7 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace PNM_STATUS_AT_7 = "Died 0-7d"  if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH <= 7 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace PNM_STATUS_AT_7 = "Stillborn"  if BDF_BIRTH_STATUS == 2
label variable PNM_STATUS_AT_7 "Perinatal mortality: Verified status at 7 days"

gen     ANY_BABY_DEATH = ""
replace ANY_BABY_DEATH = "Alive at birth"   if BDF_BIRTH_STATUS == 1
replace ANY_BABY_DEATH = "Stillborn"        if BDF_BIRTH_STATUS == 2
replace ANY_BABY_DEATH = "Alive at 28 days" if NNM_STATUS_AT_28 == "Alive at 28 days"
replace ANY_BABY_DEATH = "Dead at 28 days"  if NNM_STATUS_AT_28 == "Dead at 28 days"
replace ANY_BABY_DEATH = "Dead at 28 days"  if PNM_STATUS_AT_7  == "Died 0-7d"
label variable ANY_BABY_DEATH "Any mortality: Status at birth or 28 days"


*
* * * TOCOLYTICS ADMINISTRATION
gen TOCOLYTICS_ADMINISTRATION = .

replace TOCOLYTICS_ADMINISTRATION = 0 if ACS_ADMINISTRATION==1 
replace TOCOLYTICS_ADMINISTRATION = 1 if ACS_ADMINISTRATION==1  & (ACS_TOCOLYTICS1==1 | ACS_TOCOLYTICS2==1 | EHS_TOCOLYTICS==1)
label define TOCOLABEL 1 "ACS & Tocolytics" 0 "ACS but No Tocolytics"
label values TOCOLYTICS_ADMINISTRATION TOCOLABEL 


* TOCOLYTICS ADMINISTRATION FOR THE EPTs
gen TOCOLYTICS_USE_EPT = ""

replace TOCOLYTICS_USE_EPT = "No ACS"                if ACS_ADMINISTRATION != 1 & EPT == 1  
replace TOCOLYTICS_USE_EPT = "ACS but No Tocolytics" if TOCOLYTICS_ADMINISTRATION == 0 & EPT == 1 
replace TOCOLYTICS_USE_EPT = "ACS & Tocolytics"      if TOCOLYTICS_ADMINISTRATION == 1 & EPT == 1 


*
* *
* * *
*ADMISSION TO DELIVERY LESS THAN 6 HOURS IN ACS IMPLEMENTING FACILITY

gen     ACS_FAC_LES_6_ADM_DEL_EPT = .
replace ACS_FAC_LES_6_ADM_DEL_EPT = 0 if EPT==1 & FORM_BDF==1 & HOSPNUM_BDF==1
replace ACS_FAC_LES_6_ADM_DEL_EPT = 1 if DAYS_ADM_TO_DEL < 0.25 & EPT==1 & FORM_BDF==1 & HOSPNUM_BDF==1

label define ADMCAT 0 "" 1 "<6 Hours"
label values ACS_FAC_LES_6_ADM_DEL_EPT ADMCAT
label variable ACS_FAC_LES_6_ADM_DEL_EPT "ACS facility <6 hours from admission. Identified as EPT"

* ADMISSION TO DELIVERY GREATER THAN 6 HOURS IN ACS IMPLEMENTING FACILITY
gen     ACS_FAC_GRET_6_ADM_DEL_EPT = .
replace ACS_FAC_GRET_6_ADM_DEL_EPT = 0 if EPT==1 & FORM_BDF==1 & HOSPNUM_BDF==1
replace ACS_FAC_GRET_6_ADM_DEL_EPT = 1 if DAYS_ADM_TO_DEL >= 0.25 & EPT==1 & FORM_BDF==1 & HOSPNUM_BDF==1

label define ADMCATL 0 "" 1 ">6 Hours"
label values ACS_FAC_GRET_6_ADM_DEL_EPT ADMCATL
label variable ACS_FAC_GRET_6_ADM_DEL_EPT "ACS facility >6 hours from admission. Identified as EPT"


*
* *
* * *
*  ADMISSION TO DELIVERY LESS THAN 2 HOURS IN PERIPHERAL FACILITY 
gen     PRF_FAC_LES_2_ADM_DEL_EPT  = .
replace PRF_FAC_LES_2_ADM_DEL_EPT  = 0 if EPT==1 & FORM_BDF==1 & HOSPNUM_BDF!=1
replace PRF_FAC_LES_2_ADM_DEL_EPT  = 1 if DAYS_ADM_TO_DEL < 0.0833333 & EPT==1 & FORM_BDF==1 & HOSPNUM_BDF!=1

label define PRFADMCAT 0 "" 1 "<2 Hours"
label values PRF_FAC_LES_2_ADM_DEL_EPT PRFADMCAT
label variable PRF_FAC_LES_2_ADM_DEL_EPT "Peripheral facility <2 hours from admission. Identified as EPT"


*  ADMISSION TO DELIVERY LESS THAN 2 HOURS IN PERIPHERAL FACILITY 
gen     PRF_FAC_GRET_2_ADM_DEL_EPT  = .
replace PRF_FAC_GRET_2_ADM_DEL_EPT  = 0 if EPT==1 & FORM_BDF==1 & HOSPNUM_BDF!=1
replace PRF_FAC_GRET_2_ADM_DEL_EPT  = 1 if DAYS_ADM_TO_DEL >= 0.0833333 & EPT==1 & FORM_BDF==1 & HOSPNUM_BDF!=1

label define PRFADMCATL 0 "" 1 ">2 Hours"
label values   PRF_FAC_GRET_2_ADM_DEL_EPT PRFADMCATL
label variable PRF_FAC_GRET_2_ADM_DEL_EPT "Peripheral facility >2 hours from admission. Identified as EPT"



*
* *
* * * EXCLUSION CRITERIA

* 1) Births less than 26 weeks gestation by the earliest ultrasound are excluded. 
* 2) Births less than 500 grams are excluded. This weight cut point is only used for babies without information from the earliest ultrasound available. 
* 3) Women who delivered at a facility outside the network of care are excluded from the main indicators. 

gen     EXCLUDE = 0
replace EXCLUDE = 1 if GA_BIRTH_COR_EUSG < 26*7 & GA_BIRTH_COR_EUSG != .
replace EXCLUDE = 2 if BDF_BIRTH_WEIGHT < 500 & BDF_BIRTH_WEIGHT != . & GA_BIRTH_COR_EUSG == .
replace EXCLUDE = 3 if FORM_BDF != 1

label variable EXCLUDE "Exclusion criteria"

label define EXCLUDE 0 "Valid, keep" 1 "Invalid GA (<26 EUSG), drop" 2 "Invalid weight (<500) without EUSG, drop" 3 "Invalid place of birth (no BDF), drop"
label values EXCLUDE EXCLUDE

* FOR ANALYSIS:
 *keep if EXCLUDE == 0
 *saveold "Full_database_analysis_Phase I_EXCLUDED_LONG.dta", replace version(13)


* DROP THOSE TO BE EXCLUDED:
keep if EXCLUDE == 0

*
* *
* * *

saveold "Full_database_analysis_Phase I_LONG.dta", replace version(13)

export excel     using "Full_database_analysis_Phase I_LONG.xlsx", firstrow(variables) nolabel replace
* export delimited using "Full_database_analysis_ALL_COUNTRIES_LONG.csv", replace 

*end
