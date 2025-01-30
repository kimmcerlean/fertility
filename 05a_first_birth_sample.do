********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: first_birth_sample
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the first birth sample, adds on partner characteristics
* and creates necessary couple-level variables and final sample restrictions
* Also adds in birth DVs (right now time constant, need to be time-varying)

/* Steps I wrote in file 4 we need to make sure are done by end of this file:
* a. matched partner info - do here
* b. a flag for birth in year - do here
* c. remove observations after relevant birth (e.g. after first birth for that sample) - did in prev file, but double check once data all sorted
* d. eventually deduplicate (so just one observation per year) - did in prev file
* e. eventually do the age restrictions (once partner data matched) - do here
*/

use "$created_data/PSID_first_birth_sample.dta", clear

// first merge partner characteristics
merge m:1 partner_id survey_yr using "$created_data\PSID_individ_allyears.dta", keepusing(*_sp) // created step 2
	// have to do m:1 bc of missing partner ids; it's not a unique list of partners
drop if _merge==2
tab _merge
inspect partner_id if _merge==1 // yes, unmatched are missing pid - it's about 15% of uniques; is this too many?
inspect partner_id if _merge==3
tabstat partner_id, by(_merge)
unique unique_id, by(_merge)

drop _merge

replace age_sp = survey_yr - birth_yr_sp if age_sp==. & birth_yr_sp!=9999

browse unique_id partner_id survey_yr SEX weekly_hrs_t_focal weekly_hrs_t_sp housework_focal housework_sp age_focal age_sp

********************************************************************************
* add in birth indicators - aka create our DV and final sample clean up
********************************************************************************

unique unique_id partner_id, by(joint_first_birth)
replace joint_first_birth=0 if joint_first_birth==.

tab cah_child_birth_yr1_ref joint_first_birth, m // so there should not be birth years here for 0s? about 22% have? so some is bc AFTER relationship ended
tab cah_child_birth_yr1_ref joint_first_birth if num_births_pre_ref==0 & num_births_pre_sp==0, m 
tab cah_child_birth_yr1_sp joint_first_birth, m // col nofreq
tab shared_birth1_refyr joint_first_birth, m col nofreq // so there are less shared, but that's almost worse?
tab shared_birth1_spyr joint_first_birth, m col nofreq

