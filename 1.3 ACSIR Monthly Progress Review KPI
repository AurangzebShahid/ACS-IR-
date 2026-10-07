
*  ACSIR Monthly Progress Review KPI cascade 

*===============================================================================
* Monthly Progress Review KPI cascade --  Runs case-level browse
*   blocks at every step so specific PIDs can be traced for data-quality review.
*
*   Scope: ONE cluster at a time, intervention arm only.
*   CLUSTER_TYPE: 1 = Intervention (CLUST_NUM 2,3,7,13), 2 = Control (4,6,8,10)
*
*   "<34 weeks" categorisation uses GEST_CAT_4 <= 1 (EEPT+EPT, codes 0/1), 
*  GEST_CAT_4 falls back to birthweight when USG is unavailable -- so "confirmed by USG" no longer
*   describes this population precisely; some of these cases are BW-derived.

*===============================================================================

* EDIT THIS LOCAL TO RUN A SINGLE CLUSTER'S REPORT:
local target_clust = 13   // 2=Malakand 3=Hafizabad 7=Mandi Bahauddin 13=Mansehra
local clust_label "Mansehra"

* OPTIONAL: set to a specific HOSPITAL_NAME_ACS value to also run Segment C
* (facility-level ACS use, ungated by delivery-network status). Leave "" to
* skip Segment C and only run the cluster-level Segments A/B above.
local target_facility ""

cap log close
cd "E:\ACSIR Data Management\Phase 2\WHO Monitoring"
clear all
use "Full_database_analysis_P2_LONG_M_PK.dta", clear

* Intervention Clusters -- Malakand(2), Hafizabad(3), Mandi Bahauddin(7), Mansehra(13)
keep if CLUST_NUM == `target_clust'
assert CLUSTER_TYPE == 1

keep if YYYY==2026 & MM == 07 // Monitoring Month

global bdf_id  DIST_NAME HOSPITAL_NAME_BDF RA_NAME MM PID
global acs_id  DIST_NAME_ACS HOSPITAL_NAME_ACS RA_NAME_ACS PID

cap log close
log using "KPI_Cascade_`clust_label'_Jul2026.log", replace text

di as text _n "{hline 78}" _n "MONTHLY PROGRESS REVIEW -- `clust_label' (Intervention), July 2026" _n "{hline 78}"

*
* * Overview
*===============================================================================
* 1. Total births
*===============================================================================
di as text _n "-- Total births (FORM_BDF==1) --"
count if STATUS

*===============================================================================
* 2. GA estimation by USG %
*===============================================================================
di as text _n "-- GA estimation by USG -- (EUSG_AVAIL) --"
tab EUSG_AVAIL if STATUS == 1, missing

*===============================================================================
* 3. All births <34 weeks (GEST_CAT_4 <= 1, EEPT+EPT -- USG-first, BW fallback)
*===============================================================================
di as text _n "-- Births <34 weeks (GEST_CAT_4 == 1) --exluding EEPT"
count if FORM_BDF == 1 & GEST_CAT_4 == 1

di as text "Case list:"
list $bdf_id BDF_DT_DELIVERY GEST_CAT_4 DGA_WEEKS  ///
    if FORM_BDF == 1 & GEST_CAT_4 == 1, sep(0)

*===============================================================================
* 4. Stillbirths <34 weeks (BDF_VITAL_STATUS == 2)
*===============================================================================
di as text _n "-- Stillbirths <34 weeks --"
count if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 2

list $bdf_id BDF_DT_DELIVERY ///
    if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 2, sep(0)

*===============================================================================
* 5. Live births <34 weeks (BDF_VITAL_STATUS == 1)
*===============================================================================
di as text _n "-- Live births <34 weeks --"
count if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1

list $bdf_id BDF_DT_DELIVERY ///
    if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1, sep(0)

*===============================================================================
* 6. LCG use in live births <34 weeks
*===============================================================================
di as text _n "-- LCG use in live births <34 weeks --"
tab BDF_LCG if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1, missing

list $bdf_id BDF_DT_DELIVERY BDF_LCG ///
    if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1 & BDF_LCG == 1, sep(0)


*
* *
* * * Segment A: Live births <34 weeks in cluster

*===============================================================================	
* A1. Live births <34 weeks in cluster	
*===============================================================================

di as text _n "-- Live births <34 weeks --"
count  if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1
	
*===============================================================================	
* A2. Delivered in a facility with small and sick newborn care	
*===============================================================================
di as text _n "Deliveried in facility with small and sick newborn care" _n
count if  FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1 & ACS_IF == 1

	
*===============================================================================
* A2.1. Received ACS / did not receive ACS -- WITHIN the SSNC-network subgroup
*    only (ACS_IF==1). Matches the reference dashboard's cluster-level logic:
*    the received/not-received split is scoped to babies delivered in the
*    network of care; the 2 delivered outside SSNC (Section A3) are excluded
*    from this split entirely, not counted as "not received" here.
*===============================================================================
gen byte ACS_RECEIVED_LT34 = 0 if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1 & ACS_IF == 1
replace ACS_RECEIVED_LT34 = 1 if (FORM_ACS1 == 1 & ACS_CONSENT1 == 1 | BDF_ACS_RECEIVED==1)  ///
    & FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1 & ACS_IF == 1

