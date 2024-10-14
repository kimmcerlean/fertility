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
gen partner_id = unique_id

forvalues n=1/20{
	rename cah_parent_marital_status`n' cah_parent_marst`n' // think getting too long for what I want to work
}

foreach var in cah_*{
	rename `var' `var'_ref // make a set for partner and a set for spouse
	// gen `var'_sp = `var' // not working
}

forvalues n=1/20{
	gen cah_child_int_number`n'_sp = cah_child_int_number`n'_ref // need spouse version
	gen cah_child_per_num`n'_sp = cah_child_per_num`n'_ref 
	gen cah_unique_id_child`n'_sp = cah_unique_id_child`n'_ref 
	gen cah_event_type`n'_sp = cah_event_type`n'_ref 
	gen cah_parent_marst`n'_sp = cah_parent_marst`n'_ref 
	gen cah_num_children`n'_sp = cah_num_children`n'_ref 
	gen cah_child_sex`n'_sp = cah_child_sex`n'_ref 
	gen cah_child_birth_yr`n'_sp = cah_child_birth_yr`n'_ref 
	gen cah_child_birth_mon`n'_sp = cah_child_birth_mon`n'_ref 
	gen cah_child_hispanicity`n'_sp = cah_child_hispanicity`n'_ref 
	gen cah_child_race1`n'_sp = cah_child_race1`n'_ref 
	gen cah_child_race2`n'_sp = cah_child_race2`n'_ref 
	gen cah_child_race3`n'_sp = cah_child_race3`n'_ref 
	gen cah_mom_wanted`n'_sp = cah_mom_wanted`n'_ref 
	gen cah_mom_timing`n'_sp = cah_mom_timing`n'_ref 
	gen cah_dad_wanted`n'_sp = cah_dad_wanted`n'_ref 
	gen cah_dad_timing`n'_sp = cah_dad_timing`n'_ref 
	gen cah_birth_order`n'_sp = cah_birth_order`n'_ref 
}
   
save "$temp\birth_history_wide.dta", replace

********************************************************************************
**# Now import main data and append birth history / figure out births
********************************************************************************
use "$created_data/PSID_partners_cleaned.dta", clear

browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr RELATION_ 

// attempt to create partner ids
gen id_ref=.
replace id_ref = unique_id if inlist(RELATION_,1,10) 
bysort survey_yr FAMILY_INTERVIEW_NUM_ (id_ref): replace id_ref = id_ref[1]

gen id_wife=.
replace id_wife = unique_id if inlist(RELATION_,2,20,22) 
bysort survey_yr FAMILY_INTERVIEW_NUM_ (id_wife): replace id_wife = id_wife[1]

sort unique_id survey_yr
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr RELATION_ id_ref id_wife

gen partner_id=.
replace partner_id = id_ref if inlist(RELATION_,2,20,22)  // so need opposite id
replace partner_id = id_wife if inlist(RELATION_,1,10)

browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr RELATION_ partner_id id_ref id_wife
sort unique_id survey_yr

// merge on birth history: respondent
merge m:1 unique_id using "$temp\birth_history_wide.dta", keepusing(*_ref)
drop if _merge==2

gen in_birth_history=0
replace in_birth_history=1 if _merge==3
drop _merge

tab in_birth_history in_marital_history, m // okay, so exact same overlap, which makes sense, bc both started in 1985

// merge on birth history: partner
merge m:1 partner_id using "$temp\birth_history_wide.dta", keepusing(*_sp)
drop if _merge==2

gen in_birth_history_sp=0
replace in_birth_history_sp=1 if _merge==3
drop _merge

// birth history date matches
sort unique_id survey_yr
gen check=.
replace check=0 if FIRST_BIRTH_YR != cah_child_birth_yr1_ref & in_birth_history==1
replace check=1 if FIRST_BIRTH_YR == cah_child_birth_yr1_ref & in_birth_history==1
tab FIRST_BIRTH_YR if check==0 // all 9999s
browse FIRST_BIRTH_YR cah_child_birth_yr*_ref if check==0

**These seem wrong for some reason and I want to create for both ref and partner
drop had_birth had_first_birth had_first_birth_alt
sort unique_id wave