foreach var in any_births_pre_rel num_births_pre_ref num_births_pre_indv_ref num_births_pre_sp num_births_pre_indv_sp{
	tab `var', m
}
// so the ref and spouse births pre rel at INDIVIDUAL level + the joint indicator are all 0
// so I think these are pre rel births that are shared? so I do need to remove?

tab num_births_pre_ref num_births_pre_indv_ref , m
tab num_births_pre_sp  num_births_pre_indv_sp , m
tab any_births_pre_rel num_births_pre_ref, m
tab any_births_pre_rel num_births_pre_sp, m

gen had_first_birth=0
replace had_first_birth=1 if survey_yr==joint_first_birth_yr
tab had_first_birth, m
tab joint_first_birth had_first_birth, m

browse unique_id partner_id survey_yr rel_start_yr rel_end_yr any_births_pre_rel joint_first_birth joint_first_birth_yr had_first_birth joint_first_birth_rel joint_first_birth_timing first_survey_yr last_survey_yr first_survey_yr_sp last_survey_yr_sp cah_child_birth_yr1_ref cah_child_birth_yr1_sp shared_birth1_refyr shared_birth1_spyr num_births_pre_ref num_births_pre_sp

// make sure of two things:
	// a. I am not following people after their relationship end year / last survey year (if censored) OR capturing births after this. okay, so some peopled do have a birth after relationship ends, but I don't have those years here, so it's fine
	// b. also possible the first birth year is not observed? I think? so I removed years after, but what prior years so I remove? do I remove years before rel_start? are those here? I don't know...
	// okay i think this and c. are related. there are people with a first birth that is not observed? so use first survey yr relative to first birth? but not all of them have joint_first_birth=1 flag
	// c. something that is happening that I need to figure out, I think people with a joint first birth that is PRIOR to relationship start are somehow here?
	// d. I am not capturing people with a first birth somehow that is not joint, but is in the confines of this observed relationship?

********************************************************************************
* more sample restrictions (namely, age of partner and same-gender couples)
********************************************************************************
tab SEX SEX_sp, m
drop if SEX==1 & SEX_sp==1
drop if SEX==2 & SEX_sp==2

gen age_man = age_focal if SEX==1
replace age_man = age_sp if SEX==2

gen age_woman = age_focal if SEX==2
replace age_woman = age_sp if SEX==1

// browse unique_id partner_id survey_yr SEX SEX_sp age_man age_woman age_focal age_sp

keep if (age_man>=20 & age_man<=60) & (age_woman>=20 & age_woman<50) // Comolli using the PSID does 16-49 for women and < 60 for men, but I want a higher lower limit for measurement of education? In general, age limit for women tends to range from 44-49, will use the max of 49 for now. lower limit of 20 seems justifiable based on prior research (and could prob go even older)

unique unique_id partner_id
unique unique_id partner_id if joint_first_birth==1

unique unique_id partner_id if rel_start_yr >= 2005 // focus on post-recession period?
unique unique_id partner_id if joint_first_birth==1 & rel_start_yr >= 2005 // focus on post-recession period?

********************************************************************************
**# Exploring imputation here instead
* (was trying to use the full couple-level data for more observations but taking FOREVER)
********************************************************************************
// clean up data
drop if raceth_fixed_focal==. // for now, just so this is actually complete
drop if age_focal==. // so complete
drop if partner_id==. // so only MATCHED observations for now
drop if age_sp==.
drop if raceth_fixed_sp==. 

mi set flong
mi register imputed weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t2_focal housework_focal housework_t1_focal housework_t2_focal earnings_t_focal earnings_t1_focal earnings_t2_focal educ_focal educ_t1_focal educ_t2_focal religion_focal religion_t1_focal religion_t2_focal weekly_hrs_t_sp weekly_hrs_t1_sp weekly_hrs_t2_sp earnings_t_sp earnings_t1_sp earnings_t2_sp housework_sp housework_t1_sp housework_t2_sp educ_sp educ_t1_sp educ_t2_sp religion_sp religion_t1_sp religion_t2_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_ 
mi register regular survey_yr age_focal age_sp SEX SEX_sp raceth_fixed_focal raceth_fixed_sp sample_type sample_type_sp rel_start_yr had_first_birth // FIRST_BIRTH_YR relationship_est

#delimit ;

mi impute chained

/* work hours */
(pmm, knn(5) include (weekly_hrs_t1_focal weekly_hrs_t2_focal housework_focal earnings_t_focal educ_focal religion_focal NUM_CHILDREN_ AGE_YOUNG_CHILD_ age_focal i.SEX i.raceth_fixed_focal i.sample_type)) weekly_hrs_t_focal
(pmm, knn(5) include (weekly_hrs_t_focal weekly_hrs_t2_focal housework_t1_focal earnings_t1_focal educ_t1_focal religion_t1_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) weekly_hrs_t1_focal
(pmm, knn(5) include (weekly_hrs_t_focal weekly_hrs_t1_focal housework_t2_focal earnings_t2_focal educ_t2_focal religion_t2_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) weekly_hrs_t2_focal

(pmm, knn(5) include (weekly_hrs_t1_sp weekly_hrs_t2_sp housework_sp earnings_t_sp educ_sp religion_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_ age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) weekly_hrs_t_sp
(pmm, knn(5) include (weekly_hrs_t_sp weekly_hrs_t2_sp housework_t1_sp earnings_t1_sp educ_t1_sp religion_t1_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) weekly_hrs_t1_sp
(pmm, knn(5) include (weekly_hrs_t_sp weekly_hrs_t1_sp housework_t2_sp earnings_t2_sp educ_t2_sp religion_t2_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) weekly_hrs_t2_sp

/* earnings */
(pmm, knn(5) include (weekly_hrs_t_focal earnings_t2_focal housework_focal earnings_t1_focal educ_focal religion_focal NUM_CHILDREN_ AGE_YOUNG_CHILD_ age_focal i.SEX i.raceth_fixed_focal i.sample_type)) earnings_t_focal
(pmm, knn(5) include (weekly_hrs_t1_focal earnings_t2_focal housework_t1_focal earnings_t_focal educ_t1_focal religion_t1_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) earnings_t1_focal
(pmm, knn(5) include (earnings_t_focal weekly_hrs_t2_focal housework_t2_focal earnings_t1_focal educ_t2_focal religion_t2_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) earnings_t2_focal

(pmm, knn(5) include (weekly_hrs_t_sp earnings_t2_sp housework_sp earnings_t1_sp educ_sp religion_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_ )) earnings_t_sp
(pmm, knn(5) include (weekly_hrs_t1_sp earnings_t2_sp housework_t1_sp earnings_t_sp educ_t1_sp religion_t1_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) earnings_t1_sp
(pmm, knn(5) include (earnings_t_sp weekly_hrs_t2_sp housework_t2_sp earnings_t1_sp educ_t2_sp religion_t2_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) earnings_t2_sp

/* housework */
(pmm, knn(5) include (weekly_hrs_t_focal housework_t2_focal earnings_t_focal housework_t1_focal educ_focal religion_focal NUM_CHILDREN_ AGE_YOUNG_CHILD_ age_focal i.SEX i.raceth_fixed_focal i.sample_type)) housework_focal
(pmm, knn(5) include (weekly_hrs_t1_focal housework_t2_focal housework_focal earnings_t1_focal educ_t1_focal religion_t1_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) housework_t1_focal
(pmm, knn(5) include (housework_t1_focal weekly_hrs_t2_focal earnings_t2_focal housework_focal educ_t2_focal religion_t2_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) housework_t2_focal

(pmm, knn(5) include (weekly_hrs_t_sp housework_t2_sp earnings_t_sp housework_t1_sp educ_sp religion_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_)) housework_sp
(pmm, knn(5) include (weekly_hrs_t1_sp housework_t2_sp housework_sp earnings_t1_sp educ_t1_sp religion_t1_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) housework_t1_sp
(pmm, knn(5) include (housework_t1_sp weekly_hrs_t2_sp earnings_t2_sp housework_sp educ_t2_sp religion_t2_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) housework_t2_sp

/* other controls */
(ologit, include (educ_t2_focal educ_t1_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) educ_focal
(ologit, include (educ_t2_focal educ_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) educ_t1_focal
(ologit, include (educ_focal educ_t1_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) educ_t2_focal
(pmm, knn(5) include (weekly_hrs_t_focal religion_t2_focal earnings_t_focal housework_focal educ_focal religion_t1_focal NUM_CHILDREN_ AGE_YOUNG_CHILD_ age_focal i.SEX i.raceth_fixed_focal i.sample_type)) religion_focal
(pmm, knn(5) include (weekly_hrs_t1_focal housework_t1_focal religion_t2_focal earnings_t1_focal educ_t1_focal religion_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) religion_t1_focal
(pmm, knn(5) include (religion_focal weekly_hrs_t2_focal earnings_t2_focal housework_t2_focal educ_t2_focal religion_t1_focal age_focal i.SEX i.raceth_fixed_focal i.sample_type)) religion_t2_focal

(ologit, include (educ_t2_sp educ_t1_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) educ_sp
(ologit, include (educ_t2_sp educ_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) educ_t1_sp
(ologit, include (educ_sp educ_t1_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) educ_t2_sp
(pmm, knn(5) include (weekly_hrs_t_sp religion_t2_sp earnings_t_sp housework_sp educ_sp religion_t1_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_ age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) religion_sp
(pmm, knn(5) include (weekly_hrs_t1_sp housework_t1_sp religion_t2_sp earnings_t1_sp educ_t1_sp religion_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) religion_t1_sp
(pmm, knn(5) include (religion_sp weekly_hrs_t2_sp earnings_t2_sp housework_t2_sp educ_t2_sp religion_t1_sp age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) religion_t2_sp

/* child vars */
(pmm, knn(5) include (weekly_hrs_t_focal housework_focal earnings_t_focal educ_focal religion_focal weekly_hrs_t_sp housework_sp earnings_t_sp educ_sp religion_sp AGE_YOUNG_CHILD_ age_focal i.SEX i.raceth_fixed_focal i.sample_type age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) NUM_CHILDREN_
(pmm, knn(5) include (weekly_hrs_t_focal housework_focal earnings_t_focal educ_focal religion_focal weekly_hrs_t_sp housework_sp earnings_t_sp educ_sp religion_sp NUM_CHILDREN_ age_focal i.SEX i.raceth_fixed_focal i.sample_type age_sp i.SEX_sp i.raceth_fixed_sp i.sample_type_sp)) AGE_YOUNG_CHILD_

= i.survey_yr i.rel_start_yr i.had_first_birth, chaindots add(10) rseed(8675309) noimputed augment // dryrun // chainonly savetrace(impstats) // force augment noisily burnin(1)

/* moving some of these variables up - might that make the spouse ones less crazy?
= i.survey_yr age_focal age_sp i.SEX i.SEX_sp i.raceth_fixed_focal i.raceth_fixed_sp i.sample_type i.sample_type_sp  i.rel_start_yr i.had_first_birth, chaindots add(10) rseed(8675309) noimputed augment // chainonly savetrace(impstats) // dryrun // force augment noisily burnin(1)

if I want to do by sex
= i.survey_yr i.age_focal i.raceth_fixed_focal i.sample_type  i.rel_start_yr i.relationship_est i.shared_birth_in_yr i.FIRST_BIRTH_YR, by(SEX) chaindots add(1) rseed(8675309) noimputed noisily // dryrun // force augment noisily
*/

;
#delimit cr

save "$temp/PSID_first_birth_imputed.dta", replace

// let's look at some descriptives regarding data distributions

gen imputed=0
replace imputed=1 if inrange(_mi_m,1,10)

inspect weekly_hrs_t_focal earnings_t_focal housework_focal weekly_hrs_t_sp earnings_t_sp housework_sp if imputed==0
inspect weekly_hrs_t_focal earnings_t_focal housework_focal weekly_hrs_t_sp earnings_t_sp housework_sp if imputed==1

tabstat  weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t2_focal earnings_t_focal earnings_t1_focal earnings_t2_focal housework_focal housework_t1_focal housework_t2_focal educ_focal educ_t1_focal educ_t2_focal religion_focal religion_t1_focal religion_t2_focal, by(imputed) stats(mean sd p50)
tabstat  weekly_hrs_t_sp weekly_hrs_t1_sp weekly_hrs_t2_sp earnings_t_sp earnings_t1_sp earnings_t2_sp housework_sp housework_t1_sp housework_t2_sp educ_sp educ_t1_sp educ_t2_sp religion_sp religion_t1_sp religion_t2_sp, by(imputed) stats(mean sd p50)

twoway (histogram weekly_hrs_t_focal if imputed==0 & weekly_hrs_t_focal<=100, width(2) color(blue%30)) (histogram weekly_hrs_t_focal if imputed==1 & weekly_hrs_t_focal<=100, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours")
twoway (histogram housework_focal if imputed==0 & housework_focal<=50, width(2) color(blue%30)) (histogram housework_focal if imputed==1 & housework_focal<=50, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Housework Hours")
twoway (histogram earnings_t_focal if imputed==0 & earnings_t_focal >=-1000 & earnings_t_focal <=300000, width(10000) color(blue%30)) (histogram earnings_t_focal if imputed==1 & earnings_t_focal >=-1000 & earnings_t_focal <=300000, width(10000) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Annual Earnings")

twoway (histogram weekly_hrs_t_sp if imputed==0 & weekly_hrs_t_sp<=100, width(2) color(blue%30)) (histogram weekly_hrs_t_sp if imputed==1 & weekly_hrs_t_sp<=100, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours")
twoway (histogram housework_sp if imputed==0 & housework_sp<=50, width(2) color(blue%30)) (histogram housework_sp if imputed==1 & housework_sp<=50, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Housework Hours")
twoway (histogram earnings_t_sp if imputed==0 & earnings_t_sp >=-1000 & earnings_t_sp <=300000, width(10000) color(blue%30)) (histogram earnings_t_sp if imputed==1 & earnings_t_sp >=-1000 & earnings_t_sp <=300000, width(10000) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Annual Earnings")


********************************************************************************
**# Create gendered variables and couple-level IVs and control variables
* Making t, t-1, and t-2 versions of all variables
********************************************************************************
use "$temp/PSID_first_birth_imputed.dta", clear

browse unique_id partner_id survey_yr SEX SEX_sp weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t_sp weekly_hrs_t1_sp housework_focal housework_t1_focal housework_sp housework_t1_sp _mi_m // the spouse HW estimation seems worse than focal. should I do BEFORE deduplicating and then rematch that info? also, how misaligned are t, t1 and t2? Should I leave as is via imputation or fill in t1 using t, etc?

foreach var in weekly_hrs_t weekly_hrs_t1 weekly_hrs_t2 earnings_t earnings_t1 earnings_t2 housework housework_t1 housework_t2 religion religion_t1 religion_t2 educ educ_t1 educ_t2 raceth raceth_fixed{
	mi passive: gen `var'_man = `var'_focal if SEX==1
	mi passive: replace `var'_man = `var'_sp if SEX==2
	
	mi passive: gen `var'_woman = `var'_focal if SEX==2
	mi passive: replace `var'_woman = `var'_sp if SEX==1
}

