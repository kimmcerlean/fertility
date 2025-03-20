********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: create_subsamples
********************************************************************************
********************************************************************************
ssc inst unique, replace // for HPC

********************************************************************************
* Description
********************************************************************************
* This files uses the matched imputed data, restricts to the four different
* subsamples based on parity / premarital birth status and creates four
* new sample files for analysis. It also deduplicates so only one row per couple

// flag variables to filter on:
* First birth conservative: first_birth_sample_flag_check
* First birth broad: first_birth_broad_sample
* Second birth conservative: second_birth_cons_sample
* Second birth broad: second_birth_broad_sample

********************************************************************************
**# First births: conservative
********************************************************************************
// use "created data/PSID_couples_matched_allbirths.dta", clear // this is for HPC
// use "$created_data/PSID_matched_mi3_allbirths.dta", clear // to test on computer
use "$created_data_large/PSID_couples_matched_allbirths.dta", clear // real data

// browse unique_id partner_id sort_id _mi_m FAMILY_INTERVIEW_NUM_ main_fam_id relationship_duration survey_yr rel_start_all min_dur max_dur if sort_id==.
// browse unique_id partner_id sort_id _mi_m FAMILY_INTERVIEW_NUM_ main_fam_id relationship_duration survey_yr rel_start_all min_dur max_dur if main_fam_id==5
// browse unique_id partner_id sort_id _mi_m FAMILY_INTERVIEW_NUM_ main_fam_id relationship_duration survey_yr rel_start_all min_dur max_dur if inlist(unique_id,5172,5176,23031,23177,5537215,5537037,6115005,6115214)

keep if first_birth_sample_flag_check==1

unique unique_id partner_id // 7703

tab SEX marital_status_updated, m
/*

    SEX OF |                      marital_status_updated
INDIVIDUAL | Married (  Partnered     Single   Divorced  Separated          . |     Total
-----------+------------------------------------------------------------------+----------
      Male |   109,747     23,639        176         22         22     51,909 |   185,515 
    Female |   109,439     23,232        176         11         33     50,281 |   183,172 
-----------+------------------------------------------------------------------+----------
     Total |   219,186     46,871        352         33         55    102,190 |   368,687 

*/

tab rel_start_all, m // okay none missing, so don't need to figure out who has more info on partnership

// now deduplicate
sort _mi_m sort_id relationship_duration unique_id partner_id
browse unique_id partner_id relationship_duration survey_yr main_fam_id sort_id _mi_m // wait, does it matter if one partner kept sometimes and the other other times? or should be fine because sort order?

*then rank the remaining members
bysort sort_id relationship_duration _mi_m  : egen per_id = rank(unique_id)
tab per_id, m // 1s / odd #s should approximately total above - there are only 1s and 2s okay

sort sort_id relationship_duration unique_id partner_id
browse unique_id partner_id per_id relationship_duration survey_yr main_fam_id sort_id 

sort _mi_m unique_id partner_id relationship_duration
browse unique_id partner_id per_id relationship_duration survey_yr main_fam_id sort_id _mi_m

keep if inlist(per_id,1,3,5,7)

tab SEX marital_status_updated, m // check - should be half of above. It's a little more bc I think sometimes partner info missing.

unique unique_id partner_id // now, 4186
unique unique_id partner_id, by(joint_first_birth)

save "$created_data/PSID_first_birth_sample_cons.dta", replace

********************************************************************************
**# Second births: conservative
********************************************************************************
// use "created data/PSID_couples_matched_allbirths.dta", clear // this is for HPC
// use "$created_data/PSID_matched_mi3_allbirths.dta", clear // to test on computer
use "$created_data_large/PSID_couples_matched_allbirths.dta", clear // real data

keep if second_birth_cons_sample==1 // starting with CONSERVATIVE sample
unique unique_id partner_id // 5635

tab SEX marital_status_updated, m
/* essentially want half of this at the end

    SEX OF |                      marital_status_updated
INDIVIDUAL | Married (  Partnered     Single   Divorced  Separated          . |     Total
-----------+------------------------------------------------------------------+----------
      Male |    94,611     12,331        132         11         11     20,900 |   127,996 
    Female |    94,875     12,584         99         11         11     20,966 |   128,546 
-----------+------------------------------------------------------------------+----------
     Total |   189,486     24,915        231         22         22     41,866 |   256,542 


*/

tab rel_start_all, m // okay none missing, so don't need to figure out who has more info on partnership

// now deduplicate
sort _mi_m sort_id relationship_duration unique_id partner_id
browse unique_id partner_id relationship_duration survey_yr main_fam_id sort_id _mi_m // wait, does it matter if one partner kept sometimes and the other other times? or should be fine because sort order?

*then rank the remaining members
bysort sort_id relationship_duration _mi_m  : egen per_id = rank(unique_id)
tab per_id, m

sort _mi_m sort_id relationship_duration unique_id partner_id
browse unique_id partner_id per_id relationship_duration survey_yr main_fam_id sort_id 

sort _mi_m unique_id partner_id relationship_duration
browse unique_id partner_id per_id relationship_duration survey_yr main_fam_id sort_id _mi_m

keep if inlist(per_id,1,3,5,7)

