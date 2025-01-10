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
* (couple sample created for growth curve project - in weequalize data creation folder)

********************************************************************************
* First, create a lookup file of children and their parents with the unique ID I can link back to other files
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
**# * Then, sort out birth history data to append
********************************************************************************
use "$fam_history/cah85_21.dta", clear

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

** Should I do sample restrictions here? need to reorient myself to who and what are included
// browse unique_id partner_id survey_yr first_survey_yr rel_start rel_start_yr rel_start_yr_est mh_yr_married1 mh_yr_married2 mh_yr_married3 rel_end rel_end_pre rel_end_yr rel_end_yr_est
keep if rel_start_yr>=1990 & rel_start_yr!=. // my measures don't start until 1990, and that works with "gender revolution" framing, so restrict to that

// browse unique_id partner_id survey_yr SEX AGE_INDV_ BIRTH_YR_INDV_ year_birth yr_born_head AGE_HEAD_ yr_born_wife AGE_WIFE_ // should I restrict to certain ages now? or later?
keep if (AGE_HEAD_>=20 & AGE_HEAD_<=60) & (AGE_WIFE_>=20 & AGE_WIFE_<50) // Comolli using the PSID does 16-49 for women and < 60 for men, but I want a higher lower limit for measurement of education? In general, age limit for women tends to range from 44-49, will use the max of 49 for now. lower limit of 20 seems justifiable based on prior research (and could prob go even older)

** Okay, start to add birth info in
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
tab FIRST_BIRTH_YR if check==0 // all 9999s - aka no kids for that person specifically
browse FIRST_BIRTH_YR cah_child_birth_yr*_ref if check==0

********************************************************************************
* Create actual birth measures
********************************************************************************
**These seem wrong for some reason and I want to create for both ref and partner (and joint). also going to revisit all of these variables, so just dropping for now - these were created in earlier data creation phase
drop had_birth had_first_birth had_first_birth_alt

// browse unique_id partner_id SEX survey_yr rel_start_yr rel_end_yr cah_unique_id_child1_ref cah_unique_id_mom1_ref cah_unique_id_dad1_ref cah_child_birth_yr1_ref cah_unique_id_child2_ref cah_unique_id_mom2_ref cah_unique_id_dad2_ref cah_child_birth_yr2_ref cah_unique_id_child1_sp cah_unique_id_mom1_sp cah_unique_id_dad1_sp  cah_child_birth_yr1_sp  cah_unique_id_child2_sp cah_unique_id_mom2_sp cah_unique_id_dad2_sp cah_child_birth_yr2_sp

