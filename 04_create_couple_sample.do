********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: create_couple_sample
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the individual data and first couples all couples
* it adds various birth history information to then create fertility samples
* Code based off of primary PSID data creation code for project with some modifications

********************************************************************************
**# First, restrict file to couples only and fill in marital history info
********************************************************************************
use "$created_data\PSID_individ_allyears.dta", clear

egen wave = group(survey_yr) // this will make years consecutive, easier for later

tab in_sample,m 
tab partnered, m
tab relationship MARITAL_PAIRS_, m
tab partnered MARITAL_PAIRS_, m
browse unique_id survey_yr in_sample relationship partnered MARITAL_PAIRS_

gen partnered_full = partnered
replace partnered_full = 0 if partnered_full==. & MARITAL_PAIRS_==0
replace partnered_full = 1 if partnered_full==. & inrange(MARITAL_PAIRS_,1,4)
tab partnered_full, m

unique unique_id, by(partnered_full)
unique unique_id if partnered_full==1 | partnered_full==.
browse unique_id survey_yr in_sample relationship partnered_full MARITAL_PAIRS_  MARST_DEFACTO_HEAD_ MARST_LEGAL_HEAD_

label define marr_defacto 1 "Partnered" 2 "Single" 3 "Widowed" 4 "Divorced" 5 "Separated"
label values MARST_DEFACTO_HEAD_ marr_defacto

label define marr_legal 1 "Married" 2 "Single" 3 "Widowed" 4 "Divorced" 5 "Separated"
label values MARST_LEGAL_HEAD_ marr_legal

keep if partnered_full==1 | partnered_full==. // so right now, partnered missing is an off survey year where the year prior they were in a relationship but the year after were not (or vice versa). leave for now until I get history and figure out if should be partnered or not.

gen cohab_est_head=0
replace cohab_est_head=1 if MARST_DEFACTO_HEAD_==1 & inlist(MARST_LEGAL_HEAD_,2,3,4,5) // will only apply after 1977

gen marital_status_updated=.
replace marital_status_updated=1 if MARST_DEFACTO_HEAD_==1 & cohab_est_head==0
replace marital_status_updated=2 if MARST_DEFACTO_HEAD_==1 & cohab_est_head==1
replace marital_status_updated=3 if MARST_DEFACTO_HEAD_==2
replace marital_status_updated=4 if MARST_DEFACTO_HEAD_==3
replace marital_status_updated=5 if MARST_DEFACTO_HEAD_==4
replace marital_status_updated=6 if MARST_DEFACTO_HEAD_==5

label define marital_status_updated 1 "Married (or pre77)" 2 "Partnered" 3 "Single" 4 "Widowed" 5 "Divorced" 6 "Separated"
label values marital_status_updated marital_status_updated

tab marital_status_updated in_sample, m
tab marital_status_updated relationship, m

unique unique_id if relationship!=3
unique unique_id if relationship==1 | relationship==2

// add marital history so I can start to add relationship start and end dates
merge m:1 unique_id using "$temp\psid_composition_history.dta" // try this for now
drop partner_id // need to clean up some things I don't need in this file for now

drop if _merge==2
drop _merge

// filling in marital history (JUST marriages)
browse unique_id survey_yr relationship partnered_full marital_status_updated FIRST_MARRIAGE_YR_START mh_yr_married1 marr1_start mh_yr_end1 marr1_end mh_status1 mh_yr_married2 marr2_start mh_yr_end2 marr2_end mh_yr_married3 mh_yr_end3 mh_yr_married4 mh_yr_end4 in_marital_history // so will compare what is provided in individual file, what is provided in MH, what I calculated based on observed transitions. will start with official martal history

gen rel_number=.
forvalues r=1/9{
	replace rel_number=`r' if survey_yr >=mh_yr_married`r' & survey_yr <= mh_yr_end`r'
}
forvalues r=12/13{
	replace rel_number=`r' if survey_yr >=mh_yr_married`r' & survey_yr <= mh_yr_end`r'
}

tab rel_number, m
tab rel_number in_marital_history, m // so about half of the missing are bc not in marital history, but still a bunch otherwise
tab rel_number marital_status_updated if in_marital_history==1, m // okay, so yes, the vast majority of missing are bc partnered, not married, so that makes sense.

gen rel_start_yr=.
gen rel_end_yr=.
gen rel_status=.

forvalues r=1/9{
	replace rel_start_yr=mh_yr_married`r' if rel_number==`r'
	replace rel_end_yr=mh_yr_end`r' if rel_number==`r'
	replace rel_status=mh_status`r' if rel_number==`r'
}
forvalues r=12/13{
	replace rel_start_yr=mh_yr_married`r' if rel_number==`r'
	replace rel_end_yr=mh_yr_end`r' if rel_number==`r'
	replace rel_status=mh_status`r' if rel_number==`r'
}

browse unique_id survey_yr marital_status_updated rel_number rel_start_yr rel_end_yr FIRST_MARRIAGE_YR_START mh_yr_married1 mh_yr_end1 mh_status1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 mh_yr_married4 mh_yr_end4 in_marital_history

gen flag=0
replace flag=1 if rel_start_yr==. // aka need to add manually

// so, right now, official relationship start and end filled in for those in marital history and not cohabiting. let's figure out the rest
browse unique_id survey_yr marital_status_updated in_marital_history flag rel_start_yr rel_end_yr rel_start moved change_yr hh1_start hh2_start hh1_end hh2_end rel1_start rel1_end rel2_start rel2_end mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2
browse unique_id survey_yr marital_status_updated in_marital_history rel_start_yr rel_end_yr rel_start moved change_yr hh1_start hh2_start hh1_end hh2_end rel1_start rel1_end rel2_start rel2_end if flag==1

