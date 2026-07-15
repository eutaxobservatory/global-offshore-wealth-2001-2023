//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose:  Fill household_share_sensitivity_template.xlsx 
//
// Output:
//   $tables/household_share_sensitivity_filled.xlsx
//
//----------------------------------------------------------------------------//

clear
set more off

if "$tables" == "" | "$work" == "" {
	di as error "Run code/00-master/0a-setup.do first so the path globals are defined."
	exit 198
}

local template "$tables/household_share_sensitivity_template.xlsx"
local out "$tables/household_share_sensitivity_filled.xlsx"

capture confirm file "`template'"
if _rc {
	di as error "Template not found: `template'"
	exit 601
}

copy "`template'" "`out'", replace

local scenarios "preferred minus10 plus10 allone freeze2007"
local cols "B C D E F"

// Sheet 1: total_attracted. Source is ofw_aggregate; variables are USD bn.
local attracted_iso "CHE GBR HKG SGP USA LUX ARE JEY CYM PAN IMN MAC BHS GGY CYP BHR BMU ofw"

putexcel set "`out'", sheet("total_attracted") modify
forvalues s = 1/5 {
	local sc : word `s' of `scenarios'
	local col : word `s' of `cols'

	use "$work/countries_hh_`sc'.dta", clear
	keep if year == 2023 & indicator=="total_attracted"

	forvalues r = 1/17 {
		local iso : word `r' of `attracted_iso'
		local row = `r' + 2
		quietly summarize value if iso3 == "`iso'", meanonly
		if r(N) > 0 {
			putexcel `col'`row' = (r(mean))
		}
	}

	quietly summarize value
	putexcel `col'20 = (r(sum))

}

// Sheet 2: total_owned. Preferred country-owned measure is total_russia_adjustment.
local owner_iso "USA CHN GBR TWN FRA SAU DEU ITA JPN RUS ESP CAN IND BRA IRL NLD BEL CYP"

putexcel set "`out'", sheet("total_owned") modify
forvalues s = 1/5 {
	local sc : word `s' of `scenarios'
	local col : word `s' of `cols'

	use "$work/countries_hh_`sc'.dta", clear
	keep if year == 2023 & indicator == "total_russia_adjustment"

	forvalues r = 1/18 {
		local iso : word `r' of `owner_iso'
		local row = `r' + 2
		quietly summarize value if iso3 == "`iso'", meanonly
		if r(N) > 0 {
			putexcel `col'`row' = (r(mean))
		}
	}
}

di as result "Wrote `out'"
