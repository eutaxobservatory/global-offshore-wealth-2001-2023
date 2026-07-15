//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: Build Hong Kong tables for the China/Hong Kong robustness check
//
// Output:
//   $tables/hong_kong_bilateral_filled.xlsx
//----------------------------------------------------------------------------//

clear
set more off
set graphics off

if "$do" == "" | "$work" == "" | "$tables" == "" {
	di as error "Run code/00-master/0a-setup.do first so the path globals are defined."
	exit 198
}

local template "$tables/hong_kong_bilateral_template.xlsx"
local out "$tables/hong_kong_bilateral_filled.xlsx"

capture confirm file "`template'"
if _rc {
	di as error "Template not found: `template'"
	exit 601
}

// 1. Observed Hong Kong bilateral BIS deposits.
capture confirm file "$work/locational.dta"
if _rc {
	do "$do/04-bis-deposits-build/4a-import-bis.do"
}

use "$work/locational.dta", clear
keep if bank == "HK" & position == "L" & instrument == "A" & sector == "N" & parent == "5J"
keep if inrange(year, 2014, 2023)
keep if inlist(counter, "5J", "GB", "CN", "HK")

// Annual mean, matching the bilateral-deposit construction in 4b.
// For end-year Q4 stocks instead, add: keep if quarter == 4
collapse (mean) value, by(year counter)
reshape wide value, i(year) j(counter) string

foreach c in 5J GB CN HK {
	capture confirm numeric variable value`c'
	if _rc gen value`c' = .
}

rename value5J hk_total
rename valueGB hk_uk
rename valueCN hk_china
rename valueHK hk_hk_residents

gen uk_share = hk_uk / hk_total
gen china_share = hk_china / hk_total

save "$work/hk_bilateral_deposits_2014_2023.dta", replace

// 2. Run only the HK-specific household-share scenarios needed for the shock table.
local hk_scenarios "preferred hk_low hk_high"
foreach sc of local hk_scenarios {
	capture confirm file "$work/ofw_aggregate_hh_`sc'.dta"
	if _rc {
		di as text "Running Hong Kong household-share scenario: `sc'"
		global hh_scenario "`sc'"
		do "$do/04-bis-deposits-build/4b-build-bis-01-23.do"
		do "$do/07-offshore-wealth-analysis/7a-build-offshore.do"
		do "$do/07-offshore-wealth-analysis/7c-build-countries.do"
		copy "$work/ofw_aggregate.dta" "$work/ofw_aggregate_hh_`sc'.dta", replace
	}
}
macro drop hh_scenario

// 3. Fill Excel template.
copy "`template'" "`out'", replace

putexcel set "`out'", sheet("hk_evolution") modify
use "$work/hk_bilateral_deposits_2014_2023.dta", clear
forvalues y = 2014/2023 {
	local row = `y' - 2011
	quietly summarize hk_total if year == `y', meanonly
	putexcel B`row' = (r(mean))
	quietly summarize hk_uk if year == `y', meanonly
	putexcel C`row' = (r(mean))
	quietly summarize hk_china if year == `y', meanonly
	putexcel D`row' = (r(mean))
}

// 2023 observed shares for the shock table.
use "$work/hk_bilateral_deposits_2014_2023.dta", clear
keep if year == 2023

quietly summarize hk_total, meanonly
local hk_total = r(mean)
quietly summarize hk_uk, meanonly
local hk_uk = r(mean)
quietly summarize hk_china, meanonly
local hk_china = r(mean)
quietly summarize hk_hk_residents, meanonly
if r(N) > 0 {
	local hk_hk = r(mean)
}
else {
	local hk_hk = .
}

local sh_uk = `hk_uk' / `hk_total'
local sh_cn = `hk_china' / `hk_total'
local sh_cn_low = max(`sh_cn' - .10, 0)
local sh_cn_high = min(`sh_cn' + .10, 1)
if missing(`hk_hk') {
	local sh_cn_hk = .
}
else {
	local sh_cn_hk = min((`hk_china' + `hk_hk') / `hk_total', 1)
}

foreach sc in preferred hk_low hk_high {
	use "$work/ofw_aggregate_hh_`sc'.dta", clear
	keep if year == 2023
	quietly summarize depHK, meanonly
	local ofwHK_`sc' = r(mean)
}

putexcel set "`out'", sheet("hk_assumption_shocks") modify

// Rows 3-5: observed BIS deposits. Rows 6-8: implied offshore wealth in USD bn.
putexcel B3 = (`hk_total') C3 = (`hk_total') D3 = (`hk_total') E3 = (`hk_total') F3 = (`hk_total') G3 = (`hk_total')
putexcel B4 = (`hk_uk') C4 = (`hk_uk') D4 = (`hk_uk') E4 = (`hk_uk') F4 = (`hk_uk') G4 = (`hk_uk')
putexcel B5 = (`hk_china') C5 = (`hk_china') D5 = (`hk_china') E5 = (`hk_total' * `sh_cn_low') F5 = (`hk_total' * `sh_cn_high') G5 = (`hk_total' * `sh_cn_hk')

putexcel B6 = (`ofwHK_preferred') C6 = (`ofwHK_hk_low') D6 = (`ofwHK_hk_high') E6 = (`ofwHK_preferred') F6 = (`ofwHK_preferred') G6 = (`ofwHK_preferred')
putexcel B7 = (`ofwHK_preferred' * `sh_cn') C7 = (`ofwHK_hk_low' * `sh_cn') D7 = (`ofwHK_hk_high' * `sh_cn') E7 = (`ofwHK_preferred' * `sh_cn_low') F7 = (`ofwHK_preferred' * `sh_cn_high') G7 = (`ofwHK_preferred' * `sh_cn_hk')
putexcel B8 = (`ofwHK_preferred' * `sh_uk') C8 = (`ofwHK_hk_low' * `sh_uk') D8 = (`ofwHK_hk_high' * `sh_uk') E8 = (`ofwHK_preferred' * `sh_uk') F8 = (`ofwHK_preferred' * `sh_uk') G8 = (`ofwHK_preferred' * `sh_uk')

di as result "Wrote `out'"