// okay NEW problem, what if birth happens in an off year when the survey is biennial? right now, acting like no birth, but that is not right... GAH. add one to all of those? (basically if it's after 1997 and even year? so if birth is in 1998, let's record in 1999. OR should I record in 1997 because then we can say that is like "conception" so might not even need to lag the HH indicators?) okay also think about this gah. first let's create a flag to understand how many births, in general, are in off years

forvalues b=1/20{
	gen birth_yr_ref`b'_off=0
	replace birth_yr_ref`b'_off=1 if inlist(cah_child_birth_yr`b'_ref,1998,2000,2002,2004,2006,2008,2010,2012,2014,2016,2018,2020)
	
	gen birth_yr_sp`b'_off=0 
	replace birth_yr_sp`b'_off=1 if inlist(cah_child_birth_yr`b'_sp,1998,2000,2002,2004,2006,2008,2010,2012,2014,2016,2018,2020)
}

forvalues b=1/20{
	gen birth_yr_ref`b'_adj=.
	replace birth_yr_ref`b'_adj = cah_child_birth_yr`b'_ref if birth_yr_ref`b'_off==0
	replace birth_yr_ref`b'_adj = (cah_child_birth_yr`b'_ref - 1) if birth_yr_ref`b'_off==1
	
	gen birth_yr_sp`b'_adj=.
	replace birth_yr_sp`b'_adj = cah_child_birth_yr`b'_sp if birth_yr_sp`b'_off==0
	replace birth_yr_sp`b'_adj = (cah_child_birth_yr`b'_sp - 1) if birth_yr_sp`b'_off==1
}

// any births
gen had_birth_ref=0
replace had_birth_ref=1 if NUM_CHILDREN_ == NUM_CHILDREN_[_n-1]+1 & AGE_YOUNG_CHILD_==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen had_birth_alt_ref=0
forvalues b=1/20{
	replace had_birth_alt_ref=1 if survey_yr==cah_child_birth_yr`b'_ref // so if survey year matches any of the birth dates
}

gen had_birth_test_ref=0
forvalues b=1/20{
	replace had_birth_test_ref=1 if survey_yr==birth_yr_ref`b'_adj // so if survey year matches any of the birth dates, adjusted for non-survey years
}

tab had_birth_ref had_birth_alt_ref
tab had_birth_ref had_birth_test_ref

browse unique_id survey_yr had_birth_ref had_birth_alt_ref had_birth_test_ref cah_child_birth_yr*_ref

gen had_birth_sp=0
replace had_birth_sp=1 if NUM_CHILDREN_ == NUM_CHILDREN_[_n-1]+1 & AGE_YOUNG_CHILD_==1 & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1 // assuming if the partner is in the household, the birth is shared across the two of them

