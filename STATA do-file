*************************************
** ACS-IR Phase 2: Data compilation **
*************************************

* Stata version:  17.0 
* Legacy editors:  Nicole MINCKAS, Juha PYYKKO, Kayleigh RYAN (WHO Geneva)
* Latest editor :  Aurangzeb
* Desigination  :  Data Associate (PHC Global Pakistan)
* Code version  :  2025-09-11 (Combine P2A and P2B)

/* Edits since 2025-09-11
- In ACS form drop DT_DUE
- In ACS reshape add: Transfer_ACS App_Version_ACS
- Add AGE_DEATH_28_W_SB
- Relabel NFU_INFORMANT, NFU_TYPE_INTERVIEW, BDF_MODE_DELIVERY, ACS_OUTCOME_ADM with 9 "NA"
- Add  YYYYMM_ACS
- Adding NFU_KM and NFU_BREASTFED
- Previoulsy on those with BDf were kept, now with ACS or MNFU only. Removed from the section "Missing BDF": drop if HOSPNUM == .
- Do not recode 8888/9999 birth weight on import
- Add FW_NUM_BDF and FW_NUM_ACS
- On Mortality: added "replace AGE_DEATH = 0 if BDF_LEFT_STATUS  == 3", edited ANY_BABY_DEATH
- Corrected: gen HOSPITAL = 10000 * COUNTRY_NUM + 100 * CLUST_NUM + HOSPNUM_BDF
- label variable BABY_NUM "Birth order"
- added to reshape: NFU_KMC NFU_KMC_FAC NFU_BREASTFED NFU_BREASTFED_FAC
- remove GEST_CAT_old
- added: * Drop extra ACS generated due to long format (i.e., keep 1st instance a.k.a. BABY_NUM==1)
- reshape in ACS import to include FW_NUM_ACS
- merge CLUST_NAME_ACS
- In terms of facility: NOC -> Peripheral
- Removing the section where PIDs were dropped if P2B born on August or P2A born on September
- Drop facilities not included in the P2B
*/

* Local environment 
clear 
cd "E:\ACSIR Data Management\Phase 2\WHO Monitoring"

*
**
***
**** Importing BDF form: 
import excel "Outcome_Data_PK.xlsx", firstrow sheet("BDF") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	keep if BDF_CONSENT == 1
	
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM CLUST_NUM PID BDF_DATE
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_BDF = cond(_N==1,1,_n)
	 log using dup_BDF.log, replace
	 tab FORM_NUM_BDF
	 list PID if FORM_NUM_BDF > 1
     log close
	keep if FORM_NUM_BDF==1
	drop FORM_NUM_BDF

   
** FORM DETAILS **
	gen FORM_BDF = 1
	gen APP = "P2A"
	rename HOSPNUM HOSPNUM_BDF
	rename FW_NUM  FW_NUM_BDF
	rename TAB_CODE TAB_CODE_BDF
	rename DT_SUBMIT Submit_BDF
	rename DT_TRANSFER Transfer_BDF
	rename App_Version App_Version_BDF
	format  Submit_BDF %tC
	format  Transfer_BDF %tC
	format BDF_DATE BDF_DT_ADM BDF_DT_EARLY_USG BDF_DT_LMP BDF_DT_DELIVERY %td
	order COUNTRY_NUM CLUST_NUM CLUST_NUM
	saveold "BDF.dta", replace version(13)
	

**** Importing NFU-Hospitalization form 
	import excel "Outcome_Data_PK.xlsx", firstrow sheet("NFU-Hospitalization") clear
	destring *, ignore("NULL") replace
	drop App_Version USER_CODE STATUS DT_SUBMIT
** RESHAPE
	gen BABY_NO = substr(BABY_ID, 13,13)
	destring BABY_NO, replace
	* Paste facility name
	gen COUNTRY_NUM = substr(PID, 1, 1)
	gen CLUST_NUM = substr(PID, 2, 2)
	destring COUNTRY_NUM, replace
	destring CLUST_NUM, replace
	gen FAC_ID = COUNTRY_NUM * 1000 + CLUST_NUM * 100 + NFU_B1_SNCU_HOSP
	merge m:m FAC_ID using "Facility List Phase II.dta", nogen keepusing(HOSPITAL_NAME_BDF)
	drop if ADMIT_NO == .
	* Gen only one variable of hospital name
	gen     NFU_SNCU_HOSP_ADM = HOSPITAL_NAME_BDF
	tostring NFU_B1_SNCU_OTHER_NAME, replace
	replace NFU_SNCU_HOSP_ADM = NFU_B1_SNCU_OTHER_NAME if NFU_B1_SNCU_HOSP == 0
	drop NFU_B1_SNCU_HOSP NFU_B1_SNCU_OTHER_NAME HOSPITAL_NAME_BDF COUNTRY_NUM CLUST_NUM 
	rename FAC_ID NFU_SNCU_ID_ADM
	* 1st sort by admit
	sort       PID BABY_ID ADMIT_NO
	reshape wide NFU_SNCU_ID_ADM NFU_SNCU_HOSP_ADM, i(BABY_ID PID) j(ADMIT_NO)
	drop BABY_ID
    * 2nd sort by baby
	sort       PID BABY_NO
	* gen variables for max 5 admissions if not there
	capture generate NFU_SNCU_ID_ADM2 = .
	capture generate NFU_SNCU_HOSP_ADM2 = ""
	capture generate NFU_SNCU_ID_ADM3 = .
	capture generate NFU_SNCU_HOSP_ADM3 = ""
	capture generate NFU_SNCU_ID_ADM4 = .
	capture generate NFU_SNCU_HOSP_ADM4 = ""
	capture generate NFU_SNCU_ID_ADM5 = .
	capture generate NFU_SNCU_HOSP_ADM5 = ""
	rename NFU_SNCU_HOSP_ADM1 NFU_SNCU_HOSP_ADM1_B
	rename NFU_SNCU_HOSP_ADM2 NFU_SNCU_HOSP_ADM2_B
	rename NFU_SNCU_HOSP_ADM3 NFU_SNCU_HOSP_ADM3_B
	rename NFU_SNCU_HOSP_ADM4 NFU_SNCU_HOSP_ADM4_B
	rename NFU_SNCU_HOSP_ADM5 NFU_SNCU_HOSP_ADM5_B
	rename NFU_SNCU_ID_ADM1 NFU_SNCU_ID_ADM1_B
	rename NFU_SNCU_ID_ADM2 NFU_SNCU_ID_ADM2_B
	rename NFU_SNCU_ID_ADM3 NFU_SNCU_ID_ADM3_B
	rename NFU_SNCU_ID_ADM4 NFU_SNCU_ID_ADM4_B
	rename NFU_SNCU_ID_ADM5 NFU_SNCU_ID_ADM5_B
	order PID BABY_NO
	reshape wide NFU_SNCU_ID_ADM1_B-NFU_SNCU_HOSP_ADM5_B, i(PID) j(BABY_NO)
** FORM DETAILS **
    gen FORM_NFU_HOSP = 1
	saveold "NFU_HOSP.dta", replace version(13)


**** Importing NFU form 
	import excel "Outcome_Data_PK.xlsx", firstrow sheet("NFU") clear
	destring *, ignore("NULL") replace
* LTFU with STATUS=0 before (glitch before August '25. Now corrected)
	drop if NFU_DT_FILL < date("01jan2020","DMY")
	drop if STATUS == 0 & NFU_INTERVIEW_DONE == 1
	drop if STATUS == 0 & NFU_INTERVIEW_DONE == .
*keep if STATUS == 1
	
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM CLUST_NUM PID NFU_DT_FILL
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_NFU = cond(_N==1,1,_n)
	 log using dup_NFU.log, replace
	 tab FORM_NUM_NFU
	 list PID if FORM_NUM_NFU > 1
     log close
	keep if FORM_NUM_NFU == 1
	drop FORM_NUM_NFU
** FORM DETAILS **
	gen    FORM_NFU = 1 // Form_Name
	rename FW_NUM 		FW_NUM_NFU
	rename TAB_CODE 	TAB_CODE_NFU
	rename USER_CODE 	USER_CODE_NFU  
	rename App_Version 	App_Version_NFU 
	rename HOSPNUM      HOSPNUM_NFU
	rename DT_SUBMIT    Submit_NFU
	format  Submit_NFU  %tC
	format  NFU_DT_FILL NFU_MOTHER_READMIT_DT NFU_B1_DEATH_DATE NFU_B2_DEATH_DATE NFU_B3_DEATH_DATE NFU_B4_DEATH_DATE NFU_B5_DEATH_DATE NFU_B6_DEATH_DATE %td
	drop STATUS
* MERGE HSOP
	merge 1:1 PID using "NFU_HOSP.dta"
	drop _merge
	order COUNTRY_NUM CLUST_NUM CLUST_NUM
	saveold "NFU.dta", replace version(13)


* COMBINED DATABASE
use "BDF.dta", clear
merge 1:1 PID using "NFU.dta",      gen(match_DAN)

* Convert string variables to numeric variables
  quietly destring *, ignore("NULL") replace

* Save raw data:
saveold "Full_database_PIIA_Integrated.dta", replace version(13)

*
* *
* * * P2B
clear 
cd "E:\ACSIR Data Management\Phase 2\WHO Monitoring"

*
**
***
**** Importing BDF form: 
import excel "Outcome_Data.xlsx", firstrow sheet("BDF") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	keep if BDF_CONSENT == 1
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM CLUST_NUM PID BDF_DATE
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_BDF = cond(_N==1,1,_n)
	 log using dup_BDF.log, replace
	 tab FORM_NUM_BDF
	 list PID if FORM_NUM_BDF > 1
     log close
	keep if FORM_NUM_BDF==1
	drop FORM_NUM_BDF

   
** FORM DETAILS **
	gen FORM_BDF = 1
	gen APP = "P2B"
	rename HOSPNUM 		HOSPNUM_BDF
	rename FW_NUM       FW_NUM_BDF
	rename TAB_CODE 	TAB_CODE_BDF
	rename DT_SUBMIT 	Submit_BDF
	rename DT_TRANSFER 	Transfer_BDF
	rename App_Version 	App_Version_BDF
	format  Submit_BDF 	%tC
	format  Transfer_BDF %tC
	format BDF_DATE BDF_DT_ADM BDF_DT_EARLY_USG BDF_DT_LMP BDF_DT_DELIVERY %td
	order COUNTRY_NUM CLUST_NUM CLUST_NUM
	saveold "BDF.dta", replace version(13)
	
**** Importing ACS form 
import excel "Outcome_Data.xlsx", firstrow sheet("ACS") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	drop USER_CODE STATUS DT_DUE
** REMOVE IF NO CONSENT **
	drop if ACS_CONSENT == 2
** FORM DETAILS **
	gen    FORM_ACS  =  1
	rename HOSPNUM   	HOSPNUM_ACS
	rename FW_NUM    	FW_NUM_ACS
	rename TAB_CODE  	TAB_CODE_ACS
	rename DT_SUBMIT 	Submit_ACS
	rename DT_TRANSFER 	Transfer_ACS
	rename App_Version 	App_Version_ACS
	format  Submit_ACS 	%tC
	format  Transfer_ACS %tC
	format  ACS_DATE ACS_DT_EARLY_USG ACS_DT_LMP ACS_DOSE1_DATE ACS_OUTCOME_DT %td
**RESHAPE TO WIDE**
	saveold "ACS.dta", replace version(13)
	sort       COUNTRY_NUM CLUST_NUM PID ACS_DOSE1_DATE // Sort by 1st dose order if two or more courses
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_ACS = cond(_N==1,1,_n)
	reshape wide ACS* FORM_ACS HOSPNUM_ACS FW_NUM_ACS FORM_NO TAB_CODE_ACS Submit_ACS Transfer_ACS App_Version_ACS, i(COUNTRY_NUM CLUST_NUM PID) j(FORM_NUM_ACS)
	* First ACS as main hospital
	gen HOSPNUM_ACS = HOSPNUM_ACS1
	gen APP = "P2B"
	saveold "ACS_WIDE.dta", replace version(13)

**** Importing NFU form 
	import excel "Outcome_Data.xlsx", firstrow sheet("NFU") clear
	destring *, ignore("NULL") replace
	
	** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM CLUST_NUM PID NFU_DT_FILL
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_NFU = cond(_N==1,1,_n)
	 log using dup_NFU.log, replace
	 tab FORM_NUM_NFU
	 list PID if FORM_NUM_NFU > 1
     log close
	keep if FORM_NUM_NFU == 1
	drop FORM_NUM_NFU
** FORM DETAILS **
	gen    FORM_NFU = 1
	rename HOSPNUM 	   HOSPNUM_NFU
	rename FW_NUM      FW_NUM_NFU
	rename TAB_CODE    TAB_CODE_NFU
	rename USER_CODE   USER_CODE_NFU 
	rename DT_SUBMIT   Submit_NFU
	rename DT_TRANSFER Transfer_NFU
	rename App_Version App_Version_NFU
	format  Submit_NFU 	%tC
	format  Transfer_NFU %tC
	format  NFU_DT_FILL NFU_MOTHER_READMIT_DT *_DATE %td
	gen APP = "P2B"
	order COUNTRY_NUM CLUST_NUM
	saveold "NFU.dta", replace version(13)

* COMBINED DATABASE
use "BDF.dta", clear
merge 1:1 PID using "ACS_WIDE.dta", gen(match_DA)
merge 1:1 PID using "NFU.dta",      gen(match_DAN)

* Convert string variables to numeric variables
  quietly destring *, ignore("NULL") replace
		
* Save raw data:
saveold "Full_database_PIIB_Integrated.dta", replace version(13)

*
* * 
* * * 
* * * * 
* * * * *
* * * * * * COMBINE Phase2A and Phase2B * * * * * * * * * * * * * * * * * * * 

clear 
cd "E:\ACSIR Data Management\Phase 2\WHO Monitoring"
use "Full_database_PIIA_Integrated.dta"
append using "Full_database_PIIB_Integrated.dta",force 

order APP

saveold "Full_database_Complete_Integrated.dta", replace version(13)

*
* * 
* * * 
* * * * 
* * * * *
* * * * * * EXPORTING FACILITY LIST INTO STATA FORMAT (.dta) * * * * * * * * * * * * * * * 
clear
import excel "FACILITY_LIST_P2.xlsx", firstrow 
saveold "Facility List Phase II.dta", replace version(13)

* * * * * * EXPORTING RA NAME LIST INTO STATA FORMAT (.dta) * * * * * * * * * * * * * * * 
clear
import excel "RA_LIST.xlsx", firstrow 
saveold "RA_LIST.dta", replace version(13)

*
* * 
* * * COMBINE MAIN DATASET WITH FACILITY LIST * * * * * * * * * * * * * * * 
clear
use   "Full_database_Complete_Integrated.dta"
* Merge facility list (Facility type and name)
merge n:1 COUNTRY_NUM CLUST_NUM HOSPNUM_BDF  using "Facility List Phase II.dta", ///
 nogen keepusing(FAC_BDF DIST_NAME HOSPITAL_NAME_BDF FAC_ID)

* Merge facility list (Facility type and name)
merge n:1 COUNTRY_NUM CLUST_NUM HOSPNUM_ACS  using "Facility List Phase II.dta", ///
 nogen keepusing(FAC_ACS DIST_NAME_ACS HOSPITAL_NAME_ACS )

*
* * 
* * * COMBINE MAIN DATASET WITH FACILITY LIST * * * * * * * * * * * * * * * 
* Merge facility list (Facility type and name)
merge n:1 CLUST_NUM TAB_CODE_BDF using "RA_LIST.dta", ///
 nogen keepusing(RA_NAME)

* Merge facility list (Facility type and name)
merge n:1 CLUST_NUM TAB_CODE_ACS1 using "RA_LIST.dta", ///
 nogen keepusing(RA_NAME_ACS)

*
* *
* * * Clean

* Drop no PID
drop if PID == ""

** RECODE BIRTWEIGHT **
  quietly recode BDF_BIRTH_WEIGHT1 BDF_BIRTH_WEIGHT2 BDF_BIRTH_WEIGHT3 BDF_BIRTH_WEIGHT4 BDF_BIRTH_WEIGHT5 BDF_BIRTH_WEIGHT6 (7777=.) (8888=.) (9999=.) // Converting missing weights to 0

** RECODING MISSING VALUES  
ds, has(type numeric)
quietly  recode `r(varlist)' (99 = .) (88 = .)


* Change NK/NA/missing dates (9.9.1909 etc.) to missing value (.)
foreach var of varlist *_DT_* *_DATE {
	replace `var'=. if `var' < mdy(1, 1, 2024)
}

