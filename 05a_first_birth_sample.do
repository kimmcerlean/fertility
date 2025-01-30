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
/*
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
*/

mi passive: gen educ_type=.
mi passive: replace educ_type=1 if inrange(educ_man,1,3) & inrange(educ_woman,1,3)
mi passive: replace educ_type=2 if educ_man == 4 & inrange(educ_woman,1,3)
mi passive: replace educ_type=3 if inrange(educ_man,1,3) & educ_woman == 4
mi passive: replace educ_type=4 if educ_man == 4 & educ_woman == 4

tab educ_man educ_woman, cell nofreq
mi estimate: proportion educ_type

mi passive: gen educ_type_t1=.
mi passive: replace educ_type_t1=1 if inrange(educ_t1_man,1,3) & inrange(educ_t1_woman,1,3)
mi passive: replace educ_type_t1=2 if educ_t1_man == 4 & inrange(educ_t1_woman,1,3)
mi passive: replace educ_type_t1=3 if inrange(educ_t1_man,1,3) & educ_t1_woman == 4
mi passive: replace educ_type_t1=4 if educ_t1_man == 4 & educ_t1_woman == 4

mi passive: gen educ_type_t2=.
mi passive: replace educ_type_t2=1 if inrange(educ_t2_man,1,3) & inrange(educ_t2_woman,1,3)
mi passive: replace educ_type_t2=2 if educ_t2_man == 4 & inrange(educ_t2_woman,1,3)
mi passive: replace educ_type_t2=3 if inrange(educ_t2_man,1,3) & educ_t2_woman == 4
mi passive: replace educ_type_t2=4 if educ_t2_man == 4 & educ_t2_woman == 4

label define educ_type 1 "Neither College" 2 "Him College" 3 "Her College" 4 "Both College"
label values educ_type educ_type_t1 educ_type_t2 educ_type

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

* t-2 version
mi passive: egen couple_earnings_t2 = rowtotal(earnings_t2_man earnings_t2_woman)
	
mi passive: gen female_earn_pct_t2 = earnings_t2_woman/(couple_earnings_t2)

mi passive: gen hh_earn_type_t2=.
mi passive: replace hh_earn_type_t2=1 if female_earn_pct_t2 >=.4000 & female_earn_pct_t2 <=.6000
mi passive: replace hh_earn_type_t2=2 if female_earn_pct_t2 < .4000 & female_earn_pct_t2 >=0
mi passive: replace hh_earn_type_t2=3 if female_earn_pct_t2 > .6000 & female_earn_pct_t2 <=1
mi passive: replace hh_earn_type_t2=4 if earnings_t2_man==0 & earnings_t2_woman==0

label values hh_earn_type_t2 hh_earn_type

mi estimate: proportion hh_earn_type_t2

browse unique_id partner_id survey_yr hh_earn_type couple_earnings earnings_t_man earnings_t_woman hh_earn_type_t1 couple_earnings_t1 earnings_t1_man earnings_t1_woman  hh_earn_type_t2

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

* t-2 version
mi passive: egen couple_hours_t2 = rowtotal(weekly_hrs_t2_man weekly_hrs_t2_woman)
mi passive: gen female_hours_pct_t2 = weekly_hrs_t2_woman/couple_hours_t2

mi passive: gen hh_hours_type_t2=.
mi passive: replace hh_hours_type_t2=1 if female_hours_pct_t2 >=.4000 & female_hours_pct_t2 <=.6000
mi passive: replace hh_hours_type_t2=2 if female_hours_pct_t2 <.4000
mi passive: replace hh_hours_type_t2=3 if female_hours_pct_t2 >.6000 & female_hours_pct_t2!=.
mi passive: replace hh_hours_type_t2=4 if weekly_hrs_t2_man==0 & weekly_hrs_t2_woman==0

label values hh_hours_type_t2 hh_hours_type

mi estimate: proportion hh_hours_type_t2

browse unique_id partner_id survey_yr hh_hours_type hh_hours_type_t1 hh_hours_type_t2 couple_hours weekly_hrs_t_man weekly_hrs_t_woman  couple_hours_t1 weekly_hrs_t1_man weekly_hrs_t1_woman 

