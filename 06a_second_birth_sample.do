********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: second_birth_sample
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the second birth sample, adds on partner characteristics
* and creates necessary couple-level variables and final sample restrictions
* Also adds in birth DVs (right now time constant, need to be time-varying)

use "$created_data/PSID_second_birth_sample.dta", clear

// first merge partner characteristics
merge 1:1 partner_id survey_yr using "$created_data\PSID_individ_allyears.dta", keepusing(*_sp) // created step 2 - there are no missing partner ids for second births

drop if _merge==2
tab _merge
drop _merge

replace age_sp = survey_yr - birth_yr_sp if age_sp==. & birth_yr_sp!=9999
inspect age_sp
inspect age_focal

browse unique_id partner_id survey_yr SEX weekly_hrs_t_focal weekly_hrs_t_sp housework_focal housework_sp age_focal age_sp

********************************************************************************
* add in birth indicators - aka create our DV
********************************************************************************
unique unique_id partner_id, by(joint_second_birth_opt2)
replace joint_second_birth_opt2=0 if joint_second_birth_opt2==.

browse unique_id partner_id survey_yr rel_start_yr rel_end_yr any_births_pre_rel joint_second_birth_opt2 joint_second_birth_yr joint_first_birth_yr joint_second_birth_timing first_survey_yr last_survey_yr first_survey_yr_sp last_survey_yr_sp cah_child_birth_yr2_ref cah_child_birth_yr2_sp shared_birth2_refyr shared_birth2_spyr num_births_pre_ref num_births_pre_sp

tab cah_child_birth_yr2_ref joint_second_birth_opt2, m // so there should not be birth years here for 0s? about 10% have? so some (most?) is bc AFTER relationship ended
tab cah_child_birth_yr2_ref joint_second_birth_opt2 if num_births_pre_ref==0 & num_births_pre_sp==0, m 
tab shared_birth2_refyr joint_second_birth_opt2, m col nofreq // so there are less shared, but that's almost worse? are actually better bc suggests it is shared? and just before teh relationship started
tab shared_birth2_spyr joint_second_birth_opt2, m col nofreq

