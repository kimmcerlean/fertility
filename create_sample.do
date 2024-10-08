********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: create_sample
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes sample of couples and restricts it to fertility sample
* (couple sample created for growth curve project)

********************************************************************************
* First, sort out birth history data to append
********************************************************************************
use "$fam_history/cah85_21.dta", clear

gen unique_id = (CAH3*1000) + CAH4
browse CAH3 CAH4 unique_id
gen unique_id_child = (CAH10*1000) + CAH11

/* first rename relevant variables for ease*/
rename CAH3 int_number
rename CAH4 per_num
rename CAH10 child_int_number
rename CAH11 child_per_num
rename CAH2 event_type
rename CAH106 num_children
rename CAH5 parent_sex
rename CAH7 parent_birth_yr
rename CAH6 parent_birth_mon
rename CAH8 parent_marital_status
rename CAH9 birth_order
rename CAH12 child_sex
rename CAH15 child_birth_yr
rename CAH13 child_birth_mon
rename CAH27 child_hispanicity
rename CAH28 child_race1
rename CAH29 child_race2
rename CAH30 child_race3
rename CAH100 mom_wanted
rename CAH101 mom_timing
rename CAH102 dad_wanted
rename CAH103 dad_timing

label define wanted 1 "Yes" 5 "No"
label values mom_wanted dad_wanted wanted
replace mom_wanted = . if inlist(mom_wanted,8,9)
replace dad_wanted = . if inlist(dad_wanted,8,9)

label define timing 1 "Not at that time" 2 "None" 3 "Didn't matter"
label values mom_timing dad_timing timing
replace mom_timing = . if inlist(mom_timing,8,9)
replace dad_timing = . if inlist(dad_timing,8,9)

gen no_children=0
replace no_children=1 if child_int_number==0 & child_per_num==0 

// this is currently LONG - one record per birth. want to make WIDE
local birthvars "int_number per_num unique_id child_int_number child_per_num unique_id_child event_type num_children parent_sex parent_birth_yr parent_birth_mon parent_marital_status birth_order child_sex child_birth_yr child_birth_mon child_hispanicity child_race1 child_race2 child_race3 mom_wanted mom_timing dad_wanted dad_timing"

keep `birthvars'

rename parent_birth_yr parent_birth_yr_0
bysort unique_id: egen parent_birth_yr = min(parent_birth_yr_0)
drop parent_birth_yr_0

rename parent_birth_mon parent_birth_mon_0
bysort unique_id: egen parent_birth_mon = min(parent_birth_mon_0)
drop parent_birth_mon_0

browse unique_id birth_order * // looks like the 98s are causing problems
sort unique_id birth_order
by unique_id: egen birth_rank = rank(birth_order), unique
browse unique_id birth_order birth_rank child_birth_yr * 
tab birth_rank birth_order

reshape wide child_int_number child_per_num unique_id_child event_type parent_marital_status num_children child_sex child_birth_yr child_birth_mon child_hispanicity child_race1 child_race2 child_race3 mom_wanted mom_timing dad_wanted dad_timing birth_order, i(int_number per_num unique_id parent_sex parent_birth_yr parent_birth_mon)  j(birth_rank)

gen INTERVIEW_NUM_1968 = int_number

foreach var in *{
	rename `var' cah_`var' // so I know where it came from
}

rename cah_int_number int_number
rename cah_per_num per_num
rename cah_unique_id unique_id
rename cah_INTERVIEW_NUM_1968 INTERVIEW_NUM_1968

save "$temp\birth_history_wide.dta", replace

********************************************************************************
**# Now import main data and append birth history / figure out births
********************************************************************************
use "$created_data/PSID_partners_cleaned.dta", clear

// merge on marital history
merge m:1 unique_id using "$temp\birth_history_wide.dta"
drop if _merge==2

gen in_birth_history=0
replace in_birth_history=1 if _merge==3
drop _merge

tab in_birth_history in_marital_history, m // okay, so exact same overlap, which makes sense, bc both started in 1985

sort unique_id survey_yr
gen check=.
replace check=0 if FIRST_BIRTH_YR != cah_child_birth_yr1 & in_birth_history==1
replace check=1 if FIRST_BIRTH_YR == cah_child_birth_yr1 & in_birth_history==1
tab FIRST_BIRTH_YR if check==0 // all 9999s
browse FIRST_BIRTH_YR cah_child_birth_yr* if check==0

**These seem wrong for some reason
drop had_birth had_first_birth had_first_birth_alt

sort unique_id wave

// any births
gen had_birth=0
replace had_birth=1 if NUM_CHILDREN_ == NUM_CHILDREN_[_n-1]+1 & AGE_YOUNG_CHILD_==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen had_birth_lag=.
replace had_birth_lag=had_birth[_n+1] if unique_id==unique_id[_n+1] & wave==wave[_n+1]-1
replace had_birth_lag=0 if had_birth_lag==. // seems to be recorded one year off. okay but this is getting wild