gen had_birth_alt_sp=0
forvalues b=1/20{
	replace had_birth_alt_sp=1 if survey_yr==birth_yr_sp`b'_adj // so if survey year matches any of the birth dates
}

tab had_birth_sp had_birth_alt_sp
tab had_birth_ref had_birth_sp
tab had_birth_alt_ref had_birth_alt_sp

// first births
// gen had_first_birth_ref=0
// replace had_first_birth_ref=1 if had_birth_ref==1 & (survey_yr==cah_child_birth_yr1_ref | survey_yr==cah_child_birth_yr1_ref+1) // think sometimes recorded a year late

gen had_first_birth_ref=0
replace had_first_birth_ref=1 if (survey_yr==birth_yr_ref1_adj)

gen had_first_birth_alt_ref=0
replace had_first_birth_alt_ref=1 if NUM_CHILDREN_==1 & NUM_CHILDREN_[_n-1]==0 & AGE_YOUNG_CHILD_==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen had_first_birth_sp=0
replace had_first_birth_sp=1 if (survey_yr==birth_yr_sp1_adj)

gen had_first_birth_alt_sp=0
replace had_first_birth_alt_sp=1 if NUM_CHILDREN_==1 & NUM_CHILDREN_[_n-1]==0 & AGE_YOUNG_CHILD_==1 & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1

browse unique_id survey_yr in_birth_history NUM_CHILDREN_ AGE_YOUNG_CHILD_ had_birth_ref had_birth_sp had_birth_alt_ref had_first_birth_ref had_first_birth_alt_ref cah_child_birth_yr*_ref 

// to use
gen first_birth_use_ref=.
replace first_birth_use_ref = had_first_birth_ref if in_birth_history==1 // so rely on birth history for primary
replace first_birth_use_ref = had_first_birth_alt_ref if in_birth_history==0 // supplement with calculated but ONLY for those not in birth history
tab first_birth_use_ref, m

gen birth_use_ref=.
replace birth_use_ref = had_birth_test_ref if in_birth_history==1
replace birth_use_ref = had_birth_ref if in_birth_history==0
tab birth_use_ref, m

gen first_birth_use_sp=.
replace first_birth_use_sp = had_first_birth_sp if in_birth_history_sp==1 // so rely on birth history for primary
replace first_birth_use_sp = had_first_birth_alt_sp if in_birth_history_sp==0 // supplement with calculated but ONLY for those not in birth history
tab first_birth_use_sp, m

gen birth_use_sp=.
replace birth_use_sp = had_birth_alt_sp if in_birth_history_sp==1
replace birth_use_sp = had_birth_sp if in_birth_history_sp==0
tab birth_use_sp, m

tab birth_use_ref birth_use_sp
tab first_birth_use_ref first_birth_use_sp, m // so this is the thing - do I need BOTH of them to have had a first birth together?

browse unique_id survey_yr in_birth_history NUM_CHILDREN_ AGE_YOUNG_CHILD_ first_birth_use_ref cah_child_birth_yr1_ref first_birth_use_sp cah_child_birth_yr1_sp

gen joint_first_birth=0
replace joint_first_birth=1 if first_birth_use_ref==1 & first_birth_use_sp==1 & birth_yr_ref1_adj==birth_yr_sp1_adj & in_birth_history==1 & in_birth_history_sp==1
replace joint_first_birth=1 if first_birth_use_ref==1 & first_birth_use_sp==1 & in_birth_history==0 & in_birth_history_sp==0
replace joint_first_birth=1 if first_birth_use_ref==1 & first_birth_use_sp==1 & ((in_birth_history==0 & in_birth_history_sp==1) | (in_birth_history==1 & in_birth_history_sp==0))

tab joint_first_birth,m
tab first_birth_use_ref first_birth_use_sp, m

bysort unique_id partner_id (joint_first_birth): egen first_birth_together=max(joint_first_birth) // so flag if they had first birth together? might make sample stuff easier?
sort unique_id survey_yr
browse unique_id partner_id survey_yr joint_first_birth first_birth_together first_birth_use_ref first_birth_use_sp // so this helps 

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

// restrict to working age? okay actually men can be under 60, but women need to be under childbearing age, so let's say, 50?
tab AGE_REF_ employed_ly_head, row
keep if (AGE_REF_>=18 & AGE_REF_<=60) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=50)

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

// quick recode
sort unique_id wave 

gen earn_housework_lag=.
replace earn_housework_lag=earn_housework[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
// label define earn_housework 1 "Egal" 2 "Second Shift" 3 "Traditional" 4 "Counter Traditional" 5 "All others"
label values earn_housework_lag earn_housework

// do I need to censor after a birth?! do I need TWO samples - one for first birth, one for not first?
save "$temp\all_couples.dta", replace // let's save a version here, again with ALL couples, then make a first birth only sample?

********************************************************************************
**# FIRST BIRTH SAMPLE
********************************************************************************
// so basically need to keep anyone who entered their relationship or the survey without kids? why am I struggling here lol bc also number of children might be in HH, not total births, so I need to figure this out. maybe first birth after survey start? or first birth after their first year in survey?

tab in_birth_history, m // good news is bc of time period, i have history for all of them which should help with the timing / sample part
tab in_birth_history_sp, m

tab NUM_BIRTHS, m
tab NUM_BIRTHS if cah_child_birth_yr1_ref>9000, m // so thee are people without births, so they are eligible

// remove if first birth prior to relationship start - either or both?! well probably either if my outcome will be joint first birth? because if either had a birth prior to the relationship, they are no longer eligible for a joint first birth...
gen first_birth_prior=0
replace first_birth_prior= 1 if cah_child_birth_yr1_ref<rel_start_yr | cah_child_birth_yr1_sp<rel_start_yr

tab first_birth_prior joint_first_birth // yes confirms that they can't have a joint first birth if either one had a birth prior

browse unique_id partner_id survey_yr rel_start_yr first_birth_prior NUM_BIRTHS NUM_CHILDREN_ cah_child_birth_yr1_ref cah_child_birth_yr1_sp joint_first_birth first_birth_together first_birth_use_ref first_birth_use_sp

drop if first_birth_prior==1
tab first_birth_use_ref first_birth_use_sp, m

// should I also drop if the first birth year is not the same for the partners?
gen joint_first_birth_year=.
replace joint_first_birth_year = birth_yr_ref1_adj if birth_yr_ref1_adj==birth_yr_sp1_adj

inspect joint_first_birth_year // about 5% missing
drop if joint_first_birth_year==.

// then remove all years AFTER the transition year - but okay what if no transition? that will still work bc it's 9999? so the survey year will never be greater than?
browse unique_id partner_id survey_yr rel_start_yr first_birth_together joint_first_birth joint_first_birth_year NUM_CHILDREN_ NUM_BIRTHS
tab joint_first_birth, m

gen censored=0
replace censored=1 if survey_yr > joint_first_birth_year
tab censored joint_first_birth, row m // want to make sure I waon't accidentally drop any observed transitions.

drop if censored==1

save "$created_data/PSID_first_birth_sample.dta", replace

********************************************************************************
**# SECOND BIRTH SAMPLE
********************************************************************************
use "$temp\all_couples.dta", clear // okay back to file with all couples

// so firt drop all couples with 0 births? because can't be eligible to have a second birth if never had a first...
drop if NUM_BIRTHS==0

/*
// maybe first try removing those with first AND second births prior to relationship? okay, but wait, what if someone's second birth is their first birth together, do I want them still?
gen second_birth_prior=0
replace second_birth_prior= 1 if cah_child_birth_yr2_ref<rel_start_yr | cah_child_birth_yr2_sp<rel_start_yr

drop if second_birth_prior==1

// also denote if the first birth was at least together, because the sample should be those who had a first birth together? Except, the problem, as below, is that it might not be both of their first births, but as long as they had a birth together previously, that should count?
gen joint_first_birth_year=.
replace joint_first_birth_year = cah_child_birth_yr1_ref if cah_child_birth_yr1_ref==cah_child_birth_yr1_sp

inspect joint_first_birth_year // about 40% missing
drop if joint_first_birth_year==.
*/

// so I want the BASE / eligible sample to be all couples who had one birth together. I don't *think* I care if the first birth has been observed? so, that just means their first birth year is the same? or should the first birth be the same AND after the relationship start date?
// okay, but do I care if their FIRST birth is the same year? or just that they had one baby together? so it could have been one's first birth and the other's second.
// gah so how do I know that? so I think I need to actually observe first and second birth? or generally, just keep the years in between the first and second birth? even if not all observed? so clock 1 = time of first birth and censored at time of second? okay but how do I figure out if they had two kids TOGETHER, especially if some had birth PRIOR to relationship?

// let's try this - but this only works for births I observed
gen ref_birth_no=.
gen sp_birth_no=.
forvalues b=1/20{
	replace ref_birth_no=`b' if survey_yr == birth_yr_ref`b'_adj
	replace sp_birth_no=`b' if survey_yr == birth_yr_sp`b'_adj
}

