*clear
*use "Full_database_analysis_Phase I.dta"


*****************************************************
*    Time and Dates: BDF FORMS                
*****************************************************
*
* * 
* * * BDF: Cases where differnce between date of admission and date of register completion is greater than 4 days 

gen DAYS_REG_COM_TO_ADM = BDF_DATE - BDF_DT_DELIVERY

* List Cases with a difference greater than 4 days
	sort YYYY MM
	list YYYY MM PID HOSPITAL_NAME_BDF BDF_DATE  BDF_DT_DELIVERY DAYS_REG_COM_TO_ADM if    	DAYS_REG_COM_TO_ADM > 4 & FORM_BDF==1

***********************************************************
* PATIENT AGE DURING PREGENANCY
***********************************************************
* Women Age
gen WOMEN_AGE= .
	replace WOMEN_AGE = 1 if BDF_AGE >= 14 & BDF_AGE < 20
	replace WOMEN_AGE = 2 if BDF_AGE >= 20 & BDF_AGE < 25
	replace WOMEN_AGE = 3 if BDF_AGE >= 25 & BDF_AGE < 30
	replace WOMEN_AGE = 4 if BDF_AGE >= 30 & BDF_AGE < 35
	replace WOMEN_AGE = 5 if BDF_AGE >= 35 & BDF_AGE < 40
	replace WOMEN_AGE = 6 if BDF_AGE >= 40 & BDF_AGE!=.
label define AGELABEL1  1 "15-19 years" 2 "20-24 years" 3 "25-29 years" 4 "30-34 years" 5 "35-40 years" 6 "40+ years"
	label values WOMEN_AGE AGELABEL1
	
* * Categorizing the Number of Previous Deliveries
gen BDF_CAT_PREVIOUS_DELIVERIES = .

* * Assign categories based on the number of previous deliveries
	replace BDF_CAT_PREVIOUS_DELIVERIES = 1 if BDF_NUM_PRV_DEL == 0  & BDF_NUM_PRV_DEL!=.
	replace BDF_CAT_PREVIOUS_DELIVERIES = 2 if BDF_NUM_PRV_DEL >= 1  & BDF_NUM_PRV_DEL <= 2
	replace BDF_CAT_PREVIOUS_DELIVERIES = 3 if BDF_NUM_PRV_DEL >= 3  & BDF_NUM_PRV_DEL <= 4
	replace BDF_CAT_PREVIOUS_DELIVERIES = 4 if BDF_NUM_PRV_DEL >= 5  & BDF_NUM_PRV_DEL <= 6
	replace BDF_CAT_PREVIOUS_DELIVERIES = 5 if BDF_NUM_PRV_DEL >= 7  & BDF_NUM_PRV_DEL <= 9
	replace BDF_CAT_PREVIOUS_DELIVERIES = 6 if BDF_NUM_PRV_DEL >= 10 & BDF_NUM_PRV_DEL <= 80
replace BDF_CAT_PREVIOUS_DELIVERIES = 8 if BDF_NUM_PRV_DEL == 88 

* * Label the variable and values
label variable BDF_CAT_PREVIOUS_DELIVERIES "Categorizing number of previous deliveries"
label define PREVDELLABEL ///
    1 "1st delivery" ///
    2 "1-2 deliveries" ///
    3 "3-4 deliveries" ///
    4 "5-6 deliveries" ///
    5 "7-9 deliveries" ///
    6 "More than 10 deliveries" ///
    8 "NK (Not Known)"
	label values BDF_CAT_PREVIOUS_DELIVERIES PREVDELLABEL

* Tabulate Patient Age with Number of previous deliveries
tab  WOMEN_AGE  BDF_CAT_PREVIOUS_DELIVERIES 

* Relationship Between Mother's Age and Number of Previous Deliveries"
set scheme white_tableau
	scatter   BDF_NUM_PRV_DEL BDF_AGE if BDF_AGE <80 & BDF_NUM_PRV_DEL<80, ///
	mcolor(blue) msymbol(circle) legend(off) ///
    title("Mother's Age vs. Number of Previous Deliveries", size(medium)) ///
    xlabel(10(2)55) ylabel(0(1)15) ///
    xtitle("Mother Age") ytitle("Number of previous deliveries")