gen had_birth_alt=0
forvalues b=1/20{
	replace had_birth_alt=1 if survey_yr==cah_child_birth_yr`b' // so if survey year matches any of the birth dates
}

tab had_birth had_birth_alt
tab had_birth_lag had_birth_alt

// first births
gen had_first_birth=0
replace had_first_birth=1 if had_birth==1 & (survey_yr==cah_child_birth_yr1 | survey_yr==cah_child_birth_yr1+1) // think sometimes recorded a year late

gen had_first_birth_alt=0
replace had_first_birth_alt=1 if (survey_yr==cah_child_birth_yr1)

gen had_first_birth_alt2=0
replace had_first_birth_alt2=1 if NUM_CHILDREN_==1 & NUM_CHILDREN_[_n-1]==0 & AGE_YOUNG_CHILD_==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

browse unique_id survey_yr in_birth_history NUM_CHILDREN_ AGE_YOUNG_CHILD_ had_birth had_birth_alt had_first_birth* FIRST_BIRTH_YR cah_child_birth_yr* 

tab had_first_birth had_first_birth_alt
tab had_first_birth had_first_birth_alt2
tab had_first_birth_alt had_first_birth_alt2

// to use
gen first_birth_use=.
replace first_birth_use = had_first_birth_alt if in_birth_history==1 // so rely on birth history for primary
replace first_birth_use = had_first_birth_alt2 if in_birth_history==0 // supplement with calculated but ONLY for those not in birth history
tab first_birth_use, m

gen birth_use=.
replace birth_use = had_birth_alt if in_birth_history==1
replace birth_use = had_birth if in_birth_history==0
tab birth_use, m

browse unique_id survey_yr in_birth_history NUM_CHILDREN_ AGE_YOUNG_CHILD_ birth_use first_birth_use cah_child_birth_yr* 

********************************************************************************
**# Now figure out other general sample restrictions
********************************************************************************
// first, need to just keep one record per HH (currently two) - this comes from growth curve file

tab SEX marital_status_updated if SEX_HEAD_==1
/* need to end up with this amount of respondents after the below
           | marital_status_update
    SEX OF |           d
INDIVIDUAL | Married (  Partnered |     Total
-----------+----------------------+----------
      Male |   159,508     10,819 |   170,327 
    Female |   159,508     10,803 |   170,311 
-----------+----------------------+----------
     Total |   319,016     21,622 |   340,638 
*/

drop if SEX_HEAD_!=1
tab rel_start_yr SEX, m // is either one's data more reliable?

// keep only one respondent per household (bc all data recorded for all)
sort survey_yr FAMILY_INTERVIEW_NUM_  unique_id   

gen has_rel_info=0
replace has_rel_info=1 if rel_start_yr!=.

bysort survey_yr FAMILY_INTERVIEW_NUM_: egen rel_info = max(has_rel_info)

* first drop the partner WITHOUT rel info if at least one of them does
drop if has_rel_info==0 & rel_info==1

*then rank the remaining members
bysort survey_yr FAMILY_INTERVIEW_NUM_ : egen per_id = rank(unique_id) // so if there is only one member left after above, will get a 1
browse survey_yr FAMILY_INTERVIEW_NUM_  unique_id per_id

tab per_id // 1s should approximately total above
keep if per_id==1

tab marital_status_updated // check

/*
marital_status_upd |
              ated |      Freq.     Percent        Cum.
-------------------+-----------------------------------
Married (or pre77) |    159,316       93.69       93.69
         Partnered |     10,730        6.31      100.00
-------------------+-----------------------------------
             Total |    170,046      100.00
*/

// restrict to working age?
tab AGE_REF_ employed_ly_head, row
keep if (AGE_REF_>=18 & AGE_REF_<=60) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=60) // sort of drops off a cliff after 60?

// restrict to marriages started after 1990 bc that is when I have data for family measures
unique unique_id
unique unique_id if rel_start_yr>=1990 & rel_start_yr!=.
keep if rel_start_yr>=1990 & rel_start_yr!=.

// ooh, can I merge structural family measures here first as well?
rename STATE_ state_fips
drop year
gen year = survey_yr

merge m:1 state_fips year using "$states/structural_familism.dta", keepusing(structural_familism)
drop if _merge==2
tab year _merge
drop _merge

// do I need to censor after a birth?! do I need TWO samples - one for first birth, one for not first?
save "$temp\all_couples.dta", replace // let's save a version here, again with ALL couples, then make a first birth only sample?

********************************************************************************
**# FIRST BIRTH SAMPLE
********************************************************************************
// so basically need to keep anyone who entered their relationship or the survey without kids? why am I struggling here lol bc also number of children might be in HH, not total births, so I need to figure this out. maybe first birth after survey start?
browse unique_id survey_yr rel_start_yr NUM_CHILDREN_ cah_child_birth_yr1 first_birth_use