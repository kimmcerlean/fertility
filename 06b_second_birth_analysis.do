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
// logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t1 `controls' if time_since_first_birth!=0 // this actually made results stronger? oh duh I was thinking about this backwards in my head. just assuming more people in male BW in year after first birth but also unlikely to have second birth in that year
margins hh_hours_type_t1
margins, dydx(hh_hours_type_t1)

logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t1 `controls'
// logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t1 `controls' if time_since_first_birth!=0
margins hh_earn_type_t1
margins, dydx(hh_earn_type_t1)

logistic had_second_birth i.time_since_first_birth i.housework_bkt_t1_imp `controls'
margins housework_bkt_t1_imp
margins, dydx(housework_bkt_t1_imp)

logistic had_second_birth i.time_since_first_birth i.hours_housework_t1_imp `controls'
margins hours_housework_t1_imp
margins, dydx(hours_housework_t1_imp)

logistic had_second_birth i.time_since_first_birth structural_familism_t1 `controls' if state_fips!=11
margins, at(structural_familism_t1=(-5(1)10))
marginsplot
margins, dydx(structural_familism_t1)

logistic had_second_birth i.time_since_first_birth i.couple_work_t1 `controls'
margins couple_work_t1
margins, dydx(couple_work_t1)

logistic had_second_birth i.time_since_first_birth i.couple_work_ow_t1 `controls'
margins couple_work_ow_t1
margins, dydx(couple_work_ow_t1)

** t-2
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"
// should I also remove the first year post first-birth here? because can't have a birth?

logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t2 `controls'
// logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t2 `controls' if time_since_first_birth!=0 // this actually made results stronger? oh duh I was thinking about this backwards in my head. just assuming more people in male BW in year after first birth but also unlikely to have second birth in that year
margins hh_hours_type_t2
margins, dydx(hh_hours_type_t2)

logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t2 `controls'
// logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t2 `controls' if time_since_first_birth!=0
margins hh_earn_type_t2
margins, dydx(hh_earn_type_t2)

logistic had_second_birth i.time_since_first_birth i.housework_bkt_t2_imp `controls'
margins housework_bkt_t2_imp
margins, dydx(housework_bkt_t2_imp)

logistic had_second_birth i.time_since_first_birth i.hours_housework_t2_imp `controls'
margins hours_housework_t2_imp
margins, dydx(hours_housework_t2_imp)

logistic had_second_birth i.time_since_first_birth structural_familism_t2 `controls' if state_fips!=11
margins, at(structural_familism_t2=(-5(1)10))
marginsplot
margins, dydx(structural_familism_t2)

logistic had_second_birth i.time_since_first_birth i.couple_work_t2 `controls'
margins couple_work_t2
margins, dydx(couple_work_t2)

