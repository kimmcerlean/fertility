********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: create_family_histories
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files just preps the various relationship history and birth history
* files that are needed 

********************************************************************************
********************************************************************************
* 1. Create a lookup file of children and their parents 
* with the unique ID I can link back to other files
********************************************************************************
********************************************************************************
use "$fam_history/pid21.dta", clear

// (ER30001 * 1000) + ER30002
// (1968 interview ID multiplied by 1000) plus Person Number

gen unique_id_child = (PID2*1000) + PID3 // this is what I will match to below
browse PID2 PID3 unique_id_child

gen unique_id_mom = (PID4*1000) + PID5 // these will be for reference
browse PID4 PID5 unique_id_mom PID19
rename PID19 in_cah_mom

gen has_birth_mom_info=0
replace has_birth_mom_info=1 if inrange(PID5,1,999)
tab has_birth_mom_info // okay this matches codebook - 43015

tab has_birth_mom_info in_cah_mom, row // so like 79% of those with info recorded in birth history. is this concerning? does that mean I should use this file? and not birth history?

gen unique_id_dad = (PID23*1000) + PID24
browse PID23 PID24 unique_id_dad PID37
rename PID37 in_cah_dad

gen has_birth_dad_info=0
replace has_birth_dad_info=1 if inrange(PID24,1,999)
tab has_birth_dad_info // okay this matches codebook - 49539

tab has_birth_dad_info in_cah_dad, row

browse unique_id_child unique_id_mom unique_id_dad has_birth_mom_info has_birth_dad_info in_cah_mom in_cah_dad // some children have no birth parents? or adoptive (but less interested in that)
tab has_birth_mom_info has_birth_dad_info, cell // so 30% have neither? okay, this matches what the codebook says: "Of the 102,074 individuals who do have records on the Parent Identification File, approximately two-thirds of the records contain identifiers for at least one biological or adoptive parent." unclear what to do about rest. maybe they are just people never observed as child (like if entered panel when adult) - so then their parents never in? this file specifically doesn't have any info on age or birth years

keep unique_id_child unique_id_mom unique_id_dad has_birth_mom_info has_birth_dad_info in_cah_mom in_cah_dad

save "$temp\child_parent_lookup.dta", replace

********************************************************************************
********************************************************************************
**# 2. Sort out birth history data to append
********************************************************************************
********************************************************************************
use "$fam_history/cah_85_21.dta", clear

gen unique_id = (CAH3*1000) + CAH4
browse CAH3 CAH4 unique_id
gen unique_id_child = (CAH10*1000) + CAH11 // this is what I will match to above

/* first rename relevant variables for ease*/
rename CAH3 int_number
rename CAH4 per_num
rename CAH10 child_int_number
rename CAH11 child_per_num
rename CAH2 event_type  // 1 = childbirth 2 = adoption
rename CAH106 num_children // analyze with record type
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

// now, I want to match the child birth parent info for later and before i make wide
merge m:1 unique_id_child using "$temp\child_parent_lookup.dta"

tab has_birth_dad_info has_birth_mom_info if _merge==2, cell // so about 70% of using only are those with no parent info, which makes sense. unsure about the remainder...
tab in_cah_dad in_cah_mom if _merge==2, cell // the remainder are those where parents not recorded in history. are these children useful to me? I am sure I can recover their birth info later? revisit this

tab _merge if unique_id_child==0 // master only - which makes sense, because they are people without children
tab _merge if unique_id_child!=0 // so only 1.5% of those with a child id didn't have a match in pid
drop if _merge==2
drop _merge

browse unique_id unique_id_child child_birth_yr child_birth_mon unique_id_mom unique_id_dad in_cah_dad in_cah_mom

gen id_check=0
replace id_check=1 if unique_id==unique_id_mom | unique_id==unique_id_dad
tab id_check, m
tab id_check if unique_id_child!=0 // yes, so unique_id is listed as either mom or dad in 96% of cases.
	// browse unique_id unique_id_child child_birth_yr child_birth_mon unique_id_mom unique_id_dad in_cah_dad in_cah_mom if id_check==0 & unique_id_child!=0
	// tab has_birth_mom_info has_birth_dad_info if id_check==0, cell

