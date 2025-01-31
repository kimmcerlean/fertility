********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: second_birth_analysis
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the second birth sample and runs analysis

// created in step 6a
use "$created_data/PSID_second_birth_sample_rec.dta", clear

tab relationship_duration had_second_birth, row m 
tab time_since_first_birth had_second_birth, row m 

gen age_woman_sq = age_woman * age_woman

********************************************************************************
********************************************************************************
********************************************************************************
**# Imputed data
********************************************************************************
********************************************************************************
********************************************************************************
* Will revisit this post CLIC

********************************************************************************
********************************************************************************
********************************************************************************
**# Non-imputed data
********************************************************************************
********************************************************************************
********************************************************************************
mi extract 0, clear

// crude way of getting structural variable t2. when I revisit full code, I will integrate this (and t1) better
browse unique_id partner_id survey_yr state_fips structural_familism_t structural_familism_t1
gen structural_familism_t2 = structural_familism_t1[_n-1] if unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1

// temp try alt way of doing housework
egen housework_t1_man_imp = rowmean(housework_man housework_t2_man)
replace housework_t1_man_imp = housework_t1_man if housework_t1_man!=.

egen housework_t1_woman_imp = rowmean(housework_woman housework_t2_woman)
replace housework_t1_woman_imp = housework_t1_woman if housework_t1_woman!=.
browse unique_id partner_id survey_yr housework_man housework_t1_man housework_t2_man housework_t1_man_imp housework_woman housework_t1_woman housework_t2_woman housework_t1_woman_imp

inspect housework_t1_woman housework_t1_woman_imp housework_t1_man housework_t1_man_imp

// 
egen couple_housework_t1_imp = rowtotal (housework_t1_woman_imp housework_t1_man_imp)
gen wife_housework_pct_t1_imp = housework_t1_woman_imp / couple_housework_t1_imp

gen housework_bkt_t1_imp=.
replace housework_bkt_t1_imp=1 if wife_housework_pct_t1_imp >=.4000 & wife_housework_pct_t1_imp <=.6000
replace housework_bkt_t1_imp=2 if wife_housework_pct_t1_imp >.6000 & wife_housework_pct_t1_imp!=.
replace housework_bkt_t1_imp=3 if wife_housework_pct_t1_imp <.4000
replace housework_bkt_t1_imp=3 if housework_t1_woman_imp==0 & housework_t1_man_imp==0

label values housework_bkt_t1_imp housework_bkt
tab housework_bkt_t1, m
tab housework_bkt_t1_imp, m
tab housework_bkt_t1_imp housework_bkt_t1, m

gen housework_bkt_t2_imp = housework_bkt_t1_imp[_n-1] if unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1
replace housework_bkt_t2_imp = housework_bkt_t2 if housework_bkt_t2!=.
label values housework_bkt_t2_imp housework_bkt

browse unique_id partner_id survey_yr housework_bkt housework_bkt_t1_imp housework_bkt_t2 housework_bkt_t2_imp

// now create new hours_housework measure
gen hours_housework_t1_imp=.
replace hours_housework_t1_imp=1 if hh_hours_type_t1==1 & housework_bkt_t1_imp==1 // dual both (egal)
replace hours_housework_t1_imp=2 if hh_hours_type_t1==1 & housework_bkt_t1_imp==2 // dual earner, female HM (second shift)
replace hours_housework_t1_imp=3 if hh_hours_type_t1==2 & housework_bkt_t1_imp==2 // male BW, female HM (traditional)
replace hours_housework_t1_imp=4 if hh_hours_type_t1==3 & housework_bkt_t1_imp==3 // female BW, male HM (counter-traditional)
replace hours_housework_t1_imp=5 if hours_housework_t1_imp==. & hh_hours_type_t1!=. & housework_bkt_t1_imp!=. // all others

label values hours_housework_t1_imp hours_housework 
tab hours_housework_t1_imp
tab hours_housework_t1

gen hours_housework_t2_imp=.
replace hours_housework_t2_imp=1 if hh_hours_type_t2==1 & housework_bkt_t2_imp==1 // dual both (egal)
replace hours_housework_t2_imp=2 if hh_hours_type_t2==1 & housework_bkt_t2_imp==2 // dual earner, female HM (second shift)
replace hours_housework_t2_imp=3 if hh_hours_type_t2==2 & housework_bkt_t2_imp==2 // male BW, female HM (traditional)
replace hours_housework_t2_imp=4 if hh_hours_type_t2==3 & housework_bkt_t2_imp==3 // female BW, male HM (counter-traditional)
replace hours_housework_t2_imp=5 if hours_housework_t2_imp==. & hh_hours_type_t2!=. & housework_bkt_t2_imp!=. // all others