** First indicate, for each birth of each partner, if it is with current partner
forvalues c=1/20{
	gen cah_sharedchild`c'_ref=.
	replace cah_sharedchild`c'_ref = 0 if SEX==2 & cah_unique_id_child`c'_ref!=0 & unique_id == cah_unique_id_mom`c'_ref & partner_id != cah_unique_id_dad`c'_ref // first do assuming ref is mom
	replace cah_sharedchild`c'_ref = 0 if SEX==1 & cah_unique_id_child`c'_ref!=0 & unique_id == cah_unique_id_dad`c'_ref & partner_id != cah_unique_id_mom`c'_ref // then assuming ref is dad
	replace cah_sharedchild`c'_ref = 1 if SEX==2 & cah_unique_id_child`c'_ref!=0 & unique_id == cah_unique_id_mom`c'_ref & partner_id == cah_unique_id_dad`c'_ref // first do assuming ref is mom
	replace cah_sharedchild`c'_ref = 1 if SEX==1 & cah_unique_id_child`c'_ref!=0 & unique_id == cah_unique_id_dad`c'_ref & partner_id == cah_unique_id_mom`c'_ref // then assuming ref is dad
}

egen num_shared_births_ref=rowtotal(cah_sharedchild*_ref)

// browse unique_id partner_id SEX survey_yr cah_unique_id_child1_ref cah_sharedchild1_ref cah_unique_id_mom1_ref cah_unique_id_dad1_ref cah_child_birth_yr1_ref cah_unique_id_child2_ref cah_sharedchild2_ref cah_unique_id_mom2_ref cah_unique_id_dad2_ref cah_child_birth_yr2_ref
// inspect cah_unique_id_child1_ref if cah_sharedchild1_ref==.

forvalues c=1/20{
	gen cah_sharedchild`c'_sp=.
	replace cah_sharedchild`c'_sp = 0 if SEX==2 & cah_unique_id_child`c'_sp!=0 & unique_id != cah_unique_id_mom`c'_sp & partner_id == cah_unique_id_dad`c'_sp // this is matched to partner, so if the ref is F, then we need the partner ID to match dad (bc he is M) and HER id not to match - bc these are his records
	replace cah_sharedchild`c'_sp = 0 if SEX==1 & cah_unique_id_child`c'_sp!=0 & unique_id != cah_unique_id_dad`c'_sp & partner_id == cah_unique_id_mom`c'_sp // then assuming ref is dad so partner records that need to match are mom's
	replace cah_sharedchild`c'_sp = 1 if SEX==2 & cah_unique_id_child`c'_sp!=0 & unique_id == cah_unique_id_mom`c'_sp & partner_id == cah_unique_id_dad`c'_sp // first do assuming ref is mom
	replace cah_sharedchild`c'_sp = 1 if SEX==1 & cah_unique_id_child`c'_sp!=0 & unique_id == cah_unique_id_dad`c'_sp & partner_id == cah_unique_id_mom`c'_sp // then assuming ref is dad
}

// browse unique_id partner_id SEX survey_yr cah_unique_id_child1_sp cah_sharedchild1_sp cah_unique_id_mom1_sp cah_unique_id_dad1_sp cah_child_birth_yr1_sp cah_unique_id_child2_sp cah_sharedchild2_sp cah_unique_id_mom2_sp cah_unique_id_dad2_sp cah_child_birth_yr2_sp
// inspect cah_unique_id_child1_sp if cah_sharedchild1_sp==.

egen num_shared_births_sp=rowtotal(cah_sharedchild*_sp)
tab num_shared_births_ref num_shared_births_sp, m row // mostly congruous, but def some discrepancies in reporting
tab cah_num_bio_kids_ref num_shared_births_ref, m row // so there is definitely less conguence between number of total kids and number of shared kids
tab cah_num_bio_kids_ref cah_num_bio_kids_sp, m

gen all_births_shared=0
replace all_births_shared = 1 if cah_num_bio_kids_ref==cah_num_bio_kids_sp & cah_num_bio_kids_ref==num_shared_births_ref & num_shared_births_ref==num_shared_births_sp & cah_num_bio_kids_ref!=0 & cah_num_bio_kids_ref!=. & cah_num_bio_kids_sp!=0 & cah_num_bio_kids_sp!=.
replace all_births_shared=. if cah_num_bio_kids_ref==0 & cah_num_bio_kids_sp==0 // no births

browse unique_id partner_id survey_yr all_births_shared num_shared_births_ref num_shared_births_sp cah_num_bio_kids_ref cah_num_bio_kids_sp

// browse unique_id partner_id SEX survey_yr cah_sharedchild1_ref cah_sharedchild2_ref cah_sharedchild3_ref cah_sharedchild1_sp cah_sharedchild2_sp cah_sharedchild3_sp

** Designate if first birth was together
tab cah_sharedchild1_ref, m
tab cah_sharedchild1_sp, m
tab cah_sharedchild1_ref cah_sharedchild1_sp, m // is the overlap of 1s the joint first birth? but that doesn't nec. indicate that ORDER matches, just that the birth was in this relationship. it could be like mom's first birth but dad's second.