// this is currently LONG - one record per birth. want to make WIDE
local birthvars "int_number per_num unique_id child_int_number child_per_num unique_id_child event_type num_children parent_sex parent_birth_yr parent_birth_mon parent_marital_status birth_order child_sex child_birth_yr child_birth_mon child_hispanicity child_race1 child_race2 child_race3 mom_wanted mom_timing dad_wanted dad_timing unique_id_mom unique_id_dad"

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

tab event_type
tab num_children

gen num_bio_kids = num_children if event_type==1
gen num_adoptive_kids = num_children if event_type==2
bysort unique_id (num_bio_kids): replace num_bio_kids = num_bio_kids[1]
bysort unique_id (num_adoptive_kids): replace num_adoptive_kids = num_adoptive_kids[1]
replace num_adoptive_kids = 0 if num_adoptive_kids==.
sort unique_id birth_order
browse unique_id event_type num_children num_bio_kids num_adoptive_kids

drop num_children

reshape wide child_int_number child_per_num unique_id_child event_type parent_marital_status child_sex child_birth_yr child_birth_mon child_hispanicity child_race1 child_race2 child_race3 mom_wanted mom_timing dad_wanted dad_timing birth_order unique_id_mom unique_id_dad, i(int_number per_num unique_id parent_sex parent_birth_yr parent_birth_mon num_bio_kids num_adoptive_kids)  j(birth_rank) // num_children

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
	gen cah_unique_id_mom`n'_sp = cah_unique_id_mom`n'_ref 
	gen cah_unique_id_dad`n'_sp = cah_unique_id_dad`n'_ref
}

gen cah_num_bio_kids_sp = cah_num_bio_kids_ref
gen cah_num_adoptive_kids_sp = cah_num_adoptive_kids_ref

// browse unique_id cah_unique_id_child1_ref cah_child_birth_yr1_ref cah_unique_id_mom1_ref cah_unique_id_dad1_ref cah_unique_id_child2_ref cah_child_birth_yr2_ref cah_unique_id_mom2_ref cah_unique_id_dad2_ref cah_num_bio_kids_ref cah_num_adoptive_kids_ref
   
save "$temp\birth_history_wide.dta", replace

********************************************************************************
********************************************************************************
**# 3. Marital history data to merge on
********************************************************************************
********************************************************************************
use "$fam_history\mh85_21.dta", clear

gen unique_id = (MH2*1000) + MH3
browse MH3 MH2 unique_id
gen unique_id_spouse = (MH7*1000) + MH8

/* first rename for ease*/
rename MH1 releaseno
rename MH2 fam_id
rename MH3 main_per_id
rename MH4 sex
rename MH5 mo_born
rename MH6 yr_born
rename MH7 fam_id_spouse
rename MH8 per_no_spouse
rename MH9 marrno 
rename MH10 mo_married
rename MH11 yr_married
rename MH12 status
rename MH13 mo_widdiv
rename MH14 yr_widdiv
rename MH15 mo_sep
rename MH16 yr_sep
rename MH17 history
rename MH18 num_marriages
rename MH19 marital_status
rename MH20 num_records

label define status 1 "Intact" 3 "Widow" 4 "Divorce" 5 "Separation" 7 "Other" 8 "DK" 9 "Never Married"
label values status status

egen yr_end = rowmin(yr_widdiv yr_sep)
browse unique_id marrno status yr_widdiv yr_sep yr_end

// this is currently LONG - one record per marriage. want to make WIDE

drop mo_born mo_widdiv yr_widdiv mo_sep yr_sep history
bysort unique_id: egen year_birth = min(yr_born)
drop yr_born

reshape wide unique_id_spouse fam_id_spouse per_no_spouse mo_married yr_married status yr_end, i(unique_id main_per_id fam_id) j(marrno)
gen INTERVIEW_NUM_1968 = fam_id

foreach var in *{
	rename `var' mh_`var' // so I know it came from marital history
}

rename mh_fam_id fam_id
rename mh_main_per_id main_per_id
rename mh_unique_id unique_id
rename mh_year_birth year_birth 
rename mh_INTERVIEW_NUM_1968 INTERVIEW_NUM_1968