gen hhno_est=.
forvalues h=1/5{
	replace hhno_est=`h' if survey_yr >=hh`h'_start & survey_yr <= hh`h'_end
}

gen relno_est=.
forvalues r=1/5{
	replace relno_est=`r' if survey_yr >=rel`r'_start & survey_yr <= rel`r'_end
}

gen rel_start_yr_est=.
gen rel_end_yr_est =.
gen hh_start_yr_est=.
gen hh_end_yr_est=.

forvalues r=1/5{
	replace rel_start_yr_est=rel`r'_start if relno_est==`r'
	replace rel_end_yr_est=rel`r'_end if relno_est==`r'
	replace hh_start_yr_est=hh`r'_start if hhno_est==`r'
	replace hh_end_yr_est=hh`r'_end if hhno_est==`r'
}

egen max_start_yr_est = rowmax(hh_start_yr_est rel_start_yr_est)
egen max_end_yr_est = rowmax(hh_end_yr_est rel_end_yr_est)
egen min_start_yr_est = rowmin(hh_start_yr_est rel_start_yr_est)
egen min_end_yr_est = rowmin(hh_end_yr_est rel_end_yr_est)
// browse unique_id survey_yr max_start_yr_est max_end_yr_est hh_start_yr_est rel_start_yr_est hh_end_yr_est rel_end_yr_est

replace rel_start_yr = rel_start_yr_est if flag==1 & hh_start_yr_est==. // so use relationship if no HH info
replace rel_end_yr = rel_end_yr_est if flag==1 & hh_end_yr_est==. // so use relationship if no HH info

replace rel_start_yr = hh_start_yr_est if rel_start_yr_est==hh_start_yr_est & rel_start_yr_est!=. & hh_start_yr_est!=. & rel_start_yr==. // fill in if they match
replace rel_start_yr = hh_start_yr_est if (abs(rel_start_yr_est-hh_start_yr_est)==1 | abs(rel_start_yr_est-hh_start_yr_est)==2) & rel_start_yr_est!=. & hh_start_yr_est!=. & rel_start_yr==. // fill in if they are just a year or two off in either direction (bc of biennial surveys)
replace rel_start_yr = max_start_yr_est if rel_start_yr_est!=. & hh_start_yr_est!=. & rel_start_yr==. // I think the later date makes sense in these instances
replace rel_start_yr = hh_start_yr_est if rel_start_yr==. & hh_start_yr_est!=.
tab hh_start_yr_est if rel_start_yr==. , m
tab rel_start_yr_est if rel_start_yr==. , m

replace rel_end_yr = hh_end_yr_est if rel_end_yr_est==hh_end_yr_est & rel_end_yr_est!=. & hh_end_yr_est!=. & rel_end_yr==. // fill in if they match
replace rel_end_yr = hh_end_yr_est if (abs(rel_end_yr_est-hh_end_yr_est)==1 | abs(rel_end_yr_est-hh_end_yr_est)==2) & rel_end_yr_est!=. & hh_end_yr_est!=. & rel_end_yr==. // fill in if they are just a year off in either direction
replace rel_end_yr = hh_end_yr_est if rel_end_yr==. // use hh end if no rel end bc I think this better captures move outs then permanent attrits
replace rel_end_yr = rel_end_yr_est if rel_end_yr==. // then for rest, use rel end, okay these are all missing
tab hh_end_yr_est if rel_end_yr==. , m
tab rel_end_yr_est if rel_end_yr==. , m

tab rel_start_yr partnered_full, m // the missing for partnered missing may be bc those years are, in fact, outside the scope of the relationship
tab rel_start_yr marital_status_updated, m // but still a decent amount missing for partnered, especially cohab

browse unique_id survey_yr marital_status_updated in_marital_history rel_start_yr rel_end_yr mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 hh_start_yr_est rel_start_yr_est hh_end_yr_est rel_end_yr_est rel1_start rel2_start rel3_start rel1_end rel2_end rel3_end

// based on exploration - those missing rel start yr AND marital status are outside the bounds of the relationship
drop if rel_start_yr==. & marital_status_updated==.
drop if rel_start_yr==. & rel_start_yr_est==. // so also seems outside of my estimated bounds

// add relationship duration
gen relationship_duration = survey_yr - rel_start_yr

// attempt to create partner ids
// this will be harder with missing relationship info. but see if there is another way to fill it out based on the rel no variables I created above. also, what do I do about others?
tab relationship, m

gen relationship_est = relationship
replace relationship_est = relationship[_n-1] if unique_id == unique_id[_n-1] & wave==wave[_n-1]+1 & relationship_est==.
replace relationship_est = relationship[_n+1] if unique_id == unique_id[_n+1] & wave==wave[_n+1]-1 & relationship_est==.
browse unique_id survey_yr wave FAMILY_INTERVIEW_NUM_ relationship_est relationship
tab relationship_est, m

label values relationship_est relationship

browse unique_id main_fam_id FAMILY_INTERVIEW_NUM_ survey_yr in_sample relationship_est rel_number hhno_est relno_est 
replace FAMILY_INTERVIEW_NUM_ = FAMILY_INTERVIEW_NUM_[_n-1] if unique_id == unique_id[_n-1] & wave==wave[_n-1]+1 & FAMILY_INTERVIEW_NUM_==.
replace FAMILY_INTERVIEW_NUM_ = FAMILY_INTERVIEW_NUM_[_n+1] if unique_id == unique_id[_n+1] & wave==wave[_n+1]-1 & FAMILY_INTERVIEW_NUM_==.

sort survey_yr FAMILY_INTERVIEW_NUM_
browse unique_id main_fam_id FAMILY_INTERVIEW_NUM_ survey_yr in_sample relationship_est rel_number hhno_est relno_est 

