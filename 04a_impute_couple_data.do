********************************************************************************
********************************************************************************
* Project: Policy and Fertility
* Owner: Kimberly McErlean
* Started: October 2024
* File: impute_couple_data
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************

use "$created_data/PSID_couple_births_shared.dta", clear

browse unique_id partner_id survey_yr rel_start_yr relationship_duration in_sample // okay, one problem with doing here is that I haven't yet matched partner data. Do I need to do that first?
// Unless I want to impute the individual level data? that feels crazy, especially if I won't use those people.