* Summaey of the Numeric Variables 
ds, has(type numeric)
sum 

*
* *
* * *
* * * *
* * * * * Download/today date

gen TODAY = date(c(current_date), "DMY")
format TODAY %td
label variable TODAY "Date of data download/code run"
tab TODAY

* * Tabulation of observations by the Tablet phase. 
tab APP

*
* *
* * * VARIABLE CREATION

*
* *
* * *
* * * * Basic details:

gen HOSPNUM = HOSPNUM_BDF
	
* FACILITY CATEGORIZATION:	

gen            ACS_IF = .
replace        ACS_IF = 1 if FAC_BDF == "Core Facility"
replace        ACS_IF = 2 if FAC_BDF == "NOC Facility"
label define   ACS_IF  1 "Core Facility" 2 "NOC Facility"
label values   ACS_IF ACS_IF
label variable ACS_IF "Facility type BDF"

gen FAC = FAC_BDF

*
* *
* * * TIMELINE

* PERIOD DELIVERY: creating the month/year date
gen       YYYY =    year(BDF_DT_DELIVERY) 
gen         MM =   month(BDF_DT_DELIVERY)
gen     YYYYMM = ym(year(BDF_DT_DELIVERY), month(BDF_DT_DELIVERY))
format  YYYYMM %tm

* PERIOD DELIVERY: creating the month/year date
gen       YYYY_ACS =    year(ACS_DOSE1_DATE1) 
gen         MM_ACS =   month(ACS_DOSE1_DATE1)
gen     YYYYMM_ACS = ym(year(ACS_DOSE1_DATE1), month(ACS_DOSE1_DATE1))
format  YYYYMM_ACS %tm

* PERIOD DELIVERY: creating the month/year date
gen       YYYY_MNFU =    year(NFU_DT_FILL) 
gen         MM_MNFU =   month(NFU_DT_FILL)
gen     YYYYMM_MNFU = ym(year(NFU_DT_FILL), month(NFU_DT_FILL))
format  YYYYMM_MNFU %tm

* QUARTER BDF
gen     QUARTER = .
replace QUARTER = 1  if YYYY == 2025 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 2  if YYYY == 2025 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 3  if YYYY == 2025 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 4  if YYYY == 2025 & (MM == 10 | MM == 11 | MM == 12)
replace QUARTER = 5  if YYYY == 2026 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 6  if YYYY == 2026 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 7  if YYYY == 2026 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 8  if YYYY == 2026 & (MM == 10 | MM == 11 | MM == 12)
replace QUARTER = 9  if YYYY == 2027 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 10 if YYYY == 2027 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 11 if YYYY == 2027 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 12 if YYYY == 2027 & (MM == 10 | MM == 11 | MM == 12)
replace QUARTER = 13 if YYYY == 2028 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 14 if YYYY == 2028 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 15 if YYYY == 2028 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 16 if YYYY == 2028 & (MM == 10 | MM == 11 | MM == 12)


gen MONTH_BDF = ""
label define monthlbl 1 "January" 2 "February" 3 "March" 4 "April" 5 "May" 6 "June" ///
                      7 "July" 8 "August" 9 "September" 10 "October" 11 "November" 12 "December"
label values MM MM_ACS MM_MNFU monthlbl


*
* *
* * * TIMES

* Error handling, missing time, save original for reference:
gen BDF_TM_DELIVERY_HH_original = BDF_TM_DELIVERY_HH
gen BDF_TM_DELIVERY_MM_original = BDF_TM_DELIVERY_MM

gen BDF_TM_ADM_HH_original = BDF_TM_ADM_HH
gen BDF_TM_ADM_MM_original = BDF_TM_ADM_MM

gen ACS_DOSE1_HH1_original = ACS_DOSE1_HH1
gen ACS_DOSE1_MM1_original = ACS_DOSE1_MM1

** RECODE MISSING HH:MM: delivery to end of day
replace BDF_TM_DELIVERY_HH = 23 if BDF_DT_DELIVERY != . & (BDF_TM_DELIVERY_HH > 23 | BDF_TM_DELIVERY_HH == .)
replace BDF_TM_DELIVERY_MM = 59 if BDF_DT_DELIVERY != . & (BDF_TM_DELIVERY_MM > 59 | BDF_TM_DELIVERY_MM == .)

** RECODE MISSING HH:MM: admission to start of day
replace BDF_TM_ADM_HH = 0 if BDF_DT_DELIVERY != . & (BDF_TM_ADM_HH > 23 | BDF_TM_ADM_HH == .)
replace BDF_TM_ADM_MM = 0 if BDF_DT_DELIVERY != . & (BDF_TM_ADM_MM > 59 | BDF_TM_ADM_MM == .)

** RECODE MISSING HH:MM: administration to start of day
replace ACS_DOSE1_HH1 = 0 if ACS_DOSE1_DATE1 != . & (ACS_DOSE1_HH1 > 23 | ACS_DOSE1_MM1 == .)
replace ACS_DOSE1_MM1 = 0 if ACS_DOSE1_DATE1 != . & (ACS_DOSE1_MM1 > 59 | ACS_DOSE1_MM1 == .)

* Date + time:

** Delivery clock
gen double      DEL_TIME = hms(BDF_TM_DELIVERY_HH,BDF_TM_DELIVERY_MM,0)
format %tcHH:MM DEL_TIME
label variable  DEL_TIME "Delivery time"

** Delivery date+time	
gen double     DEL_DT = cofd(BDF_DT_DELIVERY) + DEL_TIME
format         DEL_DT %tcNN/DD/CCYY_HH:MM
label variable DEL_DT "Delivery date and time"

** Admission clock
gen double      ADM_TIME = hms(BDF_TM_ADM_HH,BDF_TM_ADM_MM,0)
format %tcHH:MM ADM_TIME
label variable  ADM_TIME "Delivery admission time"

** Admission date+time
gen double     ADM_DT = cofd(BDF_DT_ADM) + ADM_TIME
format         ADM_DT %tcNN/DD/CCYY_HH:MM
label variable ADM_DT "Delivery admission date and time"

** Administration (Course 1) clock
gen double     ACS_TIME = hms(ACS_DOSE1_HH1, ACS_DOSE1_MM1,0)
format %tcHH   ACS_TIME
label variable ACS_TIME "ACS Dose 1, Course 1, time"

** Administration (Course 1) date+time
gen double     ACS_DT = cofd(ACS_DOSE1_DATE1) + ACS_TIME
format         ACS_DT %tcNN/DD/CCYY_HH:MM
label variable ACS_DT "ACS Dose 1, Course 1, date and time"

gen ADM_SHIFT = .
replace ADM_SHIFT = 1 if inrange(BDF_TM_ADM_HH, 8, 13)     // 8:00 to 13:59
replace ADM_SHIFT = 2 if inrange(BDF_TM_ADM_HH, 14, 19)    // 14:00 to 19:59
replace ADM_SHIFT = 3 if BDF_TM_ADM_HH < 8 | BDF_TM_ADM_HH >= 20
label variable ADM_SHIFT "Admission Shift"
label define ADM_SHIFT_LABEL 1 "Morning" 2 "Evening" 3 "Night"
label values ADM_SHIFT ADM_SHIFT_LABEL 

*
* *
* * * * TIME DIFFERENCES

* Calculating time between admission and delivery (days+hours)
gen            DAYS_ADM_TO_DEL = (DEL_DT  - ADM_DT)/ 864e5 
label variable DAYS_ADM_TO_DEL "Days from admission to delivery (including hours and minutes)"

* Calculating time between ACS administration and delivery
gen            DAYS_ACS_TO_DEL = (DEL_DT  - ACS_DT)/ 864e5 
label variable DAYS_ACS_TO_DEL "Days from Dose 1 to delivery (including hours and minutes)"


* Days from admission to delivery
gen            DAYS_FROM_ADM_TO_DEL = BDF_DT_DELIVERY - BDF_DT_ADM if FORM_BDF == 1
label variable DAYS_FROM_ADM_TO_DEL "Days from admission to delivery"

* Days from ACS Dose1 to delivery
gen DAYS_FROM_DOSE1_TO_DEL = (DEL_DT - ACS_DT) / (1000*60*60*24) if FORM_BDF == 1 & FORM_ACS1 == 1
label variable DAYS_FROM_DOSE1_TO_DEL "Days from ACS Dose1 to Delivery"

