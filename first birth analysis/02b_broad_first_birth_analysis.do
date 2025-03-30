********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: broad_first_birth_analysis
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the first birth sample and runs analysis

// created in file 2a
use "$created_data/PSID_first_birth_sample_broad_RECODED.dta", clear

browse unique_id partner_id survey_yr rel_start_all marital_status_use relationship_duration had_first_birth joint_first_birth joint_first_birth_yr

tab relationship_duration had_first_birth, row m // should relationship duration be my discrete time indicator?
tab age_woman had_first_birth, row m  // or age?? I guess both should be in the models?

gen age_woman_sq = age_woman * age_woman

label values raceth_fixed_woman raceth_fixed_man raceth
label values marital_status_use marital_status_updated

mi passive: gen hh_hours_type_t1_x = hh_hours_type_t1
mi passive: replace hh_hours_type_t1_x = 1 if hh_hours_type_t1_x==4

mi estimate: proportion hh_hours_type_t1 hh_hours_type_t1_x

// with controls - per that Rindfuss article, do I need to interact age with these variables? bc some variables affect timing of births more than birth itself (and might have negative impact on timing but positive on completed fertility)
global controls "age_woman age_woman_sq couple_age_diff i.educ_type i.couple_joint_religion i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_last_two i.any_births_pre_rel"

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
mi estimate: logistic had_first_birth i.relationship_duration i.hh_hours_type_t1 $controls, or
mimrgns hh_hours_type_t1, predict(pr)
mimrgns, dydx(hh_hours_type_t1) predict(pr) post
estimates store est1

mi estimate: logistic had_first_birth i.relationship_duration i.hh_earn_type_t1 $controls, or
mimrgns hh_earn_type_t1, predict(pr)
mimrgns, dydx(hh_earn_type_t1) predict(pr) post
estimates store est1a

mi estimate: logistic had_first_birth i.relationship_duration i.couple_work_t1 $controls, or
mimrgns couple_work_t1, predict(pr)
mimrgns, dydx(couple_work_t1) predict(pr) post
estimates store est1b

coefplot (est1, nokey) (est1a, nokey) (est1b, nokey), drop(4.hh_hours_type_t1 4.hh_earn_type_t1) base nolabel xline(0) ///
coeflabels(1.hh_hours_type_t1 = "Dual Earner" 2.hh_hours_type_t1 = "Male Breadwinner" 3.hh_hours_type_t1 = "Female Breadwinner" 1.hh_earn_type_t1 = "Dual Earner" 2.hh_earn_type_t1 = "Male Breadwinner" 3.hh_earn_type_t1 = "Female Breadwinner" 1.couple_work_t1 = "Male Breadwinner" 2.couple_work_t1 = "1.5 Male Breadwinner" 3.couple_work_t1 = "Dual FT" 4.couple_work_t1 = "Female Breadwinner" 5.couple_work_t1 = "Underwork") headings(1.hh_hours_type_t1= "{bf:Division of Work Hours}"  1.hh_earn_type_t1 = "{bf:Division of Earnings}"   1.couple_work_t1 = "{bf:Employment Status}")

mi estimate: logistic had_first_birth i.relationship_duration i.housework_bkt_t1 $controls, or
mimrgns housework_bkt_t1,  predict(pr)
mimrgns, dydx(housework_bkt_t1)  predict(pr) post
estimates store est2

mi estimate: logistic had_first_birth i.relationship_duration i.hours_housework_t1 $controls, or
mimrgns hours_housework_t1, predict(pr)
mimrgns, dydx(hours_housework_t1) predict(pr) post
estimates store est3

mi estimate: logistic had_first_birth i.relationship_duration fertility_factor_t1 $controls if state_fips!=11, or
mimrgns, at(fertility_factor_t1=(-1(1)3)) cmdmargins predict(pr)
marginsplot
mimrgns, dydx(fertility_factor_t1) predict(pr) post
estimates store est4

mi estimate: logistic had_first_birth i.relationship_duration prek_enrolled_public_t1 $controls if state_fips!=11, or
mimrgns, dydx(prek_enrolled_public_t1) predict(pr) post
estimates store est4a

mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 $controls if state_fips!=11, or
mimrgns, dydx(paid_leave_t1) predict(pr) post
estimates store est4b

set scheme cleanplots

coefplot (est1, nokey) (est2, nokey) (est3, nokey) (est4, nokey) (est4a, nokey) (est4b, nokey), base drop(4.hh_hours_type_t1 4.hh_earn_type_t1 4.housework_bkt_t1) nolabel xline(0) xtitle(Average Marginal Effects, size(small)) ///
coeflabels(1.hh_hours_type_t1 = "Dual Earner" 2.hh_hours_type_t1 = "Male Breadwinner" 3.hh_hours_type_t1 = "Female Breadwinner"  1.housework_bkt_t1 = "Dual Housework" 2.housework_bkt_t1 = "Female Housework" 3.housework_bkt_t1 = "Male Housework" 1.hours_housework_t1 = "Egalitarian" 2.hours_housework_t1 = "Her Second Shift" 3.hours_housework_t1 = "Traditional" 4.hours_housework_t1 = "Counter Traditional" 5.hours_housework_t1 = "All Others" fertility_factor_t1= "Combined Policy" prek_enrolled_public_t1= "Public Pre-K Coverage" 0.paid_leave_t1 = "No Paid Leave" 1.paid_leave_t1 = "Paid Leave") ///
 headings(1.hh_hours_type_t1= "{bf:Division of Work Hours}"  1.housework_bkt_t1 = "{bf:Division of Housework}" 1.hours_housework_t1 = "{bf:Combined Division of Labor}" fertility_factor_t1="{bf:Work-Family Policy}")

// coefplot (est1, offset(.20) nokey lcolor("dkgreen") mcolor("dkgreen") ciopts(color("dkgreen"))) (est2, offset(.20) nokey lcolor("teal") mcolor("teal") ciopts(color("teal")))

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
mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.hh_hours_type_t1 c.fertility_factor_t1#i.hh_hours_type_t1 $controls if state_fips!=11, or
// outreg2 using "$results/first_birth_cons.xls", sideway stats(coef pval) label ctitle(Hours T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