browse unique_id partner_id survey_yr SEX SEX_sp weekly_hrs_t_woman weekly_hrs_t_man weekly_hrs_t_focal weekly_hrs_t_sp

// couple-level education
mi passive: gen college_man = .
mi passive: replace college_man = 0 if inlist(educ_man,1,2,3)
mi passive: replace college_man = 1 if educ_man==4

mi passive: gen college_woman = .
mi passive: replace college_woman = 0 if inlist(educ_woman,1,2,3)
mi passive: replace college_woman = 1 if educ_woman==4

mi passive: gen couple_educ_gp=.
mi passive: replace couple_educ_gp=0 if college_man==0 & college_woman==0
mi passive: replace couple_educ_gp=1 if (college_man==1 | college_woman==1)

label define couple_educ 0 "Neither College" 1 "At Least One College"
label values couple_educ_gp couple_educ

mi passive: gen educ_type=.
mi passive: replace educ_type=1 if inrange(educ_man,1,3) & inrange(educ_woman,1,3)
mi passive: replace educ_type=2 if educ_man == 4 & inrange(educ_woman,1,3)
mi passive: replace educ_type=3 if inrange(educ_man,1,3) & educ_woman == 4
mi passive: replace educ_type=4 if educ_man == 4 & educ_woman == 4

