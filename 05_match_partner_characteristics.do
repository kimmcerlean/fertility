********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: match_partner_characteristics
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the imputed individual level data that is long
*  and then matches partner's imputed characteristics

use "$created_data_large/PSID_births_imputed_long_sample.dta", clear

// let's see if this will work here on the HPC - okay, it does not
/*
twoway (histogram weekly_hrs_t_focal if imputed==0 & weekly_hrs_t_focal<=100, width(2) color(blue%30)) (histogram weekly_hrs_t_focal if imputed==1 & weekly_hrs_t_focal<=100, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours")
twoway (histogram weekly_hrs_t1_focal if imputed==0 & weekly_hrs_t1_focal<=200, width(2) color(blue%30)) (histogram weekly_hrs_t1_focal if imputed==1 & weekly_hrs_t1_focal<=200, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours (T1)")
twoway (histogram housework_focal if imputed==0 & housework_focal<=50, width(2) color(blue%30)) (histogram housework_focal if imputed==1 & housework_focal<=50, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Housework Hours")
twoway (histogram earnings_t_focal if imputed==0 & earnings_t_focal >=-1000 & earnings_t_focal <=300000, width(10000) color(blue%30)) (histogram earnings_t_focal if imputed==1 & earnings_t_focal >=-1000 & earnings_t_focal <=300000, width(10000) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Annual Earnings")
*/

********************************************************************************
* First, create partner versions of the variables
********************************************************************************
// browse unique_id partner_id relationship_duration min_dur max_dur _mi_miss _mi_m _mi_id imputed first_birth_sample_flag second_birth_flag_cons second_birth_sample_flag

foreach var in COR_IMM_WT CORE_WEIGHT CROSS_SECTION_FAM_WT CROSS_SECTION_WT LONG_WT NUM_CHILDREN AGE_YOUNG_CHILD{
	mi rename `var'_ `var'
}

// just keep necessary variables
local partnervars_fixed "SEX SAMPLE SAMPLE_STATUS_TYPE sample_type  has_psid_gene first_survey_yr last_survey_yr NUM_BIRTHS all_births_shared any_births_pre_rel any_shared_births birth_yr cluster FIRST_BIRTH_YR first_educ_focal last_race_focal raceth_fixed_focal IN_UNIT permanent_attrit first_religion_focal first_marital_status"

local partnervars_time "weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t2_focal earnings_t_focal earnings_t1_focal earnings_t2_focal housework_focal housework_t1_focal housework_t2_focal age_focal shared_birth_in_yr religion_focal religion_t1_focal religion_t2_focal partnered raceth_focal college_focal educ_focal educ_t1_focal educ_t2_focal second_birth_sample_flag second_birth_flag_cons first_birth_sample_flag  any_psid_births_t_focal any_psid_births_t_hh any_psid_births_t1_focal any_psid_births_t1_hh NUM_CHILDREN AGE_YOUNG_CHILD children marital_status_updated relationship_est in_sample COR_IMM_WT CORE_WEIGHT CROSS_SECTION_FAM_WT CROSS_SECTION_WT LONG_WT imputed"

keep unique_id partner_id rel_start_all rel_end_all relationship_duration _mi_miss _mi_m _mi_id  `partnervars_fixed' `partnervars_time'

mi rename partner_id x
mi rename unique_id partner_id
mi rename x unique_id // sp swap unique and partner to match (bc need to know it's the same couple / duration). I guess I could merge on rel_start_all as well

// rename them to indicate they are for spouse
foreach var in `partnervars_fixed' `partnervars_time'{
	mi rename `var' `var'_sp
}

mi update

save "$temp/partner_data_imputed.dta", replace

// unique unique_id partner_id // 19267, 1732896

********************************************************************************
* Match couples
********************************************************************************
// match on partner id and relationship duration
use "$created_data_large/PSID_births_imputed_long_sample", clear

mi merge 1:1 unique_id partner_id relationship_duration using "$temp/partner_data_imputed.dta", keep(match) // gen(howmatch) rel_start_all rel_end_all keep(match master)

// browse unique_id partner_id rel_start_all rel_end_all duration_rec weekly_hrs_t_focal weekly_hrs_t_focal_sp if howmatch!=3
// browse unique_id partner_id rel_start_all rel_end_all duration_rec howmatch weekly_hrs_t_focal weekly_hrs_t_focal_sp if inlist(unique_id, 16032, 18037, 5579003) | inlist(partner_id, 16032, 18037, 5579003)

mi update