* List women Age < 19 and Deliveries of more than 3-4
	list YYYY MM HOSPITAL_NAME_BDF PID BDF_AGE BDF_NUM_PRV_DEL  if WOMEN_AGE==1 &  BDF_CAT_PREVIOUS_DELIVERIES >=3 & BDF_CAT_PREVIOUS_DELIVERIES !=8

******************************************************************
* WEIGHT TO GESTATIONAL AGE RATIO (WGA) 
******************************************************************

* * Convert gestational age during birth from days to weeks
gen GA_BIRTH_EUSG_WEEKS = floor(GA_BIRTH_EUSG / 7)

** Falg the EUSG GA <26 and >45
list  YYYY MM HOSPITAL_NAME_BDF PID GA_BIRTH_EUSG_WEEKS if GA_BIRTH_EUSG_WEEKS<26
asdoc list  YYYY MM HOSPITAL_NAME_BDF PID BDF_GA_WEEKS BDF_DT_EARLY_USG		BDF_GA_EARLYUSG_WKS BDF_GA_EARLYUSG_DAYS GA_BIRTH_EUSG_WEEKS if GA_BIRTH_EUSG_WEEKS>45 & ~missing(GA_BIRTH_EUSG_WEEKS) & YYYY==2025

* Compute WGA Ratio
gen WGA_RATIO = .
    replace WGA_RATIO= floor(BDF_BIRTH_WEIGHT / GA_BIRTH_EUSG_WEEKS)

	
summarize WGA_RATIO if GA_BIRTH_EUSG_WEEKS >=24 &GA_BIRTH_EUSG_WEEKS <34, detail


histogram WGA_RATIO if GA_BIRTH_EUSG_WEEKS >=24 &GA_BIRTH_EUSG_WEEKS <34 , normal
histogram WGA_RATIO if GA_BIRTH_EUSG_WEEKS >=34 &GA_BIRTH_EUSG_WEEKS <37 , normal
histogram WGA_RATIO if GA_BIRTH_EUSG_WEEKS >=37 & GA_BIRTH_EUSG_WEEKS <=45, normal

* Define WGA thresholds for gestational age categories
gen WGA_FLAG = 0
	replace WGA_FLAG = 1 if GA_BIRTH_EUSG_WEEKS > 26 & GA_BIRTH_EUSG_WEEKS < 28 & (WGA_RATIO < 30 | WGA_RATIO > 35)   // Extreemly Early Preterm
    replace WGA_FLAG = 2 if GA_BIRTH_EUSG_WEEKS > 28 & GA_BIRTH_EUSG_WEEKS < 34 & (WGA_RATIO < 35 | WGA_RATIO > 50)   // Early Preterm
    replace WGA_FLAG = 3 if GA_BIRTH_EUSG_WEEKS >= 34 & GA_BIRTH_EUSG_WEEKS < 37 & (WGA_RATIO <= 50 | WGA_RATIO >= 70) // Late Preterm
    replace WGA_FLAG = 4 if GA_BIRTH_EUSG_WEEKS >= 37 & (WGA_RATIO <= 70 | WGA_RATIO >= 120)  // Term

    * List flagged cases for review
**EEPT
 list YYYY MM HOSPITAL_NAME_BDF PID BDF_BIRTH_WEIGHT GA_BIRTH_EUSG_WEEKS WGA_RATIO if WGA_FLAG==1 & NUM_LIVEBIRTH>0 & YYYY==2025 & MM==4 // EEPT
*EPT
 list YYYY MM HOSPITAL_NAME_BDF PID BDF_BIRTH_WEIGHT GA_BIRTH_EUSG_WEEKS WGA_RATIO if WGA_FLAG==2 & NUM_LIVEBIRTH>0 & YYYY==2025 & MM==4 // EPT
*LPT
 list YYYY MM HOSPITAL_NAME_BDF PID BDF_BIRTH_WEIGHT GA_BIRTH_EUSG_WEEKS WGA_RATIO if WGA_FLAG==3 & NUM_LIVEBIRTH>0 & YYYY==2025 & MM==4 // PT
 *TERM
 list YYYY MM HOSPITAL_NAME_BDF PID BDF_BIRTH_WEIGHT GA_BIRTH_EUSG_WEEKS WGA_RATIO if WGA_FLAG==4 & NUM_LIVEBIRTH>0 & YYYY==2025 & MM==4 // LPT