* DELIVERY DHIFTS 
gen DEL_SHIFT = .
replace DEL_SHIFT = 1 if inrange(BDF_TM_DELIVERY_HH, 8, 13)     // 8:00 to 13:59
replace DEL_SHIFT = 2 if inrange(BDF_TM_DELIVERY_HH, 14, 19)    // 14:00 to 19:59
replace DEL_SHIFT = 3 if BDF_TM_DELIVERY_HH < 8 | BDF_TM_DELIVERY_HH >= 20

label variable ADM_SHIFT "Delivery Shift"
label values DEL_SHIFT ADM_SHIFT_LABEL 


*-----------------------------------------------------------
* * * Gestational Age Calculation by Provider Assessment
*-----------------------------------------------------------

// Provider assessment in days (BDF)

gen     GA_BIRTH = BDF_GA_WEEKS * 7       if BDF_GA_WEEKS < 80 & FORM_BDF==1
replace GA_BIRTH = GA_BIRTH + BDF_GA_DAYS if BDF_GA_DAYS  < 8  & FORM_BDF==1
label variable GA_BIRTH "Gestational age in days at birth using provider estimate"


// Provider assessment in categories (BDF)
gen     GA_BIRTH_CAT = . if FORM_BDF != 1
replace GA_BIRTH_CAT = 1 if GA_BIRTH >= 28*7 & GA_BIRTH < 34*7  // 34*7 = 238
replace GA_BIRTH_CAT = 2 if GA_BIRTH >= 34*7 & GA_BIRTH < 37*7  // 37*7 = 259
replace GA_BIRTH_CAT = 3 if GA_BIRTH >= 37*7 & GA_BIRTH < 45*7  // 45*7 = 315
replace GA_BIRTH_CAT = 9 if GA_BIRTH >= 45*7 & FORM_BDF == 1
replace GA_BIRTH_CAT = 9 if GA_BIRTH <  28*7 & FORM_BDF == 1                  // 28*7 = 182
label variable GA_BIRTH_CAT "Gestational age category at birth from provider BDF"
label define GA_BIRTH_CAT 1 "<34 weeks" 2 "34-<37 weeks" 3 ">37 weeks" 9 "No Provider estimate", replace
label values GA_BIRTH_CAT GA_BIRTH_CAT


*
* * ACS
// Provider assessment in days (ACS)
gen     GA_ACS_DAY = ACS_GA_ADM_WEEKS1 * 7         if ACS_GA_ADM_WEEKS1 < 80
replace GA_ACS_DAY = GA_ACS_DAY + ACS_GA_ADM_DAYS1 if ACS_GA_ADM_DAYS1  < 8
label variable GA_ACS_DAY "Gestational age in days at dose1 course1, provider"

gen     GA_ACS_CAT = .
replace GA_ACS_CAT = 1 if GA_ACS_DAY >= 24*7 & GA_ACS_DAY < 34*7
replace GA_ACS_CAT = 2 if GA_ACS_DAY >= 34*7 & GA_ACS_DAY < 37*7
replace GA_ACS_CAT = 3 if GA_ACS_DAY >= 37*7 & GA_ACS_DAY < 45*7
replace GA_ACS_CAT = 9 if GA_ACS_DAY >= 45*7
replace GA_ACS_CAT = 9 if GA_ACS_DAY  < 24*7
replace GA_ACS_CAT = 9 if GA_ACS_DAY == .
replace GA_ACS_CAT = . if FORM_ACS1 != 1
label variable GA_ACS_CAT "Gestational age (HCW) at dose 1, course 1"
label define GA_ACS_CAT 1 "<34 weeks" 2 "34-<37 weeks" 3 ">37 weeks" 9 "No Provider estimate"
label values GA_ACS_CAT GA_ACS_CAT

*----------------------------------------------*
*               GA by Early USG
* ---------------------------------------------*
*
* *
* * * EUSG available

gen     EUSG_BDF_AVAIL = .
replace EUSG_BDF_AVAIL = 0 if FORM_BDF == 1
replace EUSG_BDF_AVAIL = 1 if FORM_BDF == 1 &  BDF_DT_EARLY_USG != . & BDF_DT_EARLY_USG!=.
label define USG_AVL_BDF 0 "No BDF USG" 1 "BDF USG"
label values EUSG_BDF_AVAIL USG_AVL_BDF


gen     EUSG_ACS_AVAIL = .
replace EUSG_ACS_AVAIL = 0 if FORM_ACS1 == 1
replace EUSG_ACS_AVAIL = 1 if FORM_ACS1 == 1 &  ACS_DT_EARLY_USG1 != . & ACS_GA_EARLYUSG_WKS1!=.
label define USG_AVL_ACS 0 "No ACS USG" 1 "ACS USG"
label values EUSG_ACS_AVAIL USG_AVL_ACS

gen     EUSG_AVAIL = 0
replace EUSG_AVAIL = 1 if EUSG_BDF_AVAIL == 1
replace EUSG_AVAIL = 1 if EUSG_ACS_AVAIL == 1
label define USG_AVL 1 "USG available" 0 "No USG available"
label values EUSG_AVAIL USG_AVL


*
* * BDF

// Earliest USG in days (BDF)

gen     EARLYUSG_BDF_DAYS = BDF_GA_EARLYUSG_WKS * 7                  if BDF_GA_EARLYUSG_WKS < 60 & BDF_DT_EARLY_USG != .
replace EARLYUSG_BDF_DAYS = EARLYUSG_BDF_DAYS + BDF_GA_EARLYUSG_DAYS if BDF_GA_EARLYUSG_DAYS < 8 & BDF_DT_EARLY_USG != .
label variable EARLYUSG_BDF_DAYS "Gestational age in days at earliest USG (BDF)"

gen     EARLYUSG_ACS_DAYS = ACS_GA_EARLYUSG_WKS1 * 7                  if ACS_GA_EARLYUSG_WKS1 < 60 & ACS_DT_EARLY_USG1!=.
replace EARLYUSG_ACS_DAYS = EARLYUSG_ACS_DAYS + ACS_GA_EARLYUSG_DAYS1 if ACS_GA_EARLYUSG_DAYS1 < 8 & ACS_DT_EARLY_USG1!=.
label variable EARLYUSG_ACS_DAYS "Gestational age in days at earliest USG ACS course 1"

gen USG_DEL = BDF_DT_DELIVERY - BDF_DT_EARLY_USG  if EUSG_BDF_AVAIL == 1 // Days from Delivery to earliest USG
gen USG_ACS = ACS_DOSE1_DATE1 - ACS_DT_EARLY_USG1 if EUSG_ACS_AVAIL == 1 // Days fro ACS dose to earliest USG

gen GA_BIRTH_EUSG = USG_DEL + EARLYUSG_BDF_DAYS   if FORM_BDF==1 & BDF_DT_DELIVERY != . & BDF_DT_EARLY_USG != . & EARLYUSG_BDF_DAYS  != .
label variable GA_BIRTH_EUSG "Gestational age in days at birth using the earliest USG"

gen GA_ACS_EUSG = USG_ACS + EARLYUSG_ACS_DAYS     if FORM_ACS1==1 & ACS_DT_EARLY_USG1 != . & ACS_DOSE1_DATE1 != . & EARLYUSG_ACS_DAYS  != .
label variable GA_ACS_EUSG "Gestational age in days at ACS dose 1 using the earliest USG"




*
* * Gestation age calculation for the BDF based on EUSG available in ACS

gen ACS_DEL_EUSG = BDF_DT_DELIVERY - ACS_DOSE1_DATE1 if ACS_DOSE1_DATE1!=. // Days from Delivery to ACS dose date

gen GA_AB_EUSG = ACS_DEL_EUSG + GA_ACS_EUSG if ACS_DEL_EUSG !=. & GA_ACS_EUSG!=.
label variable GA_AB_EUSG "Gestational age in days at birth using the earliest USG from ACS course 1"

// Invalid Ultrasound records 
gen     INVALID_BDF_USG = 0 	if GA_BIRTH_EUSG <  7*24 & EUSG_BDF_AVAIL == 1
replace INVALID_BDF_USG = 1 	if GA_BIRTH_EUSG >= 7*45 & EUSG_BDF_AVAIL == 1
label define INVALID_BDF_USG 0 "<168 days by EUSG" 1 ">=315 day by EUSG"
label values INVALID_BDF_USG INVALID_BDF_USG

gen 	INVALID_ACS_USG = 0 	if GA_AB_EUSG <  7*24 & EUSG_ACS_AVAIL == 1
replace INVALID_ACS_USG = 1 	if GA_AB_EUSG >= 7*45 & EUSG_ACS_AVAIL == 1
label define INVALID_ACS_USG 0 "<168 days by EUSG" 1 ">=315 day by EUSG"
label values INVALID_ACS_USG INVALID_ACS_USG

//Replacing impossible values as missing
replace GA_BIRTH_EUSG = . 		if GA_BIRTH_EUSG <  7*24
replace GA_BIRTH_EUSG = . 		if GA_BIRTH_EUSG >= 7*45 
replace GA_BIRTH_EUSG = . 		if USG_DEL       <  0
replace GA_ACS_EUSG=. 			if GA_AB_EUSG    <  7*24
replace GA_ACS_EUSG=. 			if GA_AB_EUSG    >= 7*45
replace GA_ACS_EUSG=. 			if USG_ACS 		 <   0
replace USG_DEL=. 				if USG_DEL       <   0
replace USG_ACS=. 				if USG_ACS       <   0



*
* * GA Categorization based on EUSG in BDF and ACS
gen 	GA_BIRTH_CATU = .
replace GA_BIRTH_CATU = 1 if GA_BIRTH_EUSG <  7*34 
replace GA_BIRTH_CATU = 2 if GA_BIRTH_EUSG >= 7*34 & GA_BIRTH_EUSG < 7*37
replace GA_BIRTH_CATU = 3 if GA_BIRTH_EUSG >= 7*37 
replace GA_BIRTH_CATU = 9 if GA_BIRTH_EUSG == .    & FORM_BDF ==1
label variable GA_BIRTH_CATU "Gestational age at Birth from earliest USG"
label define GA_BIRTH_CAT_EUSG 1 "<34 Weeks" 2 "34-37 Weeks" 3 ">37 Weeks" 9 "No USG"
label values GA_BIRTH_CATU GA_BIRTH_CAT_EUSG

gen     GA_ACS_CATU = .	if FORM_ACS1 == .
replace GA_ACS_CATU = 1 if GA_ACS_EUSG <  7*34 & FORM_ACS1==1
replace GA_ACS_CATU = 2 if GA_ACS_EUSG >= 7*34 & GA_ACS_EUSG < 7*37 & FORM_ACS1==1
replace GA_ACS_CATU = 3 if GA_ACS_EUSG >= 7*37 & FORM_ACS1==1
replace GA_ACS_CATU = 9 if GA_ACS_EUSG==.      & FORM_ACS1==1
label variable GA_ACS_CATU "Gestational age at ACS from earliest USG"
label define GA_ACS_CAT_EUSG 1 "<34 Weeks" 2 "34-37 Weeks" 3 ">37 Weeks" 9 "No USG"
label values GA_ACS_CATU GA_ACS_CAT_EUSG

*
* *
* * * EARLIEST USG BEFORE 24 WEEKS (WHO preference over trimesters)

gen     EARLYUSG_BDF_24 = .
replace EARLYUSG_BDF_24 = 1 if EARLYUSG_BDF_DAYS   < 24*7
replace EARLYUSG_BDF_24 = 2 if EARLYUSG_BDF_DAYS  >= 24*7
replace EARLYUSG_BDF_24 = 9 if EUSG_BDF_AVAIL        == 0	  & FORM_BDF == 1
label variable EARLYUSG_BDF_24 "Timing of Earliest USG in BDF (24 weeks)"

gen     EARLYUSG_ACS_24 = .
replace EARLYUSG_ACS_24 = 1 if EARLYUSG_ACS_DAYS   < 24*7
replace EARLYUSG_ACS_24 = 2 if EARLYUSG_ACS_DAYS  >= 24*7
replace EARLYUSG_ACS_24 = 9 if EUSG_ACS_AVAIL     ==. & FORM_ACS1 == 1
label variable EARLYUSG_ACS_24 "Timing of Earliest USG in ACS (24 weeks)"

label define USG24 1 "USG <24 weeks" 2 "USG ≥24 weeks" 9 "No USG"
label values EARLYUSG_BDF_24 EARLYUSG_ACS_24 USG24


