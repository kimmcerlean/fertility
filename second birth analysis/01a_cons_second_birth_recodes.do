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

/* Steps I wrote in file 5 we need to make sure are done by end of this file:
* a. couple-level variables - do here
* b. a flag for birth in year - do here
* c. remove observations after relevant birth (e.g. after first birth for that sample) - did in prev file
* d. deduplicate (so just one observation per year) - did in prev file
* e. age restrictions (with matched partner data) - do here
*/

use "$created_data/PSID_second_birth_sample_cons.dta", clear

********************************************************************************
* First, look at imputation descriptives that I couldn't really do in other files
********************************************************************************
// let's look at some descriptives regarding data distributions

inspect weekly_hrs_t_focal earnings_t_focal housework_focal weekly_hrs_t_focal_sp earnings_t_focal_sp housework_focal_sp if imputed==0
inspect weekly_hrs_t_focal earnings_t_focal housework_focal weekly_hrs_t_focal_sp earnings_t_focal_sp housework_focal_sp if imputed==1

sum weekly_hrs_t_focal weekly_hrs_t_focal_x weekly_hrs_t1_focal weekly_hrs_t1_focal_x earnings_t_focal earnings_t_focal_x earnings_t1_focal earnings_t1_focal_x housework_focal housework_focal_x
sum weekly_hrs_t_focal_sp weekly_hrs_t_focal_sp_x weekly_hrs_t1_focal_sp weekly_hrs_t1_focal_sp_x earnings_t_focal_sp earnings_t_focal_sp_x earnings_t1_focal_sp earnings_t1_focal_sp_x housework_focal_sp housework_focal_sp_x

// focal 
tabstat weekly_hrs_t_focal weekly_hrs_t_focal_x weekly_hrs_t1_focal weekly_hrs_t1_focal_x earnings_t_focal earnings_t_focal_x earnings_t1_focal earnings_t1_focal_x housework_focal housework_focal_x, by(imputed) stats(mean sd p50)
tabstat  weekly_hrs_t_focal weekly_hrs_t1_focal earnings_t_focal earnings_t1_focal housework_focal housework_t1_focal weekly_hrs_t2_focal earnings_t2_focal housework_t2_focal, by(imputed) stats(mean sd p50)

// spouse
tabstat weekly_hrs_t_focal_sp weekly_hrs_t_focal_sp_x weekly_hrs_t1_focal_sp weekly_hrs_t1_focal_sp_x earnings_t_focal_sp earnings_t_focal_sp_x earnings_t1_focal_sp earnings_t1_focal_sp_x housework_focal_sp housework_focal_sp_x, by(imputed) stats(mean sd p50)
tabstat  weekly_hrs_t_focal_sp weekly_hrs_t1_focal_sp earnings_t_focal_sp earnings_t1_focal_sp housework_focal_sp housework_t1_focal_sp weekly_hrs_t2_focal_sp earnings_t2_focal_sp housework_t2_focal_sp, by(imputed) stats(mean sd p50)