tab SEX marital_status_updated, m // check - should be half of above. It's a little more bc I think sometimes partner info missing.
/*

    SEX OF |                      marital_status_updated
INDIVIDUAL | Married (  Partnered     Single   Divorced  Separated          . |     Total
-----------+------------------------------------------------------------------+----------
      Male |    48,191      6,677         55         11         11     13,112 |    68,057 
    Female |    49,170      7,007         66          0          0      8,459 |    64,702 
-----------+------------------------------------------------------------------+----------
     Total |    97,361     13,684        121         11         11     21,571 |   132,759 
*/

unique unique_id partner_id // now 3034
unique unique_id partner_id, by(joint_second_birth_opt2)

save "$created_data/PSID_second_birth_sample_cons.dta", replace	

********************************************************************************
**# First births: broad
********************************************************************************
// use "created data/PSID_couples_matched_allbirths.dta", clear // this is for HPC
// use "$created_data/PSID_matched_mi3_allbirths.dta", clear // to test on computer
use "$created_data_large/PSID_couples_matched_allbirths.dta", clear // real data

keep if first_birth_broad_sample==1
unique unique_id partner_id // 15300

tab SEX marital_status_updated, m
/* essentially want half of this at the end

    SEX OF |                            marital_status_updated
INDIVIDUAL | Married (  Partnered     Single    Widowed   Divorced  Separated          . |     Total
-----------+-----------------------------------------------------------------------------+----------
      Male |   249,161     59,719        308         11        132         88    112,288 |   421,707 
    Female |   248,798     59,532        308         11         88         66    109,637 |   418,440 
-----------+-----------------------------------------------------------------------------+----------
     Total |   497,959    119,251        616         22        220        154    221,925 |   840,147 


*/

// now deduplicate
sort _mi_m sort_id relationship_duration unique_id partner_id
browse unique_id partner_id relationship_duration survey_yr main_fam_id sort_id _mi_m // wait, does it matter if one partner kept sometimes and the other other times? or should be fine because sort order?

*then rank the remaining members
bysort sort_id relationship_duration _mi_m  : egen per_id = rank(unique_id)
tab per_id, m

sort _mi_m sort_id relationship_duration unique_id partner_id
browse unique_id partner_id per_id relationship_duration survey_yr main_fam_id sort_id 

sort _mi_m unique_id partner_id relationship_duration
browse unique_id partner_id per_id relationship_duration survey_yr main_fam_id sort_id _mi_m

keep if inlist(per_id,1,3,5,7,9,11,13)

tab SEX marital_status_updated, m // check - should be half of above. It's a little more bc I think sometimes partner info missing.
/*

    SEX OF |                            marital_status_updated
INDIVIDUAL | Married (  Partnered     Single    Widowed   Divorced  Separated          . |     Total
-----------+-----------------------------------------------------------------------------+----------
      Male |   124,201     33,154        154          0         66         44     62,172 |   219,791 
    Female |   130,185     33,363        154         11         44         33     56,364 |   220,154 
-----------+-----------------------------------------------------------------------------+----------
     Total |   254,386     66,517        308         11        110         77    118,536 |   439,945 


*/

unique unique_id partner_id // now 8575
unique unique_id partner_id, by(shared_first_birth)

save "$created_data/PSID_first_birth_sample_broad.dta", replace

********************************************************************************
**# Second births: broad
********************************************************************************
// use "created data/PSID_couples_matched_allbirths.dta", clear // this is for HPC
// use "$created_data/PSID_matched_mi3_allbirths.dta", clear // to test on computer
use "$created_data_large/PSID_couples_matched_allbirths.dta", clear // real data

keep if second_birth_broad_sample==1
unique unique_id partner_id // 8908

tab SEX marital_status_updated, m
/* essentially want half of this at the end

    SEX OF |                      marital_status_updated
INDIVIDUAL | Married (  Partnered     Single   Divorced  Separated          . |     Total
-----------+------------------------------------------------------------------+----------
      Male |   155,474     27,973        187         11         44     38,896 |   222,585 
    Female |   156,035     28,314        154         11         55     38,621 |   223,190 
-----------+------------------------------------------------------------------+----------
     Total |   311,509     56,287        341         22         99     77,517 |   445,775 


*/

// now deduplicate
sort _mi_m sort_id relationship_duration unique_id partner_id
browse unique_id partner_id relationship_duration survey_yr main_fam_id sort_id _mi_m // wait, does it matter if one partner kept sometimes and the other other times? or should be fine because sort order?

*then rank the remaining members
bysort sort_id relationship_duration _mi_m  : egen per_id = rank(unique_id)
tab per_id, m

sort _mi_m sort_id relationship_duration unique_id partner_id
browse unique_id partner_id per_id relationship_duration survey_yr main_fam_id sort_id 

sort _mi_m unique_id partner_id relationship_duration
browse unique_id partner_id per_id relationship_duration survey_yr main_fam_id sort_id _mi_m

keep if inlist(per_id,1,3,5,7)

tab SEX marital_status_updated, m // check - should be half of above. It's a little more bc I think sometimes partner info missing.
/*

    SEX OF |                      marital_status_updated
INDIVIDUAL | Married (  Partnered     Single   Divorced  Separated          . |     Total
-----------+------------------------------------------------------------------+----------
      Male |    80,432     16,632         88         11         22     23,265 |   120,450 
    Female |    80,102     15,070         88          0         33     17,347 |   112,640 
-----------+------------------------------------------------------------------+----------
     Total |   160,534     31,702        176         11         55     40,612 |   233,090 

*/

unique unique_id partner_id // now 4932
unique unique_id partner_id, by(shared_second_birth)

save "$created_data/PSID_second_birth_sample_broad.dta", replace