*
* *
* * * Number of livebirths
gen     NUM_LIVEBIRTH = 0 if FORM_BDF == 1
replace NUM_LIVEBIRTH = 1                 if BDF_BIRTH_STATUS1 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS2 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS3 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS4 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS5 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS6 == 1

gen     NUM_LEFT_ALIVE = 0 if FORM_BDF == 1
replace NUM_LEFT_ALIVE = 1                  if BDF_BIRTH_STATUS1 == 1 & BDF_LEFT_STATUS1 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS2 == 1 & BDF_LEFT_STATUS2 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS3 == 1 & BDF_LEFT_STATUS3 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS4 == 1 & BDF_LEFT_STATUS4 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS5 == 1 & BDF_LEFT_STATUS5 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS6 == 1 & BDF_LEFT_STATUS6 != 3

*
* *
* * *
* * * *
* * * * * NFU

gen     NEEDS_NFU = 0
replace NEEDS_NFU = 1 if BDF_MNFU_CONSENT == 1 & NUM_LEFT_ALIVE >= 1

gen AGE_NFU = NFU_DT_FILL - BDF_DT_DELIVERY
label variable AGE_NFU "Age at NFU, days"


gen DEL_NOW_DATE = today() - BDF_DT_DELIVERY
label variable DEL_NOW_DATE "Age of baby, days"

gen     AGE_READMISSION_MOTHER = .
replace AGE_READMISSION_MOTHER = NFU_MOTHER_READMIT_DT - BDF_DT_DELIVERY 

*
* *
* * * ANC VISITS (v2.2) - convert older entries to new categories:

replace BDF_NUM_ANT_VISITS_CAT = 0 if BDF_NUM_ANT_VISITS_CAT == . & BDF_NUM_ANT_VISITS == 0
replace BDF_NUM_ANT_VISITS_CAT = 1 if BDF_NUM_ANT_VISITS_CAT == . & BDF_NUM_ANT_VISITS >= 1 & BDF_NUM_ANT_VISITS <=3
replace BDF_NUM_ANT_VISITS_CAT = 2 if BDF_NUM_ANT_VISITS_CAT == . & BDF_NUM_ANT_VISITS >= 4 & BDF_NUM_ANT_VISITS <=7
replace BDF_NUM_ANT_VISITS_CAT = 3 if BDF_NUM_ANT_VISITS_CAT == . & BDF_NUM_ANT_VISITS >= 8 & BDF_NUM_ANT_VISITS < 88
replace BDF_NUM_ANT_VISITS_CAT = 8 if BDF_NUM_ANT_VISITS_CAT == . & BDF_NUM_ANT_VISITS >= 88 & BDF_NUM_ANT_VISITS <= 99
label define BDF_NUM_ANT_VISITS_CAT1 0 "Woman has no ANC visits" 1 "1–3 visits" 2 "4–7 visits" 3 "8+ visits" 8 "Missing"
label values BDF_NUM_ANT_VISITS_CAT BDF_NUM_ANT_VISITS_CAT1

*
* *
* * *

* LABELS:
label define YESNONKNA   1 "Yes" 2 "No" 8 "NK" 9 "NA"

label values BDF_CONSENT         YESNONKNA
label values BDF_ACS_RECEIVED    YESNONKNA
label values BDF_ACUTE_BACT_INF  YESNONKNA
label values BDF_RESUSCITATION1  YESNONKNA
label values BDF_RESUSCITATION2  YESNONKNA
label values BDF_RESUSCITATION3  YESNONKNA
label values BDF_RESUSCITATION4  YESNONKNA
label values BDF_RESUSCITATION5  YESNONKNA
label values BDF_RESUSCITATION6  YESNONKNA
label values BDF_MNFU_CONSENT    YESNONKNA

label define BDF_BIRTH_STATUS 1 "Liveborn" 2 "Stillborn" 8 "NK" 9 "NA"
label values BDF_BIRTH_STATUS1 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS2 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS3 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS4 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS5 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS6 BDF_BIRTH_STATUS

label define BDF_MODE_DELIVERY 1 "Vaginal" 2 "C-section (unspecified)" 3 "Emergency C-section" 4 "Planned C-section" 8 "NK"
label values BDF_MODE_DELIVERY1 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY2 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY3 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY4 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY5 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY6 BDF_MODE_DELIVERY

label define BDF_ANC_PATIENT_STATUS 1 "Booked" 2 "Un-booked" 8 "NK" 9 "NA"
label values BDF_ANC_PATIENT_STATUS BDF_ANC_PATIENT_STATUS

label define BDF_PLACE_ACS 1 "Current facility" 2 "Other in NOC" 3 "Other outside NOC" 8 "NK" 9 "NA"
label values BDF_PLACE_ACS BDF_PLACE_ACS

label define BDF_PT_BIRTH_INDICTN 1 "PPROM" 2 "Spontaneous preterm labour" 3 "Pre-eclampsia" 4 "Antepartum haemorrhage" 5 "Other" 8 "NK" 9 "NA"
label values BDF_PT_BIRTH_INDICTN BDF_PT_BIRTH_INDICTN

label define BDF_FHS 1 "FHS present" 2 "FHS absent" 3 "Not documented" 8 "NK" 9 "NA"
label values BDF_FHS BDF_FHS

label define BDF_LEFT_STATUS 1 "Alive in Postnatal Ward" 2 "Referred to NICU" 3 "Dead" 4 "Discharged" /// 
5 "Referred to NICU" 8 "NK" 9 "NA"
label values BDF_LEFT_STATUS1 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS2 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS3 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS4 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS5 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS6 BDF_LEFT_STATUS

label define SEX 1 "Female" 2 "Male" 3 "Undetermined" 8 "NK" 9 "NA"
label values BDF_SEX1 SEX
label values BDF_SEX2 SEX
label values BDF_SEX3 SEX
label values BDF_SEX4 SEX
label values BDF_SEX5 SEX
label values BDF_SEX6 SEX

label define TRIMM   1 "1st" 2 "2nd" 3 "3rd" 8 "NK" 9 "NA"
label values BDF_TRIM_1STANC_VISIT TRIMM

label define NFU_INTERVIEW_DONE 1 "Yes" 3 "Lost to follow-up (60 days)"
label values NFU_INTERVIEW_DONE NFU_INTERVIEW_DONE

label define NFU_TYPE_INTERVIEW 1 "Telephonic" 2 "Home visit" 3 "Other"
label values NFU_TYPE_INTERVIEW NFU_TYPE_INTERVIEW

label define NFU_INFORMANT 1 "Mother" 2 "Other family member" 3 "Other"	
label values NFU_INFORMANT NFU_INFORMANT

label define NFU_MOTHER_READMIT_RSN 1 "Infection/Fever" 2 "Other" 8 "NK" 9 "NA"
label values NFU_MOTHER_READMIT_RSN NFU_MOTHER_READMIT_RSN

label define NFU_VITAL_STATUS 1 "Alive" 2 "Dead" 8 "NK" 9 "NA"
label values NFU_B1_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B2_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B3_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B4_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B5_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B6_VITAL_STATUS NFU_VITAL_STATUS

label define NFU_DEATH_PLACE 1 "Facility" 2 "In transit" 3 "Community/Home" 8 "NK" 9 "NA"
label values NFU_B1_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B2_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B3_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B4_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B5_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B6_DEATH_PLACE NFU_DEATH_PLACE

label define NFU_DEATH_LOCATION 1 "Labour room" 2 "Gyn/postnatal ward" 3 "Neonatal care unit/SNCU/Nursery" 4 "Other" 8 "NK" 9 "NA"
label values NFU_B1_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B2_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B3_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B4_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B5_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B6_DEATH_LOCATION NFU_DEATH_LOCATION

label values NFU_MOTHER_ALIVE   YESNONKNA
label values NFU_MOTHER_READMIT YESNONKNA
label values NFU_B1_SNCU YESNONKNA
label values NFU_B2_SNCU YESNONKNA
label values NFU_B3_SNCU YESNONKNA
label values NFU_B4_SNCU YESNONKNA
label values NFU_B5_SNCU YESNONKNA
label values NFU_B6_SNCU YESNONKNA

* P2B
label values BDF_ANTIBIOTICS    YESNONKNA
label values BDF_ANTIB_PPROM    YESNONKNA
label values BDF_ANTIB_CS       YESNONKNA
label values BDF_ANTIB_OTHER    YESNONKNA
label values BDF_MAGNESIUM_SUL  YESNONKNA
label values BDF_MAG_NEURO      YESNONKNA
label values BDF_MAG_SPE        YESNONKNA
label values BDF_MAG_OTHER      YESNONKNA
label values ACS_TOCOLYTICS1    YESNONKNA
label values ACS_SIGNS_ACUTE_INFECTION1 YESNONKNA

label values ACS_FHS1        BDF_FHS
label values ACS_PRIM_DIAGN1 BDF_PT_BIRTH_INDICTN

label define ACS_OUTCOME_ADM 1 "No delivery (Discharged/LAMA alive prior to delivery)" 2 "Delivered" 3 "Referred to a higher-level facility" 4 "Maternal death" 5 "Miscarriage/Abortion" 6 "Remained in the facility for another treatment" 8 "NK"
label values ACS_OUTCOME_ADM1 ACS_OUTCOME_ADM

label define BINARY 0 "No" 1 "Yes"
label define BINARY1 2 "No" 1 "Yes"
label values EUSG_AVAIL BINARY
label values NEEDS_NFU  BINARY
label values BDF_LCG BINARY1
* Excluding test version data
drop if BDF_DT_ADM < mdy(6, 3, 2025)



** MNFU STATUS
* Pending MNFUs
gen MNFUS_STATUS = .

* ---- First check completed or lost ----
replace MNFUS_STATUS = 2 if DEL_NOW_DATE > 28 & NFU_INTERVIEW_DONE == 1 & BDF_MNFU_CONSENT == 1 ///
    & (BDF_BIRTH_STATUS1 == 1 | BDF_BIRTH_STATUS2==1 | BDF_BIRTH_STATUS3==1) & BDF_LEFT_STATUS1 != 3 & APP == "P2A"
replace MNFUS_STATUS = 2 if DEL_NOW_DATE > 28 & NFU_INTERVIEW_DONE == 1 & BDF_MNFU_CONSENT == 1 & APP == "P2B"

replace MNFUS_STATUS = 3 if DEL_NOW_DATE > 28 & NFU_INTERVIEW_DONE == 2 & BDF_MNFU_CONSENT == 1 ///
    & (BDF_BIRTH_STATUS1 == 1 | BDF_BIRTH_STATUS2==1 | BDF_BIRTH_STATUS3==1)  & BDF_LEFT_STATUS1 != 3 & APP == "P2A"
replace MNFUS_STATUS = 3 if DEL_NOW_DATE > 28 & NFU_INTERVIEW_DONE == 2 & BDF_MNFU_CONSENT == 1 & APP == "P2B"

* ---- Check ongoing ----
replace MNFUS_STATUS = 1 if DEL_NOW_DATE > 28 & DEL_NOW_DATE <= 35 & BDF_MNFU_CONSENT == 1 & FORM_NFU == . ///
    & MNFUS_STATUS == . & (BDF_BIRTH_STATUS1 == 1 | BDF_BIRTH_STATUS2==1 | BDF_BIRTH_STATUS3==1)  & BDF_LEFT_STATUS1 != 3 & APP == "P2A"

replace MNFUS_STATUS = 1 if DEL_NOW_DATE > 28 & DEL_NOW_DATE <= 35 & BDF_MNFU_CONSENT == 1 & FORM_NFU == . ///
    & MNFUS_STATUS == . & APP == "P2B"

* ---- Mark pending ----
replace MNFUS_STATUS = 0 if DEL_NOW_DATE > 35 & DEL_NOW_DATE < 45 & BDF_MNFU_CONSENT == 1 & MNFUS_STATUS == . & FORM_NFU == . ///
    & (BDF_BIRTH_STATUS1 == 1 | BDF_BIRTH_STATUS2==1 | BDF_BIRTH_STATUS3==1)  & BDF_LEFT_STATUS1 != 3 & APP == "P2A"
replace MNFUS_STATUS = 0 if DEL_NOW_DATE > 35 & DEL_NOW_DATE < 45 & BDF_MNFU_CONSENT == 1 & MNFUS_STATUS == . & APP == "P2B" & FORM_NFU == .

