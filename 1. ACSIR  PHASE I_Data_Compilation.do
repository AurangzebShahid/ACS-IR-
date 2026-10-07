*************************************
** ACS-IR Phase 1: Data compilation **
*************************************

*  Stata version:  17.0 (Data saved as Stata 13 version to allow use in Stata 13 - replace 'saveold...version(13)' with 'save' if wanted)
* Legacy editors:  Nicole MINCKAS, Juha PYYKKO, Kayleigh RYAN (WHO Geneva)
* Latest editor :  Aurangzeb
* Desigination  :  Data Associate (PHC Global Pakistan)
* Code version  :  2025-02-18

clear
cd  "E:\ACSIR Data Management\Phase I" 
*
**
***
**** Importing BDF form: 
import excel "Outcome_Data_PK.xlsx", firstrow sheet("BDF") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	drop App_Version
	drop TAB_CODE STATUS FW_NUM // USER_CODE TAB_CODE
	
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM DIST_NUM PID BDF_DATE
	quietly by COUNTRY_NUM DIST_NUM PID: gen FORM_NUM_BDF = cond(_N==1,1,_n)

	/*sort COUNTRY_NUM DIST_NUM PID BDF_DATE
duplicates tag PID , gen(DUPTAG)
generate PIDDUP = PID == PID[_n - 1] | PID == PID[_n + 1]
count if PIDDUP>0 | duptag>0 */
	 log using dup_BDF.log, replace
	 tab FORM_NUM_BDF
	 list PID if FORM_NUM_BDF > 1
     log close
	keep if FORM_NUM_BDF==1
	

** RECODE BIRTWEIGHT **
   recode BDF_BIRTH_WEIGHT1 BDF_BIRTH_WEIGHT2 BDF_BIRTH_WEIGHT3 BDF_BIRTH_WEIGHT4    BDF_BIRTH_WEIGHT5 BDF_BIRTH_WEIGHT6 (7777=.) (8888=.) (9999=.)
   
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_BDF
	gen FORM_BDF = 1
	rename DT_Submit Submit_BDF
	format  Submit_BDF %tC
	format BDF_DATE BDF_DT_ADM BDF_DT_EARLY_USG BDF_DT_LMP BDF_DT_DELIVERY %td
	saveold "BDF.dta", replace version(13)  

*
**
***
**** Importing ACS form 
	import excel "Outcome_Data_PK.xlsx", firstrow sheet("ACS") clear
	quietly destring *, ignore("NULL") replace
	keep if STATUS == 1
	drop App_Version
	drop USER_CODE TAB_CODE  STATUS FW_NUM

** REMOVE IF NO CONSENT **
	drop if ACS_CONSENT == 2
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_ACS
	gen FORM_ACS = 1
	rename DT_Submit Submit_ACS
	format  Submit_ACS %tC
	format  ACS_DATE ACS_DT_ADM ACS_DT_EARLY_USG ACS_DT_LMP ACS_DT_DOSE1 ACS_DT_DOSE2 ACS_DT_DOSE3 ACS_DT_DOSE4 %td
**RESHAPE TO WIDE**
	saveold "ACS.dta", replace version(13)
	sort       COUNTRY_NUM DIST_NUM PID ACS_DT_DOSE1 // Sort by 1st dose order if two or more courses
	quietly by COUNTRY_NUM DIST_NUM PID: gen FORM_NUM_ACS = cond(_N==1,1,_n)
	reshape wide ACS* HOSPNUM_ACS FORM_ACS Submit_ACS, i(COUNTRY_NUM DIST_NUM PID) j(FORM_NUM_ACS)
	* First ACS as main hospital
	gen HOSPNUM_ACS = HOSPNUM_ACS1
	saveold "ACS_WIDE.dta", replace version(13)

**** Importing MFU form 
	import excel "Outcome_Data_PK.xlsx", firstrow sheet("MFU") clear
	quietly destring *, ignore("NULL") replace
	keep if STATUS == 1
	drop App_Version
	drop USER_CODE TAB_CODE STATUS FW_NUM
	keep if MFU_WOMAN_DELIVERED == 1
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_MFU
	gen FORM_MFU = 1
	rename DT_Submit Submit_MFU
	format  Submit_MFU %tC
	format  MFU_DT_CONTACT MFU_DT_DELIVERY %td
**RESHAPE TO WIDE**
	saveold "MFU.dta", replace version(13)
	sort       COUNTRY_NUM DIST_NUM PID MFU_DT_CONTACT
	quietly by COUNTRY_NUM DIST_NUM PID: gen FORM_NUM_MFU = cond(_N==1,1,_n)
	reshape wide MFU* HOSPNUM_MFU FORM_MFU Submit_MFU, i(COUNTRY_NUM DIST_NUM PID) j(FORM_NUM_MFU)
	saveold "MFU_WIDE.dta", replace version(13)