foreach var in any_births_pre_rel num_births_pre_ref num_births_pre_indv_ref num_births_pre_sp num_births_pre_indv_sp{
	tab `var', m
}
// so the ref and spouse births pre rel at INDIVIDUAL level + the joint indicator are all 0
// so I think these are pre rel births that are shared? so I do need to remove? maybe it's okay if the first birth is pre, but the second is post and observed? bc that is what I care about here?

gen had_second_birth=0
replace had_second_birth=1 if survey_yr==joint_second_birth_yr
tab had_second_birth, m
tab joint_second_birth_opt2 had_second_birth, m

browse unique_id partner_id survey_yr rel_start_yr rel_end_yr joint_second_birth_opt2 had_second_birth joint_second_birth_yr joint_second_birth_timing first_survey_yr last_survey_yr first_survey_yr_sp last_survey_yr_sp cah_child_birth_yr2_ref cah_child_birth_yr2_sp shared_birth2_refyr shared_birth2_spyr num_births_pre_ref num_births_pre_sp

gen time_since_first_birth= survey_yr - joint_first_birth_yr
tab time_since_first_birth, m
tab time_since_first_birth had_second_birth, m row

browse unique_id partner_id survey_yr rel_start_yr rel_end_yr joint_first_birth_yr time_since_first_birth had_second_birth joint_second_birth_opt2 joint_second_birth_yr joint_second_birth_timing

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
unique unique_id partner_id if joint_second_birth_opt2==1

unique unique_id partner_id if rel_start_yr >= 2005 // focus on post-recession period?
unique unique_id partner_id if joint_second_birth_opt2==1 & rel_start_yr >= 2005 // focus on post-recession period?

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
mi register regular survey_yr age_focal age_sp SEX SEX_sp raceth_fixed_focal raceth_fixed_sp sample_type sample_type_sp rel_start_yr had_second_birth time_since_first_birth // FIRST_BIRTH_YR relationship_est

#delimit ;

mi impute chained

/* work hours */
(pmm, knn(5) include (weekly_hrs_t1_focal weekly_hrs_t2_focal housework_focal earnings_t_focal educ_focal religion_focal NUM_CHILDREN_ AGE_YOUNG_CHILD_)) weekly_hrs_t_focal
(pmm, knn(5) include (weekly_hrs_t_focal weekly_hrs_t2_focal housework_t1_focal earnings_t1_focal educ_t1_focal religion_t1_focal)) weekly_hrs_t1_focal
(pmm, knn(5) include (weekly_hrs_t_focal weekly_hrs_t1_focal housework_t2_focal earnings_t2_focal educ_t2_focal religion_t2_focal)) weekly_hrs_t2_focal

(pmm, knn(5) include (weekly_hrs_t1_sp weekly_hrs_t2_sp housework_sp earnings_t_sp educ_sp religion_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_)) weekly_hrs_t_sp
(pmm, knn(5) include (weekly_hrs_t_sp weekly_hrs_t2_sp housework_t1_sp earnings_t1_sp educ_t1_sp religion_t1_sp)) weekly_hrs_t1_sp
(pmm, knn(5) include (weekly_hrs_t_sp weekly_hrs_t1_sp housework_t2_sp earnings_t2_sp educ_t2_sp religion_t2_sp)) weekly_hrs_t2_sp

/* earnings */
(pmm, knn(5) include (weekly_hrs_t_focal earnings_t2_focal housework_focal earnings_t1_focal educ_focal religion_focal NUM_CHILDREN_ AGE_YOUNG_CHILD_)) earnings_t_focal
(pmm, knn(5) include (weekly_hrs_t1_focal earnings_t2_focal housework_t1_focal earnings_t_focal educ_t1_focal religion_t1_focal)) earnings_t1_focal
(pmm, knn(5) include (earnings_t_focal weekly_hrs_t2_focal housework_t2_focal earnings_t1_focal educ_t2_focal religion_t2_focal)) earnings_t2_focal

(pmm, knn(5) include (weekly_hrs_t_sp earnings_t2_sp housework_sp earnings_t1_sp educ_sp religion_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_)) earnings_t_sp
(pmm, knn(5) include (weekly_hrs_t1_sp earnings_t2_sp housework_t1_sp earnings_t_sp educ_t1_sp religion_t1_sp)) earnings_t1_sp
(pmm, knn(5) include (earnings_t_sp weekly_hrs_t2_sp housework_t2_sp earnings_t1_sp educ_t2_sp religion_t2_sp)) earnings_t2_sp

/* housework */
(pmm, knn(5) include (weekly_hrs_t_focal housework_t2_focal earnings_t_focal housework_t1_focal educ_focal religion_focal NUM_CHILDREN_ AGE_YOUNG_CHILD_)) housework_focal
(pmm, knn(5) include (weekly_hrs_t1_focal housework_t2_focal housework_focal earnings_t1_focal educ_t1_focal religion_t1_focal)) housework_t1_focal
(pmm, knn(5) include (housework_t1_focal weekly_hrs_t2_focal earnings_t2_focal housework_focal educ_t2_focal religion_t2_focal)) housework_t2_focal

(pmm, knn(5) include (weekly_hrs_t_sp housework_t2_sp earnings_t_sp housework_t1_sp educ_sp religion_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_)) housework_sp
(pmm, knn(5) include (weekly_hrs_t1_sp housework_t2_sp housework_sp earnings_t1_sp educ_t1_sp religion_t1_sp)) housework_t1_sp
(pmm, knn(5) include (housework_t1_sp weekly_hrs_t2_sp earnings_t2_sp housework_sp educ_t2_sp religion_t2_sp)) housework_t2_sp

/* other controls */
(ologit, include (educ_t2_focal educ_t1_focal)) educ_focal
(ologit, include (educ_t2_focal educ_focal)) educ_t1_focal
(ologit, include (educ_focal educ_t1_focal)) educ_t2_focal
(pmm, knn(5) include (weekly_hrs_t_focal religion_t2_focal earnings_t_focal housework_focal educ_focal religion_t1_focal NUM_CHILDREN_ AGE_YOUNG_CHILD_)) religion_focal
(pmm, knn(5) include (weekly_hrs_t1_focal housework_t1_focal religion_t2_focal earnings_t1_focal educ_t1_focal religion_focal)) religion_t1_focal
(pmm, knn(5) include (religion_focal weekly_hrs_t2_focal earnings_t2_focal housework_t2_focal educ_t2_focal religion_t1_focal)) religion_t2_focal

(ologit, include (educ_t2_sp educ_t1_sp)) educ_sp
(ologit, include (educ_t2_sp educ_sp)) educ_t1_sp
(ologit, include (educ_sp educ_t1_sp)) educ_t2_sp
(pmm, knn(5) include (weekly_hrs_t_sp religion_t2_sp earnings_t_sp housework_sp educ_sp religion_t1_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_)) religion_sp
(pmm, knn(5) include (weekly_hrs_t1_sp housework_t1_sp religion_t2_sp earnings_t1_sp educ_t1_sp religion_sp)) religion_t1_sp
(pmm, knn(5) include (religion_sp weekly_hrs_t2_sp earnings_t2_sp housework_t2_sp educ_t2_sp religion_t1_sp)) religion_t2_sp

/* child vars */
(pmm, knn(5) include (weekly_hrs_t_focal housework_focal earnings_t_focal educ_focal religion_focal weekly_hrs_t_sp housework_sp earnings_t_sp educ_sp religion_sp AGE_YOUNG_CHILD_)) NUM_CHILDREN_
(pmm, knn(5) include (weekly_hrs_t_focal housework_focal earnings_t_focal educ_focal religion_focal weekly_hrs_t_sp housework_sp earnings_t_sp educ_sp religion_sp NUM_CHILDREN_)) AGE_YOUNG_CHILD_

= i.survey_yr age_focal age_sp i.SEX i.SEX_sp i.raceth_fixed_focal i.raceth_fixed_sp i.sample_type i.sample_type_sp  i.rel_start_yr i.had_second_birth i.time_since_first_birth, chaindots add(10) rseed(8675309) noimputed augment // chainonly savetrace(impstats) // dryrun // force augment noisily burnin(1)
/* if I want to do by sex
= i.survey_yr i.age_focal i.raceth_fixed_focal i.sample_type  i.rel_start_yr i.relationship_est i.shared_birth_in_yr i.FIRST_BIRTH_YR, by(SEX) chaindots add(1) rseed(8675309) noimputed noisily // dryrun // force augment noisily
*/

;
#delimit cr

save "$temp/PSID_second_birth_imputed.dta", replace

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
**# Create gendered variables and couple-level IVs
********************************************************************************
foreach var in educ raceth raceth_fixed religion weekly_hrs_t earnings_t housework housework_t1 weekly_hrs_t1 earnings_t1{
	gen `var'_man = `var'_focal if SEX==1
	replace `var'_man = `var'_sp if SEX==2
	
	gen `var'_woman = `var'_focal if SEX==2
	replace `var'_woman = `var'_sp if SEX==1
}