save "$created_data_large/PSID_couples_imputed_long.dta", replace

********************************************************************************
**# Clean up variables and figure out first and second birth samples again
* Note: I am figuring this out with ONE imputed dataset (bc they are quite large)
* Once figured out, will run in the server with all to get official sample files
********************************************************************************

use "$created_data/PSID_matched_imputed_mi3.dta", clear

unique unique_id partner_id // 19267, 157536

browse unique_id partner_id relationship_duration survey_yr rel_start_all min_dur SEX SEX_sp weekly_hrs_t_focal weekly_hrs_t_focal_sp weekly_hrs_t1_focal weekly_hrs_t1_focal_sp age_focal age_focal_sp // if inlist(unique_id,4008,4179,4199) //  _mi_m
replace survey_yr = rel_start_all + relationship_duration if survey_yr==.

inspect age_focal age_focal_sp birth_yr birth_yr_sp

replace age_focal = survey_yr - birth_yr if age_focal==. & survey_yr!=.
replace age_focal_sp = survey_yr - birth_yr_sp if age_focal_sp==. & survey_yr!=. & birth_yr_sp!=.

drop if SEX==2 & SEX_sp==2

sum weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t2_focal earnings_t_focal earnings_t1_focal earnings_t2_focal housework_focal housework_t1_focal housework_t2_focal
sum weekly_hrs_t1_focal, detail
sum earnings_t_focal, detail

foreach var in weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t2_focal earnings_t_focal earnings_t1_focal earnings_t2_focal  weekly_hrs_t_focal_sp weekly_hrs_t1_focal_sp weekly_hrs_t2_focal_sp earnings_t_focal_sp earnings_t1_focal_sp earnings_t2_focal_sp housework_focal housework_t1_focal housework_t2_focal{
	sum `var', detail
	replace `var' = `r(p95)' if `var' > `r(p95)' & `var'!=.
	replace `var' = `r(p5)' if `var' < `r(p5)' & `var'!=.
} 

// when have all imputations, need to update this to be mi replace
// mi update

******************************************************************
* First birth sample: conservative (no premarital births)
******************************************************************
// so, most of these (like flags for whether ever had a first birth together, etc.) are fine because were fixed, so automatically got filled in when wide
// it's the time varying sample flags that need to be updated for waves that were imputed so are new here

tab joint_first_birth first_birth_sample_flag, m 
tab joint_first_birth, m // so some of these were missing in original. I *think* it's people without any births are missing here (yes, I wrote that in row 344 of file 4)? BUT, those are in sample bc they are eligible. BUT not eligible to have had a joint first birth
tab cah_child_birth_yr1_ref joint_first_birth, m  col // yes, 90% have 9998/9999 as first birth year, aka NO births
tab NUM_BIRTHS joint_first_birth, m col

browse unique_id partner_id relationship_duration min_dur max_dur survey_yr first_birth_sample_flag any_births_pre_rel num_births_pre_ref num_births_pre_sp joint_first_birth joint_first_birth_yr cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp

tab any_births_pre_rel joint_first_birth, m // think some of this overlap if first birth pre rel start? but mostly, impossible to have pre-rel births AND have a joint first birth - which is the point
tab any_births_pre_rel joint_first_birth_rel, m
tab joint_first_birth_yr joint_first_birth if any_births_pre_rel==0, m // so all of the missing are those without a first birth

gen first_birth_sample_flag_check=0 // this is basically just again doing what I did in step 4, but making sure this is completely filled in.
replace first_birth_sample_flag_check = 1 if any_births_pre_rel==0 // remove if either partner had birth pre-maritally. is this the primary restriction? basically, had to enter relationship without kids?
replace first_birth_sample_flag_check = 0 if num_births_pre_ref!=0 | num_births_pre_sp!=0 // this is causing problems if first birth before the coresidential relationship started
replace first_birth_sample_flag_check = 0 if joint_first_birth_yr==9998 // no first birth year but HAD a joint first birth?
replace first_birth_sample_flag_check = 0 if joint_first_birth_yr< 1990 // remove if before 1990 (bc I don't have data) - prob will need to remove even more if I want to lag, but let's start here
replace first_birth_sample_flag_check = 0 if survey_yr > joint_first_birth_yr // censored observations - years AFTER first birth (if had one)

tab first_birth_sample_flag, m
tab first_birth_sample_flag_check, m 
tab first_birth_sample_flag_check first_birth_sample_flag, m

