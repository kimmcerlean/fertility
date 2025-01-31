********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: first_birth_analysis
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the first birth sample and runs analysis

// created in file 5a
use "$created_data/PSID_first_birth_sample_rec.dta", clear

browse unique_id partner_id survey_yr rel_start_yr marital_status_updated relationship_duration had_first_birth joint_first_birth joint_first_birth_yr

tab relationship_duration had_first_birth, row m // should relationship duration be my discrete time indicator?
tab age_woman had_first_birth, row m  // or age?? I guess both should be in the models?

gen age_woman_sq = age_woman * age_woman

********************************************************************************
********************************************************************************
********************************************************************************
**# Imputed data
********************************************************************************
********************************************************************************
********************************************************************************
/* how to get AMEs and Predicted Probabilities:
https://www.statalist.org/forums/forum/general-stata-discussion/general/1354295-mimrgns-and-emargins-average-marginal-effects-the-same-as-coefficient-values
https://www.stata.com/meeting/germany16/slides/de16_klein.pdf
https://www.statalist.org/forums/forum/general-stata-discussion/general/316905-mimrgns-interaction-effects
https://www.statalist.org/forums/forum/general-stata-discussion/general/307763-mimrgns-updated-on-ssc
*/

********************************************************************************
* Main effects
********************************************************************************
**T-1
// with controls - per that Rindfuss article, do I need to interact age with these variables? bc some variables affect timing of births more than birth itself (and might have negative impact on timing but positive on completed fertility)
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag"

logistic had_first_birth i.relationship_duration i.hh_hours_type_t1 `controls'
mimrgns hh_hours_type_t1
mimrgns, dydx(hh_hours_type_t1)

logistic had_first_birth i.relationship_duration i.hh_earn_type_t1 `controls'
mimrgns hh_earn_type_t1
mimrgns, dydx(hh_earn_type_t1)

logistic had_first_birth i.relationship_duration i.housework_bkt_t1 `controls'
mimrgns housework_bkt_t1
mimrgns, dydx(housework_bkt_t1)

logistic had_first_birth i.relationship_duration i.hours_housework_t1 `controls'
mimrgns hours_housework_t1
mimrgns, dydx(hours_housework_t1)

logistic had_first_birth i.relationship_duration structural_familism_t1 `controls' if state_fips!=11
mimrgns, at(structural_familism_t1=(-5(1)10))
marginsplot
mimrgns, dydx(structural_familism_t1)

**T-2

********************************************************************************
* Key interactions with structural support measure
********************************************************************************
**T-1

// Paid labor

* interaction with hours
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag"

mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 `controls' if state_fips!=11 // hh_hours_type_t1 < 4
sum structural_familism_t1, detail
mimrgns, dydx(hh_hours_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))  predict(pr) cmdmargins dots
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag"

mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hh_earn_type_t1 c.structural_familism_t1#i.hh_earn_type_t1 `controls' if state_fips!=11 // hh_earn_type_t1 < 4
sum structural_familism_t1, detail
mimrgns, dydx(hh_earn_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))  predict(pr) cmdmargins dots
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag"

mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 `controls' if state_fips!=11 // housework_bkt_t1 < 4 
sum structural_familism_t1, detail
mimrgns, dydx(housework_bkt_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))  predict(pr) cmdmargins dots
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Both
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag"

mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 `controls' if state_fips!=11
sum structural_familism_t1, detail
margins, dydx(hours_housework_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot3opts(lcolor("gs6") mcolor("gs6")) ci3opts(color("gs6")) plot4opts(lcolor("gs12") mcolor("gs12")) ci4opts(color("gs12"))

**T-2

********************************************************************************
********************************************************************************
********************************************************************************
**# Non imputed data
********************************************************************************
********************************************************************************
********************************************************************************
mi extract 0, clear

browse unique_id partner_id survey_yr state_fips structural_familism_t structural_familism_t1
gen structural_familism_t2 = structural_familism_t1[_n-1] if unique_id==unique_id[_n-1] & partner_id==partner_id[_n-1] & wave==wave[_n-1]+1

logistic had_first_birth i.relationship_duration i.educ_woman // i.marital_status_updated
margins educ_woman

logistic had_first_birth i.age_woman i.educ_woman // i.marital_status_updated
margins educ_woman

logistic had_first_birth i.educ_woman
margins educ_woman

// which paid labor AND which measure of time?
tab hh_earn_type had_first_birth, row m
tab hh_earn_type_t1 had_first_birth, row m
tab hh_hours_type had_first_birth, row m
tab hh_hours_type_t1 had_first_birth, row m
tab housework_bkt had_first_birth, row m
tab housework_bkt_t1 had_first_birth, row m

logistic had_first_birth i.relationship_duration i.hh_earn_type_t1
margins hh_earn_type_t1

logistic had_first_birth i.age_woman i.hh_earn_type_t1
margins hh_earn_type_t1

logistic had_first_birth i.relationship_duration i.hh_hours_type_t1
margins hh_hours_type_t1

logistic had_first_birth i.age_woman i.hh_hours_type_t1
margins hh_hours_type_t1

logistic had_first_birth i.relationship_duration i.age_woman i.hh_hours_type_t1
margins hh_hours_type_t1

logistic had_first_birth i.relationship_duration i.age_woman  ib2.couple_work_t1
margins couple_work_t1

logistic had_first_birth i.relationship_duration i.age_woman  i.housework_bkt_t1
margins housework_bkt_t1

logistic had_first_birth i.relationship_duration i.age_woman  i.hours_housework_t1
margins hours_housework_t1

logistic had_first_birth i.relationship_duration i.age_woman structural_familism_t1 if state_fips!=11  // this is negative even when lagged
margins, at(structural_familism_t1=(-5(1)10))
marginsplot

********************************************************************************
* Main effects
********************************************************************************
* t-1
// adding controls - per that Rindfuss article, do I need to interact age with these variables? bc some variables affect timing of births more than birth itself (and might have negative impact on timing but positive on completed fertility)
// local controls "i.age_woman i.age_man i.religion_woman i.religion_man i.educ_man i.educ_woman i.raceth_fixed_man i.raceth_fixed_woman"
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag"

logistic had_first_birth i.relationship_duration i.hh_hours_type_t1 `controls'
margins hh_hours_type_t1
margins, dydx(hh_hours_type_t1)

logistic had_first_birth i.relationship_duration i.hh_earn_type_t1 `controls'
margins hh_earn_type_t1
margins, dydx(hh_earn_type_t1)

logistic had_first_birth i.relationship_duration i.housework_bkt_t1 `controls'
margins housework_bkt_t1
margins, dydx(housework_bkt_t1)

logistic had_first_birth i.relationship_duration i.hours_housework_t1 `controls'
margins hours_housework_t1
margins, dydx(hours_housework_t1)

logistic had_first_birth i.relationship_duration structural_familism_t1 `controls' if state_fips!=11 
margins, at(structural_familism_t1=(-5(1)10))
marginsplot
margins, dydx(structural_familism_t1)

* t-2
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

logistic had_first_birth i.relationship_duration i.hh_hours_type_t2 `controls'
margins hh_hours_type_t2
margins, dydx(hh_hours_type_t2)

logistic had_first_birth i.relationship_duration i.hh_earn_type_t2 `controls'
margins hh_earn_type_t2
margins, dydx(hh_earn_type_t2)

logistic had_first_birth i.relationship_duration i.housework_bkt_t2 `controls'
margins housework_bkt_t2
margins, dydx(housework_bkt_t2)

logistic had_first_birth i.relationship_duration i.hours_housework_t2 `controls'
margins hours_housework_t2
margins, dydx(hours_housework_t2)


/* alt time period
local controls "i.age_woman i.age_man i.religion_woman i.religion_man i.educ_man i.educ_woman i.raceth_fixed_man i.raceth_fixed_woman"

logistic had_first_birth i.relationship_duration i.hh_hours_type_t1 `controls' if rel_start_yr>=2005
margins hh_hours_type_t1
margins, dydx(hh_hours_type_t1)

logistic had_first_birth i.relationship_duration i.hh_earn_type_t1 `controls' if rel_start_yr>=2005
margins hh_earn_type_t1
margins, dydx(hh_earn_type_t1)

logistic had_first_birth i.relationship_duration i.housework_bkt_t1 `controls' if rel_start_yr>=2005 // causing problems when trying to estimate with controls. think there are prob too many
margins housework_bkt_t1
margins, dydx(housework_bkt_t1)

logistic had_first_birth i.relationship_duration i.hours_housework_t1 `controls' if rel_start_yr>=2005  // causing problems when trying to estimate with controls. think there are prob too many
margins hours_housework_t1
margins, dydx(hours_housework_t1)

logistic had_first_birth i.relationship_duration structural_familism_t1 `controls' if state_fips!=11 & rel_start_yr>=2005
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
logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 `controls' if hh_hours_type_t1 < 4 & state_fips!=11 
sum structural_familism_t1, detail
margins, dydx(hh_hours_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hh_earn_type_t1 c.structural_familism_t1#i.hh_earn_type_t1 `controls' if hh_earn_type_t1 < 4 & state_fips!=11 
sum structural_familism_t1, detail
margins, dydx(hh_earn_type_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor
logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 `controls' if housework_bkt_t1 < 4 & state_fips!=11 
sum structural_familism_t1, detail
margins, dydx(housework_bkt_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Both
logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 `controls' if state_fips!=11 
sum structural_familism_t1, detail
margins, dydx(hours_housework_t1) at(structural_familism_t1=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot3opts(lcolor("gs6") mcolor("gs6")) ci3opts(color("gs6")) plot4opts(lcolor("gs12") mcolor("gs12")) ci4opts(color("gs12"))


**T-2
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

// Paid labor
* interaction with hours
logistic had_first_birth i.relationship_duration c.structural_familism_t2 i.hh_hours_type_t2 c.structural_familism_t2#i.hh_hours_type_t2 `controls' if hh_hours_type_t2 < 4 & state_fips!=11 
sum structural_familism_t2, detail
margins, dydx(hh_hours_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
logistic had_first_birth i.relationship_duration c.structural_familism_t2 i.hh_earn_type_t2 c.structural_familism_t2#i.hh_earn_type_t2 `controls' if hh_earn_type_t2 < 4 & state_fips!=11 
sum structural_familism_t2, detail
margins, dydx(hh_earn_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor
logistic had_first_birth i.relationship_duration c.structural_familism_t2 i.housework_bkt_t2 c.structural_familism_t2#i.housework_bkt_t2 `controls' if housework_bkt_t2 < 4 & state_fips!=11 
sum structural_familism_t2, detail
margins, dydx(housework_bkt_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Both
logistic had_first_birth i.relationship_duration c.structural_familism_t2 i.hours_housework_t2 c.structural_familism_t2#i.hours_housework_t2 `controls' if state_fips!=11 
sum structural_familism_t2, detail
margins, dydx(hours_housework_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot3opts(lcolor("gs6") mcolor("gs6")) ci3opts(color("gs6")) plot4opts(lcolor("gs12") mcolor("gs12")) ci4opts(color("gs12"))