gen joint_first_birth=. // want missing to be retained for those with no kids?
replace joint_first_birth=0 if cah_sharedchild1_ref==0 | cah_sharedchild1_sp==0
replace joint_first_birth=1 if cah_unique_id_child1_ref == cah_unique_id_child1_sp & cah_unique_id_mom1_ref == cah_unique_id_mom1_sp & cah_unique_id_dad1_ref == cah_unique_id_dad1_sp & cah_child_birth_yr1_ref == cah_child_birth_yr1_sp & cah_unique_id_child1_ref!=0 // so all IDs need to match. is there ever a world where they don't.
tab joint_first_birth, m

gen joint_first_birth_yr=.
replace joint_first_birth_yr= cah_child_birth_yr1_ref if joint_first_birth==1

gen joint_first_birth_rel=.
replace joint_first_birth_rel=0 if joint_first_birth==1 & joint_first_birth_yr < rel_start_yr
replace joint_first_birth_rel=1 if joint_first_birth==1 & joint_first_birth_yr >= rel_start_yr & joint_first_birth_yr!=. & rel_start_yr!=.
tab joint_first_birth_rel // so 80% is after start

browse unique_id partner_id survey_yr marital_status_updated rel_start rel_start_yr joint_first_birth_yr joint_first_birth_rel mh_yr_married1 mh_yr_married2 mh_yr_married3

gen joint_first_birth_timing=.
replace joint_first_birth_timing = joint_first_birth_yr - rel_start_yr if joint_first_birth==1 & joint_first_birth_yr!=9998
tab joint_first_birth_timing joint_first_birth_rel, m
tab joint_first_birth_timing if joint_first_birth_rel==1
sum joint_first_birth_timing
sum joint_first_birth_timing if joint_first_birth_rel==1

	// some ids to investigate in main data to ensure the disconnect between recorded relationship start and recorded first birth makes sense: 
	// browse unique_id survey_yr SEQ_NUMBER_ MARITAL_PAIRS_ FIRST_BIRTH_YR AGE_YOUNG_CHILD_ NUM_CHILDREN_ NUM_IN_HH_ if inlist(unique_id,4008, 4179, 4039, 4201, 557030, 557175,2073031, 2073172, 3162001, 3162002, 3163001, 3163002,  4448001, 4448002, 6721172, 6721173) // have to do this in main original file, not here
	// u: 4008 p: 4179 rel: 1998 birth: 1984. 4008 in and out between 1968 and 2011, listed in "marital pairs" 1987-1992, 1999-2005, 2011. 4179 exists 1986 to 2009 (mostly), in marital pairs 1987-1992, 1999-2005.
	// u: 4039 p: 4201 rel: 2010 birth: 2009. 4039 exists 1991-2021, but only listed in "marital pairs" between 2011 and 2015. 4201 only exists (and in marital pairs) 2011-2015
	// u: 557030 p: 557175 rel: 1995 birth: 1991. 557030 in survey but not in marital pair 1972-1983, then in survey AND in pair 1994-2021. 557175 only exists (and in marital pair) 1994-2021
	// u: 2073031 p: 2073172 rel: 2004 birth: 1997. 2073031 in survey 1982-2021, but only in marital pair 2005-2021. 2073172 only in survey ANd in pair 2005-2021
	// u: 3162001 p: 3162002 rel: 1990 birth: 1980. 3162001 in survey AND in pair 1997-2021. 3162002 same
	// u: 3163001 p: 3163002 rel: 1997 birth: 1983. 3163001 in survey AND in pair 1997-2003. 3163002 in survey 1997-2021, but only in pair 1997-2003.
	// u: 4448001 p: 4448002 rel: 2017 birth: 1992. 4448001 in survey AND in pair 2017-2021. 4448002 same.
	// u: 6721172 p: 6721173 rel: 2010 birth: 2004. 6721172 in survey 2003-2021, but in pair starting 2011-2021. 6721173 in survey 2009, but in pair 2011-2021.