// now based on employment
* first need to create some variables
mi passive: gen ft_pt_woman = .
mi passive: replace ft_pt_woman = 0 if weekly_hrs_t_woman==0 // not working
mi passive: replace ft_pt_woman = 1 if weekly_hrs_t_woman > 0 & weekly_hrs_t_woman < 35 // PT
mi passive: replace ft_pt_woman = 2 if weekly_hrs_t_woman >=35 & weekly_hrs_t_woman < 50 // FT: normal
mi passive: replace ft_pt_woman = 3 if weekly_hrs_t_woman >=50 & weekly_hrs_t_woman < 1000 // FT: overwork

mi passive: gen ft_pt_t1_woman = .
mi passive: replace ft_pt_t1_woman = 0 if weekly_hrs_t1_woman==0 // not working
mi passive: replace ft_pt_t1_woman = 1 if weekly_hrs_t1_woman > 0 & weekly_hrs_t1_woman < 35 // PT
mi passive: replace ft_pt_t1_woman = 2 if weekly_hrs_t1_woman >=35 & weekly_hrs_t1_woman < 50 // FT: normal
mi passive: replace ft_pt_t1_woman = 3 if weekly_hrs_t1_woman >=50 & weekly_hrs_t1_woman < 1000 // FT: overwork

mi passive: gen ft_pt_t2_woman = .
mi passive: replace ft_pt_t2_woman = 0 if weekly_hrs_t2_woman==0 // not working
mi passive: replace ft_pt_t2_woman = 1 if weekly_hrs_t2_woman > 0 & weekly_hrs_t2_woman < 35 // PT
mi passive: replace ft_pt_t2_woman = 2 if weekly_hrs_t2_woman >=35 & weekly_hrs_t2_woman < 50 // FT: normal
mi passive: replace ft_pt_t2_woman = 3 if weekly_hrs_t2_woman >=50 & weekly_hrs_t2_woman < 1000 // FT: overwork

mi passive: gen ft_pt_man = .
mi passive: replace ft_pt_man = 0 if weekly_hrs_t_man==0 // not working
mi passive: replace ft_pt_man = 1 if weekly_hrs_t_man > 0 & weekly_hrs_t_man < 35 // PT
mi passive: replace ft_pt_man = 2 if weekly_hrs_t_man >=35 & weekly_hrs_t_man < 50 // FT: normal
mi passive: replace ft_pt_man = 3 if weekly_hrs_t_man >=50 & weekly_hrs_t_man < 1000 // FT: overwork

mi passive: gen ft_pt_t1_man = .
mi passive: replace ft_pt_t1_man = 0 if weekly_hrs_t1_man==0 // not working
mi passive: replace ft_pt_t1_man = 1 if weekly_hrs_t1_man > 0 & weekly_hrs_t1_man < 35 // PT
mi passive: replace ft_pt_t1_man = 2 if weekly_hrs_t1_man >=35 & weekly_hrs_t1_man < 50 // FT: normal
mi passive: replace ft_pt_t1_man = 3 if weekly_hrs_t1_man >=50 & weekly_hrs_t1_man < 1000 // FT: overwork

mi passive: gen ft_pt_t2_man = .
mi passive: replace ft_pt_t2_man = 0 if weekly_hrs_t2_man==0 // not working
mi passive: replace ft_pt_t2_man = 1 if weekly_hrs_t2_man > 0 & weekly_hrs_t2_man < 35 // PT
mi passive: replace ft_pt_t2_man = 2 if weekly_hrs_t2_man >=35 & weekly_hrs_t2_man < 50 // FT: normal
mi passive: replace ft_pt_t2_man = 3 if weekly_hrs_t2_man >=50 & weekly_hrs_t2_man < 1000 // FT: overwork

label define ft_pt 0 "Not working" 1 "PT" 2 "FT: Normal" 3 "FT: Overwork"
label values ft_pt_woman ft_pt_t1_woman ft_pt_t2_woman ft_pt_man ft_pt_t1_man ft_pt_t2_man ft_pt

