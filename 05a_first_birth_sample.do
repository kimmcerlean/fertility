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

********************************************************************************
**# Create gendered variables and couple-level IVs
********************************************************************************
foreach var in educ raceth raceth_fixed religion weekly_hrs_t earnings_t housework weekly_hrs_t1 earnings_t1{
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

sort unique_id partner_id survey_yr
gen housework_bkt_t1 = .
replace housework_bkt_t1 = housework_bkt[_n-1] if unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1 // I could probably get a lag from the individual level data? so the first year won't be missing by defaul

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

save "$created_data/PSID_first_birth_sample_rec.dta", replace