* ---- Risk at lost ----
replace MNFUS_STATUS = 4 if DEL_NOW_DATE >= 45  & BDF_MNFU_CONSENT == 1 & MNFUS_STATUS == . & FORM_NFU == . ///
    & (BDF_BIRTH_STATUS1 == 1 | BDF_BIRTH_STATUS2==1 | BDF_BIRTH_STATUS3==1)  & BDF_LEFT_STATUS1 != 3 & APP == "P2A"
replace MNFUS_STATUS = 4 if DEL_NOW_DATE >= 45 & BDF_MNFU_CONSENT == 1 & MNFUS_STATUS == . & APP == "P2B" & FORM_NFU == .

* ---- Label the variable ----
label define mnfu_status 0 "MNFU Pending" 1 "Ongoing MNFUs" 2 "MNFU Done" 3 "LFU" 4 "Risk at LFU"
label values MNFUS_STATUS mnfu_status


* Days passed from pending MNFUs
gen DAYS_PASSED_DUE_DT = .
replace DAYS_PASSED_DUE_DT = DEL_NOW_DATE - 28 if DEL_NOW_DATE>= 28
label variable DAYS_PASSED_DUE_DT "Days passed from the MNFU due date" 

* Delivered within or outside NOC
gen     DELIVERY_STATUS = 0 if FORM_ACS1 == 1
replace DELIVERY_STATUS = 1 if FORM_ACS1 == 1 & FORM_BDF == 1
label define DELIVERY_STATUS1 1 "Deliveried Within NOC" 0 "Delivered Outside NOC"
label values DELIVERY_STATUS DELIVERY_STATUS1

* ACS Across form Validation
gen ACS_ACROSS = .
replace ACS_ACROSS = 1 if BDF_ACS_RECEIVED == 1 /// ACS received in BDF (inside NOC) AND ACS form available
    & BDF_PLACE_ACS <= 2 ///
    & FORM_ACS1 == 1
replace ACS_ACROSS = 2 if BDF_ACS_RECEIVED == 1 /// ACS received in BDF (inside NOC) BUT ACS form missing
    & BDF_PLACE_ACS <= 2 ///
    & (missing(FORM_ACS1) | FORM_ACS1 == 0)
replace ACS_ACROSS = 3 if BDF_ACS_RECEIVED == 2 /// ACS NOT received in BDF but ACS Form is filled (inconsistency)
    & FORM_ACS1 == 1
replace ACS_ACROSS = 4 if BDF_ACS_RECEIVED == 1 /// ACS received OUTSIDE NOC but ACS Form is available
    & BDF_PLACE_ACS == 3 ///
    & FORM_ACS1 == 1
replace ACS_ACROSS = 5 if FORM_ACS1== 1 /// ACS received OUTSIDE NOC but ACS Form is available
    & FORM_BDF==. 
label define ACS_ACROSS1 ///
    1 "ACS With BDF" ///
    2 "Received ACS in BDF but ACS Form Missing" ///
    3 "No ACS in BDF but ACS Form Available" ///
    4 "Received ACS Outside NOC but ACS Form Available" ///
	5 "Deliveried Outside NOC"
label values ACS_ACROSS ACS_ACROSS1

* Dropping cases where Dose date is before September 1,2025
drop if ACS_DOSE1_DATE1<mdy(08,30,2025) & FORM_ACS1==1
*
* * 
* * * 
* * * * 
* * * * * SAVE FULL DATA * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

keep if PID != ""

order COUNTRY

saveold  "Full_integerated_database_analysis_P2.dta", replace version(13)

export excel     using "Full_integerated_database_analysis_P2.dta.xlsx", firstrow(variables) nolabel replace
* DROP UNKNOWN NEONATES
drop if BDF_NUM_FETUS == 8

/* Reveal missing BW
replace BDF_BIRTH_WEIGHT1 = 9999 if BDF_BIRTH_WEIGHT1 == . & BDF_NUM_FETUS == 1
replace BDF_BIRTH_WEIGHT2 = 9999 if BDF_BIRTH_WEIGHT2 == . & BDF_NUM_FETUS >= 2
replace BDF_BIRTH_WEIGHT3 = 9999 if BDF_BIRTH_WEIGHT3 == . & BDF_NUM_FETUS >= 3
replace BDF_BIRTH_WEIGHT4 = 9999 if BDF_BIRTH_WEIGHT4 == . & BDF_NUM_FETUS >= 4
replace BDF_BIRTH_WEIGHT5 = 9999 if BDF_BIRTH_WEIGHT5 == . & BDF_NUM_FETUS >= 5
replace BDF_BIRTH_WEIGHT6 = 9999 if BDF_BIRTH_WEIGHT6 == . & BDF_NUM_FETUS >= 6
*/


* Rename NFU variables to fit long format:
rename NFU_B1_VITAL_STATUS NFU_VITAL_STATUS1
rename NFU_B2_VITAL_STATUS NFU_VITAL_STATUS2
rename NFU_B3_VITAL_STATUS NFU_VITAL_STATUS3
rename NFU_B4_VITAL_STATUS NFU_VITAL_STATUS4
rename NFU_B5_VITAL_STATUS NFU_VITAL_STATUS5
rename NFU_B6_VITAL_STATUS NFU_VITAL_STATUS6

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

rename NFU_B1_SNCU  NFU_SNCU1
rename NFU_B2_SNCU  NFU_SNCU2
rename NFU_B3_SNCU  NFU_SNCU3
rename NFU_B4_SNCU  NFU_SNCU4
rename NFU_B5_SNCU  NFU_SNCU5
rename NFU_B6_SNCU  NFU_SNCU6

rename NFU_B1_SNCU_NUM NFU_SNCU_NUM1
rename NFU_B2_SNCU_NUM NFU_SNCU_NUM2
rename NFU_B3_SNCU_NUM NFU_SNCU_NUM3
rename NFU_B4_SNCU_NUM NFU_SNCU_NUM4
rename NFU_B5_SNCU_NUM NFU_SNCU_NUM5
rename NFU_B6_SNCU_NUM NFU_SNCU_NUM6

rename NFU_B1_DEATH_LOCATION NFU_DEATH_LOCATION1
rename NFU_B2_DEATH_LOCATION NFU_DEATH_LOCATION2
rename NFU_B3_DEATH_LOCATION NFU_DEATH_LOCATION3
rename NFU_B4_DEATH_LOCATION NFU_DEATH_LOCATION4
rename NFU_B5_DEATH_LOCATION NFU_DEATH_LOCATION5
rename NFU_B6_DEATH_LOCATION NFU_DEATH_LOCATION6

/* START: ADDED 2025-10-01 */
rename NFU_B1_KMC  NFU_KMC1
rename NFU_B2_KMC  NFU_KMC2
rename NFU_B3_KMC  NFU_KMC3
rename NFU_B4_KMC  NFU_KMC4
rename NFU_B5_KMC  NFU_KMC5
rename NFU_B6_KMC  NFU_KMC6

rename NFU_B1_KMC_FAC  NFU_KMC_FAC1
rename NFU_B2_KMC_FAC  NFU_KMC_FAC2
rename NFU_B3_KMC_FAC  NFU_KMC_FAC3
rename NFU_B4_KMC_FAC  NFU_KMC_FAC4
rename NFU_B5_KMC_FAC  NFU_KMC_FAC5
rename NFU_B6_KMC_FAC  NFU_KMC_FAC6

rename NFU_B1_BREASTFED  NFU_BREASTFED1
rename NFU_B2_BREASTFED  NFU_BREASTFED2
rename NFU_B3_BREASTFED  NFU_BREASTFED3
rename NFU_B4_BREASTFED  NFU_BREASTFED4
rename NFU_B5_BREASTFED  NFU_BREASTFED5
rename NFU_B6_BREASTFED  NFU_BREASTFED6

rename NFU_B1_BREASTFED_FAC  NFU_BREASTFED_FAC1
rename NFU_B2_BREASTFED_FAC  NFU_BREASTFED_FAC2
rename NFU_B3_BREASTFED_FAC  NFU_BREASTFED_FAC3
rename NFU_B4_BREASTFED_FAC  NFU_BREASTFED_FAC4
rename NFU_B5_BREASTFED_FAC  NFU_BREASTFED_FAC5
rename NFU_B6_BREASTFED_FAC  NFU_BREASTFED_FAC6

rename NFU_B1_DEATH_FAC NFU_DEATH_FAC1
rename NFU_B2_DEATH_FAC NFU_DEATH_FAC2
rename NFU_B3_DEATH_FAC NFU_DEATH_FAC3
rename NFU_B4_DEATH_FAC NFU_DEATH_FAC4
rename NFU_B5_DEATH_FAC NFU_DEATH_FAC5
rename NFU_B6_DEATH_FAC NFU_DEATH_FAC6

/* END: ADDED 2025-10-01 */

* Clean to fit variables
tostring BDF_CHILD_ID3, replace format("%11.1f") force
tostring BDF_CHILD_ID4, replace format("%11.1f") force
tostring BDF_CHILD_ID5, replace format("%11.1f") force
tostring BDF_CHILD_ID6, replace format("%11.1f") force

tostring NFU_SNCU_HOSP_ADM1_B1, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM2_B1, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM3_B1, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM4_B1, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM5_B1, replace format("%9.0g") force

tostring NFU_SNCU_HOSP_ADM1_B2, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM2_B2, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM3_B2, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM4_B2, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM5_B2, replace format("%9.0g") force

tostring NFU_SNCU_HOSP_ADM1_B3, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM2_B3, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM3_B3, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM4_B3, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM5_B3, replace format("%9.0g") force

* Reshape on baby variables. Generates variable BABY_NUM indicating each newborn as one line:
reshape long BDF_CHILD_ID BDF_BIRTH_ORDER BDF_MODE_DELIVERY ///
    BDF_BIRTH_STATUS BDF_BIRTH_WEIGHT BDF_SEX ///
    BDF_RESUSCITATION BDF_LEFT_STATUS ///
    NFU_VITAL_STATUS NFU_DEATH_PLACE NFU_DEATH_DATE NFU_DEATH_LOCATION ///
    NFU_SNCU NFU_SNCU_NUM ///
    NFU_SNCU_ID_ADM1_B NFU_SNCU_HOSP_ADM1_B ///
    NFU_SNCU_ID_ADM2_B NFU_SNCU_HOSP_ADM2_B ///
    NFU_SNCU_ID_ADM3_B NFU_SNCU_HOSP_ADM3_B ///
    NFU_SNCU_ID_ADM4_B NFU_SNCU_HOSP_ADM4_B ///
    NFU_SNCU_ID_ADM5_B NFU_SNCU_HOSP_ADM5_B, ///
    i(PID) j(BABY_NUM)

label variable BABY_NUM "Birth order"
			 
			 
rename NFU_SNCU_ID_ADM1_B NFU_SNCU_ID_ADM1
rename NFU_SNCU_ID_ADM2_B NFU_SNCU_ID_ADM2
rename NFU_SNCU_ID_ADM3_B NFU_SNCU_ID_ADM3
rename NFU_SNCU_ID_ADM4_B NFU_SNCU_ID_ADM4
rename NFU_SNCU_ID_ADM5_B NFU_SNCU_ID_ADM5

rename NFU_SNCU_HOSP_ADM1_B NFU_SNCU_HOSP_ADM1
rename NFU_SNCU_HOSP_ADM2_B NFU_SNCU_HOSP_ADM2
rename NFU_SNCU_HOSP_ADM3_B NFU_SNCU_HOSP_ADM3
rename NFU_SNCU_HOSP_ADM4_B NFU_SNCU_HOSP_ADM4
rename NFU_SNCU_HOSP_ADM5_B NFU_SNCU_HOSP_ADM5

label variable NFU_SNCU_HOSP_ADM1 "SNCU 1st admission hosp"
label variable NFU_SNCU_HOSP_ADM2 "SNCU 2nd admission hosp"
label variable NFU_SNCU_HOSP_ADM3 "SNCU 3rd admission hosp"
label variable NFU_SNCU_HOSP_ADM4 "SNCU 4th admission hosp"
label variable NFU_SNCU_HOSP_ADM5 "SNCU 5th admission hosp"
					   
* Label long variables
label values BDF_SEX SEX
label value BDF_MODE_DELIVERY BDF_MODE_DELIVERY

label values NFU_VITAL_STATUS NFU_VITAL_STATUS
* label values NFU_DISCHARGED YESNONKNA
label values NFU_DEATH_PLACE NFU_DEATH_PLACE