// wait a sec - there is no family interview number for missing years, so this will not work? okay need to revisit this GAH. can I do this based on the relationship number variables? or just fill in the interview numbers from the prio year? will this work for both people?

gen id_ref=.
replace id_ref = unique_id if relationship_est==1 
bysort survey_yr main_fam_id FAMILY_INTERVIEW_NUM_ (id_ref): replace id_ref = id_ref[1]

gen id_wife=.
replace id_wife = unique_id if relationship_est==2
bysort survey_yr main_fam_id FAMILY_INTERVIEW_NUM_ (id_wife): replace id_wife = id_wife[1]

sort survey_yr FAMILY_INTERVIEW_NUM_
browse unique_id main_fam_id FAMILY_INTERVIEW_NUM_ survey_yr relationship_est id_ref id_wife

gen partner_id=.
replace partner_id = id_ref if relationship_est==2 // so need opposite id
replace partner_id = id_wife if relationship_est==1
unique partner_id
unique unique_id
unique unique_id partner_id

inspect partner_id if inlist(relationship_est,1,2)

sort unique_id survey_yr // might I be able to fill in missing partner info from earlier years? need to also figure out if coding error or truly no partner in the HH in that year.
browse unique_id partner_id survey_yr rel_start_yr rel_end_yr marital_status_updated main_fam_id FAMILY_INTERVIEW_NUM_  relationship_est id_ref id_wife
replace partner_id = partner_id[_n-1] if unique_id == unique_id[_n-1] & rel_start_yr == rel_start_yr[_n-1] & wave==wave[_n-1]+1 & partner_id==.
replace partner_id = partner_id[_n+1] if unique_id == unique_id[_n+1] & rel_start_yr == rel_start_yr[_n+1] & wave==wave[_n+1]-1 & partner_id==.