* couple-level version
mi passive: gen couple_work=.
mi passive: replace couple_work = 1 if inlist(ft_pt_man,2,3) & ft_pt_woman == 0 // any FT
mi passive: replace couple_work = 2 if inlist(ft_pt_man,2,3) & ft_pt_woman == 1
mi passive: replace couple_work = 3 if inlist(ft_pt_man,2,3) & inlist(ft_pt_woman,2,3)
mi passive: replace couple_work = 4 if ft_pt_man == 0 & inlist(ft_pt_woman,2,3)
mi passive: replace couple_work = 4 if ft_pt_man == 1 & inlist(ft_pt_woman,2,3)
mi passive: replace couple_work = 5 if ft_pt_man == 1 & ft_pt_woman == 1
mi passive: replace couple_work = 5 if ft_pt_man == 0 & ft_pt_woman == 0
mi passive: replace couple_work = 5 if ft_pt_man == 0 & ft_pt_woman == 1
mi passive: replace couple_work = 5 if ft_pt_man == 1 & ft_pt_woman == 0

label define couple_work 1 "male bw" 2 "1.5 male bw" 3 "dual FT" 4 "female bw" 5 "under work"
label values couple_work couple_work

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

tab ft_pt_woman ft_pt_man, cell nofreq
mi estimate: proportion couple_work couple_work_ow

browse unique_id partner_id survey_yr couple_work couple_work_ow weekly_hrs_t_man weekly_hrs_t_woman 

* t1 versions
mi passive: gen couple_work_t1=.
mi passive: replace couple_work_t1 = 1 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 0 // any FT
mi passive: replace couple_work_t1 = 2 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 1
mi passive: replace couple_work_t1 = 3 if inlist(ft_pt_t1_man,2,3) & inlist(ft_pt_t1_woman,2,3)
mi passive: replace couple_work_t1 = 4 if ft_pt_t1_man == 0 & inlist(ft_pt_t1_woman,2,3)
mi passive: replace couple_work_t1 = 4 if ft_pt_t1_man == 1 & inlist(ft_pt_t1_woman,2,3)
mi passive: replace couple_work_t1 = 5 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 1
mi passive: replace couple_work_t1 = 5 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 0
mi passive: replace couple_work_t1 = 5 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 1
mi passive: replace couple_work_t1 = 5 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 0

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

* t2 versions
mi passive: gen couple_work_t2=.
mi passive: replace couple_work_t2 = 1 if inlist(ft_pt_t2_man,2,3) & ft_pt_t2_woman == 0 // any FT
mi passive: replace couple_work_t2 = 2 if inlist(ft_pt_t2_man,2,3) & ft_pt_t2_woman == 1
mi passive: replace couple_work_t2 = 3 if inlist(ft_pt_t2_man,2,3) & inlist(ft_pt_t2_woman,2,3)
mi passive: replace couple_work_t2 = 4 if ft_pt_t2_man == 0 & inlist(ft_pt_t2_woman,2,3)
mi passive: replace couple_work_t2 = 4 if ft_pt_t2_man == 1 & inlist(ft_pt_t2_woman,2,3)
mi passive: replace couple_work_t2 = 5 if ft_pt_t2_man == 1 & ft_pt_t2_woman == 1
mi passive: replace couple_work_t2 = 5 if ft_pt_t2_man == 0 & ft_pt_t2_woman == 0
mi passive: replace couple_work_t2 = 5 if ft_pt_t2_man == 0 & ft_pt_t2_woman == 1
mi passive: replace couple_work_t2 = 5 if ft_pt_t2_man == 1 & ft_pt_t2_woman == 0

label values couple_work_t2 couple_work

mi passive: gen couple_work_ow_t2=.
mi passive: replace couple_work_ow_t2 = 1 if inlist(ft_pt_t2_man,2,3) & ft_pt_t2_woman == 0
mi passive: replace couple_work_ow_t2 = 2 if inlist(ft_pt_t2_man,2,3) & ft_pt_t2_woman == 1
mi passive: replace couple_work_ow_t2 = 3 if ft_pt_t2_man == 2 & ft_pt_t2_woman == 2
mi passive: replace couple_work_ow_t2 = 4 if ft_pt_t2_man == 3 & ft_pt_t2_woman == 2
mi passive: replace couple_work_ow_t2 = 5 if ft_pt_t2_man == 2 & ft_pt_t2_woman == 3
mi passive: replace couple_work_ow_t2 = 6 if ft_pt_t2_man == 3 & ft_pt_t2_woman == 3
mi passive: replace couple_work_ow_t2 = 7 if ft_pt_t2_man == 0 & inlist(ft_pt_t2_woman,2,3)
mi passive: replace couple_work_ow_t2 = 7 if ft_pt_t2_man == 1 & inlist(ft_pt_t2_woman,2,3)
mi passive: replace couple_work_ow_t2 = 8 if ft_pt_t2_man == 1 & ft_pt_t2_woman == 1
mi passive: replace couple_work_ow_t2 = 8 if ft_pt_t2_man == 0 & ft_pt_t2_woman == 0
mi passive: replace couple_work_ow_t2 = 8 if ft_pt_t2_man == 0 & ft_pt_t2_woman == 1
mi passive: replace couple_work_ow_t2 = 8 if ft_pt_t2_man == 1 & ft_pt_t2_woman == 0