* Drop non-babies 2-6 generated due to long format:
drop if FORM_BDF == 1 & BDF_BIRTH_STATUS == . & BDF_BIRTH_WEIGHT == .

* Drop babies without birth status (due to error in data collection)
drop if BDF_BIRTH_STATUS == 9 

* Drop extra ACS/EHS/MIF generated due to long format (i.e., keep 1st instance a.k.a. BABY_NUM==1)
drop if FORM_BDF != 1 & FORM_ACS1 == 1 & BABY_NUM > 1
drop if FORM_BDF != 1 & FORM_NFU  == 1 & BABY_NUM > 1


* Drop non-PID
drop if PID == ""

// Provider assessment in categories estimating from weight if GA is absent (BDF)
gen GA_BIRTH_CAT_BW = .
replace GA_BIRTH_CAT_BW = 1 if GA_BIRTH >= 28*7 & GA_BIRTH < 34*7
replace GA_BIRTH_CAT_BW = 2 if GA_BIRTH >= 34*7 & GA_BIRTH < 37*7 
replace GA_BIRTH_CAT_BW = 3 if GA_BIRTH >= 37*7 & GA_BIRTH < 45*7 
replace GA_BIRTH_CAT_BW = 1 if GA_BIRTH  == .   & BDF_BIRTH_WEIGHT <= 1500
replace GA_BIRTH_CAT_BW = 2 if GA_BIRTH  == .   & BDF_BIRTH_WEIGHT >  1500
replace GA_BIRTH_CAT_BW = 3 if GA_BIRTH  == .   & BDF_BIRTH_WEIGHT >  2000
replace GA_BIRTH_CAT_BW = 9 if GA_BIRTH  == .   & BDF_BIRTH_WEIGHT == . & FORM_BDF == 1
label variable GA_BIRTH_CAT_BW "Provider GA at birth & birthweight"
label define GA_BIRTH_CAT_BW 1 "EPT" 2 "LPT" 3 "TERM" 9 "No Provider estimate or birthweight"
label values GA_BIRTH_CAT_BW GA_BIRTH_CAT_BW

*
* *
* * * Gestation category based on corrected EUSG or, if EUSG missing, then birthweight

*
* * GA Categorization in BDF based on reliable  EUSG in ACS
gen 	GA_AB_CAT= 0
replace GA_AB_CAT= 1 if GA_AB_EUSG < 34*7  & FORM_ACS1 == 1
replace GA_AB_CAT= 2 if GA_AB_EUSG >= 34*7 & GA_AB_EUSG < 37*7 & FORM_ACS1==1
replace GA_AB_CAT= 3 if GA_AB_EUSG >= 37*7 & FORM_ACS1 == 1
replace GA_AB_CAT= 9 if GA_ACS_EUSG ==.
replace GA_AB_CAT= . if FORM_ACS1  != 1
label variable GA_AB_CAT "Gestational age at birth using earliest USG at ACS D1"
label define GA_AB_CAT 1"<34 Weeks" 2"34-37 Weeks" 3">37 Weeks" 9 "No USG"
label values GA_AB_CAT GA_AB_CAT

*
* * Assessing in which Form (BDF vs ACS) the EUSG is accurate and earlier
gen 	GA_AB_ASSESS = . if FORM_ACS1 != 1
replace GA_AB_ASSESS = 0 if ACS_DT_EARLY_USG1 > BDF_DT_EARLY_USG & GA_ACS_EUSG   != .
replace GA_AB_ASSESS = 1 if ACS_DT_EARLY_USG1 < BDF_DT_EARLY_USG & GA_BIRTH_EUSG != .
replace GA_AB_ASSESS = 2 if GA_ACS_EUSG       !=. & GA_BIRTH_EUSG == .
replace GA_AB_ASSESS = 3 if GA_ACS_EUSG       ==. & GA_BIRTH_EUSG!=.
replace GA_AB_ASSESS = 4 if ACS_DT_EARLY_USG1 ==  BDF_DT_EARLY_USG & EUSG_AVAIL!=0
replace GA_AB_ASSESS = 5 if GA_ACS_EUSG       ==. & GA_BIRTH_EUSG==.
label variable GA_AB_ASSESS "Assessing the realiable earliest usg in both forms"
label define GA_AB_ASSESS 0 "EUSG at ACS later than EUSG at birth" 1 "EUSG at ACS earlier than EUSG at birth" 2 "Earliest USG only recorded at ACS" 3 "Earliest USG only recorded at birth" 4 "Same EUSG on ACS and BDF form" 5 "No EUSG on ACS or BDF Form"
label values GA_AB_ASSESS GA_AB_ASSESS

gen     GA_EUSG_DAYS = GA_BIRTH_EUSG
replace GA_EUSG_DAYS = GA_AB_EUSG if GA_AB_ASSESS==1 
replace GA_EUSG_DAYS = GA_AB_EUSG if GA_AB_ASSESS==2
label variable GA_EUSG_DAYS "Gestational Age in days from reliable USG either from BDF or ACS"

gen     EARLY_USG_24 = EARLYUSG_BDF_24 
replace EARLY_USG_24 = EARLYUSG_ACS_24 if GA_AB_ASSESS==1
replace EARLY_USG_24 = EARLYUSG_ACS_24 if GA_AB_ASSESS==2
label variable EARLY_USG_24 "Earliest or Latest Ultrasound based on reliable USG" 

gen     GA_BIRTH_CAT_EUSG_CX = 0
replace GA_BIRTH_CAT_EUSG_CX = 1 if GA_EUSG_DAYS <  7*34
replace GA_BIRTH_CAT_EUSG_CX = 2 if GA_EUSG_DAYS >= 7*34 & GA_EUSG_DAYS < 7*37
replace GA_BIRTH_CAT_EUSG_CX = 3 if GA_EUSG_DAYS >= 7*37
replace GA_BIRTH_CAT_EUSG_CX = 9 if GA_EUSG_DAYS==.
label variable GA_BIRTH_CAT_EUSG_CX  "Gestational age categorization based on only reliable USG"
label define GA_BIRTH_CAT_EUSG_CX 1 "<34 weeks" 2 "34-<37 weeks" 3 ">=37 weeks" 9 "No USG"
label values GA_BIRTH_CAT_EUSG_CX GA_BIRTH_CAT_EUSG_CX

gen     GA_BIRTH_EUSG_BW = .
replace GA_BIRTH_EUSG_BW = 1 if GA_EUSG_DAYS <  7*34
replace GA_BIRTH_EUSG_BW = 2 if GA_EUSG_DAYS >= 7*34 & GA_EUSG_DAYS < 7*37
replace GA_BIRTH_EUSG_BW = 3 if GA_EUSG_DAYS >= 7*37 & GA_EUSG_DAYS!=.
replace GA_BIRTH_EUSG_BW = 1 if GA_EUSG_DAYS ==. & BDF_BIRTH_WEIGHT <= 1500
replace GA_BIRTH_EUSG_BW = 2 if GA_EUSG_DAYS ==. & BDF_BIRTH_WEIGHT >  1500
replace GA_BIRTH_EUSG_BW = 3 if GA_EUSG_DAYS ==. & BDF_BIRTH_WEIGHT >  2000 & BDF_BIRTH_WEIGHT!=.
replace GA_BIRTH_EUSG_BW = 9 if GA_BIRTH_EUSG_BW ==. & FORM_BDF == 1
label variable GA_BIRTH_EUSG_BW  "Gestational age categorization based on only reliable USG if absent BW"
label define GA_BIRTH_EUSG_BW 1 "EPT" 2 "LPT" 3 "Term" 9 "No USG or BW"
label values GA_BIRTH_EUSG_BW GA_BIRTH_EUSG_BW 

gen 	GEST_CAT_4 = GA_BIRTH_EUSG_BW
replace GEST_CAT_4 = 0 if GA_EUSG_DAYS     <  196  & GA_BIRTH_EUSG_BW == 1
replace GEST_CAT_4 = 0 if BDF_BIRTH_WEIGHT <  1000 & GA_EUSG_DAYS     == .
replace GEST_CAT_4 = 9 if GA_BIRTH_EUSG_BW == 9
label variable GEST_CAT_4 "Final GA Categorization based on earliest EUSG or BW"
label define GEST_CAT_4 0 "EEPT" 1 "EPT" 2 "LPT" 3 "TERM" 9 "No USG/BW"
label values GEST_CAT_4 GEST_CAT_4

gen     DETECT_EPT = 1 if GA_BIRTH_CAT == 1 & GA_BIRTH_CAT_EUSG_CX == 1
replace DETECT_EPT = 0 if GA_BIRTH_CAT != 1 & GA_BIRTH_CAT_EUSG_CX == 1
label define DETECT 0 "Misclassified EPT" 1 "Assessed EPT"
label values DETECT DETECT_EPT




***************************************
* VARIABLE CREATION
***************************************

gen WEEKS_BDF_EUSG = 1 * floor(GA_BIRTH_EUSG/7) // WEEKS BY BIRTH ESUG ONLY 
gen WEEKS_BDF_PROV = 1 * floor(GA_BIRTH/7)      // WEEKS BY PROVIDER
gen WEEKS_ACS_EUSG = 1 * floor(GA_ACS_EUSG/7)   // WEEKS BY ACS EUSH ONLY
gen WEEKS_EUSG     = 1 * floor(GA_EUSG_DAYS/7)  // WEEKS BY EUSG FROM BOTH ACS AND BDF


* Delivery Gestation Age (DGA) based on Corrected Earliest USG (EUSG) from BDF as WEEKS+DAYS
gen            DGA_WEEKS = .
replace        DGA_WEEKS = floor(WEEKS_EUSG)
label variable DGA_WEEKS "DGA EUSG weeks (BDF)"

gen            DGA_DAYS = .
replace        DGA_DAYS = GA_EUSG_DAYS
label variable DGA_DAYS "DGA EUSG days (BDF)"



*
* *
* * * MORTALITY


gen AGE_TODAY = TODAY - BDF_DT_DELIVERY

* NFU (Baby)
gen     NEEDS_NFU_MOTHER = 0
replace NEEDS_NFU_MOTHER = 1 if BDF_MNFU_CONSENT == 1
label variable NEEDS_NFU_MOTHER "Consent is yes, so mother needs to be connected"

gen     NEEDS_NFU_BABY   = 0
replace NEEDS_NFU_BABY   = 1 if BDF_MNFU_CONSENT == 1 & BDF_BIRTH_STATUS == 1 & BDF_LEFT_STATUS != 3
label variable NEEDS_NFU_MOTHER "MNFU needs to be done to check on baby vital status"
label values NEEDS_NFU_BABY   BINARY
label values NEEDS_NFU_MOTHER BINARY
	
* ANY DEATH DATE
gen     DEATH_DATE = NFU_DEATH_DATE
replace DEATH_DATE = BDF_DT_DELIVERY if BDF_LEFT_STATUS==3
label variable DEATH_DATE "Date of death of baby either after birth or at 28 days of life"

* Age (days) at death
gen     AGE_DEATH = NFU_DEATH_DATE - BDF_DT_DELIVERY
replace AGE_DEATH = 0 if BDF_LEFT_STATUS  == 3
label variable AGE_DEATH "Age at death, days"

* Age of the baby from the delivery date
gen BABY_28_DAYS     = 1 if AGE_TODAY >=28
replace BABY_28_DAYS = 0 if BABY_28_DAYS ==.

gen BABY_35_DAYS     = 1 if AGE_TODAY >=35
replace BABY_35_DAYS = 0 if BABY_35_DAYS ==.

gen BABY_45_DAYS     = 1 if AGE_TODAY >=45
replace BABY_45_DAYS = 0 if BABY_45_DAYS ==.

gen BABY_60_DAYS     = 1 if AGE_TODAY >=60
replace BABY_60_DAYS = 0 if BABY_60_DAYS ==.

label define BABY_DAYS 0 "No" 1 "Yes"
label values BABY_45_DAYS BABY_28_DAYS BABY_35_DAYS BABY_60_DAYS BABY_DAYS

* MNFU pending time
gen     MNFU_PENDING_TIME = 1 if AGE_TODAY >28 & NFU_INTERVIEW_DONE != 1
replace MNFU_PENDING_TIME = 2 if AGE_TODAY >35 & NFU_INTERVIEW_DONE != 1
replace MNFU_PENDING_TIME = 3 if AGE_TODAY >45 & NFU_INTERVIEW_DONE != 1
replace MNFU_PENDING_TIME = 4 if AGE_TODAY >60 & NFU_INTERVIEW_DONE != 1
label variable  MNFU_PENDING_TIME "Calculates the time of MNFU in a pending"
label define MNFU_PENDING_TIME 1 "28-35 days" 2 "36-45 days" 3 "45-60 days" 4 ">60 days"
label values MNFU_PENDING_TIME MNFU_PENDING_TIME

