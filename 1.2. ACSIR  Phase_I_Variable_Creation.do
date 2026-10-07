*************************************
** ACS-IR Phase 1: ANALYSIS VARIABLE CREATION **
*************************************

*  Stata version:  17.0 (Data saved as Stata 13 version to allow use in Stata 13 - replace 'saveold...version(13)' with 'save' if wanted)
* Legacy editors:  Nicole MINCKAS, Juha PYYKKO, Kayleigh RYAN (WHO Geneva)
* Latest editor :  Aurangzeb
* Desigination  :  Data Associate (PHC Global Pakistan)
* Code version  :  2025-02-18*
* *
* * * 
gen HOSPNUM = HOSPNUM_BDF
		
* FACILITY CATEGORIZATION:	
gen     facility_type_del = .
replace facility_type_del = 1 if FAC_BDF == "ACS-IF"    // From FACILITY_LIST
replace facility_type_del = 2 if FAC_BDF == "NAF"
replace facility_type_del = 2 if FAC_BDF == "PRF"

gen     facility_type_acs = .
replace facility_type_acs = 1 if FAC_ACS == "ACS-IF"
replace facility_type_acs = 2 if FAC_ACS == "NAF"
replace facility_type_acs = 2 if FAC_ACS == "PRF"

label define FACILITY2 1 "ACS-IF" 2 "Non-ACS"
label values facility_type_del FACILITY2
label values facility_type_acs FACILITY2

gen            ACS_IF = facility_type_del
label define   ACS_IF  1 "ACS-IR Facility" 2 "Peripheral Facility"
label values   ACS_IF ACS_IF
label variable ACS_IF "Facility type BDF"

*
* *
* * * TIMELINE: BDF

* PERIOD DELIVERY: creating the month/year date
gen       YYYY =    year(BDF_DT_DELIVERY) 
gen         MM =   month(BDF_DT_DELIVERY)
gen     YYYYMM = ym(year(BDF_DT_DELIVERY), month(BDF_DT_DELIVERY))
format  YYYYMM %tm

* QUARTER BDF
gen     QUARTER = .
replace QUARTER = . if YYYY == 2023 &  MM == 12  // late December in BD/PK excluded from the timeline to match the start with ET/NG
replace QUARTER = 1 if YYYY == 2024 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 2 if YYYY == 2024 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 3 if YYYY == 2024 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 4 if YYYY == 2024 & (MM == 10 | MM == 11 | MM == 12)
replace QUARTER = 5 if YYYY == 2025 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 6 if YYYY == 2025 & (MM ==  4 | MM ==  5 | MM ==  6)


*
* *
* * * TIMELINE: ACS

* PERIOD ACS Dose1: creating the month/year date
gen       ACS_YYYY =    year(ACS_DT_DOSE11) 
gen         ACS_MM =    month(ACS_DT_DOSE11)
gen     ACS_YYYYMM =    ym(year(ACS_DT_DOSE11), month(ACS_DT_DOSE11))
format  ACS_YYYYMM %tm

* QUARTER ACS
gen     QUARTER_ACS = .
replace QUARTER_ACS = . if ACS_YYYY == 2023 &  ACS_MM == 12  // late December in BD/PK excluded from the timeline to match the start with ET/NG
replace QUARTER_ACS = 1 if ACS_YYYY == 2024 & (ACS_MM ==  1 | ACS_MM ==  2 | ACS_MM ==  3)
replace QUARTER_ACS = 2 if ACS_YYYY == 2024 & (ACS_MM ==  4 | ACS_MM ==  5 | ACS_MM ==  6)
replace QUARTER_ACS = 3 if ACS_YYYY == 2024 & (ACS_MM ==  7 | ACS_MM ==  8 | ACS_MM ==  9)
replace QUARTER_ACS = 4 if ACS_YYYY == 2024 & (ACS_MM == 10 | ACS_MM == 11 | ACS_MM == 12)
replace QUARTER_ACS = 5 if ACS_YYYY == 2025 & (ACS_MM ==  1 | ACS_MM ==  2 | ACS_MM ==  3)
replace QUARTER_ACS = 6 if ACS_YYYY == 2025 & (ACS_MM ==  4 | ACS_MM ==  5 | ACS_MM ==  6)
*
* *
* * * TIMES

* Error handling, missing time, save original for reference:
gen BDF_TM_DELIVERY_HH_original = BDF_TM_DELIVERY_HH
gen BDF_TM_DELIVERY_MM_original = BDF_TM_DELIVERY_MM

gen BDF_TM_ADM_HH_original = BDF_TM_ADM_HH
gen BDF_TM_ADM_MM_original = BDF_TM_ADM_MM

gen ACS_TM_DOSE1_HH1_original = ACS_TM_DOSE1_HH1
gen ACS_TM_DOSE1_MM1_original = ACS_TM_DOSE1_MM1

** RECODE MISSING HH:MM: delivery to end of day
replace BDF_TM_DELIVERY_HH = 23 if BDF_DT_DELIVERY != . & (BDF_TM_DELIVERY_HH > 23 | BDF_TM_DELIVERY_HH == .)
replace BDF_TM_DELIVERY_MM = 59 if BDF_DT_DELIVERY != . & (BDF_TM_DELIVERY_MM > 59 | BDF_TM_DELIVERY_MM == .)

** RECODE MISSING HH:MM: admission to start of day
replace BDF_TM_ADM_HH = 0 if BDF_DT_DELIVERY != . & (BDF_TM_ADM_HH > 23 | BDF_TM_ADM_HH == .)
replace BDF_TM_ADM_MM = 0 if BDF_DT_DELIVERY != . & (BDF_TM_ADM_MM > 59 | BDF_TM_ADM_MM == .)

