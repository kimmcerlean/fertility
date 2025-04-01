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

// created in step 2a
use "$created_data/PSID_second_birth_sample_broad_RECODED.dta", clear

unique unique_id partner_id
unique unique_id partner_id if _mi_m==0
unique unique_id partner_id if _mi_m==1
unique unique_id partner_id if had_second_birth==1
unique unique_id partner_id if _mi_m==0, by(had_second_birth)

tab relationship_duration had_second_birth, row m 
tab time_since_first_birth had_second_birth, row m 

gen age_woman_sq = age_woman * age_woman

browse unique_id partner_id survey_yr rel_start_all marital_status_use relationship_duration time_since_first_birth had_second_birth shared_second_birth shared_second_birth_yr

label values raceth_fixed_woman raceth_fixed_man raceth
label values marital_status_use marital_status_updated

// adding controls - per that Rindfuss article, do I need to interact age with these variables? bc some variables affect timing of births more than birth itself (and might have negative impact on timing but positive on completed fertility)
global controls "age_woman age_woman_sq couple_age_diff i.educ_type i.couple_joint_religion i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_last_two i.any_births_pre_rel weekly_hrs_t1_woman housework_t1_woman"
// should I also remove the first year post first-birth here? because can't have a birth?
// logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t1 `controls'

set scheme cleanplots

/* how to get AMEs and Predicted Probabilities:
https://www.statalist.org/forums/forum/general-stata-discussion/general/1354295-mimrgns-and-emargins-average-marginal-effects-the-same-as-coefficient-values
https://www.stata.com/meeting/germany16/slides/de16_klein.pdf
https://www.statalist.org/forums/forum/general-stata-discussion/general/316905-mimrgns-interaction-effects
https://www.statalist.org/forums/forum/general-stata-discussion/general/307763-mimrgns-updated-on-ssc
*/

********************************************************************************
********************************************************************************
********************************************************************************
**# Main effects (T1)
********************************************************************************
********************************************************************************
********************************************************************************

mi estimate: logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t1 $controls i.state_fips, or
mimrgns hh_hours_type_t1, predict(pr)
mimrgns, dydx(hh_hours_type_t1) predict(pr) post
estimates store est1

mi estimate: logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t1 $controls i.state_fips, or
mimrgns hh_earn_type_t1, predict(pr)
mimrgns, dydx(hh_earn_type_t1) predict(pr) post
estimates store est1a

mi estimate: logistic had_second_birth i.time_since_first_birth i.couple_work_t1 $controls i.state_fips, or
mimrgns couple_work_t1, predict(pr)
mimrgns, dydx(couple_work_t1) predict(pr) post
estimates store est1b

coefplot (est1, nokey) (est1a, nokey) (est1b, nokey), drop(4.hh_hours_type_t1 4.hh_earn_type_t1) base nolabel xline(0) ///
coeflabels(1.hh_hours_type_t1 = "Dual Earner" 2.hh_hours_type_t1 = "Male Breadwinner" 3.hh_hours_type_t1 = "Female Breadwinner" 1.hh_earn_type_t1 = "Dual Earner" 2.hh_earn_type_t1 = "Male Breadwinner" 3.hh_earn_type_t1 = "Female Breadwinner" 1.couple_work_t1 = "Male Breadwinner" 2.couple_work_t1 = "1.5 Male Breadwinner" 3.couple_work_t1 = "Dual FT" 4.couple_work_t1 = "Female Breadwinner" 5.couple_work_t1 = "Underwork") headings(1.hh_hours_type_t1= "{bf:Division of Work Hours}"  1.hh_earn_type_t1 = "{bf:Division of Earnings}"   1.couple_work_t1 = "{bf:Employment Status}")

mi estimate: logistic had_second_birth i.time_since_first_birth i.housework_bkt_t1 $controls i.state_fips, or
mimrgns housework_bkt_t1,  predict(pr)
mimrgns, dydx(housework_bkt_t1)  predict(pr) post
estimates store est2

mi estimate: logistic had_second_birth i.time_since_first_birth i.hours_housework_t1 $controls i.state_fips, or
mimrgns hours_housework_t1, predict(pr)
mimrgns, dydx(hours_housework_t1) predict(pr) post
estimates store est3

mi estimate: logistic had_second_birth i.time_since_first_birth i.hours_housework_det_t1 $controls i.state_fips, or
mimrgns hours_housework_det_t1, predict(pr)
mimrgns, dydx(hours_housework_det_t1) predict(pr) post
estimates store est3a

coefplot (est3, nokey) (est3a, nokey), base nolabel xline(0) /// (est3b, nokey) (est3c, nokey)
coeflabels(1.hours_housework_t1 = "Egalitarian" 2.hours_housework_t1 = "Her Second Shift" 3.hours_housework_t1 = "Traditional" 4.hours_housework_t1 = "Counter Traditional" 5.hours_housework_t1 = "All Others" ///
1.hours_housework_det_t1 = "Egalitarian" 2.hours_housework_det_t1 = "Her Second Shift" 3.hours_housework_det_t1 = "Traditional" 4.hours_housework_det_t1 = "Counter Traditional" 5.hours_housework_det_t1 = "All Other Female BW" ///
6.hours_housework_det_t1 = "Underwork" 7.hours_housework_det_t1 = "All Others")

mi estimate: logistic had_second_birth i.time_since_first_birth fertility_factor_t1 $controls i.state_fips if state_fips!=11, or
mimrgns, at(fertility_factor_t1=(-1(1)3)) cmdmargins predict(pr)
marginsplot
mimrgns, dydx(fertility_factor_t1) predict(pr) post
estimates store est4

mi estimate: logistic had_second_birth i.time_since_first_birth fertility_factor_det_t1 $controls i.state_fips if state_fips!=11, or
mimrgns, at(fertility_factor_det_t1=(-2(1)5)) cmdmargins predict(pr)
marginsplot
mimrgns, dydx(fertility_factor_det_t1) predict(pr) post
estimates store est4a

mi estimate: logistic had_second_birth i.time_since_first_birth prek_enrolled_public_t1 $controls i.state_fips if state_fips!=11, or
mimrgns, dydx(prek_enrolled_public_t1) predict(pr) post
estimates store est4b

mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 $controls i.state_fips if state_fips!=11, or
mimrgns, dydx(paid_leave_t1) predict(pr) post
estimates store est4c

set scheme cleanplots

coefplot (est1, nokey) (est2, nokey) (est3a, nokey) (est4, nokey) (est4a, nokey) (est4b, nokey) (est4c, nokey), base drop(4.hh_hours_type_t1 4.hh_earn_type_t1 4.housework_bkt_t1) nolabel xline(0) xtitle(Average Marginal Effects, size(small)) ///
coeflabels(1.hh_hours_type_t1 = "Dual Earner" 2.hh_hours_type_t1 = "Male Breadwinner" 3.hh_hours_type_t1 = "Female Breadwinner"  1.housework_bkt_t1 = "Dual Housework" 2.housework_bkt_t1 = "Female Housework" 3.housework_bkt_t1 = "Male Housework" 1.hours_housework_det_t1 = "Egalitarian" 2.hours_housework_det_t1 = "Her Second Shift" 3.hours_housework_det_t1 = "Traditional" 4.hours_housework_det_t1 = "Counter Traditional" 5.hours_housework_det_t1 = "All Other Female BW" 6.hours_housework_det_t1 = "Underwork" 7.hours_housework_det_t1 = "All Others" fertility_factor_t1= "Combined Policy"  fertility_factor_det_t1= "Combined Policy (det)" prek_enrolled_public_t1= "Public Pre-K Coverage" 0.paid_leave_t1 = "No Paid Leave" 1.paid_leave_t1 = "Paid Leave") ///
 headings(1.hh_hours_type_t1= "{bf:Division of Work Hours}"  1.housework_bkt_t1 = "{bf:Division of Housework}" 1.hours_housework_det_t1 = "{bf:Combined Division of Labor}" fertility_factor_t1="{bf:Work-Family Policy}")
 
// coefplot (est1, offset(.20) nokey lcolor("dkgreen") mcolor("dkgreen") ciopts(color("dkgreen"))) (est2, offset(.20) nokey lcolor("teal") mcolor("teal") ciopts(color("teal")))

********************************************************************************
*Alt indicators
********************************************************************************
mi passive: gen female_hours_pct_t1_x = female_hours_pct_t1
mi passive: replace female_hours_pct_t1_x = -1 if weekly_hrs_t1_woman==0 & weekly_hrs_t1_man==0

mi passive: gen wife_housework_pct_t1_x = wife_housework_pct_t1
mi passive: replace wife_housework_pct_t1_x = -1 if housework_t1_woman==0 & housework_t1_man==0

// Paid Work
* Her share
mi estimate: logistic had_second_birth i.time_since_first_birth female_hours_pct_t1_x $controls i.state_fips if state_fips!=11, or
mimrgns, dydx(female_hours_pct_t1_x) predict(pr) post
estimates store esta

mi estimate: logistic had_second_birth i.time_since_first_birth female_hours_pct_t1_x $controls i.state_fips if state_fips!=11, or // make sure not biased by how i coded no hours
mimrgns, at(female_hours_pct_t1_x=(-1 0 0.25 0.5 0.75 1)) predict(pr) cmdmargins
marginsplot

* Her total hours
mi estimate: logistic had_second_birth i.time_since_first_birth weekly_hrs_t1_woman $controls i.state_fips if state_fips!=11, or
mimrgns, dydx(weekly_hrs_t1_woman) predict(pr) post
estimates store estb

* His total hours
mi estimate: logistic had_second_birth i.time_since_first_birth weekly_hrs_t1_man $controls i.state_fips if state_fips!=11, or
mimrgns, dydx(weekly_hrs_t1_man) predict(pr) post
estimates store estc

// Unpaid Work
* Her share
mi estimate: logistic had_second_birth i.time_since_first_birth wife_housework_pct_t1_x $controls i.state_fips if state_fips!=11, or
mimrgns, dydx(wife_housework_pct_t1_x) predict(pr) post
estimates store estd

mi estimate: logistic had_second_birth i.time_since_first_birth wife_housework_pct_t1_x $controls i.state_fips if state_fips!=11, or // make sure not biased by how i coded no hours
mimrgns, at(wife_housework_pct_t1_x=(-1 0 0.25 0.5 0.75 1)) predict(pr) cmdmargins
marginsplot

* Her total hours
mi estimate: logistic had_second_birth i.time_since_first_birth housework_t1_woman $controls i.state_fips if state_fips!=11, or
mimrgns, dydx(housework_t1_woman) predict(pr) post
estimates store este

* His total hours
mi estimate: logistic had_second_birth i.time_since_first_birth housework_t1_man $controls i.state_fips if state_fips!=11, or
mimrgns, dydx(housework_t1_man) predict(pr) post
estimates store estf

coefplot (esta, nokey) (estb, nokey) (estc, nokey) (estd, nokey) (este, nokey) (estf, nokey), drop(_cons) nolabel xline(0) xtitle(Average Marginal Effects, size(small)) ///
coeflabels(female_hours_pct_t1_x= "Her % Share of Paid Work"  weekly_hrs_t1_woman= "Her Work Hours" weekly_hrs_t1_man= "His Work Hours" ///
wife_housework_pct_t1_x= "Her % Share of Housework"  housework_t1_woman= "Her Housework Hours" housework_t1_man= "His Housework Hours") ///
headings(female_hours_pct_t1_x="{bf:Paid Work}" wife_housework_pct_t1_x="{bf:Housework}")

coefplot (estb, nokey) (estc, nokey) (este, nokey) (estf, nokey), drop(_cons) nolabel xline(0) xtitle(Average Marginal Effects, size(small)) ///
coeflabels(female_hours_pct_t1_x= "Her % Share of Paid Work"  weekly_hrs_t1_woman= "Her Work Hours" weekly_hrs_t1_man= "His Work Hours" ///
wife_housework_pct_t1_x= "Her % Share of Housework"  housework_t1_woman= "Her Housework Hours" housework_t1_man= "His Housework Hours") ///
headings(weekly_hrs_t1_woman="{bf:Paid Work}" housework_t1_woman="{bf:Housework}")