mi passive: gen educ_type=.
mi passive: replace educ_type=1 if inrange(educ_man,1,3) & inrange(educ_woman,1,3)
mi passive: replace educ_type=2 if educ_man == 4 & inrange(educ_woman,1,3)
mi passive: replace educ_type=3 if inrange(educ_man,1,3) & educ_woman == 4
mi passive: replace educ_type=4 if educ_man == 4 & educ_woman == 4

mi passive: gen educ_type=.
mi passive: replace educ_type=1 if inrange(educ_man,1,3) & inrange(educ_woman,1,3)
mi passive: replace educ_type=2 if educ_man == 4 & inrange(educ_woman,1,3)
mi passive: replace educ_type=3 if inrange(educ_man,1,3) & educ_woman == 4
mi passive: replace educ_type=4 if educ_man == 4 & educ_woman == 4

label define educ_type 1 "Neither College" 2 "Him College" 3 "Her College" 4 "Both College"
label values educ_type educ_type

// income and division of paid labor
mi passive: egen couple_earnings = rowtotal(earnings_t_man earnings_t_woman)
browse unique_id partner_id SEX SEX_sp survey_yr couple_earnings earnings_t_man earnings_t_woman earnings_t_focal earnings_t_sp
	
mi passive: gen female_earn_pct = earnings_t_woman/(couple_earnings)