label define ACSLABL 1 "Received ACS" 0 "Not Received"
label values ACS_RECEIVED_LT34 ACSLABL

di as text _n "-- ACS received vs not, live births <34 weeks delivered in SSNC-network facility --"
tab ACS_RECEIVED_LT34

*===============================================================================
* A2.2. ACS coverage % -- numerator is ACS-received-AND-delivered-in-network,
*    denominator is ALL live births <34 weeks (including the non-network 2).
*    A woman who received ACS but delivered outside the network does NOT
*    count toward coverage, matching the dashboard's 16/34 (not 16/32).
*===============================================================================
di as text _n "-- ACS coverage % of ALL live births <34 weeks (network-gated numerator) --"
count if ACS_RECEIVED_LT34 == 1
local acs_covered = r(N)
count if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1
local acs_denom = r(N)
di as text "ACS coverage: `acs_covered' / `acs_denom' = " %4.1f 100*`acs_covered'/`acs_denom' "%"


di as text "Case list -- received ACS:"
list $bdf_id BDF_DT_DELIVERY ACS_RECEIVED_LT34 ///
    if ACS_RECEIVED_LT34 == 1, sep(0)

di as text "Case list -- did NOT receive ACS:"
list $bdf_id BDF_DT_DELIVERY ACS_RECEIVED_LT34 admission_to_del_hours2 ///
    if ACS_RECEIVED_LT34 == 0, sep(0)

di as text "Case list -- did NOT receive ACS & admission to birth time interval ≤6 hours:"	
list $bdf_id BDF_DT_DELIVERY ACS_RECEIVED_LT34 admission_to_del_hours2 ///
    if ACS_RECEIVED_LT34 == 0 & admission_to_del_hours2<=6, sep(0)
	
di as text "Case list -- did NOT receive ACS & admission to birth time interval >6 hours:"	
list $bdf_id BDF_DT_DELIVERY ACS_RECEIVED_LT34 admission_to_del_hours2 ///
    if ACS_RECEIVED_LT34 == 0 & admission_to_del_hours2>6, sep(0)
	
*===============================================================================
* A3. Delivered in a facility without small and sick newborn care
*===============================================================================
di as text _n "Facilities with early preterm deliveries without small and sick newborn care" _n

tab HOSPITAL_NAME_BDF ///
	if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1 & ACS_IF == 2, sort m
	
list $bdf_id BDF_DT_DELIVERY BDF_MODE_DELIVERY admission_to_del_hours2 ///
    if FORM_BDF == 1 & GEST_CAT_4 == 1 & BDF_VITAL_STATUS == 1 & ACS_IF == 2, sep(0)
	
	
	
*
* *
* * * Segment B: ACS administrations in cluster

gen byte ACS_Administartion_LT34 = 1 if GA_ACS_CATU ==1 & FORM_ACS1==1
*===============================================================================
* B1. Total ACS administrations
*===============================================================================
di as text _n "-- ACS administrations --"
count if FORM_ACS1 == 1

*===============================================================================
* B2. SAFE ACS coverage %:
*
* Received ACS <34 weeks confimed by USG and delivered ≤7 days in facility with SSNC
*===============================================================================
di as text _n "-- ACS coverage % (received / all live births <34 weeks) --" _n
count if ACS_Administartion_LT34 ==1 & DAYS_ACS_TO_DEL <=7 & !missing(DAYS_ACS_TO_DEL) & ACS_IF==1

*===============================================================================
* B3. Unsafe ACS coverage %:
*
* Received ACS >34 weeks, without USG, delivered ≤7 days or in facility without SSNC
*===============================================================================
di as text _n "-- ACS coverage % (received / all live births <34 weeks) --"
count if (ACS_Administartion_LT34 ==. | DAYS_ACS_TO_DEL > 7 ///
| EUSG_ACS_AVAIL == 0 | ACS_IF == 2) & FORM_ACS1==1

 * B3.1
	di as text _n "-- Received ACS ≥34 weeks --" _n
	count if (ACS_Administartion_LT34 ==. & FORM_ACS1==1)

	di as text "--B3.1 Case list -- Received ACS ≥34 weeks  --" _n
	list $acs_id ACS_DOSE1_DATE1 GA_ACS_CATU WEEKS_ACS_EUSG ///
    if (ACS_Administartion_LT34 ==. & FORM_ACS1==1), sep(0)
 
 * B3.2 
    di as text _n "-- Received ACS without USG --" _n
	count if EUSG_ACS_AVAIL == 0 & FORM_ACS1==1

	di as text "--Case list -- Received ACS ≥34 weeks  --" _n
	list $acs_id ACS_DOSE1_DATE1 EUSG_ACS_AVAIL ///
    if EUSG_ACS_AVAIL == 0 & FORM_ACS1==1, sep(0)

 * B3.3 
    di as text _n "-- Received ACS & delivered in facility without SSNC --" _n
	count if  ACS_IF == 2 & FORM_ACS1==1

	di as text "-- Case list -- Received ACS ≥34 weeks  --" _n
	list $acs_id HOSPITAL_NAME_ACS HOSPITAL_NAME_BDF ACS_IF ///
    if  ACS_IF == 2 & FORM_ACS1==1, sep(0)
	
