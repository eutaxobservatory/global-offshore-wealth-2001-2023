//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
// 
// Purpose: produce TABLE A3 
//
// databases used: - "$tables\FGMZ_2025_Appendix_Tables.xlsx", sheets("Table A1" "Table A2")
//                 - "$temp\data_full_matrices.dta"
//				   - "$work\Table_A1_Global_Cross_Border_Securities_Assets.dta"
//				   - "$work\Table_A2_Global_Cross_Border_Securities_Liabilities.dta"
//
// outputs:        -$tables\FGMZ_2025_Appendix_Tables_A1_to_A3.xlsx"  sheet("Table A3")
//				   -"$work\Table_A3_Global_Discrepancy_Between_Cross_Border_Securities_Assets_and_Liabilities.dta"
//
//----------------------------------------------------------------------------//

// Path to the excel 
global myexcel "$tables\FGMZ_2025_Appendix_Tables_A1_to_A3.xlsx"

// Initialize dataset with years 2001–2023
// Equities sub-dataset 
clear
set obs 23
gen year = 2000 + _n
gen asset_type="Equities"
tempfile main_eq
save `main_eq', replace
// Debt sub-dataset
clear
set obs 23
gen year = 2000 + _n
gen asset_type="Debt"
tempfile main_debt
save `main_debt', replace





use "$temp\data_full_matrices.dta", clear
sort host year source
collapse (first) hostname eqliab_host derivedeqliab_host gapeq_host debtliab_host deriveddebtliab_host gapdebt_host, by(host year)

/*
// Discrepancy control column
preserve
collapse (sum) gapeq_host gapdebt_host, by(year)

foreach var of varlist gapeq_host gapdebt_host{
	replace `var'=`var'/1000
}

mkmat gapeq_host
mkmat gapdebt_host

putexcel R33 = matrix(gapeq_host)
putexcel R56 = matrix(gapdebt_host)
clear matrix
restore
*/

// Col. (4) - (11)

collapse (first) gapeq_host gapdebt_host, by(host year)

foreach var of varlist gapeq_host gapdebt_host{
	replace `var' = `var' / 1000
}

reshape wide gapeq_host gapdebt_host, i(year) j(host)
// Luxembourg, host == 137
// Cayman, host == 377
// Ireland, host==178
// USA, host == 111
// Japan host == 158
// Switzerland, host == 146

*equities 
preserve
keep year *eq*
rename gapeq_host137 invested_in_luxembourg
rename gapeq_host377 invested_in_cayman_islands
rename gapeq_host178 invested_in_ireland
rename gapeq_host111 invested_in_usa
rename gapeq_host158 invested_in_japan
rename gapeq_host146 invested_in_switzerland
keep year invested_in*
merge 1:1 year using `main_eq', nogen
tempfile main
save `main'
restore 
*debt 
keep year *debt*
rename gapdebt_host137 invested_in_luxembourg
rename gapdebt_host377 invested_in_cayman_islands
rename gapdebt_host178 invested_in_ireland
rename gapdebt_host111 invested_in_usa
rename gapdebt_host158 invested_in_japan
rename gapdebt_host146 invested_in_switzerland
keep year invested_in*
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'



// ALL SECURITIES 
preserve 
drop asset_type
collapse (sum) *_* , by(year )
gen asset_type="All Securities"
tempfile temp1
save `temp1'
restore 
merge 1:1 * using `temp1', nogen

sort asset_type year



// Col. 1 
preserve 
use "$work\Table_A1_Global_Cross_Border_Securities_Assets.dta", clear
keep year asset_type total_securities_assets
tempfile temp1
save `temp1'
restore 
merge 1:1 year asset_type using `temp1', nogen


// Col. 2 
preserve 
use "$work\Table_A2_Global_Cross_Border_Securities_Liabilities.dta", clear
keep year asset_type total_securities_liabilities
tempfile temp1
save `temp1'
restore 
merge 1:1 year asset_type using `temp1', nogen

sort asset_type year
// Col.3 
gen discrepancy= total_securities_liabilities - total_securities_assets

// Col. 11
gen invested_in_other=discrepancy-(invested_in_luxembourg + invested_in_cayman_islands + invested_in_ireland + invested_in_usa + invested_in_japan + invested_in_switzerland)

// Col. 12
bysort year: egen discrepancy_all=max(discrepancy)
gen offshore_asset_allocation= discrepancy/discrepancy_all*100
drop discrepancy_all 

// Col. 13
gen miss_wealth_cross_border=discrepancy/total_securities_liabilities*100

////////////////////////////////Dataset Cleaning\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
rename total_securities_assets global_securities_assets
rename total_securities_liabilities global_securities_liabilities
order year asset_type ///
global_securities_assets global_securities_liabilities discrepancy ///
invested_in_luxembourg invested_in_cayman_islands invested_in_ireland invested_in_usa invested_in_japan invested_in_switzerland invested_in_other ///
offshore_asset_allocation miss_wealth_cross_border 


gen byte sort_order = .
replace sort_order = 1 if asset_type == "All Securities"
replace sort_order = 2 if asset_type == "Equities"
replace sort_order = 3 if asset_type == "Debt"
sort sort_order year
drop sort_order 

gen unit="Billions of current USD"
label var unit "Units"
label variable year "Year (December 31st data)"
label variable asset_type "Asset type"

label variable global_securities_assets       "Global Securities Assets (ΣᵢΣⱼ Âᵢⱼ)"
label variable global_securities_liabilities  "Global Securities Liabilities (ΣⱼLⱼ)"
label variable discrepancy                     "Discrepancy (Ω = ΣⱼLⱼ − ΣᵢΣⱼ Âᵢⱼ)"

label variable invested_in_luxembourg         "Where missing securities are invested: Luxembourg"
label variable invested_in_cayman_islands     "Where missing securities are invested: Cayman Islands"
label variable invested_in_ireland            "Where missing securities are invested: Ireland"
label variable invested_in_usa                "Where missing securities are invested: United States"
label variable invested_in_japan              "Where missing securities are invested: Japan"
label variable invested_in_switzerland        "Where missing securities are invested: Switzerland"
label variable invested_in_other              "Where missing securities are invested: Other"

label variable offshore_asset_allocation      "Offshore asset allocation *100"
label variable miss_wealth_cross_border       "Missing wealth / Cross-border securities *100"


label data "Table A3 – Global Discrepancy Between Cross-Border Securities Assets and Liabilities"


// ------------------
// Save final dataset
// ------------------
save "$work\Table_A3_Global_Discrepancy_Between_Cross_Border_Securities_Assets_and_Liabilities.dta", replace
*use "$work\Table_A3_Global_Discrepancy_Between_Cross_Border_Securities_Assets_and_Liabilities.dta", clear
// Export to Excel
export excel using "$myexcel", sheet("Table A3") firstrow(varlabels) sheetmodify