********************************************************************************
**# Add sample restrictions here?
********************************************************************************
**Remove if not head or wife (because won't have info?)
keep if inlist(relationship_est,1,2)

// browse unique_id partner_id survey_yr first_survey_yr rel_start rel_start_yr rel_start_yr_est mh_yr_married1 mh_yr_married2 mh_yr_married3 rel_end rel_end_pre rel_end_yr rel_end_yr_est
keep if rel_start_yr>=1990 & rel_start_yr!=. // my measures don't start until 1990, and that works with "gender revolution" framing, so restrict to that. based on fertility decline, might actually need to start later? but this works for now.

// should I restrict to certain ages now? or later?
browse unique_id survey_yr relationship_est SEX birth_yr age_focal  // think the ages will be missing in some cases because I probably didn't carry these through. do for men and women separately? okay I actually removed age of head and wife oops. AGE_HEAD_ AGE_WIFE_ - considering adding in previous, but fine for now. bt I didn't carry through age focal
replace age_focal = survey_yr - birth_yr if age_focal==. & birth_yr!=9999
drop if age_focal<0

// actually - I do want to wait until I have my partners matched. because I don't want to chop off couples in weird ways - like end up with mismatched records bc of the age differences.
// keep if (AGE_HEAD_>=20 & AGE_HEAD_<=60) & (AGE_WIFE_>=20 & AGE_WIFE_<50) // Comolli using the PSID does 16-49 for women and < 60 for men, but I want a higher lower limit for measurement of education? In general, age limit for women tends to range from 44-49, will use the max of 49 for now. lower limit of 20 seems justifiable based on prior research (and could prob go even older)

// save "$created_data\PSID_couples_allyears.dta", replace

********************************************************************************
**# Now append birth history / figure out births
********************************************************************************

// merge on birth history: respondent
merge m:1 unique_id using "$temp\birth_history_wide.dta", keepusing(*_ref)
drop if _merge==2

gen in_birth_history=0
replace in_birth_history=1 if _merge==3
drop _merge

tab in_birth_history in_marital_history, m // okay, so exact same overlap, which makes sense, bc both started in 1985. and since I restricted to 1990+, actually few people not in history

// merge on birth history: partner
merge m:1 partner_id using "$temp\birth_history_wide.dta", keepusing(*_sp)
drop if _merge==2

gen in_birth_history_sp=0
replace in_birth_history_sp=1 if _merge==3 // main mismatches here are those without a partner_id. still need to decide if will fill in or not because that probably means we don't have other data for the partner in that year (but will add that info on much later)
drop _merge

// birth history date matches
sort unique_id survey_yr
gen check=.
replace check=0 if FIRST_BIRTH_YR != cah_child_birth_yr1_ref & in_birth_history==1
replace check=1 if FIRST_BIRTH_YR == cah_child_birth_yr1_ref & in_birth_history==1
tab FIRST_BIRTH_YR if check==0 // all 9999s - aka no kids for that person specifically
tab cah_child_birth_yr1_ref if check==0, m // but then there are kids? could they be adoptive? I guess I primarily use this variable anyway, not the main PSID one?
tab cah_num_bio_kids_ref if check==0, m // okay so not just adoptive...
tab cah_num_adoptive_kids_ref if check==0, m

********************************************************************************
* Create actual birth measures
********************************************************************************
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
tab cah_num_bio_kids_ref cah_num_bio_kids_sp, m // also quite diff numbers of kids between partners

gen all_births_shared=0
replace all_births_shared = 1 if cah_num_bio_kids_ref==cah_num_bio_kids_sp & cah_num_bio_kids_ref==num_shared_births_ref & num_shared_births_ref==num_shared_births_sp & cah_num_bio_kids_ref!=0 & cah_num_bio_kids_ref!=. & cah_num_bio_kids_sp!=0 & cah_num_bio_kids_sp!=.
replace all_births_shared=. if cah_num_bio_kids_ref==0 & cah_num_bio_kids_sp==0 // no births

browse unique_id partner_id survey_yr all_births_shared num_shared_births_ref num_shared_births_sp cah_num_bio_kids_ref cah_num_bio_kids_sp
//  browse unique_id partner_id SEX survey_yr all_births_shared num_shared_births_ref num_shared_births_sp cah_num_bio_kids_ref cah_num_bio_kids_sp cah_unique_id_child1_ref cah_sharedchild1_ref cah_unique_id_mom1_ref cah_unique_id_dad1_ref cah_child_birth_yr1_ref cah_unique_id_child2_ref cah_sharedchild2_ref cah_unique_id_mom2_ref cah_unique_id_dad2_ref cah_child_birth_yr2_ref cah_unique_id_child1_sp cah_sharedchild1_sp cah_unique_id_mom1_sp cah_unique_id_dad1_sp cah_child_birth_yr1_sp cah_unique_id_child2_sp cah_sharedchild2_sp cah_unique_id_mom2_sp cah_unique_id_dad2_sp cah_child_birth_yr2_sp

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

browse unique_id partner_id survey_yr marital_status_updated rel_start_yr joint_first_birth_yr joint_first_birth_rel mh_yr_married1 mh_yr_married2 mh_yr_married3 rel1_start rel2_start rel3_start

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
* Add this info back to original file and get some descriptives / make some more new variables
********************************************************************************
use "$created_data/PSID_couple_births.dta", clear

merge m:1 unique_id partner_id using "$temp/shared_birth_lookup.dta"
drop _merge

browse unique_id partner_id num_shared_births_ref num_shared_births_sp shared_birth1_refid shared_birth2_refid shared_birth1_spid shared_birth2_spid shared_birth1_refyr shared_birth2_refyr shared_birth1_spyr shared_birth2_spyr 

// compile some descriptive info to help me wrap my head around the info
* Had pre-marital birth: wife
gen pre_rel_birth_wife = .
replace pre_rel_birth_wife = 0 if num_births_pre_indv_ref==0 & SEX==2
replace pre_rel_birth_wife = 0 if num_births_pre_indv_sp==0 & SEX==1
replace pre_rel_birth_wife = 1 if num_births_pre_indv_ref>0 & SEX==2
replace pre_rel_birth_wife = 1 if num_births_pre_indv_sp>0 & SEX==1

tab pre_rel_birth_wife, m
unique unique_id partner_id, by(pre_rel_birth_wife)

* Had pre-marital birth: husband
gen pre_rel_birth_husb = .
replace pre_rel_birth_husb = 0 if num_births_pre_indv_ref==0 & SEX==1
replace pre_rel_birth_husb = 0 if num_births_pre_indv_sp==0 & SEX==2
replace pre_rel_birth_husb = 1 if num_births_pre_indv_ref>0 & SEX==1
replace pre_rel_birth_husb = 1 if num_births_pre_indv_sp>0 & SEX==2

tab pre_rel_birth_husb, m
unique unique_id partner_id, by(pre_rel_birth_husb)

* Had pre-marital birth: either
tab num_births_pre_indv_ref num_births_pre_indv_sp, m
tab any_births_pre_rel
unique unique_id partner_id, by(any_births_pre_rel)

* Had all births together
tab all_births_shared, m
tab all_births_shared
unique unique_id partner_id, by(all_births_shared)
tab joint_first_birth all_births_shared, row // % of people with joint first birth who had all births together

* Had joint first birth - observed in data
sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr rel_start_yr joint_first_birth joint_first_birth_yr joint_first_birth_rel joint_first_birth_timing
tab joint_first_birth_yr joint_first_birth, m
tab joint_first_birth if joint_first_birth_yr >=1990, m
unique unique_id partner_id if joint_first_birth_yr >=1990, by(joint_first_birth)

* Average time between relationship start and first birth
tab joint_first_birth_timing joint_first_birth, m 
sum joint_first_birth_timing if joint_first_birth==1, detail
sum joint_first_birth_timing if joint_first_birth_rel==1, detail

* Percent with joint first birth PRE relationship start
tab joint_first_birth joint_first_birth_rel, m row // just of those with joint first birth
tab joint_first_birth_rel, m // total sample
unique unique_id partner_id, by(joint_first_birth_rel)

* Joint first and second birth - both observed in data. Variables need to be created
tab cah_sharedchild2_ref cah_sharedchild2_sp, m

browse unique_id partner_id survey_yr joint_first_birth joint_first_birth_yr shared_birth1_refid shared_birth2_refid shared_birth3_refid shared_birth1_spid shared_birth2_spid shared_birth3_spid shared_birth1_refyr shared_birth2_refyr shared_birth3_refyr shared_birth1_spyr shared_birth2_spyr shared_birth3_spyr cah_sharedchild1_ref cah_sharedchild2_ref cah_sharedchild3_ref cah_sharedchild1_sp cah_sharedchild2_sp cah_sharedchild3_sp cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr3_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp cah_child_birth_yr3_sp

	/// either both of these shared birth indicators (1 v. 0) needs to be 1 for both first and second birth for ref and spouse
	browse unique_id partner_id survey_yr joint_first_birth joint_first_birth_yr cah_sharedchild1_ref cah_sharedchild2_ref cah_sharedchild3_ref cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr3_ref cah_sharedchild1_sp cah_sharedchild2_sp cah_sharedchild3_sp cah_child_birth_yr1_sp cah_child_birth_yr2_sp cah_child_birth_yr3_sp
	
	gen joint_second_birth_opt1 = .
	// replace joint_second_birth_opt1 = 0 if cah_sharedchild2_ref==0 | cah_sharedchild2_sp==0 // so this means 0 becomes just those with at least a second birth? So missing captures those without a second birth, so could have had first birth?
	replace joint_second_birth_opt1 = 1 if cah_sharedchild1_ref==1 & cah_sharedchild1_sp==1 & cah_sharedchild2_ref==1 & cah_sharedchild2_sp==1
	
	tab joint_second_birth_opt1, m
	tab joint_first_birth joint_second_birth_opt1, m
	
	tab cah_child_birth_yr2_ref cah_child_birth_yr2_sp if joint_second_birth_opt1==1 // not 100% perfect

	// following the first birth coding - the joint first birth captures making sure all of the ids for birth 1 match (because that's how that variable was created)
	gen joint_second_birth_opt2 = .
	replace joint_second_birth_opt2 = 1 if joint_first_birth==1 & cah_unique_id_child2_ref == cah_unique_id_child2_sp & cah_unique_id_mom2_ref == cah_unique_id_mom2_sp & cah_unique_id_dad2_ref == cah_unique_id_dad2_sp & cah_child_birth_yr2_ref == cah_child_birth_yr2_sp & cah_unique_id_child2_ref!=0 & cah_unique_id_child2_ref!=9999999
	
	tab joint_second_birth_opt2, m
	tab joint_first_birth joint_second_birth_opt2, m
	
	tab joint_second_birth_opt1 joint_second_birth_opt2, m // see how well aligned. okay like 300 records are off between the two
	
	tab cah_child_birth_yr2_ref cah_child_birth_yr2_sp if joint_second_birth_opt2==1 // right so these definitely match because I coded it that way
		
	/// or the shared birth history (created in intermission) needs to indicate that shared births 1 and 2 are also birth ids 1 and 2 for ref and partner??
	browse unique_id partner_id survey_yr joint_first_birth joint_first_birth_yr shared_birth1_refid shared_birth2_refid shared_birth3_refid shared_birth1_spid shared_birth2_spid shared_birth3_spid shared_birth1_refyr shared_birth2_refyr shared_birth3_refyr shared_birth1_spyr shared_birth2_spyr shared_birth3_spyr

	gen joint_second_birth_opt3 = .
	replace joint_second_birth_opt3 = 1 if shared_birth1_refid==1 & shared_birth2_refid==2 & shared_birth1_spid==1 & shared_birth2_spid==2
	
	tab joint_second_birth_opt3, m
	tab joint_first_birth joint_second_birth_opt3, m

	tab joint_second_birth_opt1 joint_second_birth_opt3, m cell // see how well aligned - so option 1 and 3 are exactly aligned. which I think makes sense based on how coded
	tab joint_second_birth_opt2 joint_second_birth_opt3, m cell // see how well aligned - so option 2 also makes sure all of the details from birth 2 match. is that realistic? like if one partner has a missing birth year, but otherwise they seem to match, do we want that?
	
	// these are those not captured with id match
	browse unique_id partner_id survey_yr joint_first_birth joint_first_birth_yr shared_birth1_refid shared_birth2_refid shared_birth3_refid shared_birth1_spid shared_birth2_spid shared_birth3_spid shared_birth1_refyr shared_birth2_refyr shared_birth3_refyr shared_birth4_refyr shared_birth1_spyr shared_birth2_spyr shared_birth3_spyr shared_birth4_spyr cah_sharedchild1_ref cah_sharedchild2_ref cah_sharedchild3_ref cah_sharedchild1_sp cah_sharedchild2_sp cah_sharedchild3_sp cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr3_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp cah_child_birth_yr3_sp if joint_second_birth_opt1==1 & joint_second_birth_opt2==.
	// two things: some have the dates flipped for some reason (so like 2002 then 2000), but others have like one partner with more births than the other, so one has 1990, 1992, 1995. the other just has 1992, 1995.
	// so really would want the former but not the latter.
		
	// captured with id match but not otherwise - most of these are because the id is missing woops.
	browse unique_id partner_id survey_yr joint_second_birth_opt2 joint_first_birth joint_first_birth_yr shared_birth1_refid shared_birth2_refid shared_birth3_refid shared_birth1_spid shared_birth2_spid shared_birth3_spid shared_birth1_refyr shared_birth2_refyr shared_birth3_refyr shared_birth1_spyr shared_birth2_spyr shared_birth3_spyr cah_sharedchild1_ref cah_sharedchild2_ref cah_sharedchild3_ref cah_sharedchild1_sp cah_sharedchild2_sp cah_sharedchild3_sp cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr3_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp cah_child_birth_yr3_sp if joint_second_birth_opt1==. & joint_second_birth_opt2==1
	
// get actual descriptives: joint second birth, total - decided to go with id match to be conservative, the differences are negligible
tab joint_second_birth_opt2, m
unique unique_id partner_id, by(joint_second_birth_opt2)

// joint second birth, just had first birth together
tab joint_first_birth joint_second_birth_opt2, m row
unique unique_id partner_id if joint_first_birth==1 & joint_second_birth_opt2==1 // validate same as above

* Average time between first birth and second birth
gen joint_second_birth_yr =.
replace joint_second_birth_yr = cah_child_birth_yr2_ref if joint_second_birth_opt2==1

tab joint_second_birth_yr joint_second_birth_opt2, m

gen joint_second_birth_timing = .
replace joint_second_birth_timing = joint_second_birth_yr - joint_first_birth_yr if joint_second_birth_opt2==1 & joint_second_birth_yr!=9998

tab joint_second_birth_timing joint_second_birth_opt2, m
replace joint_second_birth_timing=. if joint_second_birth_timing<-100 // rogue large value.
sum joint_second_birth_timing if joint_second_birth_opt2==1, detail
sum joint_second_birth_timing if joint_second_birth_opt2==1 & joint_second_birth_timing>=0 & joint_second_birth_timing!=., detail // essentially matches above bc the negatives are so small. but let's use this bc will probably need to delete if first birth seems to be after second? or at least, reorder?

* Second birth together, but not first (or first not observed). is this both partners first not together, or what if it's one partner's first birth and other's second? so let's make this "later first birth" THEN...
* Do I mean (a) this is both of their second births and it's together, but first wasn't together for either.
* OR (b) they had a second birth together following a first birth together BUT that first birth didn't need to be their individual first births. I think this??
* So this would be a combo of first need to have either joint first birth OR later first birth.. THEN second birth. BUT problem is that second birth won't nec be number two. so like below, just both first and second shared birth can't be missing? is that actually sufficient?

	// want to see something real quick
	gen joint_first_birth_alt=.
	replace joint_first_birth_alt = 0 if shared_birth1_refid!=1 | shared_birth1_spid!=1
	replace joint_first_birth_alt = 1 if shared_birth1_refid==1 & shared_birth1_spid==1
	tab joint_first_birth joint_first_birth_alt, m // essentially the same. so my joint first birth is ALSO that this is first birth EVER not like, they had a birth together, but could have also had births with others prior
	
	// so this should actually first be how many couples have a birth together, but also had a birth NOT together before (at least one of them) - this is where I get confused, is this that the shared first birth id is not 1 for either of them?
	gen later_first_birth=.
	replace later_first_birth=1 if shared_birth1_refid!=. & shared_birth1_spid!=. & (shared_birth1_refid>1 | shared_birth1_spid>1) // so they had to have a first birth together - aka neither is missing BUT for at least one of them, it's not their total first birth
	
	tab joint_first_birth later_first_birth, m // there should be no overlap
	tab later_first_birth, m
	unique unique_id partner_id, by(later_first_birth)
	
	tab shared_birth1_refyr shared_birth1_spyr if later_first_birth==1
	// browse shared_birth1_refyr shared_birth1_spyr if later_first_birth==1
	
	egen later_first_birth_yr = rowmin(shared_birth1_refyr shared_birth1_spyr) if later_first_birth==1
	// tab later_first_birth_yr later_first_birth, m
	// browse unique_id partner_id later_first_birth later_first_birth_yr shared_birth1_refyr shared_birth1_spyr
	gen later_first_birth_timing = .
	replace later_first_birth_timing = later_first_birth_yr - rel_start_yr if later_first_birth==1 & later_first_birth_yr!=9998
	// tab later_first_birth_timing later_first_birth, m
	sum later_first_birth_timing if later_first_birth==1, detail
	sum later_first_birth_timing if later_first_birth==1 & later_first_birth_timing>=0 & later_first_birth_timing!=., detail // just if AFTER rel start
	
	// at least one shared birth - should be the sum of joint_first_birth + later first birth?
	gen shared_first_birth = .
	replace shared_first_birth = 1 if shared_birth1_refid!=. & shared_birth1_spid!=.
	tab shared_first_birth, m
	unique unique_id partner_id, by(shared_first_birth)
	tab shared_first_birth joint_first_birth, m
	tab shared_first_birth later_first_birth, m
	// tab shared_birth1_refyr shared_birth1_spyr if shared_first_birth==1
	// browse shared_birth1_refyr shared_birth1_spyr if shared_first_birth==1
	
	egen shared_first_birth_yr = rowmin(shared_birth1_refyr shared_birth1_spyr) if shared_first_birth==1
	// tab shared_first_birth_yr shared_first_birth, m
	// browse unique_id partner_id shared_first_birth shared_first_birth_yr shared_birth1_refyr shared_birth1_spyr
	gen shared_first_birth_timing = .
	replace shared_first_birth_timing = shared_first_birth_yr - rel_start_yr if shared_first_birth==1 & shared_first_birth_yr!=9998
	// tab shared_first_birth_timing shared_first_birth, m
	sum shared_first_birth_timing if shared_first_birth==1, detail
	sum shared_first_birth_timing if shared_first_birth==1 & shared_first_birth_timing>=0 & shared_first_birth_timing!=., detail // just if AFTER rel start

	browse unique_id partner_id survey_yr joint_first_birth joint_first_birth_yr later_first_birth shared_birth1_refid shared_birth2_refid shared_birth3_refid shared_birth1_spid shared_birth2_spid shared_birth3_spid shared_birth1_refyr shared_birth2_refyr shared_birth3_refyr shared_birth1_spyr shared_birth2_spyr shared_birth3_spyr
	
* Now, couples that had a first birth together AND a second birth together, but this doesn't need to be their first and second births total (option b above)
gen shared_second_birth = .
replace shared_second_birth = 1 if shared_birth1_refid!=. & shared_birth1_spid!=. & shared_birth2_refid!=. & shared_birth2_spid!=. // like, is it this easy?
tab shared_second_birth, m
tab shared_first_birth shared_second_birth, m row

unique unique_id partner_id, by(shared_second_birth)

egen shared_second_birth_yr = rowmax(shared_birth2_refyr shared_birth2_spyr) if shared_second_birth==1 & shared_birth2_refyr!=9998 & shared_birth2_spyr!=9998
// tab shared_second_birth_yr shared_second_birth, m
// browse unique_id partner_id shared_second_birth shared_second_birth_yr shared_birth2_refyr shared_birth2_spyr 
gen shared_second_birth_timing = .
replace shared_second_birth_timing = shared_second_birth_yr - shared_first_birth_yr if shared_second_birth==1 & shared_second_birth_yr!=9998 & shared_first_birth_yr!=9998
// tab shared_second_birth_timing shared_second_birth, m

sum shared_second_birth_timing if shared_second_birth==1, detail

// 	browse unique_id partner_id survey_yr shared_first_birth shared_first_birth_yr shared_second_birth shared_second_birth_yr shared_second_birth_timing shared_birth1_refid shared_birth2_refid shared_birth3_refid shared_birth1_spid shared_birth2_spid shared_birth3_spid shared_birth1_refyr shared_birth2_refyr shared_birth3_refyr shared_birth1_spyr shared_birth2_spyr shared_birth3_spyr

* Average time elapsed since relationship start without a birth - this might be easier to do later once I figure out samples and such
// would this be last year observed minus relationship start if shared_first_birth==.?
browse unique_id partner_id survey_yr last_survey_yr rel_start_yr shared_first_birth shared_first_birth_yr shared_second_birth shared_second_birth_yr

* Average time elapsed since first birth without a second birth
// would this be last year observed minus first birth year if shared_first_birth==1 & shared_second_birth==.?

* Ever parents: shared birth
tab num_shared_births_ref num_shared_births_sp , m row
gen any_shared_births=.
replace any_shared_births=0 if num_shared_births_ref==0 & num_shared_births_sp==0
replace any_shared_births=1 if (num_shared_births_ref> 0 & num_shared_births_ref!=.) | (num_shared_births_sp> 0 & num_shared_births_sp!=.)
tab any_shared_births, m
unique unique_id partner_id, by(any_shared_births)

tab any_shared_births shared_first_birth, m // validate against shared first birth measure created above

* Num of births: any births shared
tab num_shared_births_ref any_shared_births, m cell // this is right then

unique unique_id partner_id if any_shared_births==1, by(num_shared_births_ref)
unique unique_id partner_id if any_shared_births==1, by(num_shared_births_sp)

* Ever parents: all births shared
tab num_shared_births_ref num_shared_births_sp if all_births_shared==1, m // okay, so perfect congruence here

* Num of births: all births shared
tab num_shared_births_ref if all_births_shared==1, m 
tab num_shared_births_ref all_births_shared, m cell // this is right then

unique unique_id partner_id if all_births_shared==1, by(num_shared_births_ref)
unique unique_id partner_id if all_births_shared==1, by(num_shared_births_sp)

tab cah_num_bio_kids_ref  cah_num_bio_kids_sp, row

* Pre-marital births ONLY - no shared births
tab any_births_pre_rel, m
tab any_births_pre_rel any_shared_births, m cell // basically the 1 for pre but 0 for shared?
tab any_births_pre_rel later_first_birth, m cell

unique unique_id partner_id if any_births_pre_rel==1 & any_shared_births==0

* Ever parents: women
gen num_bio_kids_wife = .
replace num_bio_kids_wife = cah_num_bio_kids_ref if SEX==2
replace num_bio_kids_wife = cah_num_bio_kids_sp if SEX==1
replace num_bio_kids_wife = 4 if num_bio_kids_wife>=4 & num_bio_kids_wife < 90
replace num_bio_kids_wife = . if num_bio_kids_wife==98

gen ever_birth_wife = .
replace ever_birth_wife=0 if num_bio_kids_wife==0
replace ever_birth_wife=1 if num_bio_kids_wife > 0 & num_bio_kids_wife < 90
tab num_bio_kids_wife ever_birth_wife, m

tab ever_birth_wife, m
unique unique_id partner_id, by(ever_birth_wife)

* Num of births: women
tab num_bio_kids_wife, m
unique unique_id partner_id, by(num_bio_kids_wife)

* Ever parents: men
gen num_bio_kids_husb = .
replace num_bio_kids_husb = cah_num_bio_kids_ref if SEX==1
replace num_bio_kids_husb = cah_num_bio_kids_sp if SEX==2
replace num_bio_kids_husb = 4 if num_bio_kids_husb>=4 & num_bio_kids_husb < 90
replace num_bio_kids_husb = . if num_bio_kids_husb==98

gen ever_birth_husb = .
replace ever_birth_husb=0 if num_bio_kids_husb==0
replace ever_birth_husb=1 if num_bio_kids_husb > 0 & num_bio_kids_husb < 90
tab num_bio_kids_husb ever_birth_husb, m

tab ever_birth_husb, m
unique unique_id partner_id, by(ever_birth_husb)

* Num of births: men
tab num_bio_kids_husb, m
unique unique_id partner_id, by(num_bio_kids_husb)

********************************************************************************
**# Now, figure out first birth and second birth samples with a flag first
* need to eventually add a. matched partner info, b. a flag for birth in year
* c. remove observations after relevant birth (e.g. after first birth for that sample)
* d. eventually deduplicate (so just one observation per year)
* e. eventually do the age restrictions (once partner data matched)
********************************************************************************
// first birth sample
tab any_births_pre_rel joint_first_birth, m // think some of this overlap if first birth pre rel start? but mostly, impossible to have pre-rel births AND have a joint first birth - which is the point
tab any_births_pre_rel joint_first_birth_rel, m
browse unique_id partner_id survey_yr rel_start_yr any_births_pre_rel joint_first_birth joint_first_birth_yr shared_birth1_refyr shared_birth1_spyr cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp
tab joint_first_birth_yr joint_first_birth if any_births_pre_rel==0, m // so all of the missing are those without a first birth

gen first_birth_sample_flag=0
replace first_birth_sample_flag = 1 if any_births_pre_rel==0 // remove if either partner had birth pre-maritally. is this the primary restriction? basically, had to enter relationship without kids?
replace first_birth_sample_flag = 0 if joint_first_birth_yr==9998 // no first birth year but HAD a joint first birth?
replace first_birth_sample_flag = 0 if joint_first_birth_yr< 1990 // remove if before 1990 (bc I don't have data) - prob will need to remove even more if I want to lag, but let's start here
replace first_birth_sample_flag = 0 if survey_yr > joint_first_birth_yr // censored observations - years AFTER first birth (if had one)
tab first_birth_sample_flag, m

tab any_births_pre_rel first_birth_sample_flag, m
tab first_birth_sample_flag joint_first_birth, m // those with no flag but first birth are years after the birth?
tab joint_first_birth_yr first_birth_sample_flag, m
tab joint_first_birth_timing first_birth_sample_flag, m // I think the 1990 restriction also essentially removed everyone with births after their rel start
unique unique_id partner_id, by(first_birth_sample_flag)
unique unique_id partner_id if first_birth_sample_flag==1 & joint_first_birth==1
unique unique_id partner_id if first_birth_sample_flag==1 & shared_first_birth==1

browse unique_id partner_id survey_yr first_birth_sample_flag rel_start_yr any_births_pre_rel joint_first_birth joint_first_birth_yr

// second birth sample - basically need to decide - does it have to be a joint first birth (e.g. neither partner has any premarital births) OR any shared first birth?
browse unique_id partner_id survey_yr rel_start_yr any_births_pre_rel joint_first_birth joint_first_birth_yr shared_first_birth shared_first_birth_yr shared_second_birth shared_second_birth_yr joint_second_birth_opt2 joint_second_birth_yr

gen second_birth_sample_flag_cons=. // make this conservative - no premarital births
replace second_birth_sample_flag_cons=0 if cah_num_bio_kids_ref== 0 | cah_num_bio_kids_sp == 0 // can't have second birth if either partner has no births
replace second_birth_sample_flag_cons=0 if any_births_pre_rel== 1  // for posterity, explicitly flag as 0 if had premarital birth
replace second_birth_sample_flag_cons=0 if joint_first_birth==0 // also can't have second birth if no first births together
replace second_birth_sample_flag_cons=1 if joint_first_birth==1
replace second_birth_sample_flag_cons = 0 if survey_yr < joint_first_birth_yr // censored observations BEFORE the first birth. Want clock to start at first birth
replace second_birth_sample_flag_cons = 0 if survey_yr > joint_second_birth_yr // censored observations - years AFTER second birth (if had one)

tab second_birth_sample_flag_cons, m
tab second_birth_sample_flag_cons joint_second_birth_opt2, m
tab second_birth_sample_flag_cons shared_second_birth, m

unique unique_id partner_id, by(second_birth_sample_flag_cons)
unique unique_id partner_id if second_birth_sample_flag_cons==1 & joint_second_birth_opt2==1 // this should be the right one here
// unique unique_id partner_id if second_birth_sample_flag_cons==1 & shared_second_birth==1

gen second_birth_sample_flag=. // make this less conservative - just need a shared first birth
replace second_birth_sample_flag=0 if cah_num_bio_kids_ref== 0 | cah_num_bio_kids_sp == 0 // can't have second birth if either partner has no births
replace second_birth_sample_flag=0 if shared_first_birth==0 // also can't have second birth if no first births together
replace second_birth_sample_flag=1 if shared_first_birth==1
replace second_birth_sample_flag = 0 if survey_yr < shared_first_birth_yr // censored observations BEFORE the first birth. Want clock to start at first birth
replace second_birth_sample_flag = 0 if survey_yr > shared_second_birth_yr // censored observations - years AFTER second birth (if had one)

tab second_birth_sample_flag, m
tab second_birth_sample_flag second_birth_sample_flag_cons, m
tab second_birth_sample_flag joint_second_birth_opt2, m
tab second_birth_sample_flag shared_second_birth, m

unique unique_id partner_id, by(second_birth_sample_flag)
// unique unique_id partner_id if second_birth_sample_flag==1 & joint_second_birth_opt2==1
unique unique_id partner_id if second_birth_sample_flag==1 & shared_second_birth==1 // this should be the right one here

browse unique_id partner_id survey_yr rel_start_yr second_birth_sample_flag second_birth_sample_flag_cons any_births_pre_rel joint_first_birth joint_first_birth_yr shared_first_birth shared_first_birth_yr shared_second_birth shared_second_birth_yr joint_second_birth_opt2 joint_second_birth_yr

tab first_birth_sample_flag second_birth_sample_flag_cons, m // should be subset - oh well, at a unique level, but the flags actually won't overlap bc of the censoring after birth timing
tab first_birth_sample_flag second_birth_sample_flag, m // won't nec be

// Merge on structural family measures here first as well? ah, will state cause problems because of the off years? add that to previous file also?
label values STATE_ .
tab STATE_, m
browse unique_id partner_id survey_yr STATE_
sort unique_id partner_id survey_yr

replace STATE_ = STATE_[_n-1] if unique_id == unique_id[_n-1] & partner_id == partner_id[_n-1] & wave==wave[_n-1]+1 & STATE_==.
replace STATE_ = STATE_[_n+1] if unique_id == unique_id[_n+1] & partner_id == partner_id[_n+1] & wave==wave[_n+1]-1 & STATE_==.

replace STATE_=. if STATE_==0 | STATE_==99

rename STATE_ state_fips
gen year = survey_yr

merge m:1 state_fips year using "$states/structural_familism.dta", keepusing(structural_familism)
drop if _merge==2

tab year _merge, m // ugh, I didn't add any 2020 or 2021 data. so that is the bulk of what is missing. revisit this, but is there a world I don't want this data anyway? bc of covid?
drop _merge

save "$created_data/PSID_couple_births_shared.dta", replace

********************************************************************************
**# Now create the specific sub files for each sample
********************************************************************************
// save "$created_data/PSID_first_birth_sample.dta", replace
// save "$created_data/PSID_second_birth_sample.dta", replace


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