browse unique_id partner_id survey_yr rel_start_yr ref_birth_no sp_birth_no birth_yr_ref1_adj birth_yr_ref2_adj birth_yr_sp1_adj birth_yr_sp2_adj
// okay, but, I did restrict to relationships that started after 1990, so might that help?

// okay, I really want a time-incrementing indicator of births
gen num_births_ref=.
forvalues b=1/19{
	local c = `b' + 1
	// replace num_births_ref = cah_birth_order`b'_ref if survey_yr>=cah_child_birth_yr`b'_ref & survey_yr <cah_child_birth_yr`c'_ref
	replace num_births_ref = `b' if survey_yr>=birth_yr_ref`b'_adj & survey_yr < birth_yr_ref`c'_adj
}
// replace num_births_ref = cah_birth_order20_ref if survey_yr>=cah_child_birth_yr20_ref & survey_yr <cah_child_birth_yr2_ref
replace num_births_ref=0 if num_births_ref==.

browse unique_id survey_yr num_births_ref NUM_BIRTHS NUM_CHILDREN_ cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr3_ref cah_child_birth_yr4_ref cah_birth_order1_ref cah_birth_order2_ref cah_birth_order3_ref cah_birth_order4_ref 

gen num_births_sp=.
forvalues b=1/19{
	local c = `b' + 1
	replace num_births_sp = `b' if survey_yr>=birth_yr_sp`b'_adj & survey_yr < birth_yr_sp`c'_adj
}
replace num_births_sp=0 if num_births_sp==.