browse unique_id partner_id relationship_duration min_dur max_dur survey_yr first_birth_sample_flag_check first_birth_sample_flag any_births_pre_rel num_births_pre_ref num_births_pre_sp joint_first_birth joint_first_birth_yr cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp

// there should be no overlap
tab joint_first_birth later_first_birth, m

******************************************************************
* First birth sample: broad (okay to have premarital births)
******************************************************************
* Need to figure this out, because code currently not set up for this? Not sure I have an indicator of this, because basically, everyone is eligible, then, until they have a first birth? Even if you had like 10 births before. Then bbasically I am predicting whether or not you and your partner have a birth together. so essential need a first birth timing for joint first birth and later first birth - okay, duh, I created this: shared_first_birth_yr, largely based on these variables: shared_birth1_refyr shared_birth1_spyr

browse unique_id partner_id relationship_duration min_dur max_dur survey_yr any_births_pre_rel num_births_pre_ref num_births_pre_sp joint_first_birth joint_first_birth_yr later_first_birth later_first_birth_yr cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp
browse unique_id partner_id relationship_duration survey_yr shared_first_birth joint_first_birth later_first_birth shared_first_birth_yr joint_first_birth_yr later_first_birth_yr shared_birth1_refyr shared_birth1_spyr

replace shared_first_birth = 0 if shared_first_birth==.
replace joint_first_birth = 0 if joint_first_birth==.
replace later_first_birth = 0 if later_first_birth==.

// create one first birth year that combines the two?
tab joint_first_birth_yr joint_first_birth, m
tab later_first_birth_yr later_first_birth, m
tab shared_first_birth_yr shared_first_birth, m

tab shared_first_birth, m
tab shared_first_birth joint_first_birth, m
tab shared_first_birth later_first_birth, m

gen first_birth_broad_sample=1 // everyone in sample...
replace first_birth_broad_sample = 0 if survey_yr > shared_first_birth_yr // until you have a first birth. if you never have one (aka this is missing), you are always in sample
replace first_birth_broad_sample = 0 if shared_first_birth_yr<1990 // should get covered above but jic
replace first_birth_broad_sample = 0 if shared_first_birth_yr==9998 // not useful

tab first_birth_broad_sample, m
tab first_birth_broad_sample first_birth_sample_flag_check, m // so 1 of first birth cons should match entirely, then there should be more in broad sample and none where broad is 1 and cons is 0.
tab FIRST_BIRTH_YR first_birth_broad_sample, m

browse unique_id partner_id relationship_duration survey_yr first_birth_broad_sample first_birth_sample_flag_check shared_first_birth joint_first_birth later_first_birth shared_first_birth_yr joint_first_birth_yr later_first_birth_yr shared_birth1_refyr shared_birth1_spyr FIRST_BIRTH_YR FIRST_BIRTH_YR_sp

******************************************************************
* Second birth sample: conservative (no premarital births)
******************************************************************
// note: this is the same as second_birth_flag_cons from step 4. We are using joint_second_birth_opt2. marginally more conservative

tab joint_second_birth_opt1 joint_second_birth_opt3, m cell // perfectly congruent
tab joint_second_birth_opt2 joint_second_birth_opt3, m cell 
tab joint_second_birth_opt1 joint_second_birth_opt2, m cell 
tab joint_second_birth_yr joint_second_birth_opt2, m

// this is same code as for second_birth_flag_cons (from step 4), just filling in missing durations
gen second_birth_cons_sample=. // make this conservative - no premarital births
replace second_birth_cons_sample=0 if cah_num_bio_kids_ref== 0 | cah_num_bio_kids_sp == 0 // can't have second birth if either partner has no births
replace second_birth_cons_sample=0 if any_births_pre_rel== 1  // for posterity, explicitly flag as 0 if had premarital birth
replace second_birth_cons_sample=0 if joint_first_birth==0 // also can't have second birth if no first births together
replace second_birth_cons_sample=1 if joint_first_birth==1 // this is conservative definition of joint first birth (no premarital) so use it here as they need to first fulfill this requirement to be eligible for second birth
replace second_birth_cons_sample = 0 if survey_yr < joint_first_birth_yr // censored observations BEFORE the first birth. Want clock to start at first birth
replace second_birth_cons_sample = 0 if survey_yr > joint_second_birth_yr // censored observations - years AFTER second birth (if had one)

replace second_birth_flag_cons = 0 if second_birth_flag_cons==.
tab second_birth_flag_cons, m
tab second_birth_cons_sample, m
tab second_birth_cons_sample second_birth_flag_cons, m