** RECODE MISSING HH:MM: ACS administration to start of day
replace ACS_TM_DOSE1_HH1 = 0 if ACS_DT_DOSE11 != . & (ACS_TM_DOSE1_HH1 > 23 | ACS_TM_DOSE1_HH1 == .)
replace ACS_TM_DOSE1_MM1 = 0 if ACS_DT_DOSE11 != . & (ACS_TM_DOSE1_MM1 > 59 | ACS_TM_DOSE1_MM1 == .)

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
gen double     ACS_TIME = hms(ACS_TM_DOSE1_HH1,ACS_TM_DOSE1_MM1,0)
format %tcHH   ACS_TIME
label variable ACS_TIME "ACS Dose 1, Course 1, time"

** Administration (Course 1) date+time
gen double     ACS_DT = cofd(ACS_DT_DOSE11) + ACS_TIME
format         ACS_DT %tcNN/DD/CCYY_HH:MM
label variable ACS_DT "ACS Dose 1, Course 1, date and time"


* *
* * * * TIME DIFFERENCES

* Calculating time between admission and delivery (days+hours)
gen            DAYS_ADM_TO_DEL = (DEL_DT- ADM_DT)/ 864e5 
label variable DAYS_ADM_TO_DEL "Days from admission to delivery (including hours and minutes)"

* Extract full days
gen FULL_DAYS_ADM_TO_DEL = floor(DAYS_ADM_TO_DEL)
label variable FULL_DAYS_ADM_TO_DEL "Full days from admission to delivery"

* Extract remaining hours
gen HOURS_DAYS_ADM_TO_DEL = floor(mod(DEL_DT - ADM_DT, 864e5) / 3600000)
label variable HOURS_DAYS_ADM_TO_DEL "Remaining hours after full days"

* Extract remaining minutes
gen MINUTES_DAYS_ADM_TO_DEL = floor(mod(DEL_DT - ADM_DT, 3600000) / 60000)
label variable MINUTES_DAYS_ADM_TO_DEL "Remaining minutes after full hours"

* Generate human-readable format
gen ADMIS_TO_DEL_DAY_TIME = string(FULL_DAYS_ADM_TO_DEL) + " full day(s) and (~" + ///
                                 string(HOURS_DAYS_ADM_TO_DEL) + " hours, " + ///
                                 string(MINUTES_DAYS_ADM_TO_DEL) + " minutes)"
label variable ADMIS_TO_DEL_DAY_TIME "Formatted time from admission to delivery"

*
* *
* Calculating time between ACS administration and delivery
gen            DAYS_ACS_TO_DEL = (DEL_DT  - ACS_DT)/ 864e5 
label variable DAYS_ACS_TO_DEL "Days from Dose 1 to delivery (including hours and minutes)"

* Extract full days
gen FULL_DAYS_ACS_TO_DEL = floor(DAYS_ACS_TO_DEL)
label variable FULL_DAYS_ADM_TO_DEL "Full days from ACS Administration to delivery"

* Extract remaining hours
gen HOURS_DAYS_ACS_TO_DEL = floor(mod(DEL_DT - ACS_DT, 864e5) / 3600000)
label variable HOURS_DAYS_ACS_TO_DEL "Remaining hours after full days"

* Extract remaining minutes
gen MINUTES_DAYS_ACS_TO_DEL = floor(mod(DEL_DT - ACS_DT, 3600000) / 60000)
label variable MINUTES_DAYS_ACS_TO_DEL "Remaining minutes after full hours"

* Generate human-readable format
gen ACS_TO_DEL_DAY_TIME = string(FULL_DAYS_ACS_TO_DEL) + " full day(s) and (~" + ///
                                 string(HOURS_DAYS_ACS_TO_DEL) + " hours, " + ///
                                 string(MINUTES_DAYS_ACS_TO_DEL) + " minutes)"
label variable ADMIS_TO_DEL_DAY_TIME "Formatted time from ACS Administration to delivery"


* Days from delivery to discharge
gen            DAYS_FROM_DEL_TO_DISCHARGE = EHS_DT_OUTCOME - BDF_DT_DELIVERY if FORM_EHS == 1 & FORM_BDF == 1
label variable DAYS_FROM_DEL_TO_DISCHARGE "Days from delivery to discharge"

* Days from admission to delivery
gen            DAYS_FROM_ADM_TO_DEL = BDF_DT_DELIVERY - BDF_DT_ADM if FORM_BDF == 1
label variable DAYS_FROM_ADM_TO_DEL "Days from admission to delivery"

* Days from administration to delivery
gen            DAYS_FROM_ACS_TO_DEL = BDF_DT_DELIVERY - ACS_DT_DOSE11 if FORM_BDF == 1 & FORM_ACS1 == 1
label variable DAYS_FROM_ACS_TO_DEL "Days from 1st ACS to delivery"

*
* *
* * * Error handling: Invalid early USG date (after delivery or dose)

gen USG_TO_ACS = ACS_DT_DOSE11   - ACS_DT_EARLY_USG1 if ACS_DT_DOSE11   != . & ACS_DT_EARLY_USG1 != .
gen USG_TO_BDF = BDF_DT_DELIVERY - BDF_DT_EARLY_USG  if BDF_DT_DELIVERY != . & BDF_DT_EARLY_USG  != .

label variable USG_TO_ACS "Days from ACS EUSG to ACS dose 1"
label variable USG_TO_BDF "Days from BDF EUSG to delivery"

/* Export cases for review:
  keep if (USG_TO_ACS < 0 & USG_TO_ACS != .) | (USG_TO_BDF < 0 & USG_TO_BDF != .)
  order COUNTRY PID USG_TO_BDF BDF_DT_DELIVERY BDF_DT_EARLY_USG USG_TO_ACS     ACS_DT_DOSE11 ACS_DT_EARLY_USG1 
  replace USG_TO_BDF = . if USG_TO_BDF >= 0
  replace USG_TO_ACS = . if USG_TO_ACS >= 0
  sort COUNTRY USG_TO_BDF USG_TO_ACS
  saveold "ACSIR_EUSG_AFTER_DOSE_OR_DELIVERY.dta", replace version(13) */
  
  * Recode to missing if EUSG done after ACS dose