** Designate if entered rel already having had a birth
gen num_births_pre_ref=0
gen num_births_pre_sp=0
forvalues c=1/20{
	replace num_births_pre_ref = num_births_pre_ref + 1 if cah_child_birth_yr`c'_ref < rel_start_yr
	replace num_births_pre_sp = num_births_pre_sp + 1 if cah_child_birth_yr`c'_sp < rel_start_yr
}

tab num_births_pre_ref, m
tab num_births_pre_sp, m
tab num_births_pre_ref num_births_pre_sp, m

** Designate if entered rel already having had a birth - and births NOT with current partner
gen num_births_pre_indv_ref=0
gen num_births_pre_indv_sp=0
forvalues c=1/20{
	replace num_births_pre_indv_ref = num_births_pre_indv_ref + 1 if cah_child_birth_yr`c'_ref < rel_start_yr & cah_sharedchild`c'_ref==0 // so this is if it's before relationship start AND not as recorded as being with current partner
	replace num_births_pre_indv_sp = num_births_pre_indv_sp + 1 if cah_child_birth_yr`c'_sp < rel_start_yr & cah_sharedchild`c'_sp==0
}

tab num_births_pre_indv_ref num_births_pre_indv_sp, m

gen any_births_pre_rel=0
replace any_births_pre_rel = 1 if num_births_pre_indv_ref >0 | num_births_pre_indv_sp > 0

// browse unique_id partner_id survey_yr rel_start_yr num_births_pre_indv_ref cah_child_birth_yr1_ref cah_sharedchild1_ref cah_child_birth_yr2_ref cah_sharedchild2_ref  cah_child_birth_yr3_ref cah_sharedchild3_ref num_births_pre_indv_sp cah_child_birth_yr1_sp cah_sharedchild1_sp cah_child_birth_yr2_sp cah_sharedchild2_sp cah_child_birth_yr3_sp cah_sharedchild3_sp

**# Temp save - stopped here
save "$created_data/PSID_couple_births.dta", replace

********************************************************************************
* Intermission to figure out how to get info on the SHARED birth order
********************************************************************************
use "$created_data/PSID_couple_births.dta", clear

browse unique_id partner_id SEX survey_yr cah_num_bio_kids_ref cah_num_bio_kids_sp cah_sharedchild1_ref cah_sharedchild2_ref cah_sharedchild3_ref cah_sharedchild1_sp cah_sharedchild2_sp cah_sharedchild3_sp

collapse (max) cah_sharedchild*_ref cah_sharedchild*_sp cah_child_birth_yr*_ref cah_child_birth_yr*_sp ///
all_births_shared num_shared_births_ref num_shared_births_sp cah_num_bio_kids_ref cah_num_bio_kids_sp, ///
by (unique_id partner_id)

browse unique_id partner_id cah_num_bio_kids_ref cah_num_bio_kids_sp cah_sharedchild1_ref cah_sharedchild2_ref cah_sharedchild3_ref cah_sharedchild1_sp cah_sharedchild2_sp cah_sharedchild3_sp
tab cah_sharedchild1_ref if cah_num_bio_kids_ref!=0, m
tab cah_sharedchild1_sp if cah_num_bio_kids_sp!=0, m

reshape long cah_sharedchild@_ref cah_sharedchild@_sp cah_child_birth_yr@_ref cah_child_birth_yr@_sp, i(unique_id partner_id) j(birth_id)

// by unique_id partner_id: egen shared_order_ref = rank(cah_sharedchild_ref) if cah_sharedchild_ref==1, unique
by unique_id partner_id: egen shared_order_ref = rank(birth_id) if cah_sharedchild_ref==1, unique // hmm rank unique id or birth yr?
by unique_id partner_id: egen shared_order_sp = rank(birth_id) if cah_sharedchild_sp==1, unique