mi passive: gen hh_earn_type=.
mi passive: replace hh_earn_type=1 if female_earn_pct >=.4000 & female_earn_pct <=.6000
mi passive: replace hh_earn_type=2 if female_earn_pct < .4000 & female_earn_pct >=0
mi passive: replace hh_earn_type=3 if female_earn_pct > .6000 & female_earn_pct <=1
mi passive: replace hh_earn_type=4 if earnings_t_man==0 & earnings_t_woman==0

label define hh_earn_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_earn_type hh_earn_type

* t-1 version
mi passive: egen couple_earnings_t1 = rowtotal(earnings_t1_man earnings_t1_woman)
	
mi passive: gen female_earn_pct_t1 = earnings_t1_woman/(couple_earnings_t1)

mi passive: gen hh_earn_type_t1=.
mi passive: replace hh_earn_type_t1=1 if female_earn_pct_t1 >=.4000 & female_earn_pct_t1 <=.6000
mi passive: replace hh_earn_type_t1=2 if female_earn_pct_t1 < .4000 & female_earn_pct_t1 >=0
mi passive: replace hh_earn_type_t1=3 if female_earn_pct_t1 > .6000 & female_earn_pct_t1 <=1
mi passive: replace hh_earn_type_t1=4 if earnings_t1_man==0 & earnings_t1_woman==0

label values hh_earn_type_t1 hh_earn_type

mi estimate: proportion hh_earn_type
mi estimate: proportion hh_earn_type_t1
tab hh_earn_type hh_earn_type_t1, m

browse unique_id partner_id survey_yr hh_earn_type couple_earnings earnings_t_man earnings_t_woman hh_earn_type_t1 couple_earnings_t1 earnings_t1_man earnings_t1_woman  

// hours instead of earnings
mi passive: egen couple_hours = rowtotal(weekly_hrs_t_man weekly_hrs_t_woman)
mi passive: gen female_hours_pct = weekly_hrs_t_woman/couple_hours

mi passive: gen hh_hours_type=.
mi passive: replace hh_hours_type=1 if female_hours_pct >=.4000 & female_hours_pct <=.6000
mi passive: replace hh_hours_type=2 if female_hours_pct <.4000
mi passive: replace hh_hours_type=3 if female_hours_pct >.6000 & female_hours_pct!=.
mi passive: replace hh_hours_type=4 if weekly_hrs_t_man==0 & weekly_hrs_t_woman==0

label define hh_hours_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_hours_type hh_hours_type

	// browse unique_id partner_id survey_yr hh_hours_type weekly_hrs_t_man weekly_hrs_t_woman

* t-1 version
mi passive: egen couple_hours_t1 = rowtotal(weekly_hrs_t1_man weekly_hrs_t1_woman)
mi passive: gen female_hours_pct_t1 = weekly_hrs_t1_woman/couple_hours_t1