logistic had_second_birth i.time_since_first_birth i.couple_work_ow_t2 `controls'
margins couple_work_ow_t2
margins, dydx(couple_work_ow_t2)

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
outreg2 using "$results/second_birth_no_imp.xls", sideway stats(coef pval) label ctitle(Hours T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

sum structural_familism_t1, detail
margins, dydx(hh_hours_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hh_earn_type_t1 c.structural_familism_t1#i.hh_earn_type_t1 `controls' if hh_earn_type_t1 < 4 & state_fips!=11
outreg2 using "$results/second_birth_no_imp.xls", sideway stats(coef pval) label ctitle(Earnings T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

sum structural_familism_t1, detail
margins, dydx(hh_earn_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor
// logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 `controls' if housework_bkt_t1 < 4 & state_fips!=11
// sum structural_familism_t1, detail
// margins, dydx(housework_bkt_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
// marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12"))

// Unpaid labor - est
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.housework_bkt_t1_imp c.structural_familism_t1#i.housework_bkt_t1_imp `controls' if housework_bkt_t1_imp < 4 & state_fips!=11
outreg2 using "$results/second_birth_no_imp.xls", sideway stats(coef pval) label ctitle(HW T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

sum structural_familism_t1, detail
margins, dydx(housework_bkt_t1_imp) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12"))

// Both
// logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 `controls' if state_fips!=11
// sum structural_familism_t1, detail
// margins, dydx(hours_housework_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
// marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot3opts(lcolor("gs13") mcolor("gs13")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("gs8")) ci4opts(color("gs8"))

// Both - est
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1_imp c.structural_familism_t1#i.hours_housework_t1_imp `controls' if state_fips!=11
outreg2 using "$results/second_birth_no_imp.xls", sideway stats(coef pval) label ctitle(Combined T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

sum structural_familism_t1, detail
margins, dydx(hours_housework_t1_imp) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot3opts(lcolor("gs13") mcolor("gs13")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("gs8")) ci4opts(color("gs8"))

**T-2
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

// Paid labor
* interaction with hours
logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hh_hours_type_t2 c.structural_familism_t2#i.hh_hours_type_t2 `controls' if hh_hours_type_t2 < 4 & state_fips!=11
outreg2 using "$results/second_birth_no_imp.xls", sideway stats(coef pval) label ctitle(Hours T2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

sum structural_familism_t2, detail
margins, dydx(hh_hours_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hh_earn_type_t2 c.structural_familism_t2#i.hh_earn_type_t2 `controls' if hh_earn_type_t2 < 4 & state_fips!=11
outreg2 using "$results/second_birth_no_imp.xls", sideway stats(coef pval) label ctitle(Earnings T2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

sum structural_familism_t2, detail
margins, dydx(hh_earn_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor
// logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.housework_bkt_t2 c.structural_familism_t2#i.housework_bkt_t2 `controls' if housework_bkt_t2 < 4 & state_fips!=11
// sum structural_familism_t2, detail
// margins, dydx(housework_bkt_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
// marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor - est
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.housework_bkt_t2_imp c.structural_familism_t2#i.housework_bkt_t2_imp `controls' if housework_bkt_t2_imp < 4 & state_fips!=11
outreg2 using "$results/second_birth_no_imp.xls", sideway stats(coef pval) label ctitle(HW T2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

sum structural_familism_t2, detail
margins, dydx(housework_bkt_t2_imp) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Both
// logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hours_housework_t2 c.structural_familism_t2#i.hours_housework_t2 `controls' if state_fips!=11
// sum structural_familism_t2, detail
// margins, dydx(hours_housework_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
// marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot3opts(lcolor("gs13") mcolor("gs13")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("gs8")) ci4opts(color("gs8"))

// Both - est
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hours_housework_t2_imp c.structural_familism_t2#i.hours_housework_t2_imp `controls' if state_fips!=11
outreg2 using "$results/second_birth_no_imp.xls", sideway stats(coef pval) label ctitle(Combined T2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

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

********************************************************************************
**# Descriptive statistics
********************************************************************************
// main IVs t: hh_hours_type hh_earn_type housework_bkt hours_housework couple_work structural_familism_t
// t-1: hh_hours_type_t1 hh_earn_type_t1 housework_bkt_t1_imp hours_housework_t1_imp couple_work_t1 structural_familism_t1
// t-2: hh_hours_type_t2 hh_earn_type_t2 housework_bkt_t2_imp hours_housework_t2_imp couple_work_t2 structural_familism_t2
// for ref: local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag" 
// relationship_duration

foreach var in hh_hours_type hh_earn_type housework_bkt hours_housework couple_work hh_hours_type_t1 hh_earn_type_t1 housework_bkt_t1_imp hours_housework_t1_imp couple_work_t1 hh_hours_type_t2 hh_earn_type_t2 housework_bkt_t2_imp hours_housework_t2_imp couple_work_t2 educ_type educ_type_t1 educ_type_t2 couple_joint_religion couple_joint_religion_t1 couple_joint_religion_t2 raceth_fixed_woman couple_same_race marital_status_use moved_states_lag{
	tab `var', gen(`var')
}

putexcel set "$results/Second_birth-descriptives", replace
putexcel B1:C1 = "Time t", merge border(bottom)
putexcel D1:E1 = "Time t-1", merge border(bottom)
putexcel F1:G1 = "Time t-2", merge border(bottom)
putexcel B2 = ("All") C2 = ("Had Second Birth") D2 = ("All") E2 = ("Had Second Birth") F2 = ("All") G2 = ("Had Second Birth")
putexcel A3 = "Unique Couples"

putexcel A4 = "Dual Earning (Hours)"
putexcel A5 = "Male Breadwinner (Hours)"
putexcel A6 = "Female Breadwinner (Hours)"
putexcel A7 = "Dual Earning ($)"
putexcel A8 = "Male Breadwinner ($)"
putexcel A9 = "Female Breadwinner ($)"
putexcel A10 = "Dual Housework"
putexcel A11 = "Female Primary HW"
putexcel A12 = "Male Primary HW"
putexcel A13 = "Egalitarian"
putexcel A14 = "Second Shift"
putexcel A15 = "Traditional"
putexcel A16 = "Counter-Traditional"
putexcel A17 = "All Others"
putexcel A18 = "Male BW"
putexcel A19 = "Male 1.5 BW"
putexcel A20 = "Dual FT"
putexcel A21 = "Female BW"
putexcel A22 = "Under Work"
putexcel A23 = "Structural Support for Working Families"

putexcel A24 = "Woman's age"
putexcel A25 = "Man's age"
putexcel A26 = "Relationship duration"
putexcel A27 = "Time Since first birth"
putexcel A28 = "Married"
putexcel A29 = "Cohab"
putexcel A30 = "Total Couple Earnings"
putexcel A31 = "Neither College Degree"
putexcel A32 = "His College Degree"
putexcel A33 = "Her College Degree"
putexcel A34 = "Both College Degree"
putexcel A35 = "Both No Religion"
putexcel A36 = "Both Catholic"
putexcel A37 = "Both Protestant"
putexcel A38 = "One Catholic"
putexcel A39 = "One No Religion"
putexcel A40 = "Other Religion"
putexcel A41 = "Woman's Race: NH White"
putexcel A42 = "Woman's Race: Black"
putexcel A43 = "Woman's Race: Hispanic"
putexcel A44 = "Woman's Race: NH Asian"
putexcel A45 = "Woman's Race: NH Other"
putexcel A46 = "Husband and wife same race"
putexcel A47 = "Moved States"

local tvars "hh_hours_type1 hh_hours_type2 hh_hours_type3 hh_earn_type1 hh_earn_type2 hh_earn_type3 housework_bkt1 housework_bkt2 housework_bkt3 hours_housework1 hours_housework2 hours_housework3 hours_housework4 hours_housework5 couple_work1 couple_work2 couple_work3 couple_work4 couple_work5 structural_familism_t age_woman age_man relationship_duration time_since_first_birth marital_status_use1 marital_status_use2 couple_earnings educ_type1 educ_type2 educ_type3 educ_type4 couple_joint_religion1 couple_joint_religion2 couple_joint_religion3 couple_joint_religion4 couple_joint_religion5 couple_joint_religion6 raceth_fixed_woman1 raceth_fixed_woman2 raceth_fixed_woman3 raceth_fixed_woman4 raceth_fixed_woman5 couple_same_race2 moved_states_lag2"
// 44

local t1vars "hh_hours_type_t11 hh_hours_type_t12 hh_hours_type_t13 hh_earn_type_t11 hh_earn_type_t12 hh_earn_type_t13 housework_bkt_t1_imp1 housework_bkt_t1_imp2 housework_bkt_t1_imp3 hours_housework_t1_imp1 hours_housework_t1_imp2 hours_housework_t1_imp3 hours_housework_t1_imp4 hours_housework_t1_imp5 couple_work_t11 couple_work_t12 couple_work_t13 couple_work_t14 couple_work_t15 structural_familism_t1 age_woman age_man relationship_duration time_since_first_birth marital_status_use1 marital_status_use2 couple_earnings_t1 educ_type_t11 educ_type_t12 educ_type_t13 educ_type_t14 couple_joint_religion_t11 couple_joint_religion_t12 couple_joint_religion_t13 couple_joint_religion_t14 couple_joint_religion_t15 couple_joint_religion_t16"
// 37

local t2vars "hh_hours_type_t21 hh_hours_type_t22 hh_hours_type_t23 hh_earn_type_t21 hh_earn_type_t22 hh_earn_type_t23 housework_bkt_t2_imp1 housework_bkt_t2_imp2 housework_bkt_t2_imp3 hours_housework_t2_imp1 hours_housework_t2_imp2 hours_housework_t2_imp3 hours_housework_t2_imp4 hours_housework_t2_imp5 couple_work_t21 couple_work_t22 couple_work_t23 couple_work_t24 couple_work_t25 structural_familism_t1 age_woman age_man relationship_duration time_since_first_birth marital_status_use1 marital_status_use2 couple_earnings_t2 educ_type_t21 educ_type_t22 educ_type_t23 educ_type_t24 couple_joint_religion_t21 couple_joint_religion_t22 couple_joint_religion_t23 couple_joint_religion_t24 couple_joint_religion_t25 couple_joint_religion_t26"
// 37

// Total Sample, time t
forvalues w=1/44{
	local row=`w'+3
	local var: word `w' of `tvars'
	mean `var'
	matrix t`var'= e(b)
	putexcel B`row' = matrix(t`var'), nformat(#.#%)
}

// those with second birth
forvalues w=1/44{
	local row=`w'+3
	local var: word `w' of `tvars' 
	mean `var' if had_second_birth==1
	matrix t`var'= e(b)
	putexcel C`row' = matrix(t`var'), nformat(#.#%)
}

// Total Sample, time t-1
forvalues w=1/37{
	local row=`w'+3
	local var: word `w' of `t1vars'
	mean `var'
	matrix t`var'= e(b)
	putexcel D`row' = matrix(t`var'), nformat(#.#%)
}

// those with second birth
forvalues w=1/37{
	local row=`w'+3
	local var: word `w' of `t1vars' 
	mean `var' if had_second_birth==1
	matrix t`var'= e(b)
	putexcel E`row' = matrix(t`var'), nformat(#.#%)
}

// Total Sample, time t-2
forvalues w=1/37{
	local row=`w'+3
	local var: word `w' of `t2vars'
	mean `var'
	matrix t`var'= e(b)
	putexcel F`row' = matrix(t`var'), nformat(#.#%)
}

// those with second birth
forvalues w=1/37{
	local row=`w'+3
	local var: word `w' of `t2vars' 
	mean `var' if had_second_birth==1
	matrix t`var'= e(b)
	putexcel G`row' = matrix(t`var'), nformat(#.#%)
}

unique unique_id partner_id
unique unique_id partner_id if had_second_birth==1