label values hours_housework_t2_imp hours_housework 
tab hours_housework_t2_imp
tab hours_housework_t2

********************************************************************************
* Playing around for now
********************************************************************************
logistic had_second_birth i.time_since_first_birth i.educ_woman // i.marital_status_updated
margins educ_woman

logistic had_second_birth i.age_woman i.educ_woman  // i.marital_status_updated
margins educ_woman

logistic had_second_birth i.educ_woman 
margins educ_woman

// which paid labor AND which measure of time?
tab hh_earn_type had_second_birth, row m
tab hh_earn_type_t1 had_second_birth, row m
tab hh_hours_type had_second_birth, row m
tab hh_hours_type_t1 had_second_birth, row m
tab housework_bkt had_second_birth, row m
tab housework_bkt_t1 had_second_birth, row m

logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t1
margins hh_earn_type_t1

logistic had_second_birth i.age_woman i.hh_earn_type_t1
margins hh_earn_type_t1

logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t1
margins hh_hours_type_t1

logistic had_second_birth i.age_woman i.hh_hours_type_t1
margins hh_hours_type_t1

logistic had_second_birth i.time_since_first_birth i.age_woman i.hh_hours_type_t1
margins hh_hours_type_t1

logistic had_second_birth i.time_since_first_birth i.age_woman  ib2.couple_work_t1
margins couple_work_t1

logistic had_second_birth i.time_since_first_birth i.age_woman  i.housework_bkt_t1
margins housework_bkt_t1

logistic had_second_birth i.time_since_first_birth i.age_woman  i.hours_housework_t1
margins hours_housework_t1

logistic had_second_birth i.time_since_first_birth i.age_woman structural_familism_t1 if state_fips!=11 // not sig
marginsplot


********************************************************************************
* Main effects
********************************************************************************
* t-1
// adding controls - per that Rindfuss article, do I need to interact age with these variables? bc some variables affect timing of births more than birth itself (and might have negative impact on timing but positive on completed fertility)
// local controls "i.age_woman i.age_man i.religion_woman i.religion_man i.educ_man i.educ_woman i.raceth_fixed_man i.raceth_fixed_woman"
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag"
// should I also remove the first year post first-birth here? because can't have a birth?

logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t1 `controls'
logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t1 `controls' if time_since_first_birth!=0 // this actually made results stronger? oh duh I was thinking about this backwards in my head. just assuming more people in male BW in year after first birth but also unlikely to have second birth in that year
margins hh_hours_type_t1
margins, dydx(hh_hours_type_t1)

logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t1 `controls'
logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t1 `controls' if time_since_first_birth!=0
margins hh_earn_type_t1
margins, dydx(hh_earn_type_t1)

logistic had_second_birth i.time_since_first_birth i.housework_bkt_t1 `controls'
margins housework_bkt_t1
margins, dydx(housework_bkt_t1)

logistic had_second_birth i.time_since_first_birth i.hours_housework_t1 `controls'
margins hours_housework_t1
margins, dydx(hours_housework_t1)

logistic had_second_birth i.time_since_first_birth structural_familism_t1 `controls' if state_fips!=11
margins, at(structural_familism_t1=(-5(1)10))
marginsplot
margins, dydx(structural_familism_t1)

/* alt time period
local controls "i.age_woman i.age_man i.religion_woman i.religion_man i.educ_man i.educ_woman i.raceth_fixed_man i.raceth_fixed_woman relationship_duration"

logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t1 `controls' if rel_start_yr>=2005
margins hh_hours_type_t1
margins, dydx(hh_hours_type_t1)

logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t1 `controls' if rel_start_yr>=2005
margins hh_earn_type_t1
margins, dydx(hh_earn_type_t1)

logistic had_second_birth i.time_since_first_birth i.housework_bkt_t1 `controls' if rel_start_yr>=2005 // controls not working here
margins housework_bkt_t1
margins, dydx(housework_bkt_t1)

logistic had_second_birth i.time_since_first_birth i.hours_housework_t1 `controls' if rel_start_yr>=2005 // controls not working here
margins hours_housework_t1
margins, dydx(hours_housework_t1)

logistic had_second_birth i.time_since_first_birth structural_familism_t1 `controls' if state_fips!=11 & rel_start_yr>=2005
margins, at(structural_familism_t1=(-5(1)10))
marginsplot
margins, dydx(structural_familism_t1)
*/