* Lost to Follow-up
generate LOST_TFU = 1 if NFU_INTERVIEW_DONE == 2
replace  LOST_TFU = 2 if NFU_INTERVIEW_DONE != 2 & AGE_TODAY > 60
replace  LOST_TFU = 3 if NFU_INTERVIEW_DONE == . & AGE_TODAY > 28
replace  LOST_TFU = 4 if NFU_INTERVIEW_DONE == 1
label variable LOST_TFU "Calculates the Status of MNFUs for the lost to followups"
label define LOST_TFU 1 "Lost to follow-up (reported)" 2 "Lost to follow-up (not reported but >60 days" 3 "Pending MNFU 28-60 days" 4 "MNFU complete"
label values LOST_TFU LOST_TFU

* MNFUs completion Intervals
gen AGE_MNFU = (NFU_DT_FILL - BDF_DT_DELIVERY)
label variable AGE_MNFU  "What is age of babay when called for MNFU"

* MNFU Completed
gen  	MNFU_COMPLETE_TIME = 1   if AGE_MNFU >28 & NFU_INTERVIEW_DONE==1 & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME = 2   if AGE_MNFU >35 & NFU_INTERVIEW_DONE==1 & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME = 3   if AGE_MNFU >45 & NFU_INTERVIEW_DONE==1 & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME = 4   if AGE_MNFU >60 & NFU_INTERVIEW_DONE==1 & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME = 5   if AGE_MNFU >100 & NFU_INTERVIEW_DONE==1 & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME = 6   if AGE_MNFU<=28            & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME = 7   if NFU_INTERVIEW_DONE ==.  & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME = 7   if NFU_INTERVIEW_DONE ==2  & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME = 0   if BDF_LEFT_STATUS == 3    & BDF_BIRTH_STATUS==1
replace MNFU_COMPLETE_TIME=.     if BDF_BIRTH_STATUS== 2
label variable MNFU_COMPLETE_TIME "When did the MNFU Done"
label define MNFU_COMPLETE_TIME 0 "LR Death" 1 "29-35 days" 2 "36-45 days" 3 "45-60 days" 4 "60-99 days" 5 "100+ days" 6 "<=28 days" 7 "Incomplete"
label values MNFU_COMPLETE_TIME MNFU_COMPLETE_TIME

* MNFU STATUS AT THE 35 DAYS OF LIFE
gen MNFU_STATUS_35     = 1 if NFU_INTERVIEW_DONE == 1 & AGE_TODAY >35
replace MNFU_STATUS_35 = 0 if NFU_INTERVIEW_DONE == . & AGE_TODAY >35
replace MNFU_STATUS_35 = 0 if NFU_INTERVIEW_DONE == 2 & AGE_TODAY >35
replace MNFU_STATUS_35 = . if BDF_BIRTH_STATUS   == 2
replace MNFU_STATUS_35 = 1 if BDF_LEFT_STATUS    == 3 & AGE_TODAY >35
label define MNFU_STATUS 0 "Pending MNFU" 1 "Complete MNFU"
label values MNFU_STATUS_35 MNFU_STATUS

gen MNFU_STATUS = MNFU_STATUS_35

* MNFU Status at the 60th day of life 
gen     BIRTH_60 = 1 if AGE_TODAY > 60 & BDF_BIRTH_STATUS == 1
replace BIRTH_60 = 0 if AGE_TODAY <=60 & BDF_BIRTH_STATUS == 1

gen     MNFU_STATUS_60 = 1 if NFU_INTERVIEW_DONE == 1 & AGE_TODAY >60
replace MNFU_STATUS_60 = 0 if NFU_INTERVIEW_DONE == . & AGE_TODAY >60
replace MNFU_STATUS_60 = 0 if NFU_INTERVIEW_DONE == 2 & AGE_TODAY >60
replace MNFU_STATUS_60 = . if BDF_BIRTH_STATUS   == 2
replace MNFU_STATUS_60 = 1 if BDF_LEFT_STATUS    == 3 & AGE_TODAY >60
label values MNFU_STATUS_60 MNFU_STATUS

* When did the baby died 
gen     AGE_DEATH_CAT = 1 if AGE_DEATH==1
replace AGE_DEATH_CAT = 2 if AGE_DEATH==2
replace AGE_DEATH_CAT = 3 if AGE_DEATH==3
replace AGE_DEATH_CAT = 4 if AGE_DEATH >3
replace AGE_DEATH_CAT = 5 if AGE_DEATH >7
replace AGE_DEATH_CAT = 6 if AGE_DEATH >28
replace AGE_DEATH_CAT =.  if AGE_DEATH==. 
label variable AGE_DEATH_CAT "Days passed after the birth when the baby died"
label define AGE_DEATH_CAT 1 "Day 1" 2 "Day 2" 3 "Day 3" 4 "Day 4-7" 5 "Day 8-28" 6 ">28 days"
label values AGE_DEATH_CAT AGE_DEATH_CAT

* When did the baby died by the date brackets
gen     AGE_DEATH_CAT_2 = 1 if AGE_DEATH <= 7
replace AGE_DEATH_CAT_2 = 2 if AGE_DEATH >  7  
replace AGE_DEATH_CAT_2 = 3 if AGE_DEATH >  28
replace AGE_DEATH_CAT_2 = . if AGE_DEATH == . 
label variable AGE_DEATH_CAT_2 "Date braket when the baby died"
label define AGE_DEATH_CAT_2 1 " Day 1-7" 2 "Day 8-28" 3 ">28 days" 
label values AGE_DEATH_CAT_2 AGE_DEATH_CAT_2

* Vital Status of the baby when MNFU is done
gen     VITAL_STATUS = 1 if NFU_VITAL_STATUS == 1 
replace VITAL_STATUS = 2 if BDF_BIRTH_STATUS == 2 
replace VITAL_STATUS = 3 if BDF_LEFT_STATUS  == 3 & BDF_BIRTH_STATUS == 1 
replace VITAL_STATUS = 4 if NFU_VITAL_STATUS == 2 & AGE_DEATH        <= 28
replace VITAL_STATUS = 5 if LOST_TFU         <= 3 & BDF_LEFT_STATUS  != 3
label variable VITAL_STATUS "Vital status of the baby now"
label define VITAL_STATUS 1 "Alive" 2 "Stillborn" 3 "Died before discharge (LR)" 4 "Died after discharge from LR" 5 "Pending MNFU"
label values VITAL_STATUS VITAL_STATUS

* Vital Status of the baby when MNFU is pending
gen     VITAL_STATUS_3 = 1 if NFU_VITAL_STATUS == 1 
replace VITAL_STATUS_3 = 2 if BDF_BIRTH_STATUS == 2 
replace VITAL_STATUS_3 = 3 if BDF_LEFT_STATUS  == 3 & BDF_BIRTH_STATUS == 1 
replace VITAL_STATUS_3 = 3 if NFU_VITAL_STATUS == 2 & AGE_DEATH        <= 28
replace VITAL_STATUS_3 = 9 if LOST_TFU         <= 3 & BDF_LEFT_STATUS  !=3
label variable VITAL_STATUS_3 "Vital status of baby: MNFU is not done" 
label define VITAL_STATUS_3 1 "Alive" 2 "Stillborn" 3 "Neonatal Death" 9 "Pending MNFU"
label values VITAL_STATUS_3 VITAL_STATUS_3


* Neonatal mortality:
gen     NNM = .
replace NNM = 1 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   >= 28 & NFU_VITAL_STATUS == 1 & AGE_NFU != .
replace NNM = 1 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH >= 29 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace NNM = 2 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH <= 28 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace NNM = 2 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   <= 28 & NFU_VITAL_STATUS == 2 & AGE_NFU != .
replace NNM = 2 if BDF_BIRTH_STATUS == 1 & BDF_LEFT_STATUS == 3
label variable NNM "Neonatal mortality: Liveborn, verified status at 28 days"
label define NNM 1 "Alive at 28 days" 2 "Dead at 28 days"
label values NNM NNM

* Perinatal mortality:
gen     PNM = .
replace PNM = 1 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   >= 7 & 		   NFU_VITAL_STATUS == 1 & AGE_NFU != .
replace PNM = 1 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH  > 7 &      	    NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace PNM = 2 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH <= 7 &    	    	NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace PNM = 2 if BDF_LEFT_STATUS == 3
replace PNM = 3 if BDF_BIRTH_STATUS == 2
label variable PNM "Perinatal mortality: Verified status at 7 days"
label define PNM 1 "Alive 7d" 2 "Died 0-7d" 3 "Stillborn"
label values PNM PNM

* Any baby death
gen     ANY_BABY_DEATH = .
replace ANY_BABY_DEATH = 1 if BDF_BIRTH_STATUS == 1
replace ANY_BABY_DEATH = 2 if BDF_BIRTH_STATUS == 2
replace ANY_BABY_DEATH = 3 if NNM == 1
replace ANY_BABY_DEATH = 4 if NNM == 2
label variable ANY_BABY_DEATH "Any mortality: Status at birth or 28 days"

label define ANY_BABY_DEATH 1 "Alive at birth" 2 "Stillborn" 3 "Alive at 28 days" 4 "Dead at 28 days"
label values ANY_BABY_DEATH ANY_BABY_DEATH

* Place of the death 
gen     PLACE_OF_DEATH = 1 if BDF_LEFT_STATUS==3 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = 1 if NFU_DEATH_LOCATION==1 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = 2 if NFU_DEATH_LOCATION==2 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = 3 if NFU_DEATH_LOCATION==3 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = 4 if NFU_DEATH_PLACE==2 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = 5 if NFU_DEATH_PLACE==3 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = 9 if NFU_DEATH_PLACE==8 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = 9 if NFU_DEATH_PLACE==9 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = 9 if PLACE_OF_DEATH==. & NFU_VITAL_STATUS==2 & AGE_DEATH<=28 & BDF_BIRTH_STATUS!=2
replace PLACE_OF_DEATH= 1 if BDF_LEFT_STATUS==3 & BDF_BIRTH_STATUS!=2 & AGE_DEATH <=28
replace PLACE_OF_DEATH = . if NFU_VITAL_STATUS==1
label define PLACE_OF_DEATH 1 "Labour Room" 2 "Postnatal Ward" 3 "SNCU" 4 "In transit" 5 "Community" 9 "Unknown"
label values PLACE_OF_DEATH PLACE_OF_DEATH

* Place of death (NOC vs Outside NOC)
gen DEATH_PLACE_2     = 1 /// 	
	if NFU_DEATH_PLACE==1 & NFU_VITAL_STATUS==2 & BDF_BIRTH_STATUS==1 & AGE_DEATH<=28
replace DEATH_PLACE_2 = 1 ///
	if BDF_LEFT_STATUS==3 & BDF_BIRTH_STATUS==1
replace DEATH_PLACE_2 = 0 ///
	if NFU_DEATH_PLACE==2 & NFU_VITAL_STATUS==2 & BDF_BIRTH_STATUS==1 & AGE_DEATH<=28 & BDF_LEFT_STATUS!=3
replace DEATH_PLACE_2 = 0 ///	
	if NFU_DEATH_PLACE==3 & BDF_BIRTH_STATUS==1 & NFU_VITAL_STATUS==2 & AGE_DEATH<=28 & BDF_LEFT_STATUS!=3
replace DEATH_PLACE_2 = 0 ///
	if NFU_DEATH_PLACE==8 & BDF_BIRTH_STATUS==1 & NFU_VITAL_STATUS==2 & AGE_DEATH<=28 & BDF_LEFT_STATUS!=3
replace DEATH_PLACE_2  =. if NFU_VITAL_STATUS==1 
replace DEATH_PLACE_2 =. if BDF_BIRTH_STATUS==2
label define DEATH_PLACE_2 1 "Facility" 0 "Other"
label values DEATH_PLACE_2 DEATH_PLACE_2

* Age of death till 28 days, including BDF (stillborn or died on ward)
gen     AGE_DEATH_28_W_SB = .
replace AGE_DEATH_28_W_SB = NFU_DEATH_DATE - BDF_DT_DELIVERY
replace AGE_DEATH_28_W_SB = 0 if BDF_BIRTH_STATUS == 2 | BDF_LEFT_STATUS == 3
replace AGE_DEATH_28_W_SB = . if AGE_DEATH_28 > 28
label variable AGE_DEATH_28_W_SB "Age death 0-28 days"
   
