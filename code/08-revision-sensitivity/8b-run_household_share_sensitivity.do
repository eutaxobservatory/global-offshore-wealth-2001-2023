//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: Run household-share sensitivity scenarios for the general table.
//
// Prerequisite: the baseline replication has already produced global_portfolio_gap,
// fiduciary data, GDP, CDIS/FDi inputs, UAE deposits, and locational.dta.
//                 
//----------------------------------------------------------------------------//


clear
set more off
set graphics off
cap log close

if "$do" == "" | "$work" == "" {
	di as error "Run code/00-master/0a-setup.do first so the path globals are defined."
	exit 198
}

capture confirm file "$work/global_portfolio_gap.dta"
if _rc {
	di as error "Run the full baseline pipeline first: do $do/00-master/0b-run.do"
	exit 601
}

local scenarios "preferred minus10 plus10 allone freeze2007"

foreach sc of local scenarios {
	di as text "Running household-share scenario: `sc'"
	global hh_scenario "`sc'"

	do "$do/04-bis-deposits-build/4b-build-bis-01-23.do"
	do "$do/07-offshore-wealth-analysis/7a-build-offshore.do"
	do "$do/07-offshore-wealth-analysis/7c-build-countries.do"

	copy "$work/ofw_aggregate.dta" "$work/ofw_aggregate_hh_`sc'.dta", replace
	copy "$work/countries.dta" "$work/countries_hh_`sc'.dta", replace
}

macro drop hh_scenario
