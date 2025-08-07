//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: import EWN-dataset_12-2022
//
// databases used: - "$raw\ewn\EWN-database-January-2025.xlsx"
//
// outputs:        - "$temp\data_ewn_update.dta"
//
//----------------------------------------------------------------------------//

//Import external wealth of nations dataset
*link:
*https://www.brookings.edu/research/the-external-wealth-of-nations-database/
import excel using "$raw\ewn\EWN-database-January-2025.xlsx", sheet(Dataset) firstrow clear
rename (Year IFS_Code Portfolioequityassets Portfolioequityliabilities Debtassets Debtliabilities Portfoliodebtassets Portfoliodebtliabilities Country GDPUS) (year source aequity lequity adebt ldebt aportif_debt lportif_debt country gdp_us) 
gen ewn = 1
drop if year < 2001
keep year source country aequity adebt aportif_debt lequity lportif_debt gdp_us ewn

*Harmonise ifscode
replace source = 371 if source == 379 //British Virgin Islands
drop if country == "ECCU" | country == "Euro Area"

preserve

	//unify curacao and sint Maarten into one line by adding up (in IMF they go together under 355)
	keep if source == 354 | source == 352
	replace source = 355 if source == 354 | source == 352

	collapse (first) ewn country (sum) aequity lequity adebt gdp_us aportif_debt lportif_debt, by(source year)
	foreach var of varlist aequity lequity adebt gdp_us aportif_debt lportif_debt{
		replace `var' = . if `var' == 0
}	
	replace country = "Curacao and Sint Maarten"
	tempfile curacao
	save `curacao'
restore
drop if source == 354 | source == 352
append using `curacao'
save "$temp\data_ewn_update.dta", replace


//----------------------------------------------------------------------------//