browse unique_id partner_id survey_yr SEX SEX_sp weekly_hrs_t_woman weekly_hrs_t_man weekly_hrs_t_focal weekly_hrs_t_sp

// couple-level education
gen college_man = .
replace college_man = 0 if inlist(educ_man,1,2,3)
replace college_man = 1 if educ_man==4

gen college_woman = .
replace college_woman = 0 if inlist(educ_woman,1,2,3)
replace college_woman = 1 if educ_woman==4

gen couple_educ_gp=.
replace couple_educ_gp=0 if college_man==0 & college_woman==0
replace couple_educ_gp=1 if (college_man==1 | college_woman==1)

label define couple_educ 0 "Neither College" 1 "At Least One College"
label values couple_educ_gp couple_educ

gen educ_type=.
replace educ_type=1 if educ_man > educ_woman & educ_man!=. & educ_woman!=.
replace educ_type=2 if educ_man < educ_woman & educ_man!=. & educ_woman!=.
replace educ_type=3 if educ_man == educ_woman & educ_man!=. & educ_woman!=.

label define educ_type 1 "Hyper" 2 "Hypo" 3 "Homo"
label values educ_type educ_type

// income and division of paid labor
egen couple_earnings = rowtotal(earnings_t_man earnings_t_woman)
browse unique_id partner_id SEX SEX_sp survey_yr couple_earnings earnings_t_man earnings_t_woman earnings_t_focal earnings_t_sp
	