label values couple_work_ow_t2 couple_work_ow

mi estimate: proportion couple_work couple_work_t1 couple_work_t2 couple_work_ow couple_work_ow_t1 couple_work_ow_t2

// housework hours
mi passive: egen couple_housework = rowtotal (housework_woman housework_man)
mi passive: gen wife_housework_pct = housework_woman / couple_housework

mi passive: gen housework_bkt=.
mi passive: replace housework_bkt=1 if wife_housework_pct >=.4000 & wife_housework_pct <=.6000
mi passive: replace housework_bkt=2 if wife_housework_pct >.6000 & wife_housework_pct!=.
mi passive: replace housework_bkt=3 if wife_housework_pct <.4000
mi passive: replace housework_bkt=1 if housework_woman==0 & housework_man==0

label define housework_bkt 1 "Dual HW" 2 "Female Primary" 3 "Male Primary"
label values housework_bkt housework_bkt

mi estimate: proportion housework_bkt
tab survey_yr housework_bkt, m

*t-1 version
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
mi passive: replace housework_bkt_t1=1 if housework_t1_woman==0 & housework_t1_man==0

label values housework_bkt_t1 housework_bkt
tab survey_yr housework_bkt_t1, m
tab survey_yr housework_bkt_t1 if imputed==1, m row

*t-2 version
mi passive: egen couple_housework_t2 = rowtotal (housework_t2_man housework_t2_woman)
mi passive: gen wife_housework_pct_t2 = housework_t2_woman / couple_housework_t2

mi passive: gen housework_bkt_t2=.
mi passive: replace housework_bkt_t2=1 if wife_housework_pct_t2 >=.4000 & wife_housework_pct_t2 <=.6000
mi passive: replace housework_bkt_t2=2 if wife_housework_pct_t2 >.6000 & wife_housework_pct_t2!=.
mi passive: replace housework_bkt_t2=3 if wife_housework_pct_t2 <.4000
mi passive: replace housework_bkt_t2=1 if housework_t2_woman==0 & housework_t2_man==0

label values housework_bkt_t2 housework_bkt

browse unique_id partner_id survey_yr housework_bkt housework_bkt_t1 housework_bkt_t2 housework_woman housework_man  housework_t1_woman housework_t1_man  had_first_birth

mi estimate: proportion housework_bkt housework_bkt_t1 housework_bkt_t2
tab housework_bkt imputed, col 
tab housework_bkt_t1 imputed, col 
tab housework_bkt_t2 imputed, col 

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

mi passive: gen hours_housework_t1=.
mi passive: replace hours_housework_t1=1 if hh_hours_type_t1==1 & housework_bkt_t1==1 // dual both (egal)
mi passive: replace hours_housework_t1=2 if hh_hours_type_t1==1 & housework_bkt_t1==2 // dual earner, female HM (second shift)
mi passive: replace hours_housework_t1=3 if hh_hours_type_t1==2 & housework_bkt_t1==2 // male BW, female HM (traditional)
mi passive: replace hours_housework_t1=4 if hh_hours_type_t1==3 & housework_bkt_t1==3 // female BW, male HM (counter-traditional)
mi passive: replace hours_housework_t1=5 if hours_housework_t1==. & hh_hours_type_t1!=. & housework_bkt_t1!=. // all others

label values hours_housework_t1 hours_housework 

mi passive: gen hours_housework_t2=.
mi passive: replace hours_housework_t2=1 if hh_hours_type_t2==1 & housework_bkt_t2==1 // dual both (egal)
mi passive: replace hours_housework_t2=2 if hh_hours_type_t2==1 & housework_bkt_t2==2 // dual earner, female HM (second shift)
mi passive: replace hours_housework_t2=3 if hh_hours_type_t2==2 & housework_bkt_t2==2 // male BW, female HM (traditional)
mi passive: replace hours_housework_t2=4 if hh_hours_type_t2==3 & housework_bkt_t2==3 // female BW, male HM (counter-traditional)
mi passive: replace hours_housework_t2=5 if hours_housework_t2==. & hh_hours_type_t2!=. & housework_bkt_t2!=. // all others