browse unique_id partner_id birth_id shared_order_ref cah_sharedchild_ref shared_order_sp cah_sharedchild_sp cah_child_birth_yr_ref cah_child_birth_yr_sp

// make sure this is what i want to do before doing for the rest of births
gen shared_birth1_refid=.
replace shared_birth1_refid = birth_id if shared_order_ref==1
bysort unique_id partner_id (shared_birth1_refid): replace shared_birth1_refid = shared_birth1_refid[1]
	
gen shared_birth1_refyr=.
replace shared_birth1_refyr = cah_child_birth_yr_ref if shared_order_ref==1
bysort unique_id partner_id (shared_birth1_refyr): replace shared_birth1_refyr = shared_birth1_refyr[1]

gen shared_birth1_spid=.
replace shared_birth1_spid = birth_id if shared_order_sp==1
bysort unique_id partner_id (shared_birth1_spid): replace shared_birth1_spid = shared_birth1_spid[1]

gen shared_birth1_spyr=.
replace shared_birth1_spyr = cah_child_birth_yr_sp if shared_order_sp==1
bysort unique_id partner_id (shared_birth1_spyr): replace shared_birth1_spyr = shared_birth1_spyr[1]

browse unique_id partner_id birth_id shared_birth1_refid shared_birth1_spid shared_order_ref shared_order_sp shared_birth1_refyr shared_birth1_spyr cah_child_birth_yr_ref cah_child_birth_yr_sp

// now loop through rest
forvalues b=2/9{
	gen shared_birth`b'_refid=.
	replace shared_birth`b'_refid = birth_id if shared_order_ref==`b'
	bysort unique_id partner_id (shared_birth`b'_refid): replace shared_birth`b'_refid = shared_birth`b'_refid[1]
	
	gen shared_birth`b'_refyr=.
	replace shared_birth`b'_refyr = cah_child_birth_yr_ref if shared_order_ref==`b'
	bysort unique_id partner_id (shared_birth`b'_refyr): replace shared_birth`b'_refyr = shared_birth`b'_refyr[1]
	
	gen shared_birth`b'_spid=.
	replace shared_birth`b'_spid = birth_id if shared_order_sp==`b'
	bysort unique_id partner_id (shared_birth`b'_spid): replace shared_birth`b'_spid = shared_birth`b'_spid[1]
	
	gen shared_birth`b'_spyr=.
	replace shared_birth`b'_spyr = cah_child_birth_yr_sp if shared_order_sp==`b'
	bysort unique_id partner_id (shared_birth`b'_spyr): replace shared_birth`b'_spyr = shared_birth`b'_spyr[1]
}

sort unique_id partner_id birth_id 

browse unique_id partner_id birth_id shared_birth1_refid shared_birth2_refid shared_birth1_spid shared_birth2_spid shared_order_ref shared_order_sp shared_birth1_refyr shared_birth2_refyr shared_birth1_spyr shared_birth2_spyr cah_child_birth_yr_ref cah_child_birth_yr_sp

collapse (max) shared_birth*_refid shared_birth*_spid shared_birth*_refyr shared_birth*_spyr num_shared_births_ref num_shared_births_sp, ///
by (unique_id partner_id)

browse unique_id partner_id num_shared_births_ref num_shared_births_sp shared_birth1_refid shared_birth2_refid shared_birth1_spid shared_birth2_spid shared_birth1_refyr shared_birth2_refyr shared_birth1_spyr shared_birth2_spyr 

tab shared_birth1_refid num_shared_births_ref, m
tab shared_birth1_refid if num_shared_births_ref!=0, m
tab shared_birth1_spid if num_shared_births_sp!=0, m

save "$temp/shared_birth_lookup.dta", replace

********************************************************************************
**# Intermission over
********************************************************************************
use "$created_data/PSID_couple_births.dta", clear

********************************************************************************
**# ALL BELOW HERE NEEDS TO BE REVISITED
********************************************************************************

** This is trying to increment births DURING the survey period
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