gen female_earn_pct = earnings_t_woman/(couple_earnings)

gen hh_earn_type=.
replace hh_earn_type=1 if female_earn_pct >=.4000 & female_earn_pct <=.6000
replace hh_earn_type=2 if female_earn_pct < .4000 & female_earn_pct >=0
replace hh_earn_type=3 if female_earn_pct > .6000 & female_earn_pct <=1
replace hh_earn_type=4 if earnings_t_man==0 & earnings_t_woman==0

label define hh_earn_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_earn_type hh_earn_type

* t-1 version
egen couple_earnings_t1 = rowtotal(earnings_t1_man earnings_t1_woman)
	
gen female_earn_pct_t1 = earnings_t1_woman/(couple_earnings_t1)

gen hh_earn_type_t1=.
replace hh_earn_type_t1=1 if female_earn_pct_t1 >=.4000 & female_earn_pct_t1 <=.6000
replace hh_earn_type_t1=2 if female_earn_pct_t1 < .4000 & female_earn_pct_t1 >=0
replace hh_earn_type_t1=3 if female_earn_pct_t1 > .6000 & female_earn_pct_t1 <=1
replace hh_earn_type_t1=4 if earnings_t1_man==0 & earnings_t1_woman==0

label values hh_earn_type_t1 hh_earn_type
tab hh_earn_type_t1, m
tab hh_earn_type hh_earn_type_t1, m

browse unique_id partner_id survey_yr hh_earn_type couple_earnings earnings_t_man earnings_t_woman hh_earn_type_t1 couple_earnings_t1 earnings_t1_man earnings_t1_woman  

// hours instead of earnings
egen couple_hours = rowtotal(weekly_hrs_t_man weekly_hrs_t_woman)
gen female_hours_pct = weekly_hrs_t_woman/couple_hours

gen hh_hours_type=.
replace hh_hours_type=1 if female_hours_pct >=.4000 & female_hours_pct <=.6000
replace hh_hours_type=2 if female_hours_pct <.4000
replace hh_hours_type=3 if female_hours_pct >.6000 & female_hours_pct!=.
replace hh_hours_type=4 if weekly_hrs_t_man==0 & weekly_hrs_t_woman==0

label define hh_hours_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_hours_type hh_hours_type

	// browse unique_id partner_id survey_yr hh_hours_type weekly_hrs_t_man weekly_hrs_t_woman

* t-1 version
egen couple_hours_t1 = rowtotal(weekly_hrs_t1_man weekly_hrs_t1_woman)
gen female_hours_pct_t1 = weekly_hrs_t1_woman/couple_hours_t1

gen hh_hours_type_t1=.
replace hh_hours_type_t1=1 if female_hours_pct_t1 >=.4000 & female_hours_pct_t1 <=.6000
replace hh_hours_type_t1=2 if female_hours_pct_t1 <.4000
replace hh_hours_type_t1=3 if female_hours_pct_t1 >.6000 & female_hours_pct_t1!=.
replace hh_hours_type_t1=4 if weekly_hrs_t1_man==0 & weekly_hrs_t1_woman==0

