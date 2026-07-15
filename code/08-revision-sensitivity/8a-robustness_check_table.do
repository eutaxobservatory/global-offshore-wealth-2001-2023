//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: generate several robustness checks tables for 2023:  Cyprus-Russia reallocation, Household-shell-company shares,  5-year moving average weights
//
// databases used: - "$work/countries`suffix'" (with suffix:   """  no_hhshell minus10pp_hhshell 70russiacyprus 90russiacyprus)
//
// outputs:        - "$tables/sensitivity_country_allocation_filled.xlsx"
//                 
//----------------------------------------------------------------------------//


local template "$tables/sensitivity_country_allocation_template.xlsx"
local out "$tables/sensitivity_country_allocation_filled.xlsx"

capture confirm file "`template'"
if _rc {
	di as error "Template not found: `template'"
	exit 601
}


*--------------0.1 - Suffix loop over all sensitivity assumptions  -----------*
local suffix_tags "main no_smoothing no_hhshell minus10pp_hhshell 70russiacyprus 90russiacyprus"
foreach tag of local suffix_tags {
local suffix "_`tag'"
if "`tag'" == "main" local suffix ""


use "$work/countries`suffix'", clear
keep if year==2023
keep if indicator== "total_russia_adjustment" | indicator=="total_attracted"
rename value value`suffix'
save "$temp/countries2023`suffix'.dta", replace

}

local suffix_tags "no_smoothing no_hhshell minus10pp_hhshell 70russiacyprus 90russiacyprus"
use "$temp/countries2023.dta"
foreach tag of local suffix_tags {
local suffix "_`tag'"
merge 1:1 country_name year indicator using "$temp/countries2023`suffix'.dta", nogenerate
}
save "$work/countries2023_robustness.dta", replace


********************************************************************************
* Table A: total_russia_adjustment in 2023
********************************************************************************

use "$work/countries2023_robustness.dta", clear
keep if indicator=="total_russia_adjustment"
* Top 20 by value, always including CYP RUS BEL GBR USA IRL NLD
gsort -value
gen rank = _n
keep if rank <= 20 | inlist(iso3, "CYP", "RUS", "BEL", "GBR", "USA", "IRL", "NLD")
drop rank

//Our prefered estimates	70% Cyprus-Russia reallocation	90% Cyprus-Russia reallocation	Household-shell-company -10p.p.	No household-shell-company 	No 5-year moving average weights
order country_name value value_70russiacyprus value_90russiacyprus value_minus10pp_hhshell value_no_hhshell value_no_smoothing
keep country_name value*


// Fill Excel template.
copy "`template'" "`out'", replace

putexcel set "`out'", sheet("total_russia_adjustment") modify
* Write country names (string) starting at A3
quietly forvalues i = 1/`=_N' {
    local row = `i' + 2
    putexcel A`row' = "`=country_name[`i']'"
}

* Write numeric columns as matrix starting at B3
mkmat value value_70russiacyprus value_90russiacyprus value_minus10pp_hhshell value_no_hhshell value_no_smoothing, matrix(M)
putexcel B3 = matrix(M)

********************************************************************************
* Table B: total_attracted in 2023
********************************************************************************

use "$work/countries2023_robustness.dta", clear
keep if indicator=="total_attracted"
* Top 20 by value, always including CYP RUS BEL GBR USA IRL NLD
gsort -value
gen rank = _n
keep if rank <= 20 | inlist(iso3, "CYP", "RUS", "BEL", "GBR", "USA", "IRL", "NLD")
drop rank

//Our prefered estimates	70% Cyprus-Russia reallocation	90% Cyprus-Russia reallocation	Household-shell-company -10p.p.	No household-shell-company 	No 5-year moving average weights
order country_name value value_70russiacyprus value_90russiacyprus value_minus10pp_hhshell value_no_hhshell value_no_smoothing
keep country_name value*

putexcel set "`out'", sheet("total_attracted") modify
* Write country names (string) starting at A3
quietly forvalues i = 1/`=_N' {
    local row = `i' + 2
    putexcel A`row' = "`=country_name[`i']'"
}

* Write numeric columns as matrix starting at B3
mkmat value value_70russiacyprus value_90russiacyprus value_minus10pp_hhshell value_no_hhshell value_no_smoothing, matrix(M)
putexcel B3 = matrix(M)