replace ACS_DT_EARLY_USG1     = . if USG_TO_ACS < 0 & USG_TO_ACS != .
replace ACS_GA_EARLYUSG_WKS1  = . if USG_TO_ACS < 0 & USG_TO_ACS != .
replace ACS_GA_EARLYUSG_DAYS1 = . if USG_TO_ACS < 0 & USG_TO_ACS != .

* Recode to missing if EUSG done after delivery
replace BDF_DT_EARLY_USG      = . if USG_TO_BDF < 0 & USG_TO_BDF != .
replace BDF_GA_EARLYUSG_WKS   = . if USG_TO_BDF < 0 & USG_TO_BDF != .
replace BDF_GA_EARLYUSG_DAYS  = . if USG_TO_BDF < 0 & USG_TO_BDF != .


*
* *
* * * GA at Early USG

gen     EARLYUSG_BDF_DAYS = BDF_GA_EARLYUSG_WKS * 7 if BDF_GA_EARLYUSG_WKS < 60 
replace EARLYUSG_BDF_DAYS = EARLYUSG_BDF_DAYS + BDF_GA_EARLYUSG_DAYS if BDF_GA_EARLYUSG_DAYS < 8
label variable EARLYUSG_BDF_DAYS "Gestational age in days at earliest USG (BDF)"

gen     EARLYUSG_ACS_DAYS = ACS_GA_EARLYUSG_WKS1 * 7 if ACS_GA_EARLYUSG_WKS1 < 60 
replace EARLYUSG_ACS_DAYS = EARLYUSG_ACS_DAYS + ACS_GA_EARLYUSG_DAYS1 if ACS_GA_EARLYUSG_DAYS1 < 8
label variable EARLYUSG_ACS_DAYS "Gestational age in days at earliest USG ACS course 1"

*
* *
* * * EARLIEST USG BEFORE 24 WEEKS (WHO preference over trimesters)

gen     EARLYUSG_BDF_24 = .
replace EARLYUSG_BDF_24 = 1 if EARLYUSG_BDF_DAYS   < 24*7
replace EARLYUSG_BDF_24 = 2 if EARLYUSG_BDF_DAYS  >= 24*7
replace EARLYUSG_BDF_24 = 9 if EARLYUSG_BDF_DAYS  == . & FORM_BDF == 1
replace EARLYUSG_BDF_24 = . if EARLYUSG_BDF_DAYS  == . & FORM_BDF != 1
label variable EARLYUSG_BDF_24 "Timing of Earliest USG in BDF (24 weeks)"

gen     EARLYUSG_ACS_24 = .
replace EARLYUSG_ACS_24 = 1 if EARLYUSG_ACS_DAYS   < 24*7
replace EARLYUSG_ACS_24 = 2 if EARLYUSG_ACS_DAYS  >= 24*7
replace EARLYUSG_ACS_24 = 9 if EARLYUSG_ACS_DAYS  == . & FORM_ACS1 == 1
replace EARLYUSG_ACS_24 = . if EARLYUSG_ACS_DAYS  == . & FORM_ACS1 != 1
label variable EARLYUSG_ACS_24 "Timing of Earliest USG in ACS (24 weeks)"

label define USG24 1 "USG <24 weeks" 2 "USG ≥24 weeks" 9 "No USG"
label values EARLYUSG_BDF_24 USG24
label values EARLYUSG_ACS_24 USG24

*
* *
* * *
* * * * GA at birth (days)

gen     GA_BIRTH = BDF_GA_WEEKS * 7       if BDF_GA_WEEKS < 60 & FORM_BDF==1
replace GA_BIRTH = GA_BIRTH + BDF_GA_DAYS if BDF_GA_DAYS  < 8  & FORM_BDF==1

label variable GA_BIRTH "Gestational age in days at birth using provider estimate"

gen     GA_BIRTH_EUSG = (BDF_DT_DELIVERY - BDF_DT_EARLY_USG) + EARLYUSG_BDF_DAYS  if FORM_BDF==1

label variable GA_BIRTH_EUSG "Gestational age in days at birth using the earliest USG"

gen     GA_BIRTH_ACS_EUSG = ACS_GA_EARLYUSG_WKS1 * 7  if ACS_GA_EARLYUSG_WKS1 < 60 & FORM_BDF==1
replace GA_BIRTH_ACS_EUSG = GA_BIRTH_ACS_EUSG + ACS_GA_EARLYUSG_DAYS1  if ACS_GA_EARLYUSG_DAYS1 < 8 & FORM_BDF==1
replace GA_BIRTH_ACS_EUSG = BDF_DT_DELIVERY - ACS_DT_EARLY_USG1 + GA_BIRTH_ACS_EUSG if FORM_BDF==1
replace GA_BIRTH_ACS_EUSG = . if ACS_DT_EARLY_USG1 == .

label variable GA_BIRTH_ACS_EUSG "Gestational age in days at birth using the earliest USG from ACS course 1"

*
* *
* * *
* * * * GA at birth (days) [corrected from ACS if not feasible in BDF]
* Replace BDF EUSG if BDF EUSG is not viable or ACS USG is earlier date & viable

* * * The earliest USG available (ACS1 vs BDF)