label values hh_hours_type_t1 hh_hours_type
tab hh_hours_type , m
tab hh_hours_type_t1, m

browse unique_id partner_id survey_yr hh_hours_type couple_hours weekly_hrs_t_man weekly_hrs_t_woman hh_hours_type_t1 couple_hours_t1 weekly_hrs_t1_man weekly_hrs_t1_woman  

// now based on employment
* first need to create some variables
gen ft_pt_woman = .
replace ft_pt_woman = 0 if weekly_hrs_t_woman==0 // not working
replace ft_pt_woman = 1 if weekly_hrs_t_woman > 0 & weekly_hrs_t_woman < 35 // PT
replace ft_pt_woman = 2 if weekly_hrs_t_woman >=35 & weekly_hrs_t_woman < 50 // FT: normal
replace ft_pt_woman = 3 if weekly_hrs_t_woman >=50 & weekly_hrs_t_woman < 150 // FT: overwork

gen ft_pt_t1_woman = .
replace ft_pt_t1_woman = 0 if weekly_hrs_t1_woman==0 // not working
replace ft_pt_t1_woman = 1 if weekly_hrs_t1_woman > 0 & weekly_hrs_t1_woman < 35 // PT
replace ft_pt_t1_woman = 2 if weekly_hrs_t1_woman >=35 & weekly_hrs_t1_woman < 50 // FT: normal
replace ft_pt_t1_woman = 3 if weekly_hrs_t1_woman >=50 & weekly_hrs_t1_woman < 150 // FT: overwork

gen ft_pt_man = .
replace ft_pt_man = 0 if weekly_hrs_t_man==0 // not working
replace ft_pt_man = 1 if weekly_hrs_t_man > 0 & weekly_hrs_t_man < 35 // PT
replace ft_pt_man = 2 if weekly_hrs_t_man >=35 & weekly_hrs_t_man < 50 // FT: normal
replace ft_pt_man = 3 if weekly_hrs_t_man >=50 & weekly_hrs_t_man < 150 // FT: overwork

gen ft_pt_t1_man = .
replace ft_pt_t1_man = 0 if weekly_hrs_t1_man==0 // not working
replace ft_pt_t1_man = 1 if weekly_hrs_t1_man > 0 & weekly_hrs_t1_man < 35 // PT
replace ft_pt_t1_man = 2 if weekly_hrs_t1_man >=35 & weekly_hrs_t1_man < 50 // FT: normal
replace ft_pt_t1_man = 3 if weekly_hrs_t1_man >=50 & weekly_hrs_t1_man < 150 // FT: overwork

label define ft_pt 0 "Not working" 1 "PT" 2 "FT: Normal" 3 "FT: Overwork"
label values ft_pt_woman ft_pt_t1_woman ft_pt_man ft_pt_t1_man ft_pt

* couple-level version
tab ft_pt_woman ft_pt_man

gen couple_work=.
replace couple_work = 1 if inlist(ft_pt_man,2,3) & ft_pt_woman == 0 // any FT
replace couple_work = 2 if inlist(ft_pt_man,2,3) & ft_pt_woman == 1
replace couple_work = 3 if inlist(ft_pt_man,2,3) & inlist(ft_pt_woman,2,3)
replace couple_work = 4 if ft_pt_man == 0 & inlist(ft_pt_woman,2,3)
replace couple_work = 4 if ft_pt_man == 1 & inlist(ft_pt_woman,2,3)
replace couple_work = 5 if ft_pt_man == 1 & ft_pt_woman == 1
replace couple_work = 6 if ft_pt_man == 0 & ft_pt_woman == 0
replace couple_work = 6 if ft_pt_man == 0 & ft_pt_woman == 1
replace couple_work = 6 if ft_pt_man == 1 & ft_pt_woman == 0

label define couple_work 1 "male bw" 2 "1.5 male bw" 3 "dual FT" 4 "female bw" 5 "dual PT" 6 "under work"
label values couple_work couple_work

tab couple_work, m

