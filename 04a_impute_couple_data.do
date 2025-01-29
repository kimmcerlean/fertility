********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: impute_couple_data
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************

use "$created_data/PSID_couple_births_shared.dta", clear

browse unique_id partner_id survey_yr rel_start_yr relationship_duration in_sample // okay, one problem with doing here is that I haven't yet matched partner data. Do I need to do that first?
// Unless I want to impute the individual level data? that feels crazy, especially if I won't use those people.

// so let's merge partner characteristics
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
replace age_sp = . if age_sp < 0

browse unique_id partner_id survey_yr SEX SEX_sp weekly_hrs_t_focal weekly_hrs_t_sp housework_focal housework_sp age_focal age_sp

// add in indicator of birth in year (potentially to use in imputation) - but remember KIM this is not yet restricted sample (though I do have those flags)
browse unique_id partner_id survey_yr SEX SEX_sp shared_birth1_refyr shared_birth2_refyr shared_birth3_refyr shared_birth1_spyr shared_birth2_spyr shared_birth3_spyr

gen shared_birth_in_yr=0
forvalues b=1/9{
	replace shared_birth_in_yr = 1 if survey_yr == shared_birth`b'_refyr & SEX==2 // prioritize women's reports
	replace shared_birth_in_yr = 1 if survey_yr == shared_birth`b'_spyr & SEX==1
}

tab shared_birth_in_yr, m
browse unique_id partner_id survey_yr rel_start_yr SEX SEX_sp shared_birth_in_yr shared_birth1_refyr shared_birth2_refyr shared_birth3_refyr shared_birth1_spyr shared_birth2_spyr shared_birth3_spyr

// what variables do I want to impute? and how. I guess I should turn wide so can use lags and leads? BUT I also don't want to impute outside of the bounds of the relationship? So the data is going to be unbalanced. I don't like that if I make it wide (bc will just get missing for those years)
// I could also just impute cross-sectionally and JUST impute housework? I guess I can impute with t-1 and t-2. but should I also use t+1, t+2?
inspect housework_focal housework_sp
inspect weekly_hrs_t_focal weekly_hrs_t_sp
inspect earnings_t_focal earnings_t_sp
inspect housework_focal weekly_hrs_t_focal earnings_t_focal if in_sample==1 & survey_yr!=last_survey_yr // are some of these missings bc not in sample? In theory, work variables should not be missing. that doesn't explain all of it. should some of these be ZEROES and not missing? (based on employment status - but that is point in time...) should I update to 0s? but could have worked at other parts of the year.
inspect housework_sp weekly_hrs_t_sp earnings_t_sp if in_sample_sp==1

browse unique_id survey_yr first_survey_yr last_survey_yr age_focal in_sample housework_focal employed_focal weekly_hrs_t_focal earnings_t_focal weekly_hrs_t1_focal earnings_t1_focal // so some are 0s. Some appear to be off years that I couldn't get data for (because corresponds to off year where they then have no more data following) OH and a bunch are 2021 because all of the data is t-1, so no data available yet. okay, yes ignoring 2021 / last survey yr helps reduce the missing

drop if survey_yr > last_survey_yr
tabstat weekly_hrs_t_focal earnings_t_focal, by(employed_focal)
inspect weekly_hrs_t_focal earnings_t_focal if employed_focal==0
inspect weekly_hrs_t_focal earnings_t_focal if employed_focal==1

// clean up data
drop if raceth_fixed_focal==. // for now, just so this is actually complete
drop if age_focal==. // so complete
drop if partner_id==. // so only MATCHED observations for now
drop if age_sp==.
drop if raceth_fixed_sp==. 

********************************************************************************
**# Imputation. going to see if I can do focal and spouse in one go
********************************************************************************
mi set flong
mi register imputed weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t2_focal housework_focal housework_t1_focal housework_t2_focal earnings_t_focal earnings_t1_focal earnings_t2_focal educ_focal educ_t1_focal educ_t2_focal religion_focal religion_t1_focal religion_t2_focal weekly_hrs_t_sp weekly_hrs_t1_sp weekly_hrs_t2_sp earnings_t_sp earnings_t1_sp earnings_t2_sp housework_sp housework_t1_sp housework_t2_sp educ_sp educ_t1_sp educ_t2_sp religion_sp religion_t1_sp religion_t2_sp NUM_CHILDREN_ AGE_YOUNG_CHILD_ 
mi register regular survey_yr age_focal age_sp SEX SEX_sp raceth_fixed_focal raceth_fixed_sp sample_type sample_type_sp rel_start_yr shared_birth_in_yr // FIRST_BIRTH_YR relationship_est

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

= i.survey_yr age_focal age_sp i.SEX i.SEX_sp i.raceth_fixed_focal i.raceth_fixed_sp i.sample_type i.sample_type_sp  i.rel_start_yr i.shared_birth_in_yr, chaindots add(1) burnin(1) rseed(8675309) noimputed augment // dryrun // force augment noisily 
/* if I want to do by sex
= i.survey_yr i.age_focal i.raceth_fixed_focal i.sample_type  i.rel_start_yr i.relationship_est i.shared_birth_in_yr i.FIRST_BIRTH_YR, by(SEX) chaindots add(1) rseed(8675309) noimputed noisily // dryrun // force augment noisily
*/

;
#delimit cr

save "$created_data/PSID_couple_births_imputed.dta", replace

// let's look at some descriptives regarding data distributions

gen imputed=0
replace imputed=1 if inrange(_mi_m,1,10)

inspect weekly_hrs_t_focal earnings_t_focal housework_focal weekly_hrs_t_sp earnings_t_sp housework_sp if imputed==0
inspect weekly_hrs_t_focal earnings_t_focal housework_focal weekly_hrs_t_sp earnings_t_sp housework_sp if imputed==1

tabstat  weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t2_focal earnings_t_focal earnings_t1_focal earnings_t2_focal housework_focal housework_t1_focal housework_t2_focal educ_focal educ_t1_focal educ_t2_focal religion_focal religion_t1_focal religion_t2_focal, by(imputed) stats(mean sd p50)
tabstat  weekly_hrs_t_sp weekly_hrs_t1_sp weekly_hrs_t2_sp earnings_t_sp earnings_t1_sp earnings_t2_sp housework_sp housework_t1_sp housework_t2_sp educ_sp educ_t1_sp educ_t2_sp religion_sp religion_t1_sp religion_t2_sp, by(imputed) stats(mean sd p50)

twoway (histogram weekly_hrs_t_focal if imputed==0 & weekly_hrs_t_focal<=100, width(2) color(blue%30)) (histogram weekly_hrs_t_focal if imputed==1 & weekly_hrs_t_focal<=100, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours")
twoway (histogram housework_focal if imputed==0 & housework_focal<=50, width(2) color(blue%30)) (histogram housework_focal if imputed==1 & housework_focal<=50, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Housework Hours")
twoway (histogram earnings_t_focal if imputed==0, width(2) color(blue%30)) (histogram earnings_t_focal if imputed==1, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Annual Earnings")

twoway (histogram weekly_hrs_t_sp if imputed==0 & weekly_hrs_t_sp<=100, width(2) color(blue%30)) (histogram weekly_hrs_t_sp if imputed==1 & weekly_hrs_t_sp<=100, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours")
twoway (histogram housework_sp if imputed==0 & housework_sp<=50, width(2) color(blue%30)) (histogram housework_sp if imputed==1 & housework_sp<=50, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Housework Hours")
twoway (histogram earnings_t_sp if imputed==0, width(2) color(blue%30)) (histogram earnings_t_sp if imputed==1, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Annual Earnings")