coefplot (esta, nokey) (estd, nokey), drop(_cons) nolabel xline(0) xtitle(Average Marginal Effects, size(small)) ///
coeflabels(female_hours_pct_t1_x= "Her % Share of Paid Work"  weekly_hrs_t1_woman= "Her Work Hours" weekly_hrs_t1_man= "His Work Hours" ///
wife_housework_pct_t1_x= "Her % Share of Housework"  housework_t1_woman= "Her Housework Hours" housework_t1_man= "His Housework Hours") ///
headings(female_hours_pct_t1_x="{bf:Paid Work}" wife_housework_pct_t1_x="{bf:Housework}")

********************************************************************************
* Main Effects Figure for Time Use Presentation
********************************************************************************

coefplot (est1, nokey lcolor("0 69 117") mcolor("0 69 117") ciopts(color("0 69 117"))) (esta, nokey lcolor("0 69 117") mcolor("0 69 117") ciopts(color("0 69 117"))) ///
 (est2, nokey lcolor("36 128 196") mcolor("36 128 196") ciopts(color("36 128 196"))) (estd, nokey lcolor("36 128 196") mcolor("36 128 196") ciopts(color("36 128 196"))) ///
 (est3a, nokey) (est4a, nokey), base drop(4.hh_hours_type_t1 4.hh_earn_type_t1 4.housework_bkt_t1) nolabel xline(0) xtitle(Average Marginal Effects, size(small)) ///
coeflabels(1.hh_hours_type_t1 = "Dual Earner" 2.hh_hours_type_t1 = "Male Breadwinner" 3.hh_hours_type_t1 = "Female Breadwinner"  female_hours_pct_t1_x= "Her % Share of Paid Work" /// 
1.housework_bkt_t1 = "Dual Housework" 2.housework_bkt_t1 = "Female Housework" 3.housework_bkt_t1 = "Male Housework" wife_housework_pct_t1_x= "Her % Share of Housework" ///
1.hours_housework_det_t1 = "Egalitarian" 2.hours_housework_det_t1 = "Her Second Shift" 3.hours_housework_det_t1 = "Traditional" 4.hours_housework_det_t1 = "Counter Traditional" 5.hours_housework_det_t1 = "All Other Female BW" 6.hours_housework_det_t1 = "Underwork" 7.hours_housework_det_t1 = "All Others" fertility_factor_det_t1= "Work-Family Policy Factor") ///
 headings(1.hh_hours_type_t1= "{bf:Division of Work Hours}"  1.housework_bkt_t1 = "{bf:Division of Housework}" 1.hours_housework_det_t1 = "{bf:Combined Division of Labor}" fertility_factor_det_t1="{bf:Work-Family Policy}")
 
// using simpler for ease - additional categories don't add value
coefplot (est1, nokey lcolor("0 69 117") mcolor("0 69 117") ciopts(color("0 69 117"))) (esta, nokey lcolor("0 69 117") mcolor("0 69 117") ciopts(color("0 69 117"))) ///
(est2, nokey lcolor("36 128 196") mcolor("36 128 196") ciopts(color("36 128 196"))) (estd, nokey lcolor("36 128 196") mcolor("36 128 196") ciopts(color("36 128 196"))) ///
(est3, nokey lcolor("200 88 38") mcolor("200 88 38") ciopts(color("200 88 38"))) (est4a, nokey lcolor("233 162 31") mcolor("233 162 31") ciopts(color("233 162 31"))), ///
base drop(4.hh_hours_type_t1 4.hh_earn_type_t1 4.housework_bkt_t1) nolabel xline(0) xtitle(Average Marginal Effects, size(small)) ///
coeflabels(1.hh_hours_type_t1 = "Dual Earner" 2.hh_hours_type_t1 = "Male Breadwinner" 3.hh_hours_type_t1 = "Female Breadwinner"  female_hours_pct_t1_x= "Her % Share of Paid Work" /// 
1.housework_bkt_t1 = "Dual Housework" 2.housework_bkt_t1 = "Female Housework" 3.housework_bkt_t1 = "Male Housework" wife_housework_pct_t1_x= "Her % Share of Housework" ///
1.hours_housework_t1 = "Egalitarian" 2.hours_housework_t1 = "Her Second Shift" 3.hours_housework_t1 = "Traditional" 4.hours_housework_t1 = "Counter Traditional" 5.hours_housework_t1 = "All Others" fertility_factor_det_t1= "Work-Family Policy Factor") ///
headings(1.hh_hours_type_t1= "{bf:Division of Work Hours}"  1.housework_bkt_t1 = "{bf:Division of Housework}" 1.hours_housework_t1 = "{bf:Combined Division of Labor}" fertility_factor_det_t1 ="{bf:Work-Family Policy}")


********************************************************************************
********************************************************************************
********************************************************************************
**# Key interactions with structural support measures
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
**Factor variable (t1)
********************************************************************************

// Paid labor hours
mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hh_hours_type_t1 c.fertility_factor_det_t1#i.hh_hours_type_t1 $controls i.state_fips if state_fips!=11, or
// outreg2 using "$results/second_birth_cons.xls", sideway stats(coef pval) label ctitle(Hours T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

