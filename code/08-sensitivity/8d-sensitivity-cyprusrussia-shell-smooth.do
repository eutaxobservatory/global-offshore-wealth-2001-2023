//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: Runs relevant do-files for 3 different types of assumptions:  Cyprus-Russia reallocation, Household-shell-company shares,  5-year moving average weights
//
// databases used: - "$work/countries`suffix'" (with suffix: "" _no_smoothing _no_hhshell _minus10pp_hhshell _70russiacyprus _90russiacyprus)
//
// outputs:        - "$work/countries_<assumption>.dta" (one per alternative assumption)
//                 - "$work/sensitivity_country_allocation_2023.dta"
//                 
//----------------------------------------------------------------------------//


/* Assumptions	                    Description
Our prefered estimates	            We use a 5-year moving average to smooth the development of offshore asset ownership over time because BIS deposits can be very volatile;  We reallocate 80%of Cyprus-owned Swiss fiduciary deposits to Russia  to avoid underestimating the true level of offshore wealth owned by Russian residents; For Belgium, the United Kingdom and the United States we respectively reallocate  50%, 50% and 20% of their offshore financial wealth holdings to residents in other countries because we assume that true ownership is concealed through shell companies. We further reallocate 75% of offshore financial wealth holdings of Ireland, and the Netherlands because their shares in financial center’s BIS deposits are strongly inflated by financial activities of multinational enterprises
70% Cyprus-Russia reallocation	    We reallocate 70% of Cyprus-owned Swiss fiduciary deposits to Russia
90% Cyprus-Russia reallocation	    We reallocate 90% of Cyprus-owned Swiss fiduciary deposits to Russia
Household-shell-company -10p.p. 	For Belgium, the United Kingdom, the United States, Ireland and the Netherlands we respectively reallocate  40%, 40%, 10%, 65% and 65% of their offshore financial wealth holdings to residents in other countries.
No household-shell-company      	For Belgium, the United Kingdom, the United States, Ireland and the Netherlands we do not respectively reallocate their offshore financial wealth holdings to residents in other countries.
No 5-year moving average weights	No 5-year moving average to smooth the development of offshore asset ownership over time */
*/

********************************************************************************
* Run each alternative assumption (one at a time)
********************************************************************************
// baseline files ("$work/offshore`i'.dta", "$work/countries.dta") are not overwritten:
// each assumption writes its own files with suffix "_<assumption>"

foreach scen in no_smoothing no_hhshell minus10pp_hhshell 70russiacyprus 90russiacyprus {
	* all assumptions at baseline, then change only one
	global smoothing_assumption baseline
	global hh_shell_assumption baseline
	global russiacyprus baseline
	if "`scen'" == "no_smoothing" global smoothing_assumption `scen'
	if inlist("`scen'", "no_hhshell", "minus10pp_hhshell") global hh_shell_assumption `scen'
	if inlist("`scen'", "70russiacyprus", "90russiacyprus") {
		global russiacyprus `scen'
		do "$do/06-swiss-fiduciary-build/6a-build-fiduciary.do"
	}
	do "$do/07-offshore-wealth-analysis/7a-build-offshore.do"
	do "$do/07-offshore-wealth-analysis/7d-build-countries.do"
}

* back to baseline
global smoothing_assumption baseline
global hh_shell_assumption baseline
global russiacyprus baseline


********************************************************************************
* Dataset: country allocation of offshore wealth in 2023 under each assumption
********************************************************************************

// stack the 6 versions side by side
tempfile robust
foreach tag in main 70russiacyprus 90russiacyprus minus10pp_hhshell no_hhshell no_smoothing {
	local s "_`tag'"
	if "`tag'" == "main" local s ""
	use "$work/countries`s'", clear
	keep if year == 2023 & indicator == "total_russia_adjustment"
	keep iso3 country_name value
	rename value value_`tag'
	if "`tag'" != "main" merge 1:1 country_name using `robust', nogenerate
	save `robust', replace
}

// top 20 + CYP RUS BEL GBR USA IRL NLD
gsort -value_main
keep if _n <= 20 | inlist(iso3, "CYP", "RUS", "BEL", "GBR", "USA", "IRL", "NLD")
keep iso3 country_name value_*
order iso3 country_name value_main value_70russiacyprus value_90russiacyprus ///
	value_minus10pp_hhshell value_no_hhshell value_no_smoothing
label var country_name            "Country"
label var value_main              "Our preferred estimates"
label var value_70russiacyprus    "70% Cyprus-Russia reallocation"
label var value_90russiacyprus    "90% Cyprus-Russia reallocation"
label var value_minus10pp_hhshell "Household-shell-company -10p.p."
label var value_no_hhshell        "No household-shell-company"
label var value_no_smoothing      "No 5-year moving average weights"
label data "Offshore wealth in 2023 (USD bn) by country under each assumption"

save "$work/sensitivity_country_allocation_2023.dta", replace
//----------------------------------------------------------------------------//