gen     GA_EUSG_AB = .
replace GA_EUSG_AB = 0 if ACS_DT_EARLY_USG1 > BDF_DT_EARLY_USG
replace GA_EUSG_AB = 1 if ACS_DT_EARLY_USG1 < BDF_DT_EARLY_USG
replace GA_EUSG_AB = 2 if ACS_DT_EARLY_USG1 != . & BDF_DT_EARLY_USG == .
replace GA_EUSG_AB = 3 if ACS_DT_EARLY_USG1 == . & BDF_DT_EARLY_USG != .
replace GA_EUSG_AB = 4 if ACS_DT_EARLY_USG1 == BDF_DT_EARLY_USG
replace GA_EUSG_AB = . if FORM_ACS1 != 1

label variable GA_EUSG_AB "Comparison of EUSG at BDF & ACS1"
label define   GA_EUSG_AB 0 "EUSG at ACS later than EUSG at birth" 1 "EUSG at ACS earlier than EUSG at birth" 2 "Earliest USG only recorded at ACS" 3 "Earliest USG only recorded at birth" 4 "Same Earliest USG date on ACS and BDF"
label values GA_EUSG_AB GA_EUSG_AB

gen     GA_BIRTH_COR_EUSG = GA_BIRTH_EUSG
replace GA_BIRTH_COR_EUSG = GA_BIRTH_ACS_EUSG if GA_BIRTH_EUSG  < 26*7 & GA_BIRTH_ACS_EUSG != .
replace GA_BIRTH_COR_EUSG = GA_BIRTH_ACS_EUSG if GA_BIRTH_EUSG >= 45*7 & GA_BIRTH_ACS_EUSG != .
replace GA_BIRTH_COR_EUSG = GA_BIRTH_ACS_EUSG if GA_EUSG_AB == 2
replace GA_BIRTH_COR_EUSG = GA_BIRTH_ACS_EUSG if GA_EUSG_AB == 1 & GA_BIRTH_ACS_EUSG >= 26*7 & GA_BIRTH_ACS_EUSG < 45*7
replace GA_BIRTH_COR_EUSG = . if FORM_BDF != 1

label variable GA_BIRTH_COR_EUSG "Corrected delivery GA EUSG"

*
* *
* * *
* * * * GA at birth (category)

gen     GA_BIRTH_CAT = .
replace GA_BIRTH_CAT = 1 if GA_BIRTH >= 26*7 & GA_BIRTH < 34*7  // 34*7 = 238
replace GA_BIRTH_CAT = 2 if GA_BIRTH >= 34*7 & GA_BIRTH < 37*7  // 37*7 = 259
replace GA_BIRTH_CAT = 3 if GA_BIRTH >= 37*7 & GA_BIRTH < 45*7  // 45*7 = 315
replace GA_BIRTH_CAT = 9 if GA_BIRTH >= 45*7
replace GA_BIRTH_CAT = 9 if GA_BIRTH <  26*7                    // 26*7 = 182
replace GA_BIRTH_CAT = 9 if GA_BIRTH == .
replace GA_BIRTH_CAT = . if FORM_BDF != 1

label variable GA_BIRTH_CAT "Gestational age category at birth from provider BDF"

gen     GA_BIRTH_CATU = .
replace GA_BIRTH_CATU = 1 if GA_BIRTH_EUSG >= 26*7 & GA_BIRTH_EUSG < 34*7
replace GA_BIRTH_CATU = 2 if GA_BIRTH_EUSG >= 34*7 & GA_BIRTH_EUSG < 37*7
replace GA_BIRTH_CATU = 3 if GA_BIRTH_EUSG >= 37*7 & GA_BIRTH_EUSG < 45*7
replace GA_BIRTH_CATU = 9 if GA_BIRTH_EUSG >= 45*7
replace GA_BIRTH_CATU = 9 if GA_BIRTH_EUSG  < 26*7
replace GA_BIRTH_CATU = 9 if GA_BIRTH_EUSG == .
replace GA_BIRTH_CATU = . if FORM_BDF != 1

label variable GA_BIRTH_CATU "Gestational age category at birth from earliest USG in BDF"

gen     GA_BIRTH_ACS_CATU = .
replace GA_BIRTH_ACS_CATU = 1 if GA_BIRTH_ACS_EUSG >= 26*7 & GA_BIRTH_ACS_EUSG < 34*7
replace GA_BIRTH_ACS_CATU = 2 if GA_BIRTH_ACS_EUSG >= 34*7 & GA_BIRTH_ACS_EUSG < 37*7
replace GA_BIRTH_ACS_CATU = 3 if GA_BIRTH_ACS_EUSG >= 37*7 & GA_BIRTH_ACS_EUSG < 45*7
replace GA_BIRTH_ACS_CATU = 9 if GA_BIRTH_ACS_EUSG >= 45*7
replace GA_BIRTH_ACS_CATU = 9 if GA_BIRTH_ACS_EUSG <  26*7
replace GA_BIRTH_ACS_CATU = 9 if GA_BIRTH_ACS_EUSG == .
replace GA_BIRTH_ACS_CATU = . if FORM_BDF != 1

label variable GA_BIRTH_ACS_CATU "Gestational age category at birth from earliest USG in ACS 1"

label define BIRTH_CAT 1 "26+0 - 33+6" 2 "34+0 - 36+6" 3 "37+0 - 44+6" 9 "NK/NA"
label values GA_BIRTH_CAT            BIRTH_CAT
label values GA_BIRTH_CATU           BIRTH_CAT
label values GA_BIRTH_ACS_CATU       BIRTH_CAT

gen     GA_BIRTH_CAT_COR = .    // COR: GA_BIRTH_CAT_EUSG
replace GA_BIRTH_CAT_COR = 1 if GA_BIRTH_COR_EUSG >= 26*7 & GA_BIRTH_COR_EUSG < 34*7
replace GA_BIRTH_CAT_COR = 2 if GA_BIRTH_COR_EUSG >= 34*7 & GA_BIRTH_COR_EUSG < 37*7
replace GA_BIRTH_CAT_COR = 3 if GA_BIRTH_COR_EUSG >= 37*7 & GA_BIRTH_COR_EUSG < 45*7
replace GA_BIRTH_CAT_COR = 7 if GA_BIRTH_COR_EUSG <  26*7
replace GA_BIRTH_CAT_COR = 8 if GA_BIRTH_COR_EUSG >= 45*7
replace GA_BIRTH_CAT_COR = 9 if GA_BIRTH_COR_EUSG == .
replace GA_BIRTH_CAT_COR = . if FORM_BDF != 1