save "$temp\marital_history_wide.dta", replace

********************************************************************************
********************************************************************************
**# 4. Relationship history, including cohabitation
********************************************************************************
********************************************************************************

use "$temp\PSID_full_long.dta", clear // this is based off of main file WITHOUT additional years so only using OBSERVED transitions

********************************************************************************
** First create some technical recodes that will make things easier
********************************************************************************
egen wave = group(survey_yr) // this will make years consecutive, easier for later

gen in_sample=.
replace in_sample=0 if SEQ_NUMBER_==0 | inrange(SEQ_NUMBER_,60,90)
replace in_sample=1 if inrange(SEQ_NUMBER_,1,59)

gen hh_status_=.
replace hh_status_=0 if SEQ_NUMBER_==0 
replace hh_status_=1 if inrange(SEQ_NUMBER_,1,20) // in sample
replace hh_status_=2 if inrange(SEQ_NUMBER_,51,59) // institutionalized
replace hh_status_=3 if inrange(SEQ_NUMBER_,71,80) // new HH 
replace hh_status_=4 if inrange(SEQ_NUMBER_,81,89) // died
label define hh_status 0 "not in sample" 1 "in sample" 2 "institutionalized" 3 "new hh" 4 "died"
label values hh_status_ hh_status

gen has_psid_gene=0
replace has_psid_gene = 1 if inlist(SAMPLE,1,2)

label define sample 0 "not sample" 1 "original sample" 2 "born-in" 3 "moved in" 4 "joint inclusion" 5 "followable nonsample parent" 6 "nonsample elderly"
label values SAMPLE sample

gen relationship=.
replace relationship=0 if RELATION_==0
replace relationship=1 if inlist(RELATION_,1,10)
replace relationship=2 if inlist(RELATION_,2,20,22,88)
replace relationship=3 if inrange(RELATION_,23,87) | inrange(RELATION_,90,98) | inrange(RELATION_,3,9)
label define relationship 0 "not in sample" 1 "head" 2 "partner" 3 "other"
label values relationship relationship

replace in_sample=0 if survey_yr==1968 & relationship==0 // no seq number in 1968
replace in_sample=1 if survey_yr==1968 & relationship!=0 // no seq number in 1968

gen moved = 0
replace moved = 1 if inlist(MOVED_,1,2) & inlist(SPLITOFF_,1,3) // moved in
replace moved = 2 if inlist(MOVED_,1,2) & inlist(SPLITOFF_,2,4) // splitoff
replace moved = 3 if inlist(MOVED_,5,6) // moved out
replace moved = 4 if MOVED_==1 & SPLITOFF_==0 // born
replace moved = 5 if MOVED_==7

label define moved 0 "no" 1 "Moved in" 2 "Splitoff" 3 "Moved out" 4 "Born" 5 "Died"
label values moved moved
tab moved in_sample, m
tab AGE_INDV_ moved

gen permanent_attrit=0
replace permanent_attrit=1 if PERMANENT_ATTRITION==1 // attrited
replace permanent_attrit=2 if inlist(PERMANENT_ATTRITION,2,3) // marked as died
label define perm 0 "no" 1 "attrited" 2 "died"
label values permanent_attrit perm

tab MOVED_YEAR_ SPLITOFF_YEAR_ if MOVED_YEAR_!=0 & SPLITOFF_YEAR_ !=0, m

********************************************************************************
* HH Composition history
********************************************************************************
gen change_yr=.
replace change_yr = MOVED_YEAR_ if MOVED_YEAR_ >0 & MOVED_YEAR_ <9000
replace change_yr = SPLITOFF_YEAR_ if SPLITOFF_YEAR_ >0 & SPLITOFF_YEAR_ <9000

bysort unique_id: egen entrance_no=rank(change_yr) if inlist(moved,1,4), track
bysort unique_id: egen leave_no=rank(change_yr) if inlist(moved,2,3,5), track
tab entrance_no, m
tab leave_no, m