**** Importing MIF form 
	import excel "Outcome_Data_PK.xlsx", firstrow sheet("MIF") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	drop App_Version
	drop USER_CODE TAB_CODE STATUS FW_NUM
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_MIF
	gen FORM_MIF = 1
	rename DT_Submit Submit_MIF
	format Submit_MIF %tC
	format MIF_DT_INTERVIEW %td
**RESHAPE TO WIDE**
	saveold "MIF.dta", replace version(13)
	sort       COUNTRY_NUM DIST_NUM PID MIF_DT_INTERVIEW
	quietly by COUNTRY_NUM DIST_NUM PID: gen FORM_NUM_MIF = cond(_N==1,1,_n)
	reshape wide MIF* HOSPNUM_MIF FORM_MIF Submit_MIF, i(COUNTRY_NUM DIST_NUM PID) j(FORM_NUM_MIF)
	saveold "MIF_WIDE.dta", replace version(13)
	
**** Importing EHS form 
	import excel "Outcome_Data_PK.xlsx", firstrow sheet("EHS") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	drop App_Version
	drop USER_CODE TAB_CODE STATUS FW_NUM
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM DIST_NUM PID EHS_DATE
	quietly by COUNTRY_NUM DIST_NUM PID: gen FORM_NUM_EHS = cond(_N==1,1,_n)
	 log using dup_EHS.log, replace
	 tab FORM_NUM_EHS
	 list PID if FORM_NUM_EHS > 1
     log close
	keep if FORM_NUM_EHS == 1
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_EHS
	gen FORM_EHS = 1
	rename DT_Submit Submit_EHS
	format Submit_EHS %tC
	format EHS_DT_OUTCOME EHS_DATE %td
	saveold "EHS.dta", replace version(13)

**** Importing NFU form 
	import excel "Outcome_Data_PK.xlsx", firstrow sheet("NFU") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	drop App_Version
	drop USER_CODE TAB_CODE STATUS FW_NUM
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM DIST_NUM PID NFU_DT_FILL
	quietly by COUNTRY_NUM DIST_NUM PID: gen FORM_NUM_NFU = cond(_N==1,1,_n)
	 log using dup_NFU.log, replace
	 tab FORM_NUM_NFU
	 list PID if FORM_NUM_NFU > 1
     log close
	keep if FORM_NUM_NFU == 1
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_NFU
	gen FORM_NFU = 1
	rename DT_SUBMIT Submit_NFU
	format  Submit_NFU %tC
	format  NFU_DT_FILL NFU_B1_DEATH_DATE NFU_B2_DEATH_DATE NFU_B3_DEATH_DATE NFU_B4_DEATH_DATE NFU_B5_DEATH_DATE NFU_B6_DEATH_DATE %td
	saveold "NFU.dta", replace version(13)

* COMBINED DATABASE
use "BDF.dta", clear
merge 1:1 PID using "ACS_WIDE.dta", gen(match_DA)
merge 1:1 PID using "MFU_WIDE.dta", gen(match_DAFU)
merge 1:1 PID using "MIF_WIDE.dta", gen(match_DAFUI)
merge 1:1 PID using "EHS.dta",      gen(match_DAFUIE)
merge 1:1 PID using "NFU.dta",      gen(match_DAFUIN)

* Convert string variables to numeric variables
destring *, ignore("NULL") replace 
		
* Save raw data:
saveold "Full_database_Integrated.dta", replace version(13)



*
* * 
* * * 
* * * * 
* * * * *
* * * * * * COMBINE MAIN DATASET WITH FACILITY LIST * * * * * * * * * * * * * * * 
clear
use          "Full_database_Integrated.dta"

* Merge facility list (Facility type and name)
merge n:1 COUNTRY_NUM HOSPNUM_BDF  using "E:\ACSIR Data Management\Phase I\FACILITY_LIST.dta", nogen keepusing(FAC_BDF  HOSPITAL_NAME_BDF)
merge n:1 COUNTRY_NUM HOSPNUM_ACS  using "E:\ACSIR Data Management\Phase I\FACILITY_LIST.dta", nogen keepusing(FAC_ACS  HOSPITAL_NAME_ACS)
merge n:1 COUNTRY_NUM HOSPNUM_ACS1 using "E:\ACSIR Data Management\Phase I\FACILITY_LIST.dta", nogen keepusing(FAC_ACS1 HOSPITAL_NAME_ACS1)
merge n:1 COUNTRY_NUM HOSPNUM_ACS2 using "E:\ACSIR Data Management\Phase I\FACILITY_LIST.dta", nogen keepusing(FAC_ACS2 HOSPITAL_NAME_ACS2)


*
* *
* * * Clean

* Drop no PID
drop if PID == ""

* Change NK/NA/missing dates (9.9.1909 etc.) to missing value (.)
foreach var of varlist *_DT_* *_DATE {
	replace `var'=. if `var' < mdy(1, 1, 2022)
}

*
* *
* * *
* * * *
* * * * * Download/today date

gen TODAY = date(c(current_date), "DMY")
format TODAY %td
label variable TODAY "Date of data download/code run"
tab TODAY