mi passive: gen hh_hours_type_t1=.
mi passive: replace hh_hours_type_t1=1 if female_hours_pct_t1 >=.4000 & female_hours_pct_t1 <=.6000
mi passive: replace hh_hours_type_t1=2 if female_hours_pct_t1 <.4000
mi passive: replace hh_hours_type_t1=3 if female_hours_pct_t1 >.6000 & female_hours_pct_t1!=.
mi passive: replace hh_hours_type_t1=4 if weekly_hrs_t1_man==0 & weekly_hrs_t1_woman==0

label values hh_hours_type_t1 hh_hours_type

mi estimate: proportion hh_hours_type
mi estimate: proportion hh_hours_type_t1

browse unique_id partner_id survey_yr hh_hours_type couple_hours weekly_hrs_t_man weekly_hrs_t_woman hh_hours_type_t1 couple_hours_t1 weekly_hrs_t1_man weekly_hrs_t1_woman  

// now based on employment
* first need to create some variables
mi passive: gen ft_pt_woman = .
mi passive: replace ft_pt_woman = 0 if weekly_hrs_t_woman==0 // not working
mi passive: replace ft_pt_woman = 1 if weekly_hrs_t_woman > 0 & weekly_hrs_t_woman < 35 // PT
mi passive: replace ft_pt_woman = 2 if weekly_hrs_t_woman >=35 & weekly_hrs_t_woman < 50 // FT: normal
mi passive: replace ft_pt_woman = 3 if weekly_hrs_t_woman >=50 & weekly_hrs_t_woman < 150 // FT: overwork

mi passive: gen ft_pt_t1_woman = .
mi passive: replace ft_pt_t1_woman = 0 if weekly_hrs_t1_woman==0 // not working
mi passive: replace ft_pt_t1_woman = 1 if weekly_hrs_t1_woman > 0 & weekly_hrs_t1_woman < 35 // PT
mi passive: replace ft_pt_t1_woman = 2 if weekly_hrs_t1_woman >=35 & weekly_hrs_t1_woman < 50 // FT: normal
mi passive: replace ft_pt_t1_woman = 3 if weekly_hrs_t1_woman >=50 & weekly_hrs_t1_woman < 150 // FT: overwork

mi passive: gen ft_pt_man = .
mi passive: replace ft_pt_man = 0 if weekly_hrs_t_man==0 // not working
mi passive: replace ft_pt_man = 1 if weekly_hrs_t_man > 0 & weekly_hrs_t_man < 35 // PT
mi passive: replace ft_pt_man = 2 if weekly_hrs_t_man >=35 & weekly_hrs_t_man < 50 // FT: normal
mi passive: replace ft_pt_man = 3 if weekly_hrs_t_man >=50 & weekly_hrs_t_man < 150 // FT: overwork

mi passive: gen ft_pt_t1_man = .
mi passive: replace ft_pt_t1_man = 0 if weekly_hrs_t1_man==0 // not working
mi passive: replace ft_pt_t1_man = 1 if weekly_hrs_t1_man > 0 & weekly_hrs_t1_man < 35 // PT
mi passive: replace ft_pt_t1_man = 2 if weekly_hrs_t1_man >=35 & weekly_hrs_t1_man < 50 // FT: normal
mi passive: replace ft_pt_t1_man = 3 if weekly_hrs_t1_man >=50 & weekly_hrs_t1_man < 150 // FT: overwork

label define ft_pt 0 "Not working" 1 "PT" 2 "FT: Normal" 3 "FT: Overwork"
label values ft_pt_woman ft_pt_t1_woman ft_pt_man ft_pt_t1_man ft_pt

* couple-level version
tab ft_pt_woman ft_pt_man

mi passive: gen couple_work=.
mi passive: replace couple_work = 1 if inlist(ft_pt_man,2,3) & ft_pt_woman == 0 // any FT
mi passive: replace couple_work = 2 if inlist(ft_pt_man,2,3) & ft_pt_woman == 1
mi passive: replace couple_work = 3 if inlist(ft_pt_man,2,3) & inlist(ft_pt_woman,2,3)
mi passive: replace couple_work = 4 if ft_pt_man == 0 & inlist(ft_pt_woman,2,3)
mi passive: replace couple_work = 4 if ft_pt_man == 1 & inlist(ft_pt_woman,2,3)
mi passive: replace couple_work = 5 if ft_pt_man == 1 & ft_pt_woman == 1
mi passive: replace couple_work = 6 if ft_pt_man == 0 & ft_pt_woman == 0
mi passive: replace couple_work = 6 if ft_pt_man == 0 & ft_pt_woman == 1
mi passive: replace couple_work = 6 if ft_pt_man == 1 & ft_pt_woman == 0