gen hh1_start=.
replace hh1_start=change_yr if entrance_no==1 
bysort unique_id (hh1_start): replace hh1_start=hh1_start[1]
gen hh2_start=.
replace hh2_start=change_yr if entrance_no==2 
bysort unique_id (hh2_start): replace hh2_start=hh2_start[1]
gen hh3_start=.
replace hh3_start=change_yr if entrance_no==3
bysort unique_id (hh3_start): replace hh3_start=hh3_start[1]
gen hh4_start=.
replace hh4_start=change_yr if entrance_no==4
bysort unique_id (hh4_start): replace hh4_start=hh4_start[1]
gen hh5_start=.
replace hh5_start=change_yr if entrance_no==5
bysort unique_id (hh5_start): replace hh5_start=hh5_start[1]

gen hh1_end=.
replace hh1_end=change_yr if leave_no==1
bysort unique_id (hh1_end): replace hh1_end=hh1_end[1]
gen hh2_end=.
replace hh2_end=change_yr if leave_no==2
bysort unique_id (hh2_end): replace hh2_end=hh2_end[1]
gen hh3_end=.
replace hh3_end=change_yr if leave_no==3
bysort unique_id (hh3_end): replace hh3_end=hh3_end[1]
gen hh4_end=.
replace hh4_end=change_yr if leave_no==4
bysort unique_id (hh4_end): replace hh4_end=hh4_end[1]
gen hh5_end=.
replace hh5_end=change_yr if leave_no==5
bysort unique_id (hh5_end): replace hh5_end=hh5_end[1]

sort unique_id survey_yr
browse unique_id survey_yr moved change_yr entrance_no leave_no hh1_start hh1_end hh2_start hh2_end

********************************************************************************
** Relationship history
********************************************************************************

gen partnered=.
replace partnered=0 if in_sample==1 & MARITAL_PAIRS_==0
replace partnered=1 if in_sample==1 & inrange(MARITAL_PAIRS_,1,3)

// type of rel
tab MARST_DEFACTO_HEAD_ COUPLE_STATUS_HEAD_, m
tab MARST_LEGAL_HEAD_ MARST_DEFACTO_HEAD_ , m
tab relationship partnered,m  
tab relationship MARITAL_PAIRS,m  
// tabstat RELATION_, by(survey_yr) // coding switched in 1983

gen cohab_est_head=0
replace cohab_est_head = 1 if inrange(MARST_LEGAL_HEAD_,2,5) & MARST_DEFACTO_HEAD_==1 // cohab
replace cohab_est_head = 2 if MARST_LEGAL_HEAD_==1 &  MARST_DEFACTO_HEAD_==1 // married
tab COUPLE_STATUS_HEAD_ cohab_est_head , m

tab MARST_DEFACTO_HEAD_ if relationship==2 // okay, but not always correlated...is this bc sometimes they retain the info if like, they died and the one is still in the HH? for a year?
tab COUPLE_STATUS_HEAD_ if relationship==2 // okay, but not always correlated...
tab MARITAL_PAIRS if relationship==2

// head
gen rel_type = .
replace rel_type = 0 if relationship==1 & inrange(MARST_DEFACTO_HEAD_,2,5) // unpartnered
replace rel_type = 1 if inrange(survey_yr,1977,2021) & relationship==1 & cohab_est_head==2  // married (def)
replace rel_type = 2 if inrange(survey_yr,1977,2021) & relationship==1 & cohab_est_head==1 // cohab (def)
replace rel_type = 3 if inrange(survey_yr,1968,1976) & relationship==1 & MARST_DEFACTO_HEAD_==1  // any rel (pre 1977, we don't know)
// partner - okay, actually, if partner of head, then head status actually applies to them as well?
// replace rel_type = 0 if relationship==2 & inrange(MARST_DEFACTO_HEAD_,2,5) // unpartnered - does this make sense? if have a label of partner...
replace rel_type = 1 if inrange(survey_yr,1977,2021) & relationship==2 & cohab_est_head==2  // married (def)
replace rel_type = 1 if inrange(survey_yr, 1983,2021) & relationship==2 & RELATION_==20  // married (def) - based on relationship type
replace rel_type = 2 if inrange(survey_yr,1977,2021) & relationship==2 & cohab_est_head==1 // cohab (def)
replace rel_type = 2 if inrange(survey_yr,1983,2021) & relationship==2 & RELATION_==22 // cohab (def)
replace rel_type = 3 if inrange(survey_yr,1968,1976) & relationship==2 // any rel (pre 1977, we don't know)
// all others (based on being in a marital pair). but, don't know what is the type
replace rel_type = 0 if relationship==3 & MARITAL_PAIRS==0
replace rel_type = 3 if relationship==3 &inrange(MARITAL_PAIRS,1,4)