browse unique_id partner_id relationship_duration survey_yr second_birth_cons_sample second_birth_flag_cons joint_second_birth_opt2 joint_second_birth_yr joint_first_birth joint_first_birth_yr any_births_pre_rel first_birth_sample_flag_check shared_birth1_refyr shared_birth1_spyr shared_birth2_refyr shared_birth2_spyr FIRST_BIRTH_YR FIRST_BIRTH_YR_sp

******************************************************************
* Second birth sample: broad (okay to have premarital births, 
* but had to have a shared first birth, so second birth together)
******************************************************************
// note: this is the same as second_birth_sample_flag from step 4.  We are using joint_second_birth_opt2
// think these will be useful: shared_second_birth shared_second_birth_yr
tab shared_second_birth, m
tab shared_second_birth_yr shared_second_birth, m

// this is same code as for second_birth_sample_flag (from step 4), just filling in missing durations
gen second_birth_broad_sample=. // just need a shared first birth
replace second_birth_broad_sample = 0 if cah_num_bio_kids_ref== 0 | cah_num_bio_kids_sp == 0 // can't have second birth if either partner has no births
replace second_birth_broad_sample = 0 if shared_first_birth==0 // also can't have second birth if no first births together
replace second_birth_broad_sample = 1 if shared_first_birth==1
replace second_birth_broad_sample = 0 if survey_yr < shared_first_birth_yr // censored observations BEFORE the first birth. Want clock to start at first birth
replace second_birth_broad_sample = 0 if survey_yr > shared_second_birth_yr // censored observations - years AFTER second birth (if had one)

replace second_birth_sample_flag = 0 if second_birth_sample_flag==.
tab second_birth_sample_flag, m
tab second_birth_broad_sample, m
tab second_birth_broad_sample second_birth_sample_flag, m
// tab second_birth_sample_flag second_birth_flag_cons, m
tab second_birth_broad_sample second_birth_cons_sample, m

browse unique_id partner_id relationship_duration survey_yr second_birth_broad_sample second_birth_cons_sample joint_second_birth_opt2 joint_second_birth_yr joint_first_birth joint_first_birth_yr any_births_pre_rel first_birth_sample_flag_check shared_birth1_refyr shared_birth1_spyr shared_birth2_refyr shared_birth2_spyr FIRST_BIRTH_YR FIRST_BIRTH_YR_sp

******************************************************************
* Before I start dropping samples, need to create unique family ID
* The provided ones won't work because don't exist when not in sample
* Need to rerun this part before doing next part (in HPC)
******************************************************************

gen sort_id = FAMILY_INTERVIEW_NUM_ if relationship_duration==min_dur
bysort unique_id partner_id (sort_id): replace sort_id = sort_id[1] // one problem here is if, for some reason, each partner has a diff family id at this point... but a quick browse suggests this is okay actually

forvalues d=0/15{
	replace sort_id = FAMILY_INTERVIEW_NUM_ if relationship_duration== `d' & sort_id==. & FAMILY_INTERVIEW_NUM_!=.
	bysort unique_id partner_id (sort_id): replace sort_id = sort_id[1] 
}

replace sort_id = main_fam_id if sort_id==.

inspect sort_id

sort unique_id partner_id relationship_duration
// browse unique_id partner_id sort_id FAMILY_INTERVIEW_NUM_ main_fam_id relationship_duration survey_yr rel_start_all min_dur max_dur if sort_id==.
// inspect min_dur if sort_id==.
// inspect max_dur if sort_id==.
// inspect FAMILY_INTERVIEW_NUM_ if sort_id==.
// inspect main_fam_id if sort_id==. 

browse unique_id partner_id sort_id FAMILY_INTERVIEW_NUM_ main_fam_id relationship_duration survey_yr min_dur max_dur

save "$created_data/PSID_matched_mi3_allbirths.dta", replace

********************************************************************************
**# Notes for next steps
********************************************************************************
// flag variables to filter on in next step:
* First birth conservative: first_birth_sample_flag_check
* First birth broad: first_birth_broad_sample
* Second birth conservative: second_birth_cons_sample
* Second birth broad: second_birth_broad_sample

// need to eventually add
* a. couple-level variables - next file, once restricted to sample
* b. a flag for birth in year - next file, once restricted to sample
* c. remove observations after relevant birth (e.g. after first birth for that sample) - did here to create flags
* d. deduplicate (so just one observation per year)
* e. age restrictions (with matched partner data) - next file, once restricted to sample