********************************************************************************
* Key interactions with structural support measure
********************************************************************************
**T-1
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag"

// Paid labor
* interaction with hours
logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 `controls' if hh_hours_type_t1 < 4 & state_fips!=11
sum structural_familism_t1, detail
margins, dydx(hh_hours_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hh_earn_type_t1 c.structural_familism_t1#i.hh_earn_type_t1 `controls' if hh_earn_type_t1 < 4 & state_fips!=11
sum structural_familism_t1, detail
margins, dydx(hh_earn_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 `controls' if housework_bkt_t1 < 4 & state_fips!=11
sum structural_familism_t1, detail
margins, dydx(housework_bkt_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12"))

// Unpaid labor - est
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.housework_bkt_t1_imp c.structural_familism_t1#i.housework_bkt_t1_imp `controls' if housework_bkt_t1_imp < 4 & state_fips!=11
sum structural_familism_t1, detail
margins, dydx(housework_bkt_t1_imp) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12"))

// Both
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 `controls' if state_fips!=11
sum structural_familism_t1, detail
margins, dydx(hours_housework_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot3opts(lcolor("gs13") mcolor("gs13")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("gs8")) ci4opts(color("gs8"))

// Both - est
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1_imp c.structural_familism_t1#i.hours_housework_t1_imp `controls' if state_fips!=11
sum structural_familism_t1, detail
margins, dydx(hours_housework_t1_imp) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot3opts(lcolor("gs13") mcolor("gs13")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("gs8")) ci4opts(color("gs8"))

**T-2
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

// Paid labor
* interaction with hours
logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hh_hours_type_t2 c.structural_familism_t2#i.hh_hours_type_t2 `controls' if hh_hours_type_t2 < 4 & state_fips!=11
sum structural_familism_t2, detail
margins, dydx(hh_hours_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hh_earn_type_t2 c.structural_familism_t2#i.hh_earn_type_t2 `controls' if hh_earn_type_t2 < 4 & state_fips!=11
sum structural_familism_t2, detail
margins, dydx(hh_earn_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.housework_bkt_t2 c.structural_familism_t2#i.housework_bkt_t2 `controls' if housework_bkt_t2 < 4 & state_fips!=11
sum structural_familism_t2, detail
margins, dydx(housework_bkt_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor - est
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.housework_bkt_t2_imp c.structural_familism_t2#i.housework_bkt_t2_imp `controls' if housework_bkt_t2_imp < 4 & state_fips!=11
sum structural_familism_t2, detail
margins, dydx(housework_bkt_t2_imp) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Both
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hours_housework_t2 c.structural_familism_t2#i.hours_housework_t2 `controls' if state_fips!=11
sum structural_familism_t2, detail
margins, dydx(hours_housework_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot3opts(lcolor("gs13") mcolor("gs13")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("gs8")) ci4opts(color("gs8"))

// Both - est
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hours_housework_t2_imp c.structural_familism_t2#i.hours_housework_t2_imp `controls' if state_fips!=11
sum structural_familism_t2, detail
margins, dydx(hours_housework_t2_imp) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot3opts(lcolor("gs13") mcolor("gs13")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("gs8")) ci4opts(color("gs8"))


/*
********************************************************************************
* Post-recession ish-period
********************************************************************************
local controls "i.age_woman i.age_man i.religion_woman i.religion_man i.educ_man i.educ_woman i.raceth_fixed_man i.raceth_fixed_woman relationship_duration"

// Paid labor
* interaction with hours
logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 `controls' if hh_hours_type_t1 < 4 & state_fips!=11 & rel_start_yr>=2005
sum structural_familism_t1, detail
margins, dydx(hh_hours_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings

logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hh_earn_type_t1 c.structural_familism_t1#i.hh_earn_type_t1 `controls' if hh_earn_type_t1 < 4 & state_fips!=11 & rel_start_yr>=2005
sum structural_familism_t1, detail
margins, dydx(hh_earn_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor
logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 `controls' if housework_bkt_t1 < 4 & state_fips!=11 & rel_start_yr>=2005
sum structural_familism_t1, detail
margins, dydx(housework_bkt_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Both
logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 `controls' if state_fips!=11 & rel_start_yr>=2005
sum structural_familism_t1, detail
margins, dydx(hours_housework_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot3opts(lcolor("gs6") mcolor("gs6")) ci3opts(color("gs6")) plot4opts(lcolor("gs12") mcolor("gs12")) ci4opts(color("gs12"))
*/