* DHQ: Plotting the scatter plot for baby weight with gestational age 
twoway ///
    scatter GA_BIRTH_EUSG BDF_BIRTH_WEIGHT if (GA_BIRTH_EUSG >150 & GA_BIRTH_EUSG <238) & BDF_BIRTH_WEIGHT <5000 & HOSPNUM==1 & NUM_LIVEBIRTH>0, ///
        mcolor(pink) msymbol(circle) ///
    || ///
    scatter GA_BIRTH_EUSG BDF_BIRTH_WEIGHT if (GA_BIRTH_EUSG >=238 & GA_BIRTH_EUSG <259) & BDF_BIRTH_WEIGHT <5000 & HOSPNUM==1 & NUM_LIVEBIRTH>0, ///
        mcolor(yellow) msymbol(circle) ///
    || ///
    scatter GA_BIRTH_EUSG BDF_BIRTH_WEIGHT if (GA_BIRTH_EUSG >=259 & GA_BIRTH_EUSG <315) & BDF_BIRTH_WEIGHT <5000 & HOSPNUM==1 & NUM_LIVEBIRTH>0, ///
        mcolor(blue) msymbol(circle) ///
    , ///
    legend(order(1 "GA < 34 Weeks" 2 "GA 34-37 Weeks" 3 "GA ≥ 37 Weeks") position(1) size(small)) ///
    title("DHQ Haripur: Gestational age and birthweight for all livebirths", size(medium)) ///
    xlabel(500(500)5000) ylabel(150(20)350) ///
    xtitle("Birthweight (grams)") ytitle("Gestational age from earliest USG (days)")
	
* Peripheral: Plotting the scatter plot for baby weight with gestational age 
twoway ///
    scatter GA_BIRTH_EUSG BDF_BIRTH_WEIGHT if (GA_BIRTH_EUSG >150 & GA_BIRTH_EUSG <238) & BDF_BIRTH_WEIGHT <5000 & HOSPNUM!=1, ///
        mcolor(pink) msymbol(circle) ///
    || ///
    scatter GA_BIRTH_EUSG BDF_BIRTH_WEIGHT if (GA_BIRTH_EUSG >=238 & GA_BIRTH_EUSG <259) & BDF_BIRTH_WEIGHT <5000 & HOSPNUM!=1, ///
        mcolor(yellow) msymbol(circle) ///
    || ///
    scatter GA_BIRTH_EUSG BDF_BIRTH_WEIGHT if (GA_BIRTH_EUSG >=259 & GA_BIRTH_EUSG <315) & BDF_BIRTH_WEIGHT <5000 & HOSPNUM!=1, ///
        mcolor(blue) msymbol(circle) ///
    , ///
    legend(order(1 "GA < 34 Weeks" 2 "GA 34-37 Weeks" 3 "GA ≥ 37 Weeks") position(1) size(tiny)) ///
    title("DHQ: Gestational Age vs Birthweight", size(medium)) ///
    xlabel(500(500)5000) ylabel(150(20)350) ///
    xtitle("Birthweight (grams)") ytitle("Gestational from earliest USG (days)")

***************************************************************
*                    ANC Visits                                        ***************************************************************
* Generating variable for "ANC Visits"
gen BDF_ANC_VISITS= .
	replace BDF_ANC_VISITS= 0 if BDF_NUM_ANT_VISITS==88
	replace BDF_ANC_VISITS= 1 if BDF_NUM_ANT_VISITS!=. | BDF_NUM_ANT_VISITS!=88
label define ANCVISITSLABEL 0 "NO ANC VISITS DONE" 1 "ANC VISITS DONE"
label values BDF_ANC_VISITS ANCVISITSLABEL


* Generating variable for the availability of EUSG during birth
gen BDF_EUSG_AVAILABILITY=. 
	replace BDF_EUSG_AVAILABILITY=0 if BDF_DT_EARLY_USG==. & FORM_BDF==1
	replace BDF_EUSG_AVAILABILITY=1 if BDF_DT_EARLY_USG!=. & FORM_BDF==1