label values hours_housework_t2 hours_housework 

tab hh_hours_type housework_bkt, m cell nofreq
mi estimate: proportion hours_housework hours_housework_t1 hours_housework_t2

tab hours_housework imputed, col 
tab hours_housework_t1 imputed, col 
tab hours_housework_t2 imputed, col 

// Stata assert command to check new variables created from imputed  
foreach var in weekly_hrs_t_man weekly_hrs_t_woman weekly_hrs_t1_man weekly_hrs_t1_woman weekly_hrs_t2_man weekly_hrs_t2_woman earnings_t_man earnings_t_woman earnings_t1_man earnings_t1_woman earnings_t2_man earnings_t2_woman housework_man housework_woman housework_t1_man housework_t1_woman housework_t2_man housework_t2_woman religion_man religion_woman religion_t1_man religion_t1_woman religion_t2_man religion_t2_woman educ_man educ_woman educ_t1_man educ_t1_woman educ_t2_man educ_t2_woman raceth_fixed_man raceth_fixed_woman educ_type educ_type_t1 educ_type_t2 couple_earnings  hh_earn_type couple_earnings_t1  hh_earn_type_t1 couple_earnings_t2  hh_earn_type_t2 couple_hours  hh_hours_type couple_hours_t1  hh_hours_type_t1 couple_hours_t2  hh_hours_type_t2 ft_pt_woman ft_pt_t1_woman ft_pt_t2_woman ft_pt_man ft_pt_t1_man ft_pt_t2_man couple_work couple_work_ow couple_work_t1 couple_work_ow_t1 couple_work_t2 couple_work_ow_t2 couple_housework  housework_bkt couple_housework_t1  housework_bkt_t1 couple_housework_t2  housework_bkt_t2 hours_housework hours_housework_t1 hours_housework_t2{  
	// inspect `var' if _mi_m != 0  
	assert `var' != . if _mi_m != 0  
} 

// will have missing if both 0: female_earn_pct female_earn_pct_t1 female_earn_pct_t2 female_hours_pct female_hours_pct_t1 female_hours_pct_t2 wife_housework_pct wife_housework_pct_t1 wife_housework_pct_t2
// not using
drop raceth_man raceth_woman 
mi update

// create some other control variables
* Age diff (instead of using both of their ages? This one might be okay to use both)
mi passive: gen couple_age_diff = age_man - age_woman
tab couple_age_diff, m
sum couple_age_diff, detail

* Joint religion - from Killewald 2016: (1) both spouses are Catholic; (2) at least one spouse reports no religion; and (3) all other
label values religion_man religion_t1_man religion_t2_man religion_woman religion_t1_woman religion_t2_woman religion

tab religion_man religion_t1_man
tab religion_man religion_woman

mi passive: gen couple_joint_religion=.
mi passive: replace couple_joint_religion = 0 if religion_man==0 & religion_woman==0
mi passive: replace couple_joint_religion = 1 if religion_man==1 & religion_woman==1
mi passive: replace couple_joint_religion = 2 if inlist(religion_man,3,4,5,6) & inlist(religion_woman,3,4,5,6)
mi passive: replace couple_joint_religion = 3 if (religion_man==1 & religion_woman!=1 & religion_woman!=.) | (religion_man!=1 & religion_man!=. & religion_woman==1)
mi passive: replace couple_joint_religion = 4 if ((religion_man==0 & religion_woman!=0 & religion_woman!=.) | (religion_man!=0 & religion_man!=. & religion_woman==0)) & couple_joint_religion==.
mi passive: replace couple_joint_religion = 5 if inlist(religion_man,2,7,8,9,10) & inlist(religion_woman,2,7,8,9,10)
mi passive: replace couple_joint_religion = 5 if couple_joint_religion==. & religion_man!=. & religion_woman!=. 
// tab religion_man religion_woman if couple_joint_religion==.

label define couple_joint_religion 0 "Both None" 1 "Both Catholic" 2 "Both Protestant" 3 "One Catholic" 4 "One No Religion" 5 "Other"
label values couple_joint_religion couple_joint_religion

tab religion_man religion_woman, cell nofreq
mi estimate: proportion couple_joint_religion

mi passive: gen couple_joint_religion_t1=.
mi passive: replace couple_joint_religion_t1 = 0 if religion_t1_man==0 & religion_t1_woman==0
mi passive: replace couple_joint_religion_t1 = 1 if religion_t1_man==1 & religion_t1_woman==1
mi passive: replace couple_joint_religion_t1 = 2 if inlist(religion_t1_man,3,4,5,6) & inlist(religion_t1_woman,3,4,5,6)
mi passive: replace couple_joint_religion_t1 = 3 if (religion_t1_man==1 & religion_t1_woman!=1 & religion_t1_woman!=.) | (religion_t1_man!=1 & religion_t1_man!=. & religion_t1_woman==1)
mi passive: replace couple_joint_religion_t1 = 4 if ((religion_t1_man==0 & religion_t1_woman!=0 & religion_t1_woman!=.) | (religion_t1_man!=0 & religion_t1_man!=. & religion_t1_woman==0)) & couple_joint_religion_t1==.
mi passive: replace couple_joint_religion_t1 = 5 if inlist(religion_t1_man,2,7,8,9,10) & inlist(religion_t1_woman,2,7,8,9,10)
mi passive: replace couple_joint_religion_t1 = 5 if couple_joint_religion_t1==. & religion_t1_man!=. & religion_t1_woman!=. 

mi passive: gen couple_joint_religion_t2=.
mi passive: replace couple_joint_religion_t2 = 0 if religion_t2_man==0 & religion_t2_woman==0
mi passive: replace couple_joint_religion_t2 = 1 if religion_t2_man==1 & religion_t2_woman==1
mi passive: replace couple_joint_religion_t2 = 2 if inlist(religion_t2_man,3,4,5,6) & inlist(religion_t2_woman,3,4,5,6)
mi passive: replace couple_joint_religion_t2 = 3 if (religion_t2_man==1 & religion_t2_woman!=1 & religion_t2_woman!=.) | (religion_t2_man!=1 & religion_t2_man!=. & religion_t2_woman==1)
mi passive: replace couple_joint_religion_t2 = 4 if ((religion_t2_man==0 & religion_t2_woman!=0 & religion_t2_woman!=.) | (religion_t2_man!=0 & religion_t2_man!=. & religion_t2_woman==0)) & couple_joint_religion_t2==.
mi passive: replace couple_joint_religion_t2 = 5 if inlist(religion_t2_man,2,7,8,9,10) & inlist(religion_t2_woman,2,7,8,9,10)
mi passive: replace couple_joint_religion_t2 = 5 if couple_joint_religion_t2==. & religion_t2_man!=. & religion_t2_woman!=. 

label values couple_joint_religion_t1 couple_joint_religion_t2 couple_joint_religion
mi estimate: proportion couple_joint_religion couple_joint_religion_t1 couple_joint_religion_t2

* Indicator of whether couple is same race/eth
tab raceth_fixed_man raceth_fixed_woman, m

mi passive: gen couple_same_race=.
mi passive: replace couple_same_race = 0 if raceth_fixed_man!=raceth_fixed_woman
mi passive: replace couple_same_race = 1 if raceth_fixed_man==raceth_fixed_woman & raceth_fixed_man!=. & raceth_fixed_woman!=.

// tab raceth_fixed_man raceth_fixed_woman, m cell nofreq
// mi estimate: proportion couple_same_race

* Logged couple earnings
mi passive: gen couple_earnings_ln = ln(couple_earnings + 1) // add .01 because can't log 0
mi passive: gen couple_earnings_t1_ln = ln(couple_earnings_t1 + 1)
mi passive: gen couple_earnings_t2_ln = ln(couple_earnings_t2 + 1)

sum couple_earnings if imputed==1
sum couple_earnings_t1 if imputed==1
sum couple_earnings_t2 if imputed==1
inspect couple_earnings_ln couple_earnings_t1_ln couple_earnings_t2_ln if imputed==1

* Migration status
sort _mi_m unique_id partner_id survey_yr 

mi passive: egen couple_id = group(unique_id partner_id)
quietly unique state_fips if state_fips!=., by(couple_id) gen(state_change)
bysort couple_id (state_change): replace state_change=state_change[1]
tab state_change, m

sort _mi_m unique_id partner_id survey_yr 
browse unique_id partner_id survey_yr _mi_m state_fips state_change moved MOVED_YEAR_ change_yr entrance_no leave_no moved_sp MOVED_YEAR_sp change_yr_sp

gen moved_states = .
replace moved_states = 0 if state_fips==state_fips[_n-1] & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1
replace moved_states = 0 if state_change==1
replace moved_states = 1 if state_fips!=state_fips[_n-1] & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1
replace moved_states = 0 if moved_states==. & state_change!=0 // remaining are first observations
tab moved_states, m

browse unique_id partner_id survey_yr _mi_m state_fips state_change moved_states rel_start_yr first_survey_yr
tab state_change moved_states, m

gen moved_states_lag = .
replace moved_states_lag = 0 if state_fips==state_fips[_n+1] & unique_id==unique_id[_n+1] & partner_id==partner_id[_n+1] & wave==wave[_n+1]-1
replace moved_states_lag = 0 if state_change==1
replace moved_states_lag = 1 if state_fips!=state_fips[_n+1] & unique_id==unique_id[_n+1] & partner_id==partner_id[_n+1] & wave==wave[_n+1]-1
replace moved_states_lag = 0 if moved_states_lag==. & state_fips==state_fips[_n-1] & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1 // last survey waves
replace moved_states_lag = 0 if moved_states_lag==. & state_change!=0 // remaining are last observations

tab moved_states_lag, m

browse unique_id partner_id survey_yr _mi_m state_fips state_change moved_states moved_states_lag rel_start_yr first_survey_yr
tab state_change moved_states_lag, m

// get lagged structural measure
rename structural_familism structural_familism_t

mi passive: gen year_t1 = survey_yr - 1
mi merge m:1 year_t1 state_fips using "$states/structural_familism.dta",keep(match master) // gen(howmatch) keepusing(structural_familism)
drop if howmatch==2

drop f1 state_name concat disapproval genderroles_egal working_mom_egal preschool_egal fepresch fechld fefam month_rent annual_rent month_own annual_own annual_housing hhincome rent_afford own_afford house_afford min_wage min_above_fed unemployment unemployment_comp right2work gdp gender_lfp_gap_nocoll gender_lfp_gap_coll paid_leave cc_cost cc_pct_income educ_spend cc_subsidies senate_dems house_dems gender_discrimin_ban equalpay contraceptive_coverage abortion_protected unemployment_percap prek_enrolled prek_enrolled_public state earn_ratio lfp_ratio pov_ratio pctfemaleleg dv_guns gender_mood child_pov welfare_all welfare_cash_asst ccdf_direct ccdf_total ccdf_per_cap population cc_eligible cc_pct_served cc_served cc_served_percap educ_spend_percap gini earn_ratio_z pctmaleleg no_paid_leave no_dv_gun_law senate_rep house_rep gender_mood_neg earn_ratio_st lfp_ratio_st pov_ratio_st pctfemaleleg_st senate_dems_st house_dems_st dv_guns_st gender_mood_st pctmaleleg_st no_paid_leave_st no_dv_gun_law_st senate_rep_st house_rep_st gender_mood_neg_st structural_sexism maternal_employment parent_earn_ratio gdp_per_cap unemployment_neg cc_pct_income_neg earn_ratio_neg parent_earn_ratio_neg min_below_fed child_pov_neg welfare_neg welfare_cash_neg gdp_neg gdp_percap_neg unemployment_neg_st min_above_fed_st paid_leave_st cc_pct_income_neg_st earn_ratio_neg_st cc_subsidies_st unemployment_st cc_pct_income_st min_below_fed_st child_pov_st child_pov_neg_st min_wage_st welfare_all_st welfare_cash_asst_st welfare_neg_st welfare_cash_neg_st ccdf_direct_st ccdf_per_cap_st cc_served_percap_st cc_pct_served_st educ_spend_st educ_spend_percap_st parent_earn_ratio_st parent_earn_ratio_neg_st maternal_employment_st gdp_st gdp_neg_st gdp_per_cap_st gdp_percap_neg_st gini_st gender_discrimin_ban_st equalpay_st contraceptive_coverage_st abortion_protected_st unemployment_percap_st prek_enrolled_st prek_enrolled_public_st

mi update

rename structural_familism structural_familism_t1

sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr state_fips structural_fam*

// final update and save

mi update

save "$created_data/PSID_first_birth_sample_rec.dta", replace