sum fertility_factor_det_t1, detail
mimrgns, dydx(hh_hours_type_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW" 3 "No Earners") rows(1)) // plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hh_hours_type_t1 c.fertility_factor_det_t1#i.hh_hours_type_t1 $controls ///
	i.state_fips if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(2.hh_hours_type_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est5

	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hh_hours_type_t1 c.fertility_factor_det_t1#i.hh_hours_type_t1 $controls ///
	i.state_fips if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(3.hh_hours_type_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est6

	coefplot (est5, mcolor("0 69 117") ciopts(color("0 69 117")) label("Male BW")) (est6, mcolor("gs12") ciopts(color("gs12")) label("Female BW")),  drop(_cons) nolabel xline(0, lcolor("black")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual-Earning, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Work-Family Policy Scale}", angle(vertical))
	
// Her share of Paid Labor
mi estimate: logistic had_second_birth i.time_since_first_birth c.female_hours_pct_t1_x c.fertility_factor_det_t1 c.female_hours_pct_t1_x#c.fertility_factor_det_t1 $controls i.state_fips if state_fips!=11, or
sum fertility_factor_det_t1, detail
mimrgns, dydx(female_hours_pct_t1_x) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store estg

coefplot (estg, nokey mcolor("0 69 117") ciopts(color("0 69 117"))),  xline(0, lcolor("black")) levels(95) coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
xtitle(Average Marginal Effects) groups(?._at = "{bf:Work-Family Policy Scale}", angle(vertical))

// Unpaid labor
mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.housework_bkt_t1 c.fertility_factor_det_t1#i.housework_bkt_t1 $controls i.state_fips if state_fips!=11, or
// outreg2 using "$results/second_birth_cons.xls", sideway stats(coef pval) label ctitle(HW T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

sum fertility_factor_det_t1, detail
mimrgns, dydx(housework_bkt_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.housework_bkt_t1 c.fertility_factor_det_t1#i.housework_bkt_t1 $controls ///
	i.state_fips if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(2.housework_bkt_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est7

	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.housework_bkt_t1 c.fertility_factor_det_t1#i.housework_bkt_t1 $controls ///
	i.state_fips if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(3.housework_bkt_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est8

	coefplot (est7, mcolor("36 128 196") ciopts(color("36 128 196")) label("Female HW")) (est8,  mcolor("gs12") ciopts(color("gs12")) label("Male HW")),  drop(_cons) nolabel xline(0, lcolor("black")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual Housework, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Work-Family Policy Scale}", angle(vertical))

// Her share of Unpaid Labor
mi estimate: logistic had_second_birth i.time_since_first_birth c.wife_housework_pct_t1_x c.fertility_factor_det_t1 c.wife_housework_pct_t1_x#c.fertility_factor_det_t1 $controls i.state_fips if state_fips!=11, or
sum fertility_factor_det_t1, detail
mimrgns, dydx(wife_housework_pct_t1_x) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store esth

coefplot (esth, nokey mcolor("36 128 196") ciopts(color("36 128 196"))),  xline(0, lcolor("black")) levels(95) coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
xtitle(Average Marginal Effects) groups(?._at = "{bf:Work-Family Policy Scale}", angle(vertical))

// Both: Simpler (for ease)
// mi estimate: xtlogit had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls if state_fips!=11, fe or
// taking forever, can I just use dummies? trying to get it to run at least once so I can validate it's the same

mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_t1 c.fertility_factor_det_t1#i.hours_housework_t1 $controls i.state_fips if state_fips!=11, or
estimates save "$models/state_dummies_ctl", replace

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(2.hours_housework_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d2

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(3.hours_housework_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d3

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(4.hours_housework_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d4

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(5.hours_housework_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d5

coefplot (est_d3, mcolor("200 88 38") ciopts(color("200 88 38")) label("Traditional")) (est_d2, mcolor("233 162 31") ciopts(color("233 162 31")) label("Second Shift"))  ///
(est_d4, mcolor("205 209 111") ciopts(color("205 209 111")) label("Counter Traditional")) (est_d5, mcolor("gs12") ciopts(color("gs12")) label("Other")) ///
,  drop(_cons) nolabel xline(0, lcolor("black")) levels(95) ///
coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
xtitle(Average Marginal Effect Relative to Egalitarian, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Work-Family Policy Scale}", angle(vertical))

coefplot (est_d3, mcolor("200 88 38") ciopts(color("200 88 38")) label("Traditional")) (est_d2, mcolor("gs12") ciopts(color("gs12")) label("Second Shift"))  ///
(est_d4, mcolor("gs12") ciopts(color("gs12")) label("Counter Traditional")) (est_d5, mcolor("gs12") ciopts(color("gs12")) label("Other")) ///
,  drop(_cons) nolabel xline(0, lcolor("black")) levels(95) ///
coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
xtitle(Average Marginal Effect Relative to Egalitarian, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Work-Family Policy Scale}", angle(vertical))

/*
// Both: Detailed
mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls iif state_fips!=11, or
// outreg2 using "$results/second_birth_cons.xls", sideway stats(coef pval) label ctitle(Combined T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mimrgns, dydx(hours_housework_det_t1) at(fertility_factor_det_t1=(-2(1)4)) predict(pr) cmdmargins
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Female BW" 5 "Underwork" 6 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))

// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls ///
	if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(2.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est9

	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls  ///
	if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(3.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est10

	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls  ///
	if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(4.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est11
	
	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls  ///
	if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(5.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est12
	
	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls  ///
	if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(6.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est13
	
	mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls  ///
	if state_fips!=11, or
	sum fertility_factor_det_t1, detail
	mimrgns, dydx(7.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est14

	coefplot (est9, mcolor(navy) ciopts(color(navy)) label("Second Shift")) (est10, label("Traditional")) (est11, label("Counter-Trad")) (est12, label("Female-BW Other")) (est13, label("Underwork")) (est14, label("Other")) ///
	,  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Egalitarian, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))
	

tabstat housework_t1_man housework_t1_woman weekly_hrs_t1_woman weekly_hrs_t1_man, by(hours_housework_det_t1)

**********************************
// gah, do I need fixed effects?
**********************************

mi xtset state_fips

mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls if state_fips!=11, or
mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls weekly_hrs_t1_woman housework_t1_woman if state_fips!=11, or

mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls i.state_fips if state_fips!=11, or
estimates save "$models/state_dummies", replace
mi estimate: logistic had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls  weekly_hrs_t1_woman housework_t1_woman i.state_fips if state_fips!=11, or
// estimates store state_dummies
estimates save "$models/state_dummies_ctl", replace

// mi estimate: xtlogit had_second_birth i.time_since_first_birth c.fertility_factor_det_t1 i.hours_housework_det_t1 c.fertility_factor_det_t1#i.hours_housework_det_t1 $controls if state_fips!=11, fe or
// taking forever, can I just use dummies? trying to get it to run at least once so I can validate it's the same

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(2.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d2

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(3.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d3

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(4.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d4

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(5.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d5

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(6.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d6

estimates use "$models/state_dummies_ctl"
sum fertility_factor_det_t1, detail
mimrgns, dydx(7.hours_housework_det_t1) at(fertility_factor_det_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
estimates store est_d7

coefplot (est_d2, mcolor(navy) ciopts(color(navy)) label("Second Shift")) (est_d3, label("Traditional")) (est_d4, label("Counter-Trad")) (est_d5, label("Female-BW Other")) (est_d6, label("Underwork")) (est_d7, label("Other")) ///
,  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
xtitle(Average Marginal Effect Relative to Egalitarian, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))
*/
	
********************************************************************************	
**# **Public Pre-K Enrollment
********************************************************************************
// -fvset clear _all-

// Paid labor hours
mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.hh_hours_type_t1 c.prek_enrolled_public_t1#i.hh_hours_type_t1 $controls if state_fips!=11, or
sum prek_enrolled_public_t1, detail
mimrgns, dydx(hh_hours_type_t1) at(prek_enrolled_public_t1=(`r(min)'(.05)`r(max)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW" 3 "No Earners") rows(1)) // plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.hh_hours_type_t1 c.prek_enrolled_public_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(2.hh_hours_type_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est5a

	mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.hh_hours_type_t1 c.prek_enrolled_public_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(3.hh_hours_type_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est6a

	coefplot (est5a, mcolor(navy) ciopts(color(navy)) label("Male BW")) (est6a, label("Female BW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual-Earning, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Pre-K Enrollment}", angle(vertical))

// Unpaid labor
mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.housework_bkt_t1 c.prek_enrolled_public_t1#i.housework_bkt_t1 $controls if state_fips!=11, or
sum prek_enrolled_public_t1, detail
mimrgns, dydx(housework_bkt_t1) at(prek_enrolled_public_t1=(`r(min)'(.05)`r(max)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.housework_bkt_t1 c.prek_enrolled_public_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(2.housework_bkt_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est7a

	mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.housework_bkt_t1 c.prek_enrolled_public_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(3.housework_bkt_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est8a

	coefplot (est7a, mcolor(navy) ciopts(color(navy)) label("Female HW")) (est8a, label("Male HW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual Housework, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Pre-K Enrollment}", angle(vertical))

// Both
mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls if state_fips!=11, or
sum prek_enrolled_public_t1, detail
mimrgns, dydx(hours_housework_t1) at(prek_enrolled_public_t1=(`r(min)'(.05)`r(max)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(2.hours_housework_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est9a

	mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(3.hours_housework_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est10a

	mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(4.hours_housework_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est11a
	
	mi estimate: logistic had_second_birth i.time_since_first_birth c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(5.hours_housework_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est12a

	coefplot (est9a, mcolor(navy) ciopts(color(navy)) label("Second Shift")) (est10a, label("Traditional")) (est11a, label("Counter-Trad")) (est12a, label("Other")) ///
	,  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Egalitarian, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Pre-K Enrollment}", angle(vertical))


********************************************************************************
**Paid Leave
********************************************************************************
// Paid labor hours
mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.hh_hours_type_t1 i.paid_leave_t1#i.hh_hours_type_t1 $controls if state_fips!=11, or
mimrgns, dydx(hh_hours_type_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins
marginsplot, xtitle("Paid Leave") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) // plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.hh_hours_type_t1 i.paid_leave_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.hh_hours_type_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est5b

	mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.hh_hours_type_t1 i.paid_leave_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(3.hh_hours_type_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est6b

	coefplot (est5b, mcolor(navy) ciopts(color(navy)) label("Male BW")) (est6b, label("Female BW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "No Paid Leave" 2._at = "Has Paid Leave") ///
	xtitle(Average Marginal Effect Relative to Dual-Earning, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Paid Leave Status}", angle(vertical))
	
// Unpaid labor
mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.housework_bkt_t1 i.paid_leave_t1#i.housework_bkt_t1 $controls if state_fips!=11, or
mimrgns, dydx(housework_bkt_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins
marginsplot, xtitle("Paid Leave") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.housework_bkt_t1 i.paid_leave_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.housework_bkt_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est7b

	mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.housework_bkt_t1 i.paid_leave_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(3.housework_bkt_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est8b

	coefplot (est7b, mcolor(navy) ciopts(color(navy)) label("Female HW")) (est8b, label("Male HW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "No Paid Leave" 2._at = "Has Paid Leave") ///
	xtitle(Average Marginal Effect Relative to Dual Housework, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Paid Leave Status}", angle(vertical))

// Both
mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls if state_fips!=11, or
mimrgns, dydx(hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins
marginsplot, xtitle("Paid Leave") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est9b

	mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(3.hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est10b

	mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(4.hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est11b
	
	mi estimate: logistic had_second_birth i.time_since_first_birth i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(5.hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est12b

	coefplot (est9b, mcolor(navy) ciopts(color(navy)) label("Second Shift")) (est10b, label("Traditional")) (est11b, label("Counter-Trad")) (est12b, label("Other")) ///
	,  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "No Paid Leave" 2._at = "Has Paid Leave") ///
	xtitle(Average Marginal Effect Relative to Egalitarian, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Paid Leave Status}", angle(vertical))


	
********************************************************************************	
**Structural Familism
********************************************************************************
// -fvset clear _all-

// Paid labor hours
mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 $controls if state_fips!=11, or
sum structural_familism_t1, detail
mimrgns, dydx(hh_hours_type_t1) at(structural_familism_t1=(`r(p5)'(1)`r(p95)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW" 3 "No Earners") rows(1)) // plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(2.hh_hours_type_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est5c

	mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(3.hh_hours_type_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est6c

	coefplot (est5c, mcolor(navy) ciopts(color(navy)) label("Male BW")) (est6c, label("Female BW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual-Earning, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))

// Unpaid labor
mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 $controls if state_fips!=11, or
sum structural_familism_t1, detail
mimrgns, dydx(housework_bkt_t1) at(structural_familism_t1=(`r(p5)'(1)`r(p95)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(2.housework_bkt_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est7c

	mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(3.housework_bkt_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est8c

	coefplot (est7c, mcolor(navy) ciopts(color(navy)) label("Female HW")) (est8c, label("Male HW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual Housework, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))

// Both
mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls if state_fips!=11, or
sum structural_familism_t1, detail
mimrgns, dydx(hours_housework_t1) at(structural_familism_t1=(`r(p5)'(1)`r(p95)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))

	// alt charts
	mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(2.hours_housework_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est9c

	mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(3.hours_housework_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est10c

	mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(4.hours_housework_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est11c
	
	mi estimate: logistic had_second_birth i.time_since_first_birth c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(5.hours_housework_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est12c

	coefplot (est9c, mcolor(navy) ciopts(color(navy)) label("Second Shift")) (est10c, label("Traditional")) (est11c, label("Counter-Trad")) (est12c, label("Other")) ///
	,  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Egalitarian, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))
	
	
********************************************************************************
********************************************************************************
********************************************************************************
**# Robustness check: relationship after 2005 (t-2)
********************************************************************************
********************************************************************************
********************************************************************************
// Not Yet Revisited

/* 
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"
logistic had_second_birth i.time_since_first_birth i.hh_hours_type_t2 `controls' if hh_hours_type_t2 < 4 & rel_start_yr>=2005
margins, dydx(hh_hours_type_t2) level(90) post
estimates store est9

logistic had_second_birth i.time_since_first_birth i.hh_earn_type_t2 `controls' if hh_earn_type_t2 < 4 & rel_start_yr>=2005
margins, dydx(hh_earn_type_t2) level(90) post
estimates store est10

logistic had_second_birth i.time_since_first_birth i.housework_bkt_t2_imp `controls' if housework_bkt_t2_imp < 4 & rel_start_yr>=2005
margins, dydx(housework_bkt_t2_imp) level(90) post
estimates store est11

logistic had_second_birth i.time_since_first_birth i.hours_housework_t2_imp `controls' if rel_start_yr>=2005
margins, dydx(hours_housework_t2_imp) level(90) post
estimates store est12

coefplot est9 est10 est11 est12,  drop(_cons) nolabel xline(0) levels(90)

set scheme cleanplots

coefplot (est9, offset(.20) nokey lcolor("dkgreen") mcolor("dkgreen") ciopts(color("dkgreen"))) (est10, offset(.20) nokey lcolor("teal") mcolor("teal") ciopts(color("teal"))) (est11, offset(-.20) nokey lcolor("navy") mcolor("navy") ciopts(color("navy"))) (est12, offset(-.20) nokey), drop(_cons) xline(0) levels(90) base xtitle(Average Marginal Effect Relative to Egalitarian Arrangement, size(small)) ///
coeflabels(2.hh_hours_type_t2 = "Male Breadwinner" 3.hh_hours_type_t2 = "Female Breadwinner" 2.hh_earn_type_t2 = "Male Breadwinner" 3.hh_earn_type_t2 = "Female Breadwinner" 1.housework_bkt_t2_imp = "Dual Housework" 2.housework_bkt_t2_imp = "Female Housework" 3.housework_bkt_t2_imp = "Male Housework" 1.hours_housework_t2_imp = "Egalitarian" 2.hours_housework_t2_imp = "Her Second Shift" 3.hours_housework_t2_imp = "Traditional" 4.hours_housework_t2_imp = "Counter Traditional" 5.hours_housework_t2_imp = "All Others") ///
 headings(1.hh_hours_type_t2= "{bf:Division of Work Hours}"   1.hh_earn_type_t2 = "{bf:Division of Earnings}"   1.housework_bkt_t2_imp = "{bf:Division of Housework}"  1.hours_housework_t2_imp = "{bf:Combined Division of Labor}")
 // (est3, offset(-.20) label(College)) 
 
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"
logistic had_second_birth i.time_since_first_birth structural_familism_t2 `controls' if state_fips!=11 & rel_start_yr>=2005
margins, at(structural_familism_t2=(-5(1)10))
marginsplot, ytitle(Predicted Probability of Second Birth) xtitle(Structural Support for Working Families) plot1opts(lcolor("eltgreen") mcolor("eltgreen")) ci1opts(color("eltgreen"))
margins, dydx(structural_familism_t2)

**Interactions
set scheme stcolor

local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

// Paid labor
* interaction with hours
logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hh_hours_type_t2 c.structural_familism_t2#i.hh_hours_type_t2 `controls' if hh_hours_type_t2 < 4 & state_fips!=11 & rel_start_yr>=2005

sum structural_familism_t2, detail
margins, dydx(hh_hours_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5)) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hh_earn_type_t2 c.structural_familism_t2#i.hh_earn_type_t2 `controls' if hh_earn_type_t2 < 4 & state_fips!=11 & rel_start_yr>=2005

sum structural_familism_t2, detail
margins, dydx(hh_earn_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5)) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor - est
logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.housework_bkt_t2_imp c.structural_familism_t2#i.housework_bkt_t2_imp `controls' if housework_bkt_t2_imp < 4 & state_fips!=11 & rel_start_yr>=2005

sum structural_familism_t2, detail
margins, dydx(housework_bkt_t2_imp) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

// Both - est
logistic had_second_birth i.time_since_first_birth c.structural_familism_t2 i.hours_housework_t2_imp c.structural_familism_t2#i.hours_housework_t2_imp `controls' if state_fips!=11 & rel_start_yr>=2005

sum structural_familism_t2, detail
margins, dydx(hours_housework_t2_imp) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Second Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))
*/

********************************************************************************
********************************************************************************
********************************************************************************
**# Descriptive statistics
********************************************************************************
********************************************************************************
********************************************************************************

// main IVs t: hh_hours_type housework_bkt hours_housework couple_work fertility_factor_det_t
// t-1: hh_hours_type_t1 housework_bkt_t1 hours_housework_t1 couple_work_t1 fertility_factor_det_t1
// controls: age_woman age_woman_sq couple_age_diff i.educ_type i.couple_joint_religion i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_last_two i.any_births_pre_rel weekly_hrs_t1_woman housework_t1_woman
// time since first birth relationship_duration
// for broad: also add premarital births (any_births_pre_rel)

tab hh_hours_type housework_bkt, cell nofreq

putexcel set "$results/Second_birth_descriptives-broad", replace
putexcel B1:C1 = "Time t", merge border(bottom)
putexcel D1:E1 = "Time t-1", merge border(bottom)
putexcel B2 = ("All") C2 = ("Had Second Birth") D2 = ("All") E2 = ("Had Second Birth")
putexcel A3 = "Unique Couples"

putexcel A4 = "Dual Earning"
putexcel A5 = "Male Breadwinner"
putexcel A6 = "Female Breadwinner"
putexcel A7 = "Dual Housework"
putexcel A8 = "Female Primary HW"
putexcel A9 = "Male Primary HW"
putexcel A10 = "Egalitarian"
putexcel A11 = "Second Shift"
putexcel A12 = "Traditional"
putexcel A13 = "Counter-Traditional"
putexcel A14 = "All Others"
putexcel A15 = "Male BW"
putexcel A16 = "Male 1.5 BW"
putexcel A17 = "Dual FT"
putexcel A18 = "Female BW"
putexcel A19 = "Under Work"
putexcel A20 = "Woman's Average Weekly Work Hours"
putexcel A21 = "Man's Average Weekly Work Hours"
putexcel A22 = "Woman's Average Weekly Housework"
putexcel A23 = "Man's Average Weekly Housework"
putexcel A24 = "Total Couple Earnings"
putexcel A25 = "Work-Family Policy Support"

putexcel A26 = "Woman's age"
putexcel A27 = "Man's age"
putexcel A28 = "Relationship duration"
putexcel A29 = "Time Since First Birth"

putexcel A30 = "Married"
putexcel A31 = "Cohab"
putexcel A32 = "Neither College Degree"
putexcel A33 = "His College Degree"
putexcel A34 = "Her College Degree"
putexcel A35 = "Both College Degree"
putexcel A36 = "Both No Religion"
putexcel A37 = "Both Catholic"
putexcel A38 = "Both Protestant"
putexcel A39 = "One Catholic"
putexcel A40 = "One No Religion"
putexcel A41 = "Other Religion"
putexcel A42 = "Woman's Race: NH White"
putexcel A43 = "Woman's Race: Black"
putexcel A44 = "Woman's Race: Hispanic"
putexcel A45 = "Woman's Race: NH Asian"
putexcel A46 = "Woman's Race: NH Other"
putexcel A47 = "Husband and Wife Same Race"
putexcel A48 = "Moved States"
putexcel A49 = "Had Premarital Birth"

global cont_t "weekly_hrs_t_woman weekly_hrs_t_man housework_woman housework_man couple_earnings fertility_factor_det_t"
global cont_t1 "weekly_hrs_t1_woman weekly_hrs_t1_man housework_t1_woman housework_t1_man couple_earnings_t1 fertility_factor_det_t1"
global cont_fixed "age_woman age_man relationship_duration time_since_first_birth"

*******************************
* Time T
*******************************
* Hours
forvalues d=1/3{
   capture mi passive: gen hh_hours_t`d' = hh_hours_type==`d'
   mi estimate: mean hh_hours_t`d'
   matrix h`d' = e(b_mi)
   local h`d' = h`d'[1,1]
   local row = 3 +`d'
   putexcel B`row' = `h`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean hh_hours_t`d' if had_second_birth==1
   matrix bh`d' = e(b_mi)
   local bh`d' = bh`d'[1,1]
   local row = 3 + `d'
   putexcel C`row' = `bh`d'', nformat(##.#%)
}

// mi estimate: proportion hh_hours_type educ_type
// mi estimate: proportion hh_hours_type if had_second_birth==1
// mi estimate: proportion educ_type if 

* HW
forvalues d=1/3{
   capture mi passive: gen housework_bkt_tx`d' = housework_bkt==`d'
   mi estimate: mean housework_bkt_tx`d'
   matrix w`d' = e(b_mi)
   local w`d' = w`d'[1,1]
   local row = 6 +`d'
   putexcel B`row' = `w`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean housework_bkt_tx`d' if had_second_birth==1
   matrix bw`d' = e(b_mi)
   local bw`d' = bw`d'[1,1]
   local row = 6 + `d'
   putexcel C`row' = `bw`d'', nformat(##.#%)
}

* Combined
forvalues d=1/5{
   capture mi passive: gen hours_hw_t`d' = hours_housework==`d'
   mi estimate: mean hours_hw_t`d'
   matrix c`d' = e(b_mi)
   local c`d' = c`d'[1,1]
   local row = 9 +`d'
   putexcel B`row' = `c`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean hours_hw_t`d' if had_second_birth==1
   matrix bc`d' = e(b_mi)
   local bc`d' = bc`d'[1,1]
   local row = 9 + `d'
   putexcel C`row' = `bc`d'', nformat(##.#%)
}

* Employment
forvalues d=1/5{
   capture mi passive: gen couple_work_tx`d' = couple_work==`d'
   mi estimate: mean couple_work_tx`d'
   matrix e`d' = e(b_mi)
   local e`d' = e`d'[1,1]
   local row = 14 +`d'
   putexcel B`row' = `e`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean couple_work_tx`d' if had_second_birth==1
   matrix be`d' = e(b_mi)
   local be`d' = be`d'[1,1]
   local row = 14 + `d'
   putexcel C`row' = `be`d'', nformat(##.#%)
}

* Raw hours
forvalues w=1/6{
	local row=`w'+19
	local var: word `w' of $cont_t
	
	mi estimate: mean `var'
	matrix m`var' = e(b_mi)
	local m`var' = m`var'[1,1]
	putexcel B`row' = `m`var'', nformat(#####)
	
	mi estimate: mean `var' if had_second_birth==1
	matrix mb`var' = e(b_mi)
	local mb`var' = mb`var'[1,1]
	putexcel C`row' = `mb`var'', nformat(#####)
}

* Other continuous
forvalues w=1/4{
	local row=`w'+25
	local var: word `w' of $cont_fixed
	
	mi estimate: mean `var'
	matrix c`var' = e(b_mi)
	local c`var' = c`var'[1,1]
	putexcel B`row' = `c`var'', nformat(#####)
	
	mi estimate: mean `var' if had_second_birth==1
	matrix cb`var' = e(b_mi)
	local cb`var' = cb`var'[1,1]
	putexcel C`row' = `cb`var'', nformat(#####)
}

* Rel Status
forvalues d=1/2{
   capture mi passive: gen rel_status`d' = marital_status_use==`d'
   mi estimate: mean rel_status`d'
   matrix r`d' = e(b_mi)
   local r`d' = r`d'[1,1]
   local row = 29 +`d'
   putexcel B`row' = `r`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean rel_status`d' if had_second_birth==1
   matrix br`d' = e(b_mi)
   local br`d' = br`d'[1,1]
   local row = 29 + `d'
   putexcel C`row' = `br`d'', nformat(##.#%)
}

* Education
forvalues d=1/4{
   capture gen educ_type`d' = educ_type==`d'
   mi estimate: mean educ_type`d'
   matrix ed`d' = e(b_mi)
   local ed`d' = ed`d'[1,1]
   local row = 31 +`d'
   putexcel B`row' = `ed`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean educ_type`d' if had_second_birth==1
   matrix bed`d' = e(b_mi)
   local bed`d' = bed`d'[1,1]
   local row = 31 + `d'
   putexcel C`row' = `bed`d'', nformat(##.#%)
}

* Religion
forvalues d=0/5{
   capture gen religion`d' = couple_joint_religion==`d'
   mi estimate: mean religion`d'
   matrix re`d' = e(b_mi)
   local re`d' = re`d'[1,1]
   local row = 36 +`d' // d is 0 so need 35 NOT 34
   putexcel B`row' = `re`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean religion`d' if had_second_birth==1
   matrix bre`d' = e(b_mi)
   local bre`d' = bre`d'[1,1]
   local row = 36 + `d'
   putexcel C`row' = `bre`d'', nformat(##.#%)
}

* Women's Race
forvalues d=1/5{
   capture gen race_wom`d' = raceth_fixed_woman==`d'
   mi estimate: mean race_wom`d'
   matrix ra`d' = e(b_mi)
   local ra`d' = ra`d'[1,1]
   local row = 41 +`d'
   putexcel B`row' = `ra`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean race_wom`d' if had_second_birth==1
   matrix bra`d' = e(b_mi)
   local bra`d' = bra`d'[1,1]
   local row = 41 + `d'
   putexcel C`row' = `bra`d'', nformat(##.#%)
}

* Same Race
mi estimate: mean couple_same_race
matrix sr = e(b_mi)
local sr = sr[1,1]
putexcel B47 = `sr', nformat(##.#%)

mi estimate, esampvaryok: mean couple_same_race if had_second_birth==1
matrix bsr = e(b_mi)
local bsr = bsr[1,1]
putexcel C47 = `bsr', nformat(##.#%)

* Moved States
mi estimate: mean moved_last_two
matrix mov = e(b_mi)
local mov = mov[1,1]
putexcel B48 = `mov', nformat(##.#%)

mi estimate, esampvaryok: mean moved_last_two if had_second_birth==1
matrix bmov = e(b_mi)
local bmov = bmov[1,1]
putexcel C48 = `bmov', nformat(##.#%)

* Had Premarital Birth
mi estimate: mean any_births_pre_rel
matrix pre = e(b_mi)
local pre = pre[1,1]
putexcel B49 = `pre', nformat(##.#%)

mi estimate, esampvaryok: mean any_births_pre_rel if had_second_birth==1
matrix bpre = e(b_mi)
local bpre = bpre[1,1]
putexcel C49 = `bpre', nformat(##.#%)

*******************************
* Time T-1
*******************************
* Hours
forvalues d=1/3{
   capture mi passive: gen hh_hours_t1x`d' = hh_hours_type_t1==`d'
   mi estimate: mean hh_hours_t1x`d'
   matrix h`d' = e(b_mi)
   local h`d' = h`d'[1,1]
   local row = 3 +`d'
   putexcel D`row' = `h`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean hh_hours_t1x`d' if had_second_birth==1
   matrix bh`d' = e(b_mi)
   local bh`d' = bh`d'[1,1]
   local row = 3 + `d'
   putexcel E`row' = `bh`d'', nformat(##.#%)
}

// mi estimate: proportion hh_hours_type_t1
// mi estimate: proportion hh_hours_type_t1 if had_second_birth==1

* HW
forvalues d=1/3{
   capture mi passive: gen housework_bkt_t1x`d' = housework_bkt_t1==`d'
   mi estimate: mean housework_bkt_t1x`d'
   matrix w`d' = e(b_mi)
   local w`d' = w`d'[1,1]
   local row = 6 +`d'
   putexcel D`row' = `w`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean housework_bkt_t1x`d' if had_second_birth==1
   matrix bw`d' = e(b_mi)
   local bw`d' = bw`d'[1,1]
   local row = 6 + `d'
   putexcel E`row' = `bw`d'', nformat(##.#%)
}

* Combined
forvalues d=1/5{
   capture mi passive: gen hours_hw_t1x`d' = hours_housework_t1==`d'
   mi estimate: mean hours_hw_t1x`d'
   matrix c`d' = e(b_mi)
   local c`d' = c`d'[1,1]
   local row = 9 +`d'
   putexcel D`row' = `c`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean hours_hw_t1x`d' if had_second_birth==1
   matrix bc`d' = e(b_mi)
   local bc`d' = bc`d'[1,1]
   local row = 9 + `d'
   putexcel E`row' = `bc`d'', nformat(##.#%)
}

* Employment
forvalues d=1/5{
   capture mi passive: gen couple_work_t1x`d' = couple_work_t1==`d'
   mi estimate: mean couple_work_t1x`d'
   matrix e`d' = e(b_mi)
   local e`d' = e`d'[1,1]
   local row = 14 +`d'
   putexcel D`row' = `e`d'', nformat(##.#%)
   
   mi estimate, esampvaryok: mean couple_work_t1x`d' if had_second_birth==1
   matrix be`d' = e(b_mi)
   local be`d' = be`d'[1,1]
   local row = 14 + `d'
   putexcel E`row' = `be`d'', nformat(##.#%)
}

* Raw hours
forvalues w=1/6{
	local row=`w'+19
	local var: word `w' of $cont_t1
	
	mi estimate: mean `var'
	matrix m`var' = e(b_mi)
	local m`var' = m`var'[1,1]
	putexcel D`row' = `m`var'', nformat(#####)
	
	mi estimate: mean `var' if had_second_birth==1
	matrix mb`var' = e(b_mi)
	local mb`var' = mb`var'[1,1]
	putexcel E`row' = `mb`var'', nformat(#####)
}

*******************************
* Uniques
*******************************
unique unique_id partner_id
unique unique_id partner_id if _mi_m==0
unique unique_id partner_id if had_second_birth==1
unique unique_id partner_id if had_second_birth==1 & _mi_m==0