label define rel_type 0 "unpartnered" 1 "married" 2 "cohab" 3 "all rels (pre-1977)"
label values rel_type rel_type

tab rel_type in_sample, m
tab rel_type partnered, m 
tab rel_type partnered if in_sample==1, m 
tab MARST_DEFACTO_HEAD relationship if partnered==1 & rel_type==0

replace partnered=0 if rel_type==0 & partnered==. // sometimes people move out bc of a breakup and become non-response; I am not currently capturing them

// relationship transitions - OBSERVED
sort unique_id wave
// start rel - observed
gen rel_start=0
replace rel_start=1 if partnered==1 & partnered[_n-1]==0 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen marriage_start=0 // from unpartnered, NOT cohabiting
replace marriage_start=1 if rel_type==1 & rel_type[_n-1]==0 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen cohab_start=0
replace cohab_start=1 if rel_type==2 & rel_type[_n-1]==0 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen rel_end=0
replace rel_end=1 if partnered==1 & partnered[_n+1]==0 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

gen marriage_end=0
replace marriage_end=1 if rel_type==1 & rel_type[_n+1]==0 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

gen cohab_end=0
replace cohab_end=1 if rel_type==2 & rel_type[_n+1]==0 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

browse unique_id survey_yr SAMPLE in_sample hh_status_ relationship partnered rel_type rel_start marriage_start cohab_start rel_end marriage_end cohab_end YR_NONRESPONSE_FIRST

// merge on marital history - bc in order of prio, it should be marital history for marriages observed, then other variables for not in marital history or cohabitation.
merge m:1 unique_id using "$temp\marital_history_wide.dta"
drop if _merge==2

gen in_marital_history=0
replace in_marital_history=1 if _merge==3
drop _merge

browse unique_id survey_yr has_psid_gene SAMPLE in_sample hh_status_ relationship partnered rel_type rel_start rel_end rel_end hh_status_ moved MOVED_YEAR_ SPLITOFF_YEAR_  YR_NONRESPONSE_FIRST permanent_attrit mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 ANY_ATTRITION COMPOSITION_CHANGE_ MOVED_

** now add estimated relationship dates - based on OBSERVATIONS
// need to create indicator of relationship that started when person entered, so that can be considered rel1 GAH
browse unique_id survey_yr in_sample hh_status rel_type

bysort unique_id: egen first_survey_yr= min(survey_yr) if in_sample==1
bysort unique_id (first_survey_yr): replace first_survey_yr=first_survey_yr[1]
tab first_survey_yr, m
bysort unique_id: egen last_survey_yr= max(survey_yr) if in_sample==1
bysort unique_id (last_survey_yr): replace last_survey_yr=last_survey_yr[1]
tab last_survey_yr, m

sort unique_id survey_yr
browse unique_id survey_yr in_sample hh_status rel_type first_survey_yr last_survey_yr YR_NONRESPONSE_RECENT YR_NONRESPONSE_FIRST 

// all relationships 
gen relationship_start = survey_yr if rel_start==1
replace relationship_start = survey_yr if survey_yr == first_survey_yr & partnered==1

bysort unique_id: egen relno=rank(relationship_start)
tab relno, m
browse unique_id survey_yr partnered rel_type rel_start relationship_start relno FIRST_MARRIAGE_YR_START

gen rel1_start=.
replace rel1_start=relationship_start if relno==1 
bysort unique_id (rel1_start): replace rel1_start=rel1_start[1]
gen rel2_start=.
replace rel2_start=relationship_start if relno==2 
bysort unique_id (rel2_start): replace rel2_start=rel2_start[1]
gen rel3_start=.
replace rel3_start=relationship_start if relno==3
bysort unique_id (rel3_start): replace rel3_start=rel3_start[1]
gen rel4_start=.
replace rel4_start=relationship_start if relno==4
bysort unique_id (rel4_start): replace rel4_start=rel4_start[1]
gen rel5_start=.
replace rel5_start=relationship_start if relno==5
bysort unique_id (rel5_start): replace rel5_start=rel5_start[1]