mimrgns, dydx(hh_hours_type_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW" 3 "No Earners") rows(1)) // plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.hh_hours_type_t1 c.fertility_factor_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.hh_hours_type_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins post
	estimates store est5

	mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.hh_hours_type_t1 c.fertility_factor_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(3.hh_hours_type_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins post
	estimates store est6

	coefplot (est5, mcolor(navy) ciopts(color(navy)) label("Male BW")) (est6, label("Female BW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "-1.0" 2._at = "-0.5" 3._at = "0" 4._at = "0.5" 5._at = "1.0" 6._at = "1.5" 7._at = "2.0") ///
	xtitle(Average Marginal Effect Relative to Dual-Earning, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))

// Unpaid labor
mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.housework_bkt_t1 c.fertility_factor_t1#i.housework_bkt_t1 $controls if state_fips!=11, or
// outreg2 using "$results/first_birth_cons.xls", sideway stats(coef pval) label ctitle(HW T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mimrgns, dydx(housework_bkt_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.housework_bkt_t1 c.fertility_factor_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.housework_bkt_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins post
	estimates store est7

	mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.housework_bkt_t1 c.fertility_factor_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(3.housework_bkt_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins post
	estimates store est8

	coefplot (est7, mcolor(navy) ciopts(color(navy)) label("Female HW")) (est8, label("Male HW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "-1.0" 2._at = "-0.5" 3._at = "0" 4._at = "0.5" 5._at = "1.0" 6._at = "1.5" 7._at = "2.0") ///
	xtitle(Average Marginal Effect Relative to Dual Housework, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))

// Both
mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.hours_housework_t1 c.fertility_factor_t1#i.hours_housework_t1 $controls if state_fips!=11, or
// outreg2 using "$results/first_birth_cons.xls", sideway stats(coef pval) label ctitle(Combined T1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mimrgns, dydx(hours_housework_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.hours_housework_t1 c.fertility_factor_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.hours_housework_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins post
	estimates store est9

	mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.hours_housework_t1 c.fertility_factor_t1#i.hours_housework_t1 $controls  ///
	if state_fips!=11, or
	mimrgns, dydx(3.hours_housework_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins post
	estimates store est10

	mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.hours_housework_t1 c.fertility_factor_t1#i.hours_housework_t1 $controls  ///
	if state_fips!=11, or
	mimrgns, dydx(4.hours_housework_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins post
	estimates store est11
	
	mi estimate: logistic had_first_birth i.relationship_duration c.fertility_factor_t1 i.hours_housework_t1 c.fertility_factor_t1#i.hours_housework_t1 $controls  ///
	if state_fips!=11, or
	mimrgns, dydx(5.hours_housework_t1) at(fertility_factor_t1=(-1(0.5)2)) predict(pr) cmdmargins post
	estimates store est12

	coefplot (est9, mcolor(navy) ciopts(color(navy)) label("Second Shift")) (est10, label("Traditional")) (est11, label("Counter-Trad")) (est12, label("Other")) ///
	,  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "-1.0" 2._at = "-0.5" 3._at = "0" 4._at = "0.5" 5._at = "1.0" 6._at = "1.5" 7._at = "2.0") ///
	xtitle(Average Marginal Effect Relative to Egalitarian, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))

********************************************************************************	
**Public Pre-K Enrollment
********************************************************************************
// -fvset clear _all-

// Paid labor hours
mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.hh_hours_type_t1 c.prek_enrolled_public_t1#i.hh_hours_type_t1 $controls if state_fips!=11, or
sum prek_enrolled_public_t1, detail
mimrgns, dydx(hh_hours_type_t1) at(prek_enrolled_public_t1=(`r(min)'(.05)`r(max)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW" 3 "No Earners") rows(1)) // plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.hh_hours_type_t1 c.prek_enrolled_public_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(2.hh_hours_type_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est5a

	mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.hh_hours_type_t1 c.prek_enrolled_public_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(3.hh_hours_type_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est6a

	coefplot (est5a, mcolor(navy) ciopts(color(navy)) label("Male BW")) (est6a, label("Female BW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual-Earning, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Pre-K Enrollment}", angle(vertical))

// Unpaid labor
mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.housework_bkt_t1 c.prek_enrolled_public_t1#i.housework_bkt_t1 $controls if state_fips!=11, or
sum prek_enrolled_public_t1, detail
mimrgns, dydx(housework_bkt_t1) at(prek_enrolled_public_t1=(`r(min)'(.05)`r(max)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.housework_bkt_t1 c.prek_enrolled_public_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(2.housework_bkt_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est7a

	mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.housework_bkt_t1 c.prek_enrolled_public_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(3.housework_bkt_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est8a

	coefplot (est7a, mcolor(navy) ciopts(color(navy)) label("Female HW")) (est8a, label("Male HW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual Housework, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Pre-K Enrollment}", angle(vertical))

// Both
mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls if state_fips!=11, or
sum prek_enrolled_public_t1, detail
mimrgns, dydx(hours_housework_t1) at(prek_enrolled_public_t1=(`r(min)'(.05)`r(max)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(2.hours_housework_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est9a

	mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(3.hours_housework_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est10a

	mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum prek_enrolled_public_t1, detail
	mimrgns, dydx(4.hours_housework_t1) at(prek_enrolled_public_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est11a
	
	mi estimate: logistic had_first_birth i.relationship_duration c.prek_enrolled_public_t1 i.hours_housework_t1 c.prek_enrolled_public_t1#i.hours_housework_t1 $controls ///
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
mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.hh_hours_type_t1 i.paid_leave_t1#i.hh_hours_type_t1 $controls if state_fips!=11, or
mimrgns, dydx(hh_hours_type_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins
marginsplot, xtitle("Paid Leave") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) // plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.hh_hours_type_t1 i.paid_leave_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.hh_hours_type_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est5b

	mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.hh_hours_type_t1 i.paid_leave_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(3.hh_hours_type_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est6b

	coefplot (est5b, mcolor(navy) ciopts(color(navy)) label("Male BW")) (est6b, label("Female BW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "No Paid Leave" 2._at = "Has Paid Leave") ///
	xtitle(Average Marginal Effect Relative to Dual-Earning, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Paid Leave Status}", angle(vertical))
	
// Unpaid labor
mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.housework_bkt_t1 i.paid_leave_t1#i.housework_bkt_t1 $controls if state_fips!=11, or
mimrgns, dydx(housework_bkt_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins
marginsplot, xtitle("Paid Leave") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.housework_bkt_t1 i.paid_leave_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.housework_bkt_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est7b

	mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.housework_bkt_t1 i.paid_leave_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(3.housework_bkt_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est8b

	coefplot (est7b, mcolor(navy) ciopts(color(navy)) label("Female HW")) (est8b, label("Male HW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "No Paid Leave" 2._at = "Has Paid Leave") ///
	xtitle(Average Marginal Effect Relative to Dual Housework, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Paid Leave Status}", angle(vertical))

// Both
mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls if state_fips!=11, or
mimrgns, dydx(hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins
marginsplot, xtitle("Paid Leave") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(2.hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est9b

	mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(3.hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est10b

	mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	mimrgns, dydx(4.hours_housework_t1) at(paid_leave_t1=(0 1)) predict(pr) cmdmargins post
	estimates store est11b
	
	mi estimate: logistic had_first_birth i.relationship_duration i.paid_leave_t1 i.hours_housework_t1 i.paid_leave_t1#i.hours_housework_t1 $controls ///
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
mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 $controls if state_fips!=11, or
sum structural_familism_t1, detail
mimrgns, dydx(hh_hours_type_t1) at(structural_familism_t1=(`r(p5)'(1)`r(p95)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW" 3 "No Earners") rows(1)) // plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(2.hh_hours_type_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est5c

	mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hh_hours_type_t1 c.structural_familism_t1#i.hh_hours_type_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(3.hh_hours_type_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est6c

	coefplot (est5c, mcolor(navy) ciopts(color(navy)) label("Male BW")) (est6c, label("Female BW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual-Earning, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))

// Unpaid labor
mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 $controls if state_fips!=11, or
sum structural_familism_t1, detail
mimrgns, dydx(housework_bkt_t1) at(structural_familism_t1=(`r(p5)'(1)`r(p95)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(2.housework_bkt_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est7c

	mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.housework_bkt_t1 c.structural_familism_t1#i.housework_bkt_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(3.housework_bkt_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est8c

	coefplot (est7c, mcolor(navy) ciopts(color(navy)) label("Female HW")) (est8c, label("Male HW")),  drop(_cons) nolabel xline(0, lcolor("red")) levels(95) ///
	coeflabels(1._at = "10th ptile" 2._at = "25th ptile" 3._at = "50th ptile" 4._at = "75th ptile" 5._at = "90th ptile") ///
	xtitle(Average Marginal Effect Relative to Dual Housework, size(small)) legend(position(bottom) rows(1)) groups(?._at = "{bf:Structural Support Scale}", angle(vertical))

// Both
mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls if state_fips!=11, or
sum structural_familism_t1, detail
mimrgns, dydx(hours_housework_t1) at(structural_familism_t1=(`r(p5)'(1)`r(p95)')) predict(pr) cmdmargins
marginsplot, xtitle("Public Pre-K Enrollment") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))

	// alt charts
	mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(2.hours_housework_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est9c

	mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(3.hours_housework_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est10c

	mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls ///
	if state_fips!=11, or
	sum structural_familism_t1, detail
	mimrgns, dydx(4.hours_housework_t1) at(structural_familism_t1=(`r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)')) predict(pr) cmdmargins post
	estimates store est11c
	
	mi estimate: logistic had_first_birth i.relationship_duration c.structural_familism_t1 i.hours_housework_t1 c.structural_familism_t1#i.hours_housework_t1 $controls ///
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
// Not Yet Updated

/*
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"
logistic had_first_birth i.relationship_duration i.hh_hours_type_t2 `controls' if hh_hours_type_t2 < 4 & rel_start_yr>=2005
margins, dydx(hh_hours_type_t2) level(90) post
estimates store est9

logistic had_first_birth i.relationship_duration i.hh_earn_type_t2 `controls' if hh_earn_type_t2 < 4 & rel_start_yr>=2005
margins, dydx(hh_earn_type_t2) level(90) post
estimates store est10

logistic had_first_birth i.relationship_duration i.housework_bkt_t2_imp `controls' if housework_bkt_t2_imp < 4 & rel_start_yr>=2005
margins, dydx(housework_bkt_t2_imp) level(90) post
estimates store est11

logistic had_first_birth i.relationship_duration i.hours_housework_t2_imp `controls' if rel_start_yr>=2005
margins, dydx(hours_housework_t2_imp) level(90) post
estimates store est12

coefplot est9 est10 est11 est12,  drop(_cons) nolabel xline(0) levels(90)

set scheme cleanplots

coefplot (est9, offset(.20) nokey lcolor("dkgreen") mcolor("dkgreen") ciopts(color("dkgreen"))) (est10, offset(.20) nokey lcolor("teal") mcolor("teal") ciopts(color("teal"))) (est11, offset(-.20) nokey lcolor("navy") mcolor("navy") ciopts(color("navy"))) (est12, offset(-.20) nokey), drop(_cons) xline(0) levels(90) base xtitle(Average Marginal Effect Relative to Egalitarian Arrangement, size(small)) ///
coeflabels(2.hh_hours_type_t2 = "Male Breadwinner" 3.hh_hours_type_t2 = "Female Breadwinner" 2.hh_earn_type_t2 = "Male Breadwinner" 3.hh_earn_type_t2 = "Female Breadwinner" 1.housework_bkt_t2_imp = "Dual Housework" 2.housework_bkt_t2_imp = "Female Housework" 3.housework_bkt_t2_imp = "Male Housework" 1.hours_housework_t2_imp = "Egalitarian" 2.hours_housework_t2_imp = "Her Second Shift" 3.hours_housework_t2_imp = "Traditional" 4.hours_housework_t2_imp = "Counter Traditional" 5.hours_housework_t2_imp = "All Others") ///
 headings(1.hh_hours_type_t2= "{bf:Division of Work Hours}"   1.hh_earn_type_t2 = "{bf:Division of Earnings}"   1.housework_bkt_t2_imp = "{bf:Division of Housework}"  1.hours_housework_t2_imp = "{bf:Combined Division of Labor}")
 // (est3, offset(-.20) label(College)) 
 
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"
logistic had_first_birth i.relationship_duration structural_familism_t2 `controls' if state_fips!=11 & rel_start_yr>=2005
margins, at(structural_familism_t2=(-5(1)10))
marginsplot, ytitle(Predicted Probability of First Birth) xtitle(Structural Support for Working Families) plot1opts(lcolor("eltgreen") mcolor("eltgreen")) ci1opts(color("eltgreen"))
margins, dydx(structural_familism_t2)

set scheme stcolor

**Interactions
local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t2 i.couple_joint_religion_t2 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t2_ln i.moved_states_lag"

// Paid labor
* interaction with hours
logistic had_first_birth i.relationship_duration c.structural_familism_t2 i.hh_hours_type_t2 c.structural_familism_t2#i.hh_hours_type_t2 `controls' if hh_hours_type_t2 < 4 & state_fips!=11 & rel_start_yr>=2005

sum structural_familism_t2, detail
margins, dydx(hh_hours_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5)) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

* interaction with earnings
logistic had_first_birth i.relationship_duration c.structural_familism_t2 i.hh_earn_type_t2 c.structural_familism_t2#i.hh_earn_type_t2 `controls' if hh_earn_type_t2 < 4 & state_fips!=11 & rel_start_yr>=2005

sum structural_familism_t2, detail
margins, dydx(hh_earn_type_t2) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5)) // xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") 

// Unpaid labor - est
logistic had_first_birth i.relationship_duration c.structural_familism_t2 i.housework_bkt_t2_imp c.structural_familism_t2#i.housework_bkt_t2_imp `controls' if housework_bkt_t2_imp < 4 & state_fips!=11 & rel_start_yr>=2005

sum structural_familism_t2, detail
margins, dydx(housework_bkt_t2_imp) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Female HW" 2 "Male HW") rows(1)) plot2opts(lcolor("gs12") mcolor("gs12")) ci2opts(color("gs12")) ci1opts(lwidth(*1.5))

// Both - est
logistic had_first_birth i.relationship_duration c.structural_familism_t2 i.hours_housework_t2_imp c.structural_familism_t2#i.hours_housework_t2_imp `controls' if state_fips!=11 & rel_start_yr>=2005

sum structural_familism_t2, detail
margins, dydx(hours_housework_t2_imp) at(structural_familism_t2=(`r(min)'(1)`r(max)'))
marginsplot, xtitle("Structural Support for Working Families") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: First Birth") title("") legend(position(6) ring(3) order(1 "Second Shift" 2 "Traditional" 3 "Counter" 4 "Other") rows(1)) plot1opts(lcolor("pink") mcolor("pink")) ci1opts(color("pink")) plot2opts(lcolor("midblue") mcolor("midblue")) ci2opts(color("midblue")) plot3opts(lcolor("gs13") mcolor("none")) ci3opts(color("gs13")) plot4opts(lcolor("gs8") mcolor("none")) ci4opts(color("gs8"))
*/
********************************************************************************
********************************************************************************
********************************************************************************
**# Descriptive statistics
********************************************************************************
********************************************************************************
********************************************************************************

// main IVs t: hh_hours_type hh_earn_type housework_bkt hours_housework couple_work structural_familism_t
// t-1: hh_hours_type_t1 hh_earn_type_t1 housework_bkt_t1_imp hours_housework_t1_imp couple_work_t1 structural_familism_t1
// t-2: hh_hours_type_t2 hh_earn_type_t2 housework_bkt_t2_imp hours_housework_t2_imp couple_work_t2 structural_familism_t2
// for ref: local controls "age_woman age_woman_sq couple_age_diff i.educ_type_t1 i.couple_joint_religion_t1 i.raceth_fixed_woman i.couple_same_race i.marital_status_use couple_earnings_t1_ln i.moved_states_lag" 
// relationship_duration

tab hh_hours_type housework_bkt, cell nofreq

foreach var in hh_hours_type hh_earn_type housework_bkt hours_housework couple_work hh_hours_type_t1 hh_earn_type_t1 housework_bkt_t1_imp hours_housework_t1_imp couple_work_t1 hh_hours_type_t2 hh_earn_type_t2 housework_bkt_t2_imp hours_housework_t2_imp couple_work_t2 educ_type educ_type_t1 educ_type_t2 couple_joint_religion couple_joint_religion_t1 couple_joint_religion_t2 raceth_fixed_woman couple_same_race marital_status_use moved_states_lag{
	tab `var', gen(`var')
}

putexcel set "$results/First_birth-descriptives_broad", replace
putexcel B1:C1 = "Time t", merge border(bottom)
putexcel D1:E1 = "Time t-1", merge border(bottom)
putexcel F1:G1 = "Time t-2", merge border(bottom)
putexcel B2 = ("All") C2 = ("Had First Birth") D2 = ("All") E2 = ("Had First Birth") F2 = ("All") G2 = ("Had First Birth")
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
putexcel A27 = "Married"
putexcel A28 = "Cohab"
putexcel A29 = "Total Couple Earnings"
putexcel A30 = "Neither College Degree"
putexcel A31 = "His College Degree"
putexcel A32 = "Her College Degree"
putexcel A33 = "Both College Degree"
putexcel A34 = "Both No Religion"
putexcel A35 = "Both Catholic"
putexcel A36 = "Both Protestant"
putexcel A37 = "One Catholic"
putexcel A38 = "One No Religion"
putexcel A39 = "Other Religion"
putexcel A40 = "Woman's Race: NH White"
putexcel A41 = "Woman's Race: Black"
putexcel A42 = "Woman's Race: Hispanic"
putexcel A43 = "Woman's Race: NH Asian"
putexcel A44 = "Woman's Race: NH Other"
putexcel A45 = "Husband and wife same race"
putexcel A46 = "Moved States"

local tvars "hh_hours_type1 hh_hours_type2 hh_hours_type3 hh_earn_type1 hh_earn_type2 hh_earn_type3 housework_bkt1 housework_bkt2 housework_bkt3 hours_housework1 hours_housework2 hours_housework3 hours_housework4 hours_housework5 couple_work1 couple_work2 couple_work3 couple_work4 couple_work5 structural_familism_t age_woman age_man relationship_duration marital_status_use1 marital_status_use2 couple_earnings educ_type1 educ_type2 educ_type3 educ_type4 couple_joint_religion1 couple_joint_religion2 couple_joint_religion3 couple_joint_religion4 couple_joint_religion5 couple_joint_religion6 raceth_fixed_woman1 raceth_fixed_woman2 raceth_fixed_woman3 raceth_fixed_woman4 raceth_fixed_woman5 couple_same_race2 moved_states_lag2"
// 43

local t1vars "hh_hours_type_t11 hh_hours_type_t12 hh_hours_type_t13 hh_earn_type_t11 hh_earn_type_t12 hh_earn_type_t13 housework_bkt_t1_imp1 housework_bkt_t1_imp2 housework_bkt_t1_imp3 hours_housework_t1_imp1 hours_housework_t1_imp2 hours_housework_t1_imp3 hours_housework_t1_imp4 hours_housework_t1_imp5 couple_work_t11 couple_work_t12 couple_work_t13 couple_work_t14 couple_work_t15 structural_familism_t1 age_woman age_man relationship_duration marital_status_use1 marital_status_use2 couple_earnings_t1 educ_type_t11 educ_type_t12 educ_type_t13 educ_type_t14 couple_joint_religion_t11 couple_joint_religion_t12 couple_joint_religion_t13 couple_joint_religion_t14 couple_joint_religion_t15 couple_joint_religion_t16"
// 36

local t2vars "hh_hours_type_t21 hh_hours_type_t22 hh_hours_type_t23 hh_earn_type_t21 hh_earn_type_t22 hh_earn_type_t23 housework_bkt_t2_imp1 housework_bkt_t2_imp2 housework_bkt_t2_imp3 hours_housework_t2_imp1 hours_housework_t2_imp2 hours_housework_t2_imp3 hours_housework_t2_imp4 hours_housework_t2_imp5 couple_work_t21 couple_work_t22 couple_work_t23 couple_work_t24 couple_work_t25 structural_familism_t1 age_woman age_man relationship_duration marital_status_use1 marital_status_use2 couple_earnings_t2 educ_type_t21 educ_type_t22 educ_type_t23 educ_type_t24 couple_joint_religion_t21 couple_joint_religion_t22 couple_joint_religion_t23 couple_joint_religion_t24 couple_joint_religion_t25 couple_joint_religion_t26"
// 36

// Total Sample, time t
forvalues w=1/43{
	local row=`w'+3
	local var: word `w' of `tvars'
	mean `var'
	matrix t`var'= e(b)
	putexcel B`row' = matrix(t`var'), nformat(#.#%)
}

// those with first birth
forvalues w=1/43{
	local row=`w'+3
	local var: word `w' of `tvars' 
	mean `var' if had_first_birth==1
	matrix t`var'= e(b)
	putexcel C`row' = matrix(t`var'), nformat(#.#%)
}

// Total Sample, time t-1
forvalues w=1/36{
	local row=`w'+3
	local var: word `w' of `t1vars'
	mean `var'
	matrix t`var'= e(b)
	putexcel D`row' = matrix(t`var'), nformat(#.#%)
}

// those with first birth
forvalues w=1/36{
	local row=`w'+3
	local var: word `w' of `t1vars' 
	mean `var' if had_first_birth==1
	matrix t`var'= e(b)
	putexcel E`row' = matrix(t`var'), nformat(#.#%)
}


// Total Sample, time t-2
forvalues w=1/36{
	local row=`w'+3
	local var: word `w' of `t2vars'
	mean `var'
	matrix t`var'= e(b)
	putexcel F`row' = matrix(t`var'), nformat(#.#%)
}

// those with first birth
forvalues w=1/36{
	local row=`w'+3
	local var: word `w' of `t2vars' 
	mean `var' if had_first_birth==1
	matrix t`var'= e(b)
	putexcel G`row' = matrix(t`var'), nformat(#.#%)
}

unique unique_id partner_id
unique unique_id partner_id if had_first_birth==1