label variable GA_BIRTH_CAT_COR "Gestational age category at birth by earliest USG from BDF, or ACS1 if earlier"

label define GA_BIRTH_CAT_COR 1 "26+0 - 33+6" 2 "34+0 - 36+6" 3 "37+0 - 44+6" 7 "<26+0" 8 "≥45+0" 9 "NK"
label values GA_BIRTH_CAT_COR GA_BIRTH_CAT_COR


*
* *
* * * ACS (days)

gen     GA_ACS_DAY = ACS_GA_ADM_WEEKS1 * 7         if ACS_GA_ADM_WEEKS1 < 60
replace GA_ACS_DAY = GA_ACS_DAY + ACS_GA_ADM_DAYS1 if ACS_GA_ADM_DAYS1 < 8
label variable GA_ACS_DAY "Gestational age in days at dose1 course1, provider"

gen     GA_ACS_EUSG = ACS_DT_DOSE11 - ACS_DT_EARLY_USG1 + EARLYUSG_ACS_DAYS
label variable GA_ACS_EUSG "Gestational age in days at ACS dose 1 course 1 using the earliest USG"

* If the earliest ultrasound information is recorded incorrectly on the ACS form 
* (beyond limits of biological viability at birth (<24 weeks or >45 weeks), 
* use the alternative earliest ultrasound from the birth register to calculate a GA at time of ACS.
gen     GA_ACS_COR_EUSG = GA_ACS_EUSG
replace GA_ACS_COR_EUSG = GA_BIRTH_COR_EUSG - (BDF_DT_DELIVERY - ACS_DT_DOSE11) if GA_ACS_EUSG     < 24*7 | GA_ACS_EUSG     >= 45*7
replace GA_ACS_COR_EUSG = .                                                     if GA_ACS_COR_EUSG < 24*7 | GA_ACS_COR_EUSG >= 45*7

*
* *
* * * ACS (category)

gen     GA_ACS_CAT = .
replace GA_ACS_CAT = 1 if GA_ACS_DAY >= 24*7 & GA_ACS_DAY < 34*7
replace GA_ACS_CAT = 2 if GA_ACS_DAY >= 34*7 & GA_ACS_DAY < 37*7
replace GA_ACS_CAT = 3 if GA_ACS_DAY >= 37*7 & GA_ACS_DAY < 45*7
replace GA_ACS_CAT = 9 if GA_ACS_DAY >= 45*7
replace GA_ACS_CAT = 9 if GA_ACS_DAY  < 24*7
replace GA_ACS_CAT = 9 if GA_ACS_DAY == .
replace GA_ACS_CAT = . if FORM_ACS1 != 1

label variable GA_ACS_CAT "Gestational age provider at dose 1, course 1"

gen     GA_ACS_CATU = .
replace GA_ACS_CATU = 1 if GA_ACS_EUSG >= 24*7 & GA_ACS_EUSG < 34*7 
replace GA_ACS_CATU = 2 if GA_ACS_EUSG >= 34*7 & GA_ACS_EUSG < 37*7 
replace GA_ACS_CATU = 3 if GA_ACS_EUSG >= 37*7 & GA_ACS_EUSG < 45*7 
replace GA_ACS_CATU = 9 if GA_ACS_EUSG >= 45*7 
replace GA_ACS_CATU = 9 if GA_ACS_EUSG  < 24*7 
replace GA_ACS_CATU = 9 if GA_ACS_EUSG == .
replace GA_ACS_CATU = . if FORM_ACS1 != 1

label variable GA_ACS_CATU "Gestational age at ACS 1 from earliest USG"

gen     GA_ACS_CAT_COR = .
replace GA_ACS_CAT_COR = 1 if GA_ACS_COR_EUSG >= 24*7 & GA_ACS_COR_EUSG < 34*7 
replace GA_ACS_CAT_COR = 2 if GA_ACS_COR_EUSG >= 34*7 & GA_ACS_COR_EUSG < 37*7 
replace GA_ACS_CAT_COR = 3 if GA_ACS_COR_EUSG >= 37*7 & GA_ACS_COR_EUSG < 45*7 
replace GA_ACS_CAT_COR = 9 if GA_ACS_COR_EUSG >= 45*7 
replace GA_ACS_CAT_COR = 9 if GA_ACS_COR_EUSG  < 24*7
replace GA_ACS_CAT_COR = 9 if GA_ACS_COR_EUSG == .
replace GA_ACS_CAT_COR = . if FORM_ACS1 != 1

label variable GA_ACS_CAT_COR "Gestational age category at ACS by earliest USG from ACS, or BDF if ACS not viable"

* Labels for GA cat
label define ACS_CAT 1 "24+0 - 33+6" 2 "34+0 - 36+6" 3 "37+0 - 44+6" 9 "NK/NA"

label values GA_ACS_CAT       ACS_CAT
label values GA_ACS_CATU      ACS_CAT
label values GA_ACS_CAT_COR   ACS_CAT

*
* *
* * * CORRECTED WEEKS+DAYS

* Delivery Gestation Age (DGA) based on Corrected Earliest USG (EUSG) from BDF as WEEKS+DAYS
gen            DGA_WEEKS = .
replace        DGA_WEEKS = floor(GA_BIRTH_COR_EUSG/7)
label variable DGA_WEEKS "DGA Corrected EUSG weeks (BDF)"

gen            DGA_DAYS = .
replace        DGA_DAYS = GA_BIRTH_COR_EUSG - DGA_WEEKS*7
label variable DGA_DAYS "DGA Corrected EUSG days (BDF)"

* Gestation Age at ACS based on Corrected Earliest USG (EUSG) from ACS as WEEKS+DAYS
gen            ACS_WEEKS = .
replace        ACS_WEEKS = floor(GA_ACS_COR_EUSG/7)
label variable ACS_WEEKS "ACS GA EUSG weeks"

gen            ACS_DAYS = .
replace        ACS_DAYS = GA_ACS_COR_EUSG - ACS_WEEKS*7
label variable ACS_DAYS "ACS GA EUSG days"


*
* *
* * *
* Calculating EPTs from provider estimates, EUSG and corrected EUSG
/*gen PROV_EPT=. 
replace PROV_EPT=1 if GA_BIRTH_CAT==1 & FORM_BDF==1  

gen EUSG_EPT= .
replace EUSG_EPT=1 if  GA_BIRTH_CATU==1 & FORM_BDF==1
replace EUSG_EPT=provider_ept if  BDF_DT_EARLY_USG==. & FORM_BDF==1

tabstat provider_ept EUSG_EPT EPT, by(QUARTER) stat(Sum)
*/

*
* *
* * * ACS given anywhere:

gen     ACS_ADMINISTRATION = .
replace ACS_ADMINISTRATION = 1 if ACS_DOSE1_GIVEN1 == 1 | ACS_DOSE2_GIVEN1 == 1 | ACS_DOSE3_GIVEN1 == 1 | ACS_DOSE4_GIVEN1 == 1 | EHS_CORTICOSTEROIDS == 1

label variable ACS_ADMINISTRATION "ACS received anywhere"

*
* * 
* * *
* * * Number of livebirths
gen byte NUM_LIVEBIRTH = 0 if FORM_BDF == 1
replace NUM_LIVEBIRTH = 1                 if BDF_BIRTH_STATUS1 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS2 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS3 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS4 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS5 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS6 == 1

replace NUM_LIVEBIRTH = 0 if missing(NUM_LIVEBIRTH)  // Ensure no missing values

destring NUM_LIVEBIRTH, replace  // Convert to a proper numeric type

*
* * 
* * *
* * * Number of STILLBITHS
gen byte NUM_STILLBIRTHS = 1 if NUM_LIVEBIRTH==0 & FORM_BDF == 1

*
* *
* * *

* LABELS:
label define YESNONKNA   1 "Yes" 2 "No" 8 "NK" 9 "NA"

label values EHS_SEV_BACT_INF    YESNONKNA
label values EHS_ACUTE_BACT_INF  YESNONKNA
label values EHS_TOCOLYTICS      YESNONKNA
label values EHS_MAGNESIUM_SUL   YESNONKNA
label values EHS_CORTICOSTEROIDS YESNONKNA
label values EHS_ACUTE_BACT_INF  YESNONKNA
label values EHS_REFERRED        YESNONKNA
label values EHS_TEMP_MORE_38C   YESNONKNA
label values EHS_PAR_ANTIBIOTIC  YESNONKNA
label values EHS_CONSENT         YESNONKNA

label values ACS_REC_PRV_ACS1 YESNONKNA
label values ACS_REC_PRV_ACS2 YESNONKNA
*label values ACS_REC_PRV_ACS3 YESNONKNA

label values MFU_WOMAN_DELIVERED1 YESNONKNA
label values MFU_WOMAN_DELIVERED2 YESNONKNA
label values MFU_WOMAN_DELIVERED3 YESNONKNA
label values MFU_WOMAN_DELIVERED4 YESNONKNA
*label values MFU_WOMAN_DELIVERED5 YESNONKNA
*label values MFU_WOMAN_DELIVERED6 YESNONKNA
*label values MFU_WOMAN_DELIVERED7 YESNONKNA
*label values MFU_WOMAN_DELIVERED8 YESNONKNA

label values ACS_CONSENT1 YESNONKNA
label values ACS_CONSENT2 YESNONKNA
*label values ACS_CONSENT3 YESNONKNA

label values ACS_ANTIBIOTICS1 YESNONKNA
label values ACS_ANTIBIOTICS2 YESNONKNA
*label values ACS_ANTIBIOTICS3 YESNONKNA

label values ACS_TOCOLYTICS1 YESNONKNA
label values ACS_TOCOLYTICS2 YESNONKNA
*label values ACS_TOCOLYTICS3 YESNONKNA

label values ACS_MAGNESIUM_SUL1 YESNONKNA
label values ACS_MAGNESIUM_SUL2 YESNONKNA
*label values ACS_MAGNESIUM_SUL3 YESNONKNA

label values MFU_CONT_SUCCESSFUL1 YESNONKNA
label values MFU_CONT_SUCCESSFUL2 YESNONKNA
label values MFU_CONT_SUCCESSFUL3 YESNONKNA

label values NFU_INTERVIEW_DONE YESNONKNA

label values NFU_B1_DISCHARGED YESNONKNA
label values NFU_B2_DISCHARGED YESNONKNA
label values NFU_B3_DISCHARGED YESNONKNA
label values NFU_B4_DISCHARGED YESNONKNA

label define BDF_GA_ASS_METHOD  1 "USG" 2 "LMP" 3 "Clinical Exam" 4 "Other" 8 "NK" 9 "NA"
label values BDF_GA_ASS_METHOD  BDF_GA_ASS_METHOD
label values ACS_GA_ASS_METHOD1 BDF_GA_ASS_METHOD 

label define BDF_BIRTH_STATUS 1 "Liveborn" 2 "Stillborn" 8 "NK" 9 "NA"
label values BDF_BIRTH_STATUS1 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS2 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS3 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS4 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS5 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS6 BDF_BIRTH_STATUS

label values MFU_NB_VITALSTAT11 BDF_BIRTH_STATUS
label values MFU_NB_VITALSTAT21 BDF_BIRTH_STATUS
label values MFU_NB_VITALSTAT31 BDF_BIRTH_STATUS
label values MFU_NB_VITALSTAT41 BDF_BIRTH_STATUS

label define ACS_OUTCOME_ADM 1 "Discharged/LAMA without delivery" 2 "Delivered" 3 "Referred to a higher level facility" 4 "Death" 6 "Miscarriage/Abortion" 8 "NK" 9 "NA"
label values ACS_OUTCOME_ADM1 ACS_OUTCOME_ADM
label values ACS_OUTCOME_ADM2 ACS_OUTCOME_ADM
*label values ACS_OUTCOME_ADM3 ACS_OUTCOME_ADM

label define EHS_PT_BIRTH_INDICTN 1 "Pprom" 2 "Spontaneous Preterm labour" 3 "Medically indicated" 4 "Other"
label values EHS_PT_BIRTH_INDICTN EHS_PT_BIRTH_INDICTN

label define BDF_MODE_DELIVERY 1 "Vaginal" 2 "C-section"
label values BDF_MODE_DELIVERY BDF_MODE_DELIVERY

label define NFU_VITAL_STATUS 1 "Alive at 28 days" 2 "Dead" 8 "NK" 9 "NA"
label values NFU_B1_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B2_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B3_VITAL_STATUS NFU_VITAL_STATUS

label define EHS_REFERRED_FROM 1 "Within district" 2 "Outside district" 3 "Current facility" 8 "NK" 9 "NA"
label values EHS_REFERRED_FROM  EHS_REFERRED_FROM
label values EHS_PL_ACS_ADMNSTR EHS_REFERRED_FROM

label define EHS_ADM_OUTCOME 1 "Discharged/LAMA" 2 "Referred to higher-level facility" 3 "Death" 8 "NK"
label values EHS_ADM_OUTCOME EHS_ADM_OUTCOME

label define ACS_CLINICAL_INDIC1 1 "Pprom" 2 "Preterm labour" 3 "Medically indicated" 9 "NA"
label values ACS_CLINICAL_INDIC1 ACS_CLINICAL_INDIC1

label define ACS_DOSE_GIVEN 1 "Yes" 2 "No" 8 "Missing" 9 "NA"
label values ACS_DOSE1_GIVEN1 ACS_DOSE_GIVEN
label values ACS_DOSE1_GIVEN2 ACS_DOSE_GIVEN
*label values ACS_DOSE1_GIVEN3 ACS_DOSE_GIVEN
label values ACS_DOSE2_GIVEN1 ACS_DOSE_GIVEN
label values ACS_DOSE2_GIVEN2 ACS_DOSE_GIVEN
*label values ACS_DOSE2_GIVEN3 ACS_DOSE_GIVEN
label values ACS_DOSE3_GIVEN1 ACS_DOSE_GIVEN
label values ACS_DOSE3_GIVEN2 ACS_DOSE_GIVEN
*label values ACS_DOSE3_GIVEN3 ACS_DOSE_GIVEN
label values ACS_DOSE4_GIVEN1 ACS_DOSE_GIVEN
label values ACS_DOSE4_GIVEN2 ACS_DOSE_GIVEN
*label values ACS_DOSE4_GIVEN3 ACS_DOSE_GIVEN

label define ACS_PL_PRV_ADMNSTR 1 "Current hospital" 2 "Other hospital in district" 3 "PHC" 4 "Private clinic" 5 "Outside the district"  6 "Other" 8 "NK" 9 "NA"
label values ACS_PL_PRV_ADMNSTR1 ACS_PL_PRV_ADMNSTR
label values ACS_PL_PRV_ADMNSTR2 ACS_PL_PRV_ADMNSTR
*label values ACS_PL_PRV_ADMNSTR3 ACS_PL_PRV_ADMNSTR

label define ACS_SIGNS_INFECTION 1 "Yes" 2 "No" 3 "Not assessed" 8 "NK" 9 "NA"
label values ACS_SIGNS_INFECTION1 ACS_SIGNS_INFECTION
label values ACS_SIGNS_INFECTION2 ACS_SIGNS_INFECTION
*label values ACS_SIGNS_INFECTION3 ACS_SIGNS_INFECTION

label define MFU_PL_DELIVERYy 1 "Within NOC" 2 "Outside NOC" 8 "NK" 9 "NA"
label values MFU_PL_DELIVERY1 MFU_PL_DELIVERYy
label values MFU_PL_DELIVERY2 MFU_PL_DELIVERYy
label values MFU_PL_DELIVERY3 MFU_PL_DELIVERYy
label values MFU_PL_DELIVERY4 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY5 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY6 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY7 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY8 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY9 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY10 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY11 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY12 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY13 MFU_PL_DELIVERYy
*label values MFU_PL_DELIVERY14 MFU_PL_DELIVERYy

label define SEX 1 "Female" 2 "Male" 3 "Undetermined" 8 "NK" 9 "NA"
label values BDF_SEX1 SEX
label values BDF_SEX2 SEX
label values BDF_SEX3 SEX
label values BDF_SEX4 SEX
label values MFU_NB_SEX11 SEX
label values MFU_NB_SEX21 SEX
label values MFU_NB_SEX31 SEX
label values MFU_NB_SEX41 SEX
label values MFU_NB_SEX12 SEX
label values MFU_NB_SEX22 SEX
label values MFU_NB_SEX32 SEX
label values MFU_NB_SEX42 SEX

label define  RESI 1 "Within study area" 2 "Outside study area" 8 "NK" 9 "NA"
label values  BDF_PERMANENT_RESI RESI
label values  BDF_RESI_AFTER_DEL RESI

label define TRIMM   1 "1st" 2 "2nd" 3 "3rd" 8 "NK" 9 "NA"
label values BDF_TRIM_1STANC_VISIT TRIMM
label values BDF_TRIM_EARLY_USG TRIMM
label values ACS_TRIM_EARLY_USG1 TRIMM
label values ACS_TRIM_EARLY_USG2 TRIMM
*label values ACS_TRIM_EARLY_USG3 TRIMM

label define ACS_DIGITAL_VAG_EXAM 1 "Done" 2 "Not done" 8 "NK" 9 "NA"
label values ACS_DIGITAL_VAG_EXAM1 ACS_DIGITAL_VAG_EXAM
label values ACS_DIGITAL_VAG_EXAM2 ACS_DIGITAL_VAG_EXAM
*label values ACS_DIGITAL_VAG_EXAM3 ACS_DIGITAL_VAG_EXAM

label define MIF_PL_1STPRES_DEL 1 "Current hospital" 2 "Other tertiary/ secondary level hospital in the area" 3 "Primary health care center" 4 "Facility from outside the district" 8 "NK"
label values MIF_PL_1STPRES_DEL1 MIF_PL_1STPRES_DEL
label values MIF_PL_1STPRES_DEL2 MIF_PL_1STPRES_DEL
*label values MIF_PL_1STPRES_DEL3 MIF_PL_1STPRES_DEL

label define MIF_PVT_PUBLIC_FAC 1 "Public" 2 "Private" 3 "Other" 8 "NK" 9 "NA"
label values MIF_PVT_PUBLIC_FAC1 MIF_PVT_PUBLIC_FAC	
label values MIF_PVT_PUBLIC_FAC2 MIF_PVT_PUBLIC_FAC
*label values MIF_PVT_PUBLIC_FAC3 MIF_PVT_PUBLIC_FAC

label define MIF_HOW_REF_THIS_FAC 1 "Own transport" 2 "Public ambulance" 3 "Private ambulance" 4 "Other" 8 "NK" 9 "NA"
label values MIF_HOW_REF_THIS_FAC1 MIF_HOW_REF_THIS_FAC
label values MIF_HOW_REF_THIS_FAC2 MIF_HOW_REF_THIS_FAC
*label values MIF_HOW_REF_THIS_FAC3 MIF_HOW_REF_THIS_FAC

label define MIF_WHR_PLAN_DELIVER 1 "At current hospital" 2 "Other secondary/tertiary level hospital in the area" 3 "Private clinic" 4 "Other" 8 "NK" 9 "NA"
label values MIF_WHR_PLAN_DELIVER1 MIF_WHR_PLAN_DELIVER
label values MIF_WHR_PLAN_DELIVER2 MIF_WHR_PLAN_DELIVER
* label values MIF_WHR_PLAN_DELIVER3 MIF_WHR_PLAN_DELIVER

label define MFUCONT 1 "Alive" 2 "Dead" 8 "NK" 9 "NA"
label values MFU_NB_VITALSTAT1_CONT1 MFUCONT
label values MFU_NB_VITALSTAT2_CONT1 MFUCONT
label values MFU_NB_VITALSTAT3_CONT1 MFUCONT
label values MFU_NB_VITALSTAT4_CONT1 MFUCONT

label define EHS_ADM_ACS_ADMNSTR 1 "Current admission" 2 "Previous admission" 8 "NK" 9 "NA"
label values EHS_ADM_ACS_ADMNSTR EHS_ADM_ACS_ADMNSTR

label define NFU_TYPE_INTERVIEW 1 "Telephonic" 2 "In-person at home" 3 "In-person in hospital" 4 "Other" 9 "NA"	
label values NFU_TYPE_INTERVIEW NFU_TYPE_INTERVIEW

label define NFU_INFORMANT 1 "Mother/Carer" 2 "Other family member" 3 "Health provider" 4 "Other, i.e. case sheet" 9 "NA"	
label values NFU_INFORMANT NFU_INFORMANT

label define NFU_DEATH_PLACE 1 "Facility (during birth hospitalization)" 2 "Community/Home" 3 "Facility (during readmission)" 9 "NA"
label values NFU_B1_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B2_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B3_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B4_DEATH_PLACE NFU_DEATH_PLACE


** VARIABLE FOR RA
gen RA_NAME = substr(PID, 4, 2)
replace RA_NAME= "Bushra Nawaz" 	if  RA_NAME == "PA"
replace RA_NAME= "Faiza Shah" 		if  RA_NAME == "PC"
replace RA_NAME= "Muhammad Zahid "  if  RA_NAME == "PD"
replace RA_NAME= "Sabeen" 			if  RA_NAME == "PH"
replace RA_NAME= "Arshi" 			if  RA_NAME == "PF"
replace RA_NAME= "Fatima Akhtar" 	if  RA_NAME == "PP"
replace RA_NAME= "Bushra Ibrahim" 	if  RA_NAME == "PQ"

*
* *
* * *
* Total Cases in each Form
distinct FORM_BDF // BDF FORM
distinct FORM_ACS1 FORM_ACS2 // ACS FORM
distinct FORM_MFU1 FORM_MFU2 FORM_MFU3 FORM_MFU4 // MFU FORM
distinct FORM_MIF1 FORM_MIF2 // MFU FORM
distinct FORM_EHS //EHS FORM
distinct FORM_NFU // NFU FORM


*
* * 
* * * 
* * * * 
* * * * * SAVE FULL DATA * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

keep if PID != ""

saveold "Full_inteherated_database_analysis_PI.dta", replace version(13)

* export excel using "Full_database_analysis_Phase_I.xlsx", firstrow(variables) nolabel replace
* export delimited using "Full_database_analysis_ALL_COUNTRIES.csv", replace 