sort unique_id survey_yr
browse unique_id survey_yr partnered rel_type rel_start relationship_start relno rel1_start FIRST_MARRIAGE_YR_START rel2_start

gen relationship_end = survey_yr if rel_end==1
bysort unique_id: egen exitno=rank(relationship_end)
browse unique_id survey_yr partnered rel_type rel_start relationship_start rel_end relationship_end relno exitno

gen rel1_end=.
replace rel1_end=relationship_end if exitno==1
bysort unique_id (rel1_end): replace rel1_end=rel1_end[1]
gen rel2_end=.
replace rel2_end=relationship_end if exitno==2
bysort unique_id (rel2_end): replace rel2_end=rel2_end[1]
gen rel3_end=.
replace rel3_end=relationship_end if exitno==3
bysort unique_id (rel3_end): replace rel3_end=rel3_end[1]
gen rel4_end=.
replace rel4_end=relationship_end if exitno==4
bysort unique_id (rel4_end): replace rel4_end=rel4_end[1]
gen rel5_end=.
replace rel5_end=relationship_end if exitno==5
bysort unique_id (rel5_end): replace rel5_end=rel5_end[1]

sort unique_id survey_yr
browse unique_id survey_yr rel_type rel_start relationship_start rel_end relationship_end relno exitno rel1_start rel1_end rel2_start rel2_end mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2

// marriages
gen marriage_start_yr = survey_yr if marriage_start==1
replace marriage_start_yr = survey_yr if survey_yr == first_survey_yr & rel_type==1

bysort unique_id: egen marrno=rank(marriage_start_yr)
tab marrno, m
browse unique_id survey_yr partnered rel_type marriage_start marriage_start_yr marrno FIRST_MARRIAGE_YR_START

gen marr1_start=.
replace marr1_start=marriage_start_yr if marrno==1 
bysort unique_id (marr1_start): replace marr1_start=marr1_start[1]
gen marr2_start=.
replace marr2_start=marriage_start_yr if marrno==2 
bysort unique_id (marr2_start): replace marr2_start=marr2_start[1]
gen marr3_start=.
replace marr3_start=marriage_start_yr if marrno==3
bysort unique_id (marr3_start): replace marr3_start=marr3_start[1]
gen marr4_start=.
replace marr4_start=marriage_start_yr if marrno==4
bysort unique_id (marr4_start): replace marr4_start=marr4_start[1]
gen marr5_start=.
replace marr5_start=marriage_start_yr if marrno==5
bysort unique_id (marr5_start): replace marr5_start=marr5_start[1]

sort unique_id survey_yr
browse unique_id survey_yr partnered rel_type marriage_start marriage_start_yr marrno marr1_start FIRST_MARRIAGE_YR_START marr2_start

gen marriage_end_yr = survey_yr if marriage_end==1
bysort unique_id: egen marr_exitno=rank(marriage_end_yr)
browse unique_id survey_yr partnered rel_type marriage_start marriage_start_yr marriage_end marriage_end_yr marrno marr_exitno

gen marr1_end=.
replace marr1_end=marriage_end_yr if marr_exitno==1
bysort unique_id (marr1_end): replace marr1_end=marr1_end[1]
gen marr2_end=.
replace marr2_end=marriage_end_yr if marr_exitno==2
bysort unique_id (marr2_end): replace marr2_end=marr2_end[1]
gen marr3_end=.
replace marr3_end=marriage_end_yr if marr_exitno==3
bysort unique_id (marr3_end): replace marr3_end=marr3_end[1]
gen marr4_end=.
replace marr4_end=marriage_end_yr if marr_exitno==4
bysort unique_id (marr4_end): replace marr4_end=marr4_end[1]
gen marr5_end=.
replace marr5_end=marriage_end_yr if marr_exitno==5
bysort unique_id (marr5_end): replace marr5_end=marr5_end[1]

sort unique_id survey_yr
browse unique_id survey_yr rel_type marriage_start marriage_start_yr marriage_end marriage_end_yr marrno marr_exitno marr1_start marr1_end marr2_start marr2_end mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2