label variable BDF_EUSG_AVAILABILITY "Availability of EUSG during Birth"
label define BDFEUSGABLABEL 0 "EUSG NOT-AVAILABLE" 1 "EUSG AVAILABLE"
label values BDF_EUSG_AVAILABILITY BDFEUSGABLABEL



* Generating variable for the availability of LMP during birth
gen BDF_LMP_DATE_AVAILABLE=.
	replace BDF_LMP_DATE_AVAILABLE = 0 if BDF_DT_LMP==. & FORM_BDF==1
	replace BDF_LMP_DATE_AVAILABLE = 1 if BDF_DT_LMP!=. & FORM_BDF==1
label define BDFLMPLABEL 0 "LMP DATE NOT-AVAILABLE" 1 "LMP DATE AVAILABLE"
label values BDF_LMP_DATE_AVAILABLE BDFLMPLABEL
	
* * If ANC visits are not done then Earliest ultrasound must not be present
list  YYYY MM HOSPITAL_NAME_BDF PID  BDF_NUM_ANT_VISITS BDF_GA_ASS_METHOD BDF_DT_EARLY_USG if  BDF_ANC_VISITS==0 & BDF_EUSG_AVAILABILITY==1 & FORM_BDF==1

* * If ANC visits are not done then GA Assessment method can't "USG"
list  YYYY MM HOSPITAL_NAME_BDF PID  BDF_NUM_ANT_VISITS BDF_GA_ASS_METHOD BDF_DT_EARLY_USG if  BDF_ANC_VISITS==0 & BDF_GA_ASS_METHOD==1 & FORM_BDF==1

* IF ANC is 0 then trimester must ba not applicable "NA"
list  YYYY MM HOSPITAL_NAME_BDF PID  BDF_NUM_ANT_VISITS BDF_TRIM_1STANC_VISIT if  BDF_ANC_VISITS==0 & BDF_TRIM_1STANC_VISIT<8 & FORM_BDF==1 
 
* IF ANC visits more than 0 then trimester can not be unknown
list  YYYY MM HOSPITAL_NAME_BDF PID  BDF_NUM_ANT_VISITS BDF_TRIM_1STANC_VISIT if  BDF_NUM_ANT_VISITS>0 & BDF_NUM_ANT_VISITS<8 & BDF_TRIM_1STANC_VISIT>=8 & FORM_BDF==1

* Tabulate ANC visits with trimester of first ANC visits
 table BDF_ANC_VISITS BDF_TRIM_1STANC_VISIT,nototal
 table BDF_NUM_ANT_VISITS BDF_TRIM_1STANC_VISIT,nototal
 
******************************************************************
*                     Gestational Age Assessment logics 
*******************************************************************
*
* * USG & EUSG Logics
* Unavailability of EUSG
list  YYYY MM HOSPITAL_NAME_BDF PID  BDF_NUM_ANT_VISITS BDF_GA_ASS_METHOD BDF_DT_EARLY_USG if BDF_EUSG_AVAILABILITY==0 & BDF_NUM_ANT_VISITS!=0 & FORM_BDF==1 & YYYY==2025

* Unavailability of EUSG by Hospital
tab (HOSPITAL_NAME_BDF) (YYYY) if BDF_EUSG_AVAILABILITY==0 & FORM_BDF==1


*GA assessment method is "USG" but earliest usg is not present
list  YYYY MM HOSPITAL_NAME_BDF PID  BDF_NUM_ANT_VISITS  BDF_GA_ASS_METHOD BDF_EUSG_AVAILABILITY  if  BDF_EUSG_AVAILABILITY==0 & BDF_GA_ASS_METHOD==1 & FORM_BDF==1 & YYYY==2025 

* Invalid earliest USG (GA< 26 Weeks & GA> 45 Weeks) 
list  YYYY MM HOSPITAL_NAME_BDF PID BDF_DT_EARLY_USG BDF_GA_EARLYUSG_WKS BDF_GA_EARLYUSG_DAYS GA_BIRTH_EUSG_WEEKS if (GA_BIRTH_EUSG_WEEKS < 26 | GA_BIRTH_EUSG_WEEKS > 45) & BDF_EUSG_AVAILABILITY==1 & FORM_BDF==1 & YYYY==2025 & MM==4