label define couple_work 1 "male bw" 2 "1.5 male bw" 3 "dual FT" 4 "female bw" 5 "dual PT" 6 "under work"
label values couple_work couple_work

mi estimate: proportion couple_work

* with overwork
mi passive: gen couple_work_ow=.
mi passive: replace couple_work_ow = 1 if inlist(ft_pt_man,2,3) & ft_pt_woman == 0
mi passive: replace couple_work_ow = 2 if inlist(ft_pt_man,2,3) & ft_pt_woman == 1
mi passive: replace couple_work_ow = 3 if ft_pt_man == 2 & ft_pt_woman == 2
mi passive: replace couple_work_ow = 4 if ft_pt_man == 3 & ft_pt_woman == 2
mi passive: replace couple_work_ow = 5 if ft_pt_man == 2 & ft_pt_woman == 3
mi passive: replace couple_work_ow = 6 if ft_pt_man == 3 & ft_pt_woman == 3
mi passive: replace couple_work_ow = 7 if ft_pt_man == 0 & inlist(ft_pt_woman,2,3)
mi passive: replace couple_work_ow = 7 if ft_pt_man == 1 & inlist(ft_pt_woman,2,3)
mi passive: replace couple_work_ow = 8 if ft_pt_man == 1 & ft_pt_woman == 1
mi passive: replace couple_work_ow = 8 if ft_pt_man == 0 & ft_pt_woman == 0
mi passive: replace couple_work_ow = 8 if ft_pt_man == 0 & ft_pt_woman == 1
mi passive: replace couple_work_ow = 8 if ft_pt_man == 1 & ft_pt_woman == 0

label define couple_work_ow 1 "male bw" 2 "1.5 male bw" 3 "dual FT: no OW" 4 "dual FT: his OW" 5 "dual FT: her OW" 6 "dual FT: both OW" /// 
7 "female bw" 8 "under work"
label values couple_work_ow couple_work_ow

mi estimate: proportion couple_work_ow

browse unique_id partner_id survey_yr couple_work couple_work_ow weekly_hrs_t_man weekly_hrs_t_woman 

* t1 versions
mi passive: gen couple_work_t1=.
mi passive: replace couple_work_t1 = 1 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 0 // any FT
mi passive: replace couple_work_t1 = 2 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 1
mi passive: replace couple_work_t1 = 3 if inlist(ft_pt_t1_man,2,3) & inlist(ft_pt_t1_woman,2,3)
mi passive: replace couple_work_t1 = 4 if ft_pt_t1_man == 0 & inlist(ft_pt_t1_woman,2,3)
mi passive: replace couple_work_t1 = 4 if ft_pt_t1_man == 1 & inlist(ft_pt_t1_woman,2,3)
mi passive: replace couple_work_t1 = 5 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 1
mi passive: replace couple_work_t1 = 6 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 0
mi passive: replace couple_work_t1 = 6 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 1
mi passive: replace couple_work_t1 = 6 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 0

label values couple_work_t1 couple_work

mi passive: gen couple_work_ow_t1=.
mi passive: replace couple_work_ow_t1 = 1 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 0
mi passive: replace couple_work_ow_t1 = 2 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 1
mi passive: replace couple_work_ow_t1 = 3 if ft_pt_t1_man == 2 & ft_pt_t1_woman == 2
mi passive: replace couple_work_ow_t1 = 4 if ft_pt_t1_man == 3 & ft_pt_t1_woman == 2
mi passive: replace couple_work_ow_t1 = 5 if ft_pt_t1_man == 2 & ft_pt_t1_woman == 3
mi passive: replace couple_work_ow_t1 = 6 if ft_pt_t1_man == 3 & ft_pt_t1_woman == 3
mi passive: replace couple_work_ow_t1 = 7 if ft_pt_t1_man == 0 & inlist(ft_pt_t1_woman,2,3)
mi passive: replace couple_work_ow_t1 = 7 if ft_pt_t1_man == 1 & inlist(ft_pt_t1_woman,2,3)
mi passive: replace couple_work_ow_t1 = 8 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 1
mi passive: replace couple_work_ow_t1 = 8 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 0
mi passive: replace couple_work_ow_t1 = 8 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 1
mi passive: replace couple_work_ow_t1 = 8 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 0

label values couple_work_ow_t1 couple_work_ow

mi estimate: proportion couple_work couple_work_t1 couple_work_ow couple_work_ow_t1

// housework hours
mi passive: egen couple_housework = rowtotal (housework_woman housework_man)