// cohab
gen cohab_start_yr = survey_yr if cohab_start==1
replace cohab_start_yr = survey_yr if survey_yr == first_survey_yr & rel_type==2

bysort unique_id: egen cohno=rank(cohab_start_yr)
tab cohno, m
browse unique_id survey_yr partnered rel_type cohab_start cohab_start_yr cohno

gen coh1_start=.
replace coh1_start=cohab_start_yr if cohno==1 
bysort unique_id (coh1_start): replace coh1_start=coh1_start[1]
gen coh2_start=.
replace coh2_start=cohab_start_yr if cohno==2 
bysort unique_id (coh2_start): replace coh2_start=coh2_start[1]
gen coh3_start=.
replace coh3_start=cohab_start_yr if cohno==3
bysort unique_id (coh3_start): replace coh3_start=coh3_start[1]

sort unique_id survey_yr
browse unique_id survey_yr partnered rel_type cohab_start cohab_start_yr cohno coh1_start coh2_start

gen cohab_end_yr = survey_yr if cohab_end==1
bysort unique_id: egen coh_exitno=rank(cohab_end_yr)
browse unique_id survey_yr partnered rel_type cohab_start cohab_start_yr cohab_end cohab_end_yr cohno coh_exitno

gen coh1_end=.
replace coh1_end=cohab_end_yr if coh_exitno==1
bysort unique_id (coh1_end): replace coh1_end=coh1_end[1]
gen coh2_end=.
replace coh2_end=cohab_end_yr if coh_exitno==2
bysort unique_id (coh2_end): replace coh2_end=coh2_end[1]
gen coh3_end=.
replace coh3_end=cohab_end_yr if coh_exitno==3
bysort unique_id (coh3_end): replace coh3_end=coh3_end[1]

sort unique_id survey_yr
browse unique_id survey_yr rel_type cohab_start cohab_start_yr cohab_end cohab_end_yr cohno coh_exitno coh1_start coh1_end coh2_start coh2_end mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2

********************************************************************************
* Now, need to try to get more accurate relationship dates
********************************************************************************

browse unique_id survey_yr has_psid_gene in_sample first_survey_yr last_survey_yr partnered rel_type rel1_start rel1_end rel2_start rel2_end moved change_yr hh1_start hh1_end hh2_start hh2_end YR_NONRESPONSE_FIRST YR_NONRESPONSE_RECENT permanent_attrit mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 ANY_ATTRITION COMPOSITION_CHANGE_ MOVED_

preserve 

collapse 	(mean) rel1_start rel2_start rel3_start rel4_start rel5_start rel1_end rel2_end rel3_end rel4_end rel5_end /// created rel variables
					marr1_start marr2_start marr3_start marr4_start marr5_start marr1_end marr2_end marr3_end marr4_end marr5_end ///
					coh1_start coh2_start coh3_start coh1_end coh2_end coh3_end ///
					hh1_start hh2_start hh3_start hh4_start hh5_start hh1_end hh2_end hh3_end hh4_end hh5_end /// based on move in / move out
					mh_yr_married1 mh_yr_married2 mh_yr_married3 mh_yr_married4 mh_yr_married5 mh_yr_married6 mh_yr_married7 mh_yr_married8 mh_yr_married9 mh_yr_married12 mh_yr_married13 /// marital history variables
					mh_yr_end1 mh_yr_end2 mh_yr_end3 mh_yr_end4 mh_yr_end5 mh_yr_end6 mh_yr_end7 mh_yr_end8 mh_yr_end9 mh_yr_end12 mh_yr_end13  ///
					mh_status1 mh_status2 mh_status3 mh_status4 mh_status5 mh_status6 mh_status7 mh_status8 mh_status9 mh_status12 mh_status13 ///
					first_survey_yr last_survey_yr YR_NONRESPONSE_FIRST YR_NONRESPONSE_RECENT ///
			(max) partnered in_marital_history /// get a sense of ever partnered
, by(unique_id has_psid_gene SAMPLE)

gen partner_id = unique_id // for later matching

**# Create file

save "$temp\psid_composition_history.dta", replace