*
* * * LMP DATES
* Unavailability of LMP data
list  YYYY MM HOSPITAL_NAME_BDF PID  BDF_LMP_DATE_AVAILABLE  if  BDF_LMP_DATE_AVAILABLE==0 & FORM_BDF==1

tabstat NUM_LIVEBIRTH BDF_LMP_DATE_AVAILABLE if  YYYY==2025, by(HOSPITAL_NAME_BDF) stat(sum)

* GA assessment method LMP but LMP Data is not available
list  YYYY MM HOSPITAL_NAME_BDF PID BDF_GA_ASS_METHOD BDF_LMP_DATE_AVAILABLE  if  BDF_LMP_DATE_AVAILABLE==0 & BDF_GA_ASS_METHOD==2 & FORM_BDF==1 &  YYYY==2025   

* GA assessment method LMP but EUSG is available
list  YYYY MM HOSPITAL_NAME_BDF PID BDF_NUM_ANT_VISITS BDF_TRIM_1STANC_VISIT BDF_GA_ASS_METHOD BDF_EUSG_AVAILABILITY if BDF_EUSG_AVAILABILITY==1 & BDF_GA_ASS_METHOD==2 &  MM==2 & YYYY==2025 & FORM_BDF==1   


******************************************************************
*Mismatched GA (+/- 7 Days) Between Provider's Assessment and Earliest USG   
***********************************************************************
*
* *
* * * MISMATCHED GA BDF FORM
* Calculate the difference in days between provider's assessment (GA_BIRTH) and earliest USG (GA_BIRTH_EUSG)
gen DIFF_EUSG_PROV_GA= .
	replace DIFF_EUSG_PROV_GA= (GA_BIRTH - GA_BIRTH_EUSG) if 	        		  BDF_EUSG_AVAILABILITY == 1 & FORM_BDF==1

** Create 'Mismatched_GA' flag: 1 
* if the difference is greater than 7 or less than -7 days
gen BDF_MISMACTHED_GA= .
	replace BDF_MISMACTHED_GA = 1 if (DIFF_EUSG_PROV_GA > 7 | DIFF_EUSG_PROV_GA <    -7)  & BDF_EUSG_AVAILABILITY == 1 & FORM_BDF==1

* Tablulate mismatched GA, Hospital with month of birth
tab HOSPITAL_NAME_BDF YYYY if BDF_MISMACTHED_GA== 1

* listing the mismatched cases by month 
list  YYYY MM HOSPITAL_NAME_BDF PID BDF_GA_WEEKS BDF_DT_EARLY_USG		BDF_GA_EARLYUSG_WKS BDF_GA_EARLYUSG_DAYS GA_BIRTH_EUSG_WEEKS       DIFF_EUSG_PROV_GA if BDF_MISMACTHED_GA== 1 & YYYY==2025 & MM==4



*************************************
*     ACS FORM
*************************************
*
* *

* Computing variables for availability of EUSG and conersions

* Generating variable for the availability of EUSG during ACS Administration
gen ACS_EUSG_AVAILABILITY=. 
	replace ACS_EUSG_AVAILABILITY=0 if ACS_DT_EARLY_USG1==. & FORM_ACS1==1
	replace ACS_EUSG_AVAILABILITY=1 if ACS_DT_EARLY_USG1!=. & FORM_ACS1==1
label variable ACS_EUSG_AVAILABILITY "Availability of EUSG during ACS Administration for the course 1"
label values ACS_EUSG_AVAILABILITY BDFEUSGABLABEL

* Convert gestational age during birth from days to weeks
gen GA_ACS_EUSG_WEEKS =.
	replace GA_ACS_EUSG_WEEKS = floor(GA_ACS_EUSG / 7) if ACS_EUSG_AVAILABILITY == 1 & FORM_ACS1==1 


********************************
* * * MISMATCHED GA IN ACS FORM
*******************************

* Calculate the difference in days between provider's assessment (GA_ACS_DAY) and earliest USG (GA_ACS_EUSG)

gen DIFF_ACS_EUSG_PROV_GA= .
	replace DIFF_ACS_EUSG_PROV_GA = (GA_ACS_DAY- GA_ACS_EUSG) if 	        		  ACS_EUSG_AVAILABILITY == 1 & FORM_ACS1==1 

** Create 'Mismatched_GA' flag: 1 
* if the difference is greater than 7 or less than -7 days
gen ACS_MISMACTHED_GA= .
	replace ACS_MISMACTHED_GA = 1 if (DIFF_ACS_EUSG_PROV_GA > 7 | DIFF_ACS_EUSG_PROV_GA <-7)  & ACS_EUSG_AVAILABILITY == 1 & FORM_ACS1==1
	
	
* Listing the mismatched cases by month 
list  ACS_YYYY ACS_MM HOSPITAL_NAME_ACS1 PID ACS_GA_ADM_WEEKS1 ACS_DT_EARLY_USG1 ACS_GA_EARLYUSG_WKS1 ACS_GA_EARLYUSG_DAYS1 GA_ACS_EUSG_WEEKS DIFF_ACS_EUSG_PROV_GA if ACS_MISMACTHED_GA== 1 & 	ACS_YYYY==2025


*****************************************************
** DISCREPENCIES BETWEEN EUSG ACROSS BDF & ACS FORM
*****************************************************

* Listing Cases where EUSG at ACS is after Birth EUSG
list  ACS_YYYY ACS_MM HOSPITAL_NAME_ACS1 PID  ACS_DT_EARLY_USG1 BDF_DT_EARLY_USG if GA_EUSG_AB==0 & ACS_YYYY==2025

* Listing Cases where EUSG at BIRTH is after ACS EUSG
list  ACS_YYYY ACS_MM HOSPITAL_NAME_ACS1 PID  ACS_DT_EARLY_USG1 BDF_DT_EARLY_USG if GA_EUSG_AB==1 & ACS_YYYY==2025

* Listing Cases where EUSG is present during ACS Administration but unavailable during birth
list  ACS_YYYY ACS_MM HOSPITAL_NAME_ACS1 PID  ACS_DT_EARLY_USG1 BDF_DT_EARLY_USG  if GA_EUSG_AB==2 & ACS_YYYY==2025 & FORM_BDF==1

* Listing Cases where EUSG is present during  birth but unavailable during  ACS Administration 
list  ACS_YYYY ACS_MM HOSPITAL_NAME_ACS1 PID  ACS_DT_EARLY_USG1 BDF_DT_EARLY_USG if GA_EUSG_AB==3

* * Lisiting Cases where days between ACS dose and delivery date is greater than 7 days
list ACS_YYYY ACS_MM HOSPITAL_NAME_ACS PID ACS_DT DEL_DT ACS_TO_DEL_DAY_TIME if FULL_DAYS_ACS_TO_DEL>7 & FORM_ACS1==1 & FORM_BDF==1


****************************************
* Tocolytics Administration 
****************************************

* * List all those cases for Tocolytics Usage
list ACS_YYYY ACS_MM PID ACS_CLINICAL_INDIC1 ACS_TOCOLYTICS1 if GA_ACS_CAT_COR==1 & HOSPNUM_ACS1==1 & ACS_YYYY==2025

* Tabulation of Tocolytics Administration with clinical indication for ACS Administration
table (ACS_TOCOLYTICS1 ) (ACS_CLINICAL_INDIC1) if GA_ACS_CAT_COR==1 & HOSPNUM_ACS1==1 & ACS_YYYY==2025 & ACS_MM==4

* * List all the Livebirth EPTs who were not tocolytized along with ACS 
list YYYY MM PID ACS_CLINICAL_INDIC1 ACS_TOCOLYTICS1 ACS_DT DEL_DT  ACS_TO_DEL_DAY_TIME  if GA_BIRTH_CAT_COR==1 & HOSPNUM_BDF==1 &  ACS_YYYY==2025 & ACS_MM==4 & FORM_ACS1==1 & FORM_BDF==1

** Tabulation of Tocolytics with ACS_Dose1 to delivery (date+time)
tab ACS_TO_DEL_DAY_TIME ACS_TOCOLYTICS1 if GA_ACS_CAT_COR==1 & FORM_ACS1==1 & FORM_BDF==1 & HOSPNUM_ACS1==1 & ACS_MM==2 & ACS_YYYY==2025