* with overwork
gen couple_work_ow=.
replace couple_work_ow = 1 if inlist(ft_pt_man,2,3) & ft_pt_woman == 0
replace couple_work_ow = 2 if inlist(ft_pt_man,2,3) & ft_pt_woman == 1
replace couple_work_ow = 3 if ft_pt_man == 2 & ft_pt_woman == 2
replace couple_work_ow = 4 if ft_pt_man == 3 & ft_pt_woman == 2
replace couple_work_ow = 5 if ft_pt_man == 2 & ft_pt_woman == 3
replace couple_work_ow = 6 if ft_pt_man == 3 & ft_pt_woman == 3
replace couple_work_ow = 7 if ft_pt_man == 0 & inlist(ft_pt_woman,2,3)
replace couple_work_ow = 7 if ft_pt_man == 1 & inlist(ft_pt_woman,2,3)
replace couple_work_ow = 8 if ft_pt_man == 1 & ft_pt_woman == 1
replace couple_work_ow = 8 if ft_pt_man == 0 & ft_pt_woman == 0
replace couple_work_ow = 8 if ft_pt_man == 0 & ft_pt_woman == 1
replace couple_work_ow = 8 if ft_pt_man == 1 & ft_pt_woman == 0

label define couple_work_ow 1 "male bw" 2 "1.5 male bw" 3 "dual FT: no OW" 4 "dual FT: his OW" 5 "dual FT: her OW" 6 "dual FT: both OW" /// 
7 "female bw" 8 "under work"
label values couple_work_ow couple_work_ow

tab couple_work_ow, m

browse unique_id partner_id survey_yr couple_work couple_work_ow weekly_hrs_t_man weekly_hrs_t_woman 

* t1 versions
gen couple_work_t1=.
replace couple_work_t1 = 1 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 0 // any FT
replace couple_work_t1 = 2 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 1
replace couple_work_t1 = 3 if inlist(ft_pt_t1_man,2,3) & inlist(ft_pt_t1_woman,2,3)
replace couple_work_t1 = 4 if ft_pt_t1_man == 0 & inlist(ft_pt_t1_woman,2,3)
replace couple_work_t1 = 4 if ft_pt_t1_man == 1 & inlist(ft_pt_t1_woman,2,3)
replace couple_work_t1 = 5 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 1
replace couple_work_t1 = 6 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 0
replace couple_work_t1 = 6 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 1
replace couple_work_t1 = 6 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 0

label values couple_work_t1 couple_work

gen couple_work_ow_t1=.
replace couple_work_ow_t1 = 1 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 0
replace couple_work_ow_t1 = 2 if inlist(ft_pt_t1_man,2,3) & ft_pt_t1_woman == 1
replace couple_work_ow_t1 = 3 if ft_pt_t1_man == 2 & ft_pt_t1_woman == 2
replace couple_work_ow_t1 = 4 if ft_pt_t1_man == 3 & ft_pt_t1_woman == 2
replace couple_work_ow_t1 = 5 if ft_pt_t1_man == 2 & ft_pt_t1_woman == 3
replace couple_work_ow_t1 = 6 if ft_pt_t1_man == 3 & ft_pt_t1_woman == 3
replace couple_work_ow_t1 = 7 if ft_pt_t1_man == 0 & inlist(ft_pt_t1_woman,2,3)
replace couple_work_ow_t1 = 7 if ft_pt_t1_man == 1 & inlist(ft_pt_t1_woman,2,3)
replace couple_work_ow_t1 = 8 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 1
replace couple_work_ow_t1 = 8 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 0
replace couple_work_ow_t1 = 8 if ft_pt_t1_man == 0 & ft_pt_t1_woman == 1
replace couple_work_ow_t1 = 8 if ft_pt_t1_man == 1 & ft_pt_t1_woman == 0

label values couple_work_ow_t1 couple_work_ow

tab couple_work_t1, m
tab couple_work, m
tab couple_work_ow_t1, m
tab couple_work_ow, m