*
* *
* * * EXCLUSION CRITERIA

* 1) Births less than 26 weeks gestation by the earliest ultrasound are excluded. 
* 2) Births less than 500 grams are excluded. This weight cut point is only used for babies without information from the earliest ultrasound available. 
* 3) Women who delivered at a facility outside the network of care are excluded from the main indicators. 

gen     EXCLUDE = 0
replace EXCLUDE = 1 if GA_BIRTH_EUSG < 28*7 & GA_BIRTH_EUSG != .
replace EXCLUDE = 2 if BDF_BIRTH_WEIGHT < 1000 & BDF_BIRTH_WEIGHT != . &   			GA_BIRTH_EUSG == .
replace EXCLUDE = 3 if FORM_BDF != 1
label variable EXCLUDE "Exclusion criteria"

label define EXCLUDE 0 "Valid, keep" 1 "Invalid GA (<28 EUSG), drop" 2 "Invalid weight (<1000) without EUSG, drop" 3 "Invalid place of birth (no BDF), drop"
label values EXCLUDE EXCLUDE


* DROP THOSE TO BE EXCLUDED:
keep if EXCLUDE == 0

duplicates tag PID, gen(dup_flag)

*
* * BABY_ID

egen BABY_ID = concat(PID BDF_BIRTH_ORDER) if BDF_BIRTH_ORDER != .

order APP App_Version_BDF App_Version_NFU App_Version_ACS1  PID BABY_NUM BDF_BIRTH_ORDER BABY_ID COUNTRY_NUM CLUST_NUM DIST_NAME HOSPNUM_BDF FORM_BDF FORM_NFU 

*
* *
* * * Save

saveold "Full_database_analysis_P2_LONG_PK.dta", replace version(13)

*
* *
* * *
* * * *
* * * * * 
* * * * * * * MONITORING VARIABLES

clear 
use "Full_database_analysis_P2_LONG_PK.dta"

*
* *
* * *



* *
* * * Truncated Admission to Delivery

gen     admission_to_del_hours = DAYS_ADM_TO_DEL * 24
replace admission_to_del_hours = 24 if DAYS_ADM_TO_DEL > 1
replace admission_to_del_hours = 0  if DAYS_ADM_TO_DEL < 0
label variable admission_to_del_hours "Number of hours from admission to delivery"
gen admission_to_del_hours2 = floor(admission_to_del_hours)

** ACS to delivery
gen     ACS_to_del_hours =   DAYS_ACS_TO_DEL * 24
replace ACS_to_del_hours = 24 if DAYS_ACS_TO_DEL > 1
replace ACS_to_del_hours = 0  if DAYS_ACS_TO_DEL < 0
label variable ACS_to_del_hours "Number of hours from ACS to delivery"
gen ACS_to_del_hours2 = floor(ACS_to_del_hours)

** Baby delivered less than 6 hours of ACS Dose
gen     ACS_DEL_6 = 0 if FORM_ACS1 == 1
replace ACS_DEL_6 = 1 if ACS_to_del_hours    < 6
replace ACS_DEL_6 = . if ACS_to_del_hours  ==  .
label define ACS_DEL_6 0 ">=6 hours" 1 "<6 hours"
label values ACS_DEL_6 ACS_DEL_6

*
* *
* * * USG TO DELIVERY (3 GROUPS)

gen     USG_TO_BDF_BIN = .
replace USG_TO_BDF_BIN = 1 if USG_TO_BDF <= 0
replace USG_TO_BDF_BIN = 2 if USG_TO_BDF == 1
replace USG_TO_BDF_BIN = 3 if USG_TO_BDF > 1
replace USG_TO_BDF_BIN = 9 if EUSG_AVAIL == 0
label define USG_TO_BDF_BIN1 1 "Delivery day USG" 2 "USG one day before delivery" 3 "USG 2+ days before delivery" 9 "No USG"
label values USG_TO_BDF_BIN USG_TO_BDF_BIN1
*
* *
* * * USG TO ADMISSION

gen USG_TO_ADM = BDF_DT_ADM - BDF_DT_EARLY_USG  if EUSG_AVAIL == 1 & BDF_DT_ADM != .

label variable USG_TO_ADM "Days from BDF EUSG to admission"

gen     USG_TO_ADM_GROUP = .
replace USG_TO_ADM_GROUP = 1 if USG_TO_ADM <= 0
replace USG_TO_ADM_GROUP = 2 if USG_TO_ADM == 1
replace USG_TO_ADM_GROUP = 3 if USG_TO_ADM >= 2  & USG_TO_ADM <= 7
replace USG_TO_ADM_GROUP = 4 if USG_TO_ADM >= 8  & USG_TO_ADM <= 28
replace USG_TO_ADM_GROUP = 5 if USG_TO_ADM >= 29 & USG_TO_ADM <= 59
replace USG_TO_ADM_GROUP = 6 if USG_TO_ADM >= 60 & USG_TO_ADM != .

label define USG_TO_ADM_Label 1 "Admission day USG" 2  "1 day before" 3 "2-7 days before" 4 "8-28 days before" /// 
5 "29-59 days before" 6 "60+ days before"
label value USG_TO_ADM_GROUP USG_TO_ADM_Label

*
* *
* * * Weight category

gen     BW = .
replace BW = 1 if BDF_BIRTH_WEIGHT > 0     & BDF_BIRTH_WEIGHT <  500
replace BW = 2 if BDF_BIRTH_WEIGHT >= 500  & BDF_BIRTH_WEIGHT < 1000
replace BW = 3 if BDF_BIRTH_WEIGHT >= 1000 & BDF_BIRTH_WEIGHT < 1500
replace BW = 4 if BDF_BIRTH_WEIGHT >= 1500 & BDF_BIRTH_WEIGHT < 2000
replace BW = 5 if BDF_BIRTH_WEIGHT >= 2000 & BDF_BIRTH_WEIGHT < 2500
replace BW = 6 if BDF_BIRTH_WEIGHT >= 2500 & BDF_BIRTH_WEIGHT < 7000
replace BW = 7 if BDF_BIRTH_WEIGHT >= 7000
replace BW = 8 if BDF_BIRTH_WEIGHT == 8888
replace BW = 9 if BDF_BIRTH_WEIGHT == 9999 | BDF_BIRTH_WEIGHT == .

label define BW 1 "0-499" 2 "500-999" 3 "1,000-1,499" 4 "1,500-1,999" 5 "2,000-2,499" 6 "2,500-7000" 7 "over 7000" 8 "NK" 9 "Missing"
label values BW BW

*
* *
* * * Weight precision

gen rounded_1    = round(BDF_BIRTH_WEIGHT, 1)
gen rounded_5    = round(BDF_BIRTH_WEIGHT, 5)
gen rounded_10   = round(BDF_BIRTH_WEIGHT, 10)
gen rounded_50   = round(BDF_BIRTH_WEIGHT, 50)
gen rounded_100  = round(BDF_BIRTH_WEIGHT, 100)
gen rounded_500  = round(BDF_BIRTH_WEIGHT, 500)
gen rounded_1000 = round(BDF_BIRTH_WEIGHT, 1000)

gen     weight_level = .
replace weight_level = 1 if BDF_BIRTH_WEIGHT == rounded_1
replace weight_level = 2 if BDF_BIRTH_WEIGHT == rounded_5
replace weight_level = 3 if BDF_BIRTH_WEIGHT == rounded_10
replace weight_level = 4 if BDF_BIRTH_WEIGHT == rounded_50
replace weight_level = 5 if BDF_BIRTH_WEIGHT == rounded_100
replace weight_level = 6 if BDF_BIRTH_WEIGHT == rounded_500
replace weight_level = 7 if BDF_BIRTH_WEIGHT == rounded_1000
replace weight_level = 8 if BDF_BIRTH_WEIGHT == . | BDF_BIRTH_WEIGHT == 8888 | BDF_BIRTH_WEIGHT == 9999
drop rounded_1 rounded_5 rounded_10 rounded_100 rounded_500 rounded_1000
label define weight_level 1 "1 g" 2 "5 g" 3 "10 g" 4 "50 g" 5 "100 g" 6 "500 g" 7 "1000 g" 8 "NK"
label values weight_level weight_level
label variable weight_level "Weight measured to accuracy"

* Weight Accuracy 10,100,500 and 1000
gen     WEIGHT_ACCURACY2=.
replace WEIGHT_ACCURACY2=1 if weight_level == 1  // 1 g
replace WEIGHT_ACCURACY2=1 if weight_level == 2  // 5 g
replace WEIGHT_ACCURACY2=1 if weight_level == 3  // 10 g
replace WEIGHT_ACCURACY2=2 if weight_level == 4  // 50 g
replace WEIGHT_ACCURACY2=3 if weight_level == 5  // 100 g
replace WEIGHT_ACCURACY2=4 if weight_level == 6  // 500 g
replace WEIGHT_ACCURACY2=5 if weight_level == 7  // 1000 g
replace WEIGHT_ACCURACY2=9 if BDF_BIRTH_WEIGHT==.
label define WEIGHT_ACCURACY2 1 "<=10g" 2 "50g" 3 "100g" 4 "500g" 5 "1000g" 9 "Missing BW"
label values WEIGHT_ACCURACY2 WEIGHT_ACCURACY2

* Weigth accuracy either 10 or more than 10
gen     WEIGHT_ACCURACY_10 = 1 if WEIGHT_ACCURACY2 <=1
replace WEIGHT_ACCURACY_10 = 0 if WEIGHT_ACCURACY2 ==.
replace WEIGHT_ACCURACY_10 = 0 if WEIGHT_ACCURACY2 >=2
replace WEIGHT_ACCURACY_10 = 0 if BDF_BIRTH_WEIGHT==.
label define WEIGHT_ACCURACY_10 0 ">10g" 1 "<=10g" 9 "Missing BW"
label values WEIGHT_ACCURACY_10 WEIGHT_ACCURACY_10

* 100 Gram accuracy
gen LAST_TWO_DIGITS = mod(BDF_BIRTH_WEIGHT, 100) if BDF_BIRTH_WEIGHT < 8000 & BDF_BIRTH_WEIGHT != .

/* Optimal ACS Coverage
gen     OPTIMAL_SAFE_COVERAGE = 0 if SAFE_COVERAGE_EUSG_BW==0
replace OPTIMAL_SAFE_COVERAGE = 1 if SAFE_COVERAGE_EUSG_BW==1
replace OPTIMAL_SAFE_COVERAGE = 2 if SAFE_COVERAGE_EUSG_BW==1 & ACS_DEL_6==0
label define OPTIMAL_SAFE_COVERAGE 0 "No Safe ACS" 1 "Safe ACS" 2 "Optiminal Safe ACS"
label values OPTIMAL_SAFE_COVERAGE OPTIMAL_SAFE_COVERAGE 

* Safe ACS Coverage
gen     SAFE_ACS_COVERAGE= 1 if SAFE_COVERAGE_EUSG_BW==1
replace SAFE_ACS_COVERAGE= 0 if SAFE_COVERAGE_EUSG_BW==0

* ACS Coverage 
gen     ACS_COVERAGE = 1 if COVERAGE_EUSG_BW ==1
replace ACS_COVERAGE = 0 if COVERAGE_EUSG_BW==0

* Optimal Safe ACS 
gen OPTIMAL_SAFE_ACS = 1 if OPTIMAL_SAFE_COVERAGE==2
replace OPTIMAL_SAFE_ACS =0 if OPTIMAL_SAFE_COVERAGE <=1
*/

* Pakistan drop cluster 05 Chakwal & 11 Tharparkar
gen DROP_CLUSTER = 0
replace DROP_CLUSTER = 1 if CLUST_NUM  == 5
replace DROP_CLUSTER = 1 if CLUST_NUM  == 11
drop if DROP_CLUSTER == 1


* Merging with FMS for the coordinates
merge m:1 FAC_ID using "FMS_ACSIR_FMS.dta", ///
 nogen keepusing(FMS_LONGDITUDE FMS_LATITUDE)

 
*
* *
* * * SAVE STATA

save "Full_database_analysis_P2_LONG_M_PK.dta", replace 

export excel     using "Full_database_analysis_P2_LONG_M_PK.xlsx", firstrow(variables) nolabel replace


