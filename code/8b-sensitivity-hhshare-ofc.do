//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: Runs relevant do-files for different household share assumptions
// as specified in the table "ofc_and_dep_assumptions.xlsx"
//----------------------------------------------------------------------------//


* save baseline
copy "$work/ofw_aggregate.dta" ///
	 "$work/ofw_aggregate_baseline.dta", replace

copy "$work/countries.dta" ///
	 "$work/countries_baseline.dta", replace


// Scenarios
// allone: household share = 1 for all OFCs (see excel sheet "allone")
// freeze: household share freezes at 2007 value for all OFCs (see excel sheet "freeze")
// hk_low: household share for Hong Kong reduced by 10pp (see excel sheet "hk_low")
// hk_high: household share for Hong Kong increased by 10pp (see excel sheet "hk_high")


foreach scenario in allone freeze hk_low hk_high  {

    global hh_scenario `scenario'

    // household share scenario: `scenario'
    do "$do/04-bis-deposits-build/4b-build-bis-01-23.do"
    do "$do/07-offshore-wealth-analysis/7a-build-offshore.do"
    do "$do/07-offshore-wealth-analysis/7c-build-global.do"
    do "$do/07-offshore-wealth-analysis/7d-build-countries.do"

    copy "$work/ofw_aggregate.dta" ///
         "$work/ofw_aggregate_hh_${hh_scenario}.dta", replace
    copy "$work/countries.dta" ///
         "$work/countries_hh_${hh_scenario}.dta", replace

}

* Restore baseline
copy "$work/ofw_aggregate_baseline.dta" ///
	 "$work/ofw_aggregate.dta", replace

copy "$work/countries_baseline.dta" ///
	 "$work/countries.dta", replace
//----------------------------------------------------------------------------//