// housework hours
egen couple_housework = rowtotal (housework_woman housework_man)

gen wife_housework_pct = housework_woman / couple_housework

gen housework_bkt=.
replace housework_bkt=1 if wife_housework_pct >=.4000 & wife_housework_pct <=.6000
replace housework_bkt=2 if wife_housework_pct >.6000 & wife_housework_pct!=.
replace housework_bkt=3 if wife_housework_pct <.4000
replace housework_bkt=4 if housework_woman==0 & housework_man==0

label define housework_bkt 1 "Dual HW" 2 "Female Primary" 3 "Male Primary" 4 "NA"
label values housework_bkt housework_bkt

tab housework_bkt, m
tab survey_yr housework_bkt, m

/*
sort unique_id partner_id survey_yr
gen housework_bkt_t1 = .
replace housework_bkt_t1 = housework_bkt[_n-1] if unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1 // I could probably get a lag from the individual level data? so the first year won't be missing by defaul
*/

egen couple_housework_t1 = rowtotal (housework_t1_man housework_t1_woman)

gen wife_housework_pct_t1 = housework_t1_woman / couple_housework_t1

gen housework_bkt_t1=.
replace housework_bkt_t1=1 if wife_housework_pct_t1 >=.4000 & wife_housework_pct_t1 <=.6000
replace housework_bkt_t1=2 if wife_housework_pct_t1 >.6000 & wife_housework_pct_t1!=.
replace housework_bkt_t1=3 if wife_housework_pct_t1 <.4000
replace housework_bkt_t1=4 if housework_t1_woman==0 & housework_t1_man==0

label values housework_bkt_t1 housework_bkt

tab survey_yr housework_bkt_t1, m
label values housework_bkt_t1 housework_bkt

browse unique_id partner_id survey_yr housework_bkt housework_bkt_t1

// combined paid and unpaid
gen hours_housework=.
replace hours_housework=1 if hh_hours_type==1 & housework_bkt==1 // dual both (egal)
replace hours_housework=2 if hh_hours_type==1 & housework_bkt==2 // dual earner, female HM (second shift)
replace hours_housework=3 if hh_hours_type==2 & housework_bkt==2 // male BW, female HM (traditional)
replace hours_housework=4 if hh_hours_type==3 & housework_bkt==3 // female BW, male HM (counter-traditional)
replace hours_housework=5 if hours_housework==. & hh_hours_type!=. & housework_bkt!=. // all others

label define hours_housework 1 "Egal" 2 "Second Shift" 3 "Traditional" 4 "Counter Traditional" 5 "All others"
label values hours_housework hours_housework 

tab survey_yr hours_housework, m // going to be missing whenever housework is missing, which is often
tab hh_hours_type housework_bkt, m cell nofreq
tab hours_housework, m

gen hours_housework_t1=.
replace hours_housework_t1=1 if hh_hours_type_t1==1 & housework_bkt_t1==1 // dual both (egal)
replace hours_housework_t1=2 if hh_hours_type_t1==1 & housework_bkt_t1==2 // dual earner, female HM (second shift)
replace hours_housework_t1=3 if hh_hours_type_t1==2 & housework_bkt_t1==2 // male BW, female HM (traditional)
replace hours_housework_t1=4 if hh_hours_type_t1==3 & housework_bkt_t1==3 // female BW, male HM (counter-traditional)
replace hours_housework_t1=5 if hours_housework_t1==. & hh_hours_type_t1!=. & housework_bkt_t1!=. // all others

label values hours_housework_t1 hours_housework 

// get lagged structural measure
rename structural_familism structural_familism_t

gen year_t1 = survey_yr - 1
merge m:1 year_t1 state_fips using "$states/structural_familism.dta", keepusing(structural_familism)
rename structural_familism structural_familism_t1
drop if _merge==2
drop _merge

sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr state_fips structural_fam*

save "$created_data/PSID_second_birth_sample_rec.dta", replace
