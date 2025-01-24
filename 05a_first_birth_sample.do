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

replace age_sp = survey_yr - birth_yr_sp if age_sp==.

browse unique_id partner_id survey_yr SEX weekly_hrs_t_focal weekly_hrs_t_sp housework_focal housework_sp age_focal age_sp

********************************************************************************
* add in birth indicators - aka create our DV and final sample clean up
********************************************************************************

unique unique_id partner_id, by(joint_first_birth)
replace joint_first_birth=0 if joint_first_birth==.

tab cah_child_birth_yr1_ref joint_first_birth, m // so there should not be birth years here for 0s? about 22% have?
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
	// a. I am not following people after their relationship end year / last survey year (if censored) OR capturing births after this
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

********************************************************************************
**# Create gendered variables and couple-level IVs
********************************************************************************
