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

use "$created_data/PSID_second_birth_sample.dta", clear

// what should duration be?

browse unique_id partner_id survey_yr rel_start_yr at_risk num_births_ref_together num_births_sp_together birth_transition_year cah_child_birth_yr1_ref cah_child_birth_yr2_ref cah_child_birth_yr3_ref cah_child_birth_yr1_sp cah_child_birth_yr2_sp cah_child_birth_yr3_sp relationship_duration

********************************************************************************
* Playing around for now
********************************************************************************
logistic second_birth i.relationship_duration i.educ_wife i.marital_status_updated
margins educ_wife

logistic second_birth i.AGE_SPOUSE_ i.educ_wife i.marital_status_updated
margins educ_wife

tab hh_earn_type second_birth, row m
logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated i.hh_earn_type
margins hh_earn_type

tab hh_earn_type_lag second_birth, row m
logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated i.hh_earn_type_lag
margins hh_earn_type_lag

logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated i.housework_bkt
margins housework_bkt

logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated i.housework_bkt_lag
margins housework_bkt_lag

logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated structural_familism if state_fips!=11
margins, at(structural_familism=(-5(1)10))
marginsplot

// Paid labor
* Structural familism interaction
logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type if hh_earn_type < 4
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12"))

* Structural familism interaction - lag (worried about sample size here)
logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated c.structural_familism i.hh_earn_type_lag c.structural_familism#i.hh_earn_type_lag if hh_earn_type_lag < 4
sum structural_familism, detail
margins, dydx(hh_earn_type_lag) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12"))

// Unpaid labor
* Structural familism interaction
logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt if housework_bkt < 4
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12"))

* Structural familism interaction - lag (worried about sample size here)
logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated c.structural_familism i.housework_bkt_lag c.structural_familism#i.housework_bkt_lag if housework_bkt_lag < 4
sum structural_familism, detail
margins, dydx(housework_bkt_lag) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12"))


// Both
* Structural familism interaction
logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated c.structural_familism i.earn_housework c.structural_familism#i.earn_housework 
sum structural_familism, detail
margins, dydx(earn_housework) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot3opts(lcolor("gs6") mcolor("gs6")) ci3opts(color("gs6")) plot4opts(lcolor("gs12") mcolor("gs12")) ci4opts(color("gs12"))

* Structural familism interaction - lag
logistic second_birth i.AGE_SPOUSE_ i.marital_status_updated c.structural_familism i.earn_housework_lag c.structural_familism#i.earn_housework_lag 
sum structural_familism, detail
margins, dydx(earn_housework_lag) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Working Families: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0)) plot3opts(lcolor("gs6") mcolor("gs6")) ci3opts(color("gs6")) plot4opts(lcolor("gs12") mcolor("gs12")) ci4opts(color("gs12"))