twoway (histogram weekly_hrs_t_focal if imputed==0 & weekly_hrs_t_focal<=100, width(2) color(blue%30)) (histogram weekly_hrs_t_focal if imputed==1 & weekly_hrs_t_focal<=100, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours")
twoway (histogram weekly_hrs_t_focal_x if imputed==0 & weekly_hrs_t_focal_x<=100, width(2) color(blue%30)) (histogram weekly_hrs_t_focal_x if imputed==1 & weekly_hrs_t_focal_x<=100, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours")
twoway (histogram housework_focal if imputed==0 & housework_focal<=50, width(2) color(blue%30)) (histogram housework_focal if imputed==1 & housework_focal<=50, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Housework Hours")
twoway (histogram earnings_t_focal if imputed==0 & earnings_t_focal >=-1000 & earnings_t_focal <=300000, width(10000) color(blue%30)) (histogram earnings_t_focal if imputed==1 & earnings_t_focal >=-1000 & earnings_t_focal <=300000, width(10000) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Annual Earnings")
twoway (histogram earnings_t_focal_x if imputed==0 & earnings_t_focal_x >=-1000 & earnings_t_focal_x <=300000, width(5000) color(blue%30)) (histogram earnings_t_focal_x if imputed==1 & earnings_t_focal_x >=-1000 & earnings_t_focal_x <=300000, width(5000) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Annual Earnings")

twoway (histogram weekly_hrs_t_focal_sp if imputed==0 & weekly_hrs_t_focal_sp<=100, width(2) color(blue%30)) (histogram weekly_hrs_t_focal_sp if imputed==1 & weekly_hrs_t_focal_sp<=100, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Employment Hours")
twoway (histogram housework_focal_sp if imputed==0 & housework_focal_sp<=50, width(2) color(blue%30)) (histogram housework_focal_sp if imputed==1 & housework_focal_sp<=50, width(2) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Weekly Housework Hours")
twoway (histogram earnings_t_focal_sp if imputed==0 & earnings_t_focal_sp >=-1000 & earnings_t_focal_sp <=300000, width(10000) color(blue%30)) (histogram earnings_t_focal_sp if imputed==1 & earnings_t_focal_sp >=-1000 & earnings_t_focal_sp <=300000, width(10000) color(red%30)), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6)) xtitle("Annual Earnings")


********************************************************************************
* add in birth indicators - aka create our DV
********************************************************************************
unique unique_id partner_id, by(joint_second_birth_opt2)
replace joint_second_birth_opt2=0 if joint_second_birth_opt2==.

browse unique_id partner_id survey_yr rel_start_all rel_end_all any_births_pre_rel joint_second_birth_opt2 joint_second_birth_yr joint_first_birth_yr joint_second_birth_timing first_survey_yr last_survey_yr first_survey_yr_sp last_survey_yr_sp cah_child_birth_yr2_ref cah_child_birth_yr2_sp shared_birth2_refyr shared_birth2_spyr num_births_pre_ref num_births_pre_sp

tab cah_child_birth_yr2_ref joint_second_birth_opt2, m // so there should not be birth years here for 0s? about 10% have? so some (most?) is bc AFTER relationship ended
tab cah_child_birth_yr2_ref joint_second_birth_opt2 if num_births_pre_ref==0 & num_births_pre_sp==0, m 
tab shared_birth2_refyr joint_second_birth_opt2, m col nofreq // so there are less shared, but that's almost worse? are actually better bc suggests it is shared? and just before teh relationship started
tab shared_birth2_spyr joint_second_birth_opt2, m col nofreq
tab joint_second_birth_yr joint_second_birth_opt2, m

foreach var in any_births_pre_rel num_births_pre_ref num_births_pre_indv_ref num_births_pre_sp num_births_pre_indv_sp{
	tab `var', m
}
// so these are all zero

gen had_second_birth=0
replace had_second_birth=1 if survey_yr==joint_second_birth_yr
tab had_second_birth, m
tab joint_second_birth_opt2 had_second_birth, m

browse unique_id partner_id survey_yr rel_start_all rel_end_all joint_second_birth_opt2 had_second_birth joint_second_birth_yr joint_second_birth_timing first_survey_yr last_survey_yr first_survey_yr_sp last_survey_yr_sp cah_child_birth_yr2_ref cah_child_birth_yr2_sp shared_birth2_refyr shared_birth2_spyr num_births_pre_ref num_births_pre_sp

gen time_since_first_birth= survey_yr - joint_first_birth_yr
tab time_since_first_birth, m
tab time_since_first_birth had_second_birth, m row

browse unique_id partner_id survey_yr rel_start_all rel_end_all joint_first_birth_yr time_since_first_birth had_second_birth joint_second_birth_opt2 joint_second_birth_yr joint_second_birth_timing

********************************************************************************
* more sample restrictions (namely, age of partner and same-gender couples)
********************************************************************************
tab SEX SEX_sp, m
drop if SEX==1 & SEX_sp==1
drop if SEX==2 & SEX_sp==2

gen age_man = age_focal if SEX==1
replace age_man = age_focal_sp if SEX==2

gen age_woman = age_focal if SEX==2
replace age_woman = age_focal_sp if SEX==1

// browse unique_id partner_id survey_yr SEX SEX_sp age_man age_woman age_focal age_sp

keep if (age_man>=20 & age_man<=60) & (age_woman>=20 & age_woman<50) // Comolli using the PSID does 16-49 for women and < 60 for men, but I want a higher lower limit for measurement of education? In general, age limit for women tends to range from 44-49, will use the max of 49 for now. lower limit of 20 seems justifiable based on prior research (and could prob go even older)

unique unique_id partner_id
unique unique_id partner_id if joint_second_birth_opt2==1

unique unique_id partner_id if rel_start_all >= 2005 // focus on post-recession period?
unique unique_id partner_id if joint_second_birth_opt2==1 & rel_start_all >= 2005 // focus on post-recession period?

mi update 

********************************************************************************
**# First some variable cleanup and things
********************************************************************************

browse unique_id partner_id survey_yr SEX SEX_sp weekly_hrs_t_focal weekly_hrs_t_focal_x weekly_hrs_t1_focal weekly_hrs_t1_focal_x weekly_hrs_t_focal_sp weekly_hrs_t_focal_sp_x weekly_hrs_t1_focal_sp weekly_hrs_t1_focal_sp_x housework_focal housework_t1_focal housework_focal_sp housework_t1_focal_sp _mi_m // how misaligned are t, t1 and t2? Should I leave as is via imputation or fill in t1 using t, etc?
browse unique_id partner_id survey_yr SEX SEX_sp weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t_focal_sp weekly_hrs_t1_focal_sp housework_focal housework_t1_focal housework_focal_sp housework_t1_focal_sp _mi_m //

// okay, want to put t in t1, but use imputed value for first year
* Hours focal
mi passive: gen weekly_hrs_t1 = .
mi passive: replace weekly_hrs_t1 = weekly_hrs_t_focal[_n-1] if unique_id == unique_id[_n-1] & partner_id == partner_id[_n-1] & relationship_duration == relationship_duration[_n-1] + 1 // bysort _mi_m unique_id partner_id relationship_duration: 
mi passive: replace weekly_hrs_t1 = weekly_hrs_t1_focal if weekly_hrs_t1==.

browse unique_id partner_id survey_yr SEX SEX_sp weekly_hrs_t_focal weekly_hrs_t1 weekly_hrs_t1_focal _mi_m //

* Earnings focal
mi passive: gen earnings_t1 = .
mi passive: replace earnings_t1 = earnings_t_focal[_n-1] if unique_id == unique_id[_n-1] & partner_id == partner_id[_n-1] & relationship_duration == relationship_duration[_n-1] + 1 // bysort _mi_m unique_id partner_id relationship_duration: 
mi passive: replace earnings_t1 = earnings_t1_focal if earnings_t1==.

* Housework focal
mi passive: gen housework_t1 = .
mi passive: replace housework_t1 = housework_focal[_n-1] if unique_id == unique_id[_n-1] & partner_id == partner_id[_n-1] & relationship_duration == relationship_duration[_n-1] + 1 // bysort _mi_m unique_id partner_id relationship_duration: 
mi passive: replace housework_t1 = housework_t1_focal if housework_t1==.

* Hours spouse
mi passive: gen weekly_hrs_t1_sp = .
mi passive: replace weekly_hrs_t1_sp = weekly_hrs_t_focal_sp[_n-1] if unique_id == unique_id[_n-1] & partner_id == partner_id[_n-1] & relationship_duration == relationship_duration[_n-1] + 1 // bysort _mi_m unique_id partner_id relationship_duration: 
mi passive: replace weekly_hrs_t1_sp = weekly_hrs_t1_focal_sp if weekly_hrs_t1_sp==.

* Earnings spouse
mi passive: gen earnings_t1_sp = .
mi passive: replace earnings_t1_sp = earnings_t_focal_sp[_n-1] if unique_id == unique_id[_n-1] & partner_id == partner_id[_n-1] & relationship_duration == relationship_duration[_n-1] + 1 // bysort _mi_m unique_id partner_id relationship_duration: 
mi passive: replace earnings_t1_sp = earnings_t1_focal_sp if earnings_t1_sp==.

* Housework spouse
mi passive: gen housework_t1_sp = .
mi passive: replace housework_t1_sp = housework_focal_sp[_n-1] if unique_id == unique_id[_n-1] & partner_id == partner_id[_n-1] & relationship_duration == relationship_duration[_n-1] + 1 // bysort _mi_m unique_id partner_id relationship_duration: 
mi passive: replace housework_t1_sp = housework_t1_focal_sp if housework_t1_sp==.


foreach var in weekly_hrs_t1 earnings_t1 housework_t1 weekly_hrs_t1_sp earnings_t1_sp housework_t1_sp{  
	// inspect `var' if _mi_m != 0  
	assert `var' != . if _mi_m != 0  
} 

browse unique_id partner_id survey_yr SEX SEX_sp earnings_t_focal earnings_t1 earnings_t1_focal housework_focal housework_t1 housework_t1_focal earnings_t_focal_sp earnings_t1_sp earnings_t1_focal_sp housework_focal_sp housework_t1_sp housework_t1_focal_sp _mi_m

sum weekly_hrs_t1 weekly_hrs_t1_focal weekly_hrs_t1_sp weekly_hrs_t1_focal_sp earnings_t1 earnings_t1_focal earnings_t1_sp earnings_t1_focal_sp housework_t1 housework_t1_focal housework_t1_sp housework_t1_focal_sp
tabstat weekly_hrs_t1 weekly_hrs_t1_focal weekly_hrs_t1_sp weekly_hrs_t1_focal_sp earnings_t1 earnings_t1_focal earnings_t1_sp earnings_t1_focal_sp housework_t1 housework_t1_focal housework_t1_sp housework_t1_focal_sp, by(imputed)

// now create gendered versions of key variables

foreach var in weekly_hrs_t weekly_hrs_t2 earnings_t earnings_t2 housework housework_t2 first_religion religion religion_t1 religion_t2 educ educ_t1 educ_t2 first_educ raceth_fixed{
	mi passive: gen `var'_man = `var'_focal if SEX==1
	mi passive: replace `var'_man = `var'_focal_sp if SEX==2
	
	mi passive: gen `var'_woman = `var'_focal if SEX==2
	mi passive: replace `var'_woman = `var'_focal_sp if SEX==1
}

foreach var in weekly_hrs_t1 earnings_t1 housework_t1 first_marital_status{
	mi passive: gen `var'_man = `var' if SEX==1
	mi passive: replace `var'_man = `var'_sp if SEX==2
	
	mi passive: gen `var'_woman = `var' if SEX==2
	mi passive: replace `var'_woman = `var'_sp if SEX==1
}

********************************************************************************
**# Now make couple-level IVs and control variables
* Making t and t-1 versions of all variables
********************************************************************************

// couple-level education
* First, need to create fixed versions
tab educ_man, m
tab educ_woman, m

browse unique_id partner_id relationship_duration educ_man educ_t1_man educ_t2_man educ_woman educ_t1_woman educ_t2_woman _mi_m

bysort unique_id partner_id _mi_m: egen educ_fixed_man = min(educ_man)
replace educ_fixed_man = first_educ_man if educ_fixed_man==.
bysort unique_id partner_id _mi_m: egen educ_fixed_woman = min(educ_woman)
replace educ_fixed_woman = first_educ_woman if educ_fixed_woman==.

label values educ_fixed_man educ_fixed_woman educ_man educ_t1_man educ_t2_man educ_woman educ_t1_woman educ_t2_woman first_educ_man first_educ_woman educ

sort _mi_m unique_id partner_id relationship_duration
browse unique_id partner_id relationship_duration educ_fixed_man first_educ_man educ_man educ_t1_man educ_t2_man educ_fixed_woman first_educ_woman educ_woman educ_t1_woman educ_t2_woman _mi_m

gen educ_type=. // making this fixed instead of time varying, and none of this is imputed, so no need to be passive
replace educ_type=1 if inrange(educ_fixed_man,1,3) & inrange(educ_fixed_woman,1,3)
replace educ_type=2 if educ_fixed_man == 4 & inrange(educ_fixed_woman,1,3)
replace educ_type=3 if inrange(educ_fixed_man,1,3) & educ_fixed_woman == 4
replace educ_type=4 if educ_fixed_man == 4 & educ_fixed_woman == 4

tab educ_fixed_man educ_fixed_woman, cell nofreq
tab educ_type, m

label define educ_type 1 "Neither College" 2 "Him College" 3 "Her College" 4 "Both College"
label values educ_type educ_type

gen couple_educ_gp=.
replace couple_educ_gp=0 if educ_type==1
replace couple_educ_gp=1 if inlist(educ_type,2,3,4)

label define couple_educ 0 "Neither College" 1 "At Least One College"
label values couple_educ_gp couple_educ

// income and division of paid labor
foreach var in earnings_t_man earnings_t_woman earnings_t1_man earnings_t1_woman{
	mi passive: replace `var' = 0 if `var' < 0 // rogue -99999s
}

mi passive: egen couple_earnings = rowtotal(earnings_t_man earnings_t_woman)
mi passive: gen female_earn_pct = earnings_t_woman/(couple_earnings)

mi passive: gen hh_earn_type=.
mi passive: replace hh_earn_type=1 if female_earn_pct >=.4000 & female_earn_pct <=.6000
mi passive: replace hh_earn_type=2 if female_earn_pct < .4000 & female_earn_pct >=0
mi passive: replace hh_earn_type=3 if female_earn_pct > .6000 & female_earn_pct <=1
mi passive: replace hh_earn_type=4 if earnings_t_man==0 & earnings_t_woman==0

label define hh_earn_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_earn_type hh_earn_type

browse unique_id partner_id SEX SEX_sp survey_yr hh_earn_type couple_earnings female_earn_pct earnings_t_man earnings_t_woman earnings_t_focal earnings_t_focal_sp

* t-1 version
mi passive: egen couple_earnings_t1 = rowtotal(earnings_t1_man earnings_t1_woman)
mi passive: gen female_earn_pct_t1 = earnings_t1_woman/(couple_earnings_t1)

mi passive: gen hh_earn_type_t1=.
mi passive: replace hh_earn_type_t1=1 if female_earn_pct_t1 >=.4000 & female_earn_pct_t1 <=.6000
mi passive: replace hh_earn_type_t1=2 if female_earn_pct_t1 < .4000 & female_earn_pct_t1 >=0
mi passive: replace hh_earn_type_t1=3 if female_earn_pct_t1 > .6000 & female_earn_pct_t1 <=1
mi passive: replace hh_earn_type_t1=4 if earnings_t1_man==0 & earnings_t1_woman==0

label values hh_earn_type_t1 hh_earn_type

mi estimate: proportion hh_earn_type hh_earn_type_t1
tab hh_earn_type hh_earn_type_t1, m

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

mi estimate: proportion hh_hours_type hh_hours_type_t1 hh_earn_type_t1
tab hh_hours_type imputed, col
tab hh_hours_type_t1 imputed, col

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

label define ft_pt 0 "Not working" 1 "PT" 2 "FT: Normal" 3 "FT: Overwork"
label values ft_pt_woman ft_pt_t1_woman ft_pt_man ft_pt_t1_man ft_pt

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

mi estimate: proportion couple_work couple_work_t1 couple_work_ow couple_work_ow_t1

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
tab survey_yr housework_bkt, row
tab imputed housework_bkt, row // see, I am still worried about this...

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

browse unique_id partner_id survey_yr housework_bkt housework_bkt_t1 housework_woman housework_man  housework_t1_woman housework_t1_man  had_second_birth

mi estimate: proportion housework_bkt housework_bkt_t1
tab imputed housework_bkt_t1, row // see, I am still worried about this...

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

tab hh_hours_type housework_bkt, m cell nofreq
mi estimate: proportion hours_housework hours_housework_t1

tab hours_housework imputed, col 
tab hours_housework_t1 imputed, col 

// Stata assert command to check new variables created from imputed  
foreach var in weekly_hrs_t_man weekly_hrs_t_woman weekly_hrs_t1_man weekly_hrs_t1_woman earnings_t_man earnings_t_woman earnings_t1_man earnings_t1_woman housework_man housework_woman housework_t1_man housework_t1_woman educ_fixed_man educ_fixed_woman raceth_fixed_man raceth_fixed_woman educ_type couple_educ_gp couple_earnings  hh_earn_type couple_earnings_t1  hh_earn_type_t1 couple_hours  hh_hours_type couple_hours_t1 hh_hours_type_t1 ft_pt_woman ft_pt_t1_woman ft_pt_man ft_pt_t1_man couple_work couple_work_ow couple_work_t1 couple_work_ow_t1 couple_housework  housework_bkt couple_housework_t1  housework_bkt_t1  hours_housework hours_housework_t1{  
	// inspect `var' if _mi_m != 0  
	assert `var' != . if _mi_m != 0  
} 

// will have missing if both 0: female_earn_pct female_earn_pct_t1 female_earn_pct_t2 female_hours_pct female_hours_pct_t1 female_hours_pct_t2 wife_housework_pct wife_housework_pct_t1 wife_housework_pct_t2

mi update

// create some other control variables
* Age diff (instead of using both of their ages? This one might be okay to use both)
mi passive: gen couple_age_diff = age_man - age_woman
tab couple_age_diff, m
sum couple_age_diff, detail

* Joint religion - from Killewald 2016: (1) both spouses are Catholic; (2) at least one spouse reports no religion; and (3) all other
* First, I need to figure out religion because could not impute
* going to use first religion for now
label values first_religion_man first_religion_woman religion_man religion_t1_man religion_t2_man religion_woman religion_t1_woman religion_t2_woman religion

tab first_religion_man religion_man // relatively congruent so, even though it can change, doesn't change v. often
tab first_religion_woman religion_woman 
tab first_religion_woman first_religion_man

gen couple_joint_religion=.
replace couple_joint_religion = 0 if first_religion_man==0 & first_religion_woman==0
replace couple_joint_religion = 1 if first_religion_man==1 & first_religion_woman==1
replace couple_joint_religion = 2 if inlist(first_religion_man,3,4,5,6) & inlist(first_religion_woman,3,4,5,6)
replace couple_joint_religion = 3 if (first_religion_man==1 & first_religion_woman!=1 & first_religion_woman!=.) | (first_religion_man!=1 & first_religion_man!=. & first_religion_woman==1)
replace couple_joint_religion = 4 if ((first_religion_man==0 & first_religion_woman!=0 & first_religion_woman!=.) | (first_religion_man!=0 & first_religion_man!=. & first_religion_woman==0)) & couple_joint_religion==.
replace couple_joint_religion = 5 if inlist(first_religion_man,2,7,8,9,10) & inlist(first_religion_woman,2,7,8,9,10)
replace couple_joint_religion = 5 if couple_joint_religion==. & first_religion_man!=. & first_religion_woman!=. 
// tab first_religion_man first_religion_woman if couple_joint_religion==.

label define couple_joint_religion 0 "Both None" 1 "Both Catholic" 2 "Both Protestant" 3 "One Catholic" 4 "One No Religion" 5 "Other"
label values couple_joint_religion couple_joint_religion

tab first_religion_man first_religion_woman, cell nofreq
tab couple_joint_religion, m

* Indicator of whether couple is same race/eth
tab raceth_fixed_man raceth_fixed_woman, m

gen couple_same_race=.
replace couple_same_race = 0 if raceth_fixed_man!=raceth_fixed_woman
replace couple_same_race = 1 if raceth_fixed_man==raceth_fixed_woman & raceth_fixed_man!=. & raceth_fixed_woman!=.

// tab raceth_fixed_man raceth_fixed_woman, m cell nofreq
// mi estimate: proportion couple_same_race

* Logged couple earnings
mi passive: gen couple_earnings_ln = ln(couple_earnings + 1) // add .01 because can't log 0
mi passive: gen couple_earnings_t1_ln = ln(couple_earnings_t1 + 1)

sum couple_earnings if imputed==1
sum couple_earnings_t1 if imputed==1
inspect couple_earnings_ln couple_earnings_t1_ln if imputed==1

// temp save
// save "$created_data/PSID_second_birth_sample_cons_RECODED.dta", replace

* Migration status
* Oh dear, one problem I will run into here is that, because of imputation, there are a lot of missing on STATE - aka, how do I add the state-level characteristics I need?
sort _mi_m unique_id partner_id survey_yr 

egen couple_id = group(unique_id partner_id)
quietly unique state_fips if state_fips!=., by(couple_id) gen(state_change)
bysort couple_id (state_change): replace state_change=state_change[1]
tab state_change, m

sort _mi_m unique_id partner_id survey_yr 
browse unique_id partner_id survey_yr _mi_m state_fips state_change moved MOVED_YEAR_ _mi_m
bysort unique_id partner_id (state_fips): replace state_fips = state_fips[1] if state_change==1
sort _mi_m unique_id partner_id survey_yr 
// browse unique_id partner_id survey_yr _mi_m state_fips state_change moved MOVED_YEAR_  if state_change!=0
// inspect state_fips if state_change==0
// inspect state_fips if state_change > 0

replace state_fips=state_fips[_n-1] if state_fips==. & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & survey_yr==survey_yr[_n-1]+1
replace state_fips=state_fips[_n+1] if state_fips==. & unique_id==unique_id[_n+1] & partner_id==partner_id[_n+1] & survey_yr==survey_yr[_n+1]-1

gen moved_states = .
replace moved_states = 0 if state_change!=0 & state_fips==state_fips[_n-1] & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & survey_yr==survey_yr[_n-1]+1
replace moved_states = 0 if state_change==1
replace moved_states = 1 if state_change!=0 & state_fips!=state_fips[_n-1] & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & survey_yr==survey_yr[_n-1]+1
replace moved_states = 0 if moved_states==. & state_change!=0 // remaining are first observations
tab moved_states, m

tab state_change moved_states, m

gen moved_states_lag = .
replace moved_states_lag = 0 if state_change!=0 & state_fips==state_fips[_n+1] & unique_id==unique_id[_n+1] & partner_id==partner_id[_n+1] & survey_yr==survey_yr[_n+1]-1
replace moved_states_lag = 0 if state_change==1
replace moved_states_lag = 1 if state_change!=0 & state_fips!=state_fips[_n+1] & unique_id==unique_id[_n+1] & partner_id==partner_id[_n+1] & survey_yr==survey_yr[_n+1]-1
replace moved_states_lag = 0 if state_change!=0 &  moved_states_lag==. & state_fips==state_fips[_n-1] & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & survey_yr==survey_yr[_n-1]+1 // last survey waves
replace moved_states_lag = 0 if moved_states_lag==. & state_change!=0 // remaining are last observations

tab moved_states_lag, m

tab state_change moved_states_lag, m

gen moved_last_two=.
replace moved_last_two = 0 if moved_states==0 & moved_states_lag==0
replace moved_last_two = 1 if moved_states==1 | moved_states_lag==1
tab moved_last_two, m
tab state_change moved_last_two, m

* Figure out if I can fill in type of relationship (married v. cohab)
tab marital_status_updated, m
tab first_marital_status, m
tab first_marital_status marital_status_updated, m
tab RELATION_ marital_status_updated, m
tab RELATION_, m
browse unique_id partner_id survey_yr relationship_est in_sample first_marital_status marital_status_updated RELATION_ mh_yr_married1 mh_yr_married2 mh_yr_married3 coh1_start coh2_start coh3_start rel1_start rel2_start rel3_start

replace marital_status_updated = 1 if inlist(marital_status_updated,3,5,6,.) & marital_status_updated[_n-1]==1 & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & survey_yr==survey_yr[_n-1]+1 // last year in survey. if year above was married, then def have to be married
replace marital_status_updated = 1 if inlist(marital_status_updated,3,5,6,.) & RELATION_==20  // (RELATION_==20 | RELATION_sp==20)
replace marital_status_updated = 2 if inlist(marital_status_updated,3,5,6,.) & RELATION_==22 // (RELATION_==22 | RELATION_sp==22)
replace marital_status_updated = marital_status_updated[_n+1] if inlist(marital_status_updated,3,5,6,.) & unique_id==unique_id[_n+1] & partner_id==partner_id[_n+1] & survey_yr==survey_yr[_n+1]-1 // off year and first year - since have no other information, just assume it is same status as first observed year
replace marital_status_updated = 1 if first_marital_status==1 // if first status is marriage, has to always be married

forvalues m=1/13{
	capture replace mh_yr_end`m'=. if mh_yr_end`m'==9998
}

forvalues m=1/13{
	capture replace marital_status_updated=1 if inlist(marital_status_updated,3,5,6,.) & survey_yr >= mh_yr_married`m' & survey_yr <= mh_yr_end`m'
}

forvalues c=1/3{
	capture replace marital_status_updated=2 if inlist(marital_status_updated,3,5,6,.) & survey_yr >= coh`c'_start & survey_yr <= coh`c'_end
	capture replace marital_status_updated=2 if inlist(marital_status_updated,3,5,6,.) & survey_yr == (coh`c'_start-1)
}

browse unique_id partner_id survey_yr first_marital_status marital_status_updated rel_start_all rel_end_all mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 coh1_start coh1_end coh2_start coh2_end coh3_start rel1_start rel2_start rel3_start

gen marital_status_use = marital_status_updated
replace marital_status_use = 2 if marital_status_updated==. | inlist(marital_status_updated,3,5,6) // assume cohab since don't meet requirements for marriage

tab marital_status_use, m
tab first_marital_status marital_status_use, m

/*
// get lagged structural measure - need to add original structural measure as well. BUT first need to figure out if this is what I want to use
rename structural_familism structural_familism_t

mi passive: gen year_t1 = survey_yr - 1
mi merge m:1 year_t1 state_fips using "$states/structural_familism.dta",keep(match master) // gen(howmatch) keepusing(structural_familism)
capture drop if howmatch==2

drop f1 state_name concat disapproval genderroles_egal working_mom_egal preschool_egal fepresch fechld fefam month_rent annual_rent month_own annual_own annual_housing hhincome rent_afford own_afford house_afford min_wage min_above_fed unemployment unemployment_comp right2work gdp gender_lfp_gap_nocoll gender_lfp_gap_coll paid_leave cc_cost cc_pct_income educ_spend cc_subsidies senate_dems house_dems gender_discrimin_ban equalpay contraceptive_coverage abortion_protected unemployment_percap prek_enrolled prek_enrolled_public state earn_ratio lfp_ratio pov_ratio pctfemaleleg dv_guns gender_mood child_pov welfare_all welfare_cash_asst ccdf_direct ccdf_total ccdf_per_cap population cc_eligible cc_pct_served cc_served cc_served_percap educ_spend_percap gini earn_ratio_z pctmaleleg no_paid_leave no_dv_gun_law senate_rep house_rep gender_mood_neg earn_ratio_st lfp_ratio_st pov_ratio_st pctfemaleleg_st senate_dems_st house_dems_st dv_guns_st gender_mood_st pctmaleleg_st no_paid_leave_st no_dv_gun_law_st senate_rep_st house_rep_st gender_mood_neg_st structural_sexism maternal_employment parent_earn_ratio gdp_per_cap unemployment_neg cc_pct_income_neg earn_ratio_neg parent_earn_ratio_neg min_below_fed child_pov_neg welfare_neg welfare_cash_neg gdp_neg gdp_percap_neg unemployment_neg_st min_above_fed_st paid_leave_st cc_pct_income_neg_st earn_ratio_neg_st cc_subsidies_st unemployment_st cc_pct_income_st min_below_fed_st child_pov_st child_pov_neg_st min_wage_st welfare_all_st welfare_cash_asst_st welfare_neg_st welfare_cash_neg_st ccdf_direct_st ccdf_per_cap_st cc_served_percap_st cc_pct_served_st educ_spend_st educ_spend_percap_st parent_earn_ratio_st parent_earn_ratio_neg_st maternal_employment_st gdp_st gdp_neg_st gdp_per_cap_st gdp_percap_neg_st gini_st gender_discrimin_ban_st equalpay_st contraceptive_coverage_st abortion_protected_st unemployment_percap_st prek_enrolled_st prek_enrolled_public_st

mi update

rename structural_familism structural_familism_t1

sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr state_fips structural_fam*
*/

// final update and save

mi update

save "$created_data/PSID_second_birth_sample_cons_RECODED.dta", replace