browse unique_id partner_id survey_yr rel_start_yr num_births_ref num_births_sp ref_birth_no sp_birth_no cah_child_birth_yr1_ref cah_child_birth_yr2_ref  cah_child_birth_yr1_sp cah_child_birth_yr2_sp

// this is still not helping me figure out if together. am i overcomplicating this?!

forvalues r=1/20{
	gen ref_birth_match`r'=0
	forvalues b=1/20{
		replace ref_birth_match`r' = `b' if cah_child_birth_yr`r'_ref == cah_child_birth_yr`b'_sp & cah_child_birth_yr`r'_ref!=9999 & cah_child_birth_yr`r'_ref!=9998 & cah_child_birth_yr`r'_ref!=.
	}
}

forvalues r=1/20{
	gen sp_birth_match`r'=0
	forvalues b=1/20{
		replace sp_birth_match`r' = `b' if cah_child_birth_yr`r'_sp == cah_child_birth_yr`b'_ref & cah_child_birth_yr`r'_sp!=9999 & cah_child_birth_yr`r'_sp!=9998 & cah_child_birth_yr`r'_sp!=.
	}
}

/*
gen num_births_ref_together=.
forvalues b=1/19{
	local c = `b' + 1
	replace num_births_ref_together = `b' if survey_yr>=cah_child_birth_yr`b'_ref & survey_yr <cah_child_birth_yr`c'_ref & ref_birth_match`b' !=0
}
replace num_births_ref_together=0 if num_births_ref_together==.
*/

gen num_births_ref_together=0
forvalues b=1/19{
	local c = `b' + 1
	replace num_births_ref_together = num_births_ref_together + 1 if survey_yr>=birth_yr_ref`b'_adj & ref_birth_match`b' !=0 // & survey_yr <cah_child_birth_yr`c'_ref 
}

gen num_births_sp_together=0
forvalues b=1/19{
	local c = `b' + 1
	replace num_births_sp_together = num_births_sp_together+1 if survey_yr>=birth_yr_sp`b'_adj  & sp_birth_match`b' !=0 //  & survey_yr <cah_child_birth_yr`c'_sp
}

browse unique_id partner_id survey_yr rel_start_yr ref_birth_match1 ref_birth_match2 sp_birth_match1 sp_birth_match2 cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr3_ref cah_child_birth_yr4_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp cah_child_birth_yr3_sp cah_child_birth_yr4_sp num_births_ref num_births_ref_together num_births_sp num_births_sp_together


// attempting to figure out who is at risk
browse unique_id partner_id survey_yr rel_start_yr num_births_ref_together num_births_sp_together
gen births_check=0
replace births_check=1 if num_births_ref_together==num_births_sp_together

sort unique_id partner_id wave
gen birth_transition_year=0
replace birth_transition_year=1 if num_births_ref_together==num_births_ref_together[_n-1]+1 & unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1

gen at_risk=.
replace at_risk=0 if num_births_ref_together>2 & num_births_sp_together>2 // not at risk if already had two births
replace at_risk=0 if num_births_ref_together==0 | num_births_sp_together==0 // not at risk if one partner has not yet had a first birth
replace at_risk=1 if num_births_ref_together==1
replace at_risk=1 if num_births_ref_together==2 & birth_transition_year==1 // only want the first year of second birth, after that, remove
replace at_risk=0 if num_births_ref_together==2 & birth_transition_year==0 // only want the first year of second birth, after that, remove

browse unique_id partner_id survey_yr rel_start_yr at_risk num_births_ref_together num_births_sp_together birth_transition_year cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr3_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp cah_child_birth_yr3_sp

// then remove all years AFTER the transition year - but okay what if no transition? that will still work bc it's 9999? so the survey year will never be greater than?
drop if at_risk==0
drop if num_births_ref_together>2
// should the clock be time since first birth? probably? or relationship duration / age?

gen second_birth=0
replace second_birth=1 if num_births_ref_together==2 & birth_transition_year==1

save "$created_data/PSID_second_birth_sample.dta", replace