* B3.3 
    di as text _n "-- Received ACS & delivered >7 days from ACS received <34 weeks --" _n
	count if  DAYS_ACS_TO_DEL > 7  & FORM_ACS1==1

	di as text "--delivered >7 days from ACS received <34 weeks  --" _n
	list $acs_id ACS_DT DEL_DT DAYS_ACS_TO_DEL ///
    if  DAYS_ACS_TO_DEL > 7  & FORM_ACS1==1, sep(0)
	
* B3.4
   di as text _n "-- Facilities with potentially unsafe ACS--" _n
   tab HOSPITAL_NAME_ACS if (ACS_Administartion_LT34 ==. | DAYS_ACS_TO_DEL > 7 ///
	| EUSG_ACS_AVAIL == 0 | ACS_IF == 2) & FORM_ACS1==1, sort m

*
* *
* * * Segment C: Overall ACS use IN ONE FACILITY (ungated by delivery network)
*    Matches the dashboard's facility-view "Overall ACS use in facility" panel.
*    KEY DIFFERENCE from Segment B (cluster-level): here "safe"/"unsafe" is
*    NOT gated by delivery-facility SSNC status or by admission-to-birth
*    timing at all -- an ACS dose administered at this facility counts
*    regardless of where (or whether) the mother ultimately delivered.
*    Delivery timing/location become informational "Other ACS notes" only,
*    not part of the safe/unsafe classification.
*===============================================================================
if `"`target_facility'"' != "" {

    di as text _n "{hline 78}" _n "SEGMENT C: Overall ACS use in facility -- `target_facility'" _n "{hline 78}"

    *--- C1. Total ACS administrations AT this facility ------------------------
    di as text _n "-- ACS administrations at `target_facility' --"
    count if FORM_ACS1 == 1 & HOSPITAL_NAME_ACS == "`target_facility'"

    *--- C2. SAFE: <34 weeks confirmed by USG -- no delivery-network/timing gate
    di as text _n "-- SAFE: Received ACS <34 weeks confirmed by USG --"
    count if ACS_Administartion_LT34 == 1 & HOSPITAL_NAME_ACS == "`target_facility'"

    *--- C3. UNSAFE: >=34 weeks OR without USG confirmation only ----------------
    di as text _n "-- UNSAFE: >=34 weeks or without USG confirmation --"
    count if (ACS_Administartion_LT34 == . | EUSG_ACS_AVAIL == 0) ///
        & FORM_ACS1 == 1 & HOSPITAL_NAME_ACS == "`target_facility'"

    di as text _n "-- C3.1 Received ACS >=34 weeks (at this facility) --"
    count if ACS_Administartion_LT34 == . & FORM_ACS1 == 1 & HOSPITAL_NAME_ACS == "`target_facility'"
    list $acs_id ACS_DOSE1_DATE1 GA_ACS_CATU WEEKS_ACS_EUSG ///
        if ACS_Administartion_LT34 == . & FORM_ACS1 == 1 & HOSPITAL_NAME_ACS == "`target_facility'", sep(0)

    di as text _n "-- C3.2 Received ACS without USG (at this facility) --"
    count if EUSG_ACS_AVAIL == 0 & FORM_ACS1 == 1 & HOSPITAL_NAME_ACS == "`target_facility'"
    list $acs_id ACS_DOSE1_DATE1 EUSG_ACS_AVAIL ///
        if EUSG_ACS_AVAIL == 0 & FORM_ACS1 == 1 & HOSPITAL_NAME_ACS == "`target_facility'", sep(0)

    *--- C4. Other ACS notes -- informational only, NOT part of safe/unsafe ----
    di as text _n "-- Other ACS notes (informational, not classification) --"

    di as text "C4.1 Delivered >7 days from ACS dose:"
    count if DAYS_ACS_TO_DEL > 7 & FORM_ACS1 == 1 & HOSPITAL_NAME_ACS == "`target_facility'"

    di as text "C4.2 Delivered elsewhere (ACS given here, BDF delivery facility differs):"
    count if FORM_ACS1 == 1 & FORM_BDF == 1 & HOSPITAL_NAME_ACS == "`target_facility'" ///
        & HOSPITAL_NAME_BDF != "`target_facility'"

    di as text "C4.3 Have not delivered yet (no BDF form on file):"
    count if FORM_ACS1 == 1 & FORM_BDF != 1 & HOSPITAL_NAME_ACS == "`target_facility'"
}

log close