mi passive: gen wife_housework_pct = housework_woman / couple_housework

mi passive: gen housework_bkt=.
mi passive: replace housework_bkt=1 if wife_housework_pct >=.4000 & wife_housework_pct <=.6000
mi passive: replace housework_bkt=2 if wife_housework_pct >.6000 & wife_housework_pct!=.
mi passive: replace housework_bkt=3 if wife_housework_pct <.4000
mi passive: replace housework_bkt=4 if housework_woman==0 & housework_man==0

label define housework_bkt 1 "Dual HW" 2 "Female Primary" 3 "Male Primary" 4 "NA"
label values housework_bkt housework_bkt

mi estimate: proportion housework_bkt
tab survey_yr housework_bkt, m

/*
sort unique_id partner_id survey_yr
gen housework_bkt_t1 = .
mi passive: replace housework_bkt_t1 = housework_bkt[_n-1] if unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1 // I could probably get a lag from the individual level data? so the first year won't be missing by defaul
*/

mi passive: egen couple_housework_t1 = rowtotal (housework_t1_man housework_t1_woman)

mi passive: gen wife_housework_pct_t1 = housework_t1_woman / couple_housework_t1

mi passive: gen housework_bkt_t1=.
mi passive: replace housework_bkt_t1=1 if wife_housework_pct_t1 >=.4000 & wife_housework_pct_t1 <=.6000
mi passive: replace housework_bkt_t1=2 if wife_housework_pct_t1 >.6000 & wife_housework_pct_t1!=.
mi passive: replace housework_bkt_t1=3 if wife_housework_pct_t1 <.4000
mi passive: replace housework_bkt_t1=4 if housework_t1_woman==0 & housework_t1_man==0

label values housework_bkt_t1 housework_bkt

tab survey_yr housework_bkt_t1, m
label values housework_bkt_t1 housework_bkt

browse unique_id partner_id survey_yr housework_bkt housework_woman housework_man housework_bkt_t1 housework_t1_woman housework_t1_man  had_first_birth // maybe I could fill in the last observation prior to year of birth? or fill in if same? then just use the SADI technique at this point?

// combined paid and unpaid
mi passive: gen hours_housework=.
mi passive: replace hours_housework=1 if hh_hours_type==1 & housework_bkt==1 // dual both (egal)
mi passive: replace hours_housework=2 if hh_hours_type==1 & housework_bkt==2 // dual earner, female HM (second shift)
mi passive: replace hours_housework=3 if hh_hours_type==2 & housework_bkt==2 // male BW, female HM (traditional)
mi passive: replace hours_housework=4 if hh_hours_type==3 & housework_bkt==3 // female BW, male HM (counter-traditional)
mi passive: replace hours_housework=5 if hours_housework==. & hh_hours_type!=. & housework_bkt!=. // all others

label define hours_housework 1 "Egal" 2 "Second Shift" 3 "Traditional" 4 "Counter Traditional" 5 "All others"
label values hours_housework hours_housework 

tab survey_yr hours_housework, m // going to be missing whenever housework is missing, which is often
tab hh_hours_type housework_bkt, m cell nofreq
mi estimate: proportion hours_housework

mi estimate: gen hours_housework_t1=.
mi passive: replace hours_housework_t1=1 if hh_hours_type_t1==1 & housework_bkt_t1==1 // dual both (egal)
mi passive: replace hours_housework_t1=2 if hh_hours_type_t1==1 & housework_bkt_t1==2 // dual earner, female HM (second shift)
mi passive: replace hours_housework_t1=3 if hh_hours_type_t1==2 & housework_bkt_t1==2 // male BW, female HM (traditional)
mi passive: replace hours_housework_t1=4 if hh_hours_type_t1==3 & housework_bkt_t1==3 // female BW, male HM (counter-traditional)
mi passive: replace hours_housework_t1=5 if hours_housework_t1==. & hh_hours_type_t1!=. & housework_bkt_t1!=. // all others

label values hours_housework_t1 hours_housework 

// Stata assert command to check new variables created from imputed  
foreach var in xxx{  
	inspect `var' if _mi_m != 0  
	assert `var' != . if _mi_m != 0  
} 

// get lagged structural measure
rename structural_familism structural_familism_t

mi passive: gen year_t1 = survey_yr - 1
mi merge m:1 year_t1 state_fips using "$states/structural_familism.dta", gen(howmatch)  // keep(match) // gen(howmatch) keepusing(structural_familism)

drop if _merge==2
drop _merge

mi update

rename structural_familism structural_familism_t1

sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr state_fips structural_fam*

// final update and save

mi update

save "$created_data/PSID_first_birth_sample_rec.dta", replace
