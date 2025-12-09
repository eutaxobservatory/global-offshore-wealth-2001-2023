//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: produce TABLE A2 "Global Cross-Border Securities Liabilities" 
// (total liabilities and corrections)
//
// databases used: - "$temp\data_full_matrices.dta"
//                 - "$temp\IIP_eqliab.dta"
//                 - "$temp\IIP_debtliab.dta"
//
// outputs:        - "$tables\FGMZ_2025_Appendix_Tables_A1_to_A3.xlsx" sheet(Table A2)
//				   - "$work\Table_A2_Global_Cross_Border_Securities_Liabilities.dta"
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



// Col. (1)
use "$temp\data_full_matrices.dta", clear
sort host year source
collapse (first) hostname ewn_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt, by(host year)

collapse (sum) lequity_host lportif_debt_host, by(year)
foreach var of varlist lequity_host lportif_debt_host{
	replace `var'=`var' / 1000
}
mkmat lequity_host 
mkmat lportif_debt_host

*equities 
preserve
keep year *eq*
rename lequity_host ewn2
merge 1:1 year using `main_eq', nogen
tempfile temp1
save `temp1'
restore 
*debt 
keep year *debt*
rename lportif_debt_host ewn2
merge 1:1 year using `main_debt', nogen
*both
merge 1:1 year asset_type using `temp1', nogen
tempfile main
save `main'



// Col. (3): no portfolio debt data in EWNII, but data in IMF IIP or derived debt liab 
use "$temp\data_full_matrices.dta", clear
sort host year source
collapse (first) hostname ewn_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt, by(host year)

*equities
preserve
keep if ewn_host == 1 & lportif_debt_host == .
collapse (sum) debtliab_host, by(year)
foreach var of varlist debtliab_host{
	replace `var' = `var' / 1000
}
rename debtliab_host correc_ewn2_nodata
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'
restore

* debt
keep if ewn_host == 1 & lequity_host == .
collapse (sum) eqliab_host, by(year)
foreach var of varlist eqliab_host{
	replace `var' = `var' / 1000
}
rename eqliab_host correc_ewn2_nodata
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'

// Col. (4): Dutch SFIs
use "$temp\data_full_matrices.dta", clear

keep if host == 138
collapse (mean) lequity_SFI ldebt_SFI, by(year)
foreach var of varlist lequity_SFI ldebt_SFI{
	replace `var' = `var' / 1000
}
*equities 
preserve
keep year *eq*
rename lequity_SFI correc_ewn2_nld_sfis
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'
restore 
*debt 
keep year *debt*
rename ldebt_SFI correc_ewn2_nld_sfis
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'




// col. (5): raw cpis derived liabilities > reported liabilities
use "$temp\data_full_matrices.dta", clear

sort host year source
collapse (first) hostname ewn_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt ofc_host, by(host year)


version 16: table year, c(sum missingliabeq sum missingliabdebt) format(%12.0fc)
version 16: table year if host != 377, c(sum missingliabeq sum missingliabdebt) format(%12.0fc)
keep if host != 377
collapse (sum) missingliabeq missingliabdebt, by(year)
foreach var of varlist missingliabeq missingliabdebt{
	replace `var' = `var' / 1000
}

*equities 
preserve
keep year *eq*
rename missingliabeq correc_ewn2_rawcpis
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'
restore 
*debt 
keep year *debt*
rename missingliabdebt correc_ewn2_rawcpis
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'

// Col. (6), (6b): Cayman Islands
use "$temp\data_full_matrices.dta", clear
sort host year source
collapse (first) hostname ewn_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt ofc_host, by(host year)

keep if host == 377

collapse (sum) eqliab_host debtliab_host lequity_host lportif_debt_host, by(year)
foreach var of varlist eqliab_host debtliab_host lequity_host lportif_debt_host{
	replace `var' = `var' / 1000
}

*equities 
preserve
keep year *eq*
rename eqliab_host correc_ewn2_cayman
rename lequity_host correc_ewn2_cayman_in_ewn
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'
restore 
*debt 
keep year *debt*
rename debtliab_host correc_ewn2_cayman
rename lportif_debt_host correc_ewn2_cayman_in_ewn
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'


// Col (7): Small OFCs
use "$temp\data_full_matrices.dta", clear
sort host year source
collapse (first) hostname ewn_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt ofc_host, by(host year)


keep if ewn_host != 1 & host != 377 & ofc_host == 1
collapse (sum) eqliab_host debtliab_host, by(year)
foreach var of varlist eqliab_host debtliab_host{
	replace `var' = `var' / 1000
}
*equities 
preserve
keep year *eq*
rename eqliab_host non_ewn2_smallofcs
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'
restore 
*debt 
keep year *debt*
rename debtliab_host non_ewn2_smallofcs
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'


// Col. (9): Other Non EWN countries
use "$temp\data_full_matrices.dta", clear
sort host year source
collapse (first) hostname ewn_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt ofc_host, by(host year)

keep if ewn_host != 1 & host != 91 & ofc_host != 1
collapse (sum) eqliab_host debtliab_host, by(year)
foreach var of varlist eqliab_host debtliab_host{
	replace `var' = `var' / 1000
}

*equities 
preserve
keep year *eq*
rename eqliab_host non_ewn2_other
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'
restore 
*debt 
keep year *debt*
rename debtliab_host non_ewn2_other
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'


// Col. (10): International Organizations
use "$temp\data_full_matrices.dta", clear
sort host year source
collapse (first) hostname ewn_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt ofc_host, by(host year)


keep if host == 91
collapse (sum) eqliab_host debtliab_host, by(year)
foreach var of varlist eqliab_host debtliab_host{
	replace `var' = `var' / 1000
}

*equities 
preserve
keep year *eq*
rename eqliab_host international_orga
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'
restore 
*debt 
keep year *debt*
rename debtliab_host international_orga
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'

// Col. (11): Total
use "$temp\data_full_matrices.dta", clear
sort host year source
collapse (first) hostname ewn_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt ofc_host, by(host year)


collapse (sum) eqliab_host debtliab_host, by(year)
foreach var of varlist eqliab_host debtliab_host{
	replace `var' = `var' / 1000
}
*equities 
preserve
keep year *eq*
rename eqliab_host total_securities_liabilities
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'
restore 
*debt 
keep year *debt*
rename debtliab_host total_securities_liabilities
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'



// Col (2): IMF IIPs
use "$temp\IIP_eqliab.dta", clear
replace eqliab_IIP = eqliab_IIP / 1000
rename eqliab_IIP imf_iips
keep year imf_iips
merge 1:1 year using `main_eq', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'

use "$temp\IIP_debtliab.dta", clear
replace debtliab_IIP = debtliab_IIP / 1000
rename debtliab_IIP imf_iips
keep year imf_iips
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `main', nogen


// ALL SECURITIES 
preserve 
drop asset_type
collapse (sum) *_* ewn2, by(year )
gen asset_type="All Securities"
tempfile temp1
save `temp1'
restore 
merge 1:1 * using `temp1', nogen

sort asset_type year

// Col (8): Memo: small OFCs / Total
gen non_ewn2_smallofcsperc= (correc_ewn2_cayman +non_ewn2_smallofcs )/ total_securities_liabilities*100
*format non_ewn2_smallofcsperc %9.2f
// Col (12): EWNII liabilities / Total liabilities
gen ewn2_perc=  ewn2/ total_securities_liabilities*100


////////////////////////////////Dataset Cleaning\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
order year asset_type ewn2 imf_iips ///
correc_ewn2_nodata correc_ewn2_nld_sfis correc_ewn2_rawcpis correc_ewn2_cayman correc_ewn2_cayman_in_ewn ///
non_ewn2_smallofcs non_ewn2_smallofcsperc non_ewn2_other ///
international_orga total_securities_liabilities ewn2_perc 

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

label variable ewn2                       "EWNII liabilities"
label variable imf_iips                   "Memo: IMF IIPs"

label variable correc_ewn2_nodata         "No data [Correction to EWNII data]"
label variable correc_ewn2_nld_sfis       "Netherlands SFIs [Correction to EWNII data]"
label variable correc_ewn2_rawcpis        "raw CPIS > reported liabilities [Correction to EWNII data]"
label variable correc_ewn2_cayman         "Cayman Islands [Correction to EWNII data]"
label variable correc_ewn2_cayman_in_ewn  "of which in EWN (Cayman Islands) [Correction to EWNII data]"

label variable non_ewn2_smallofcs         "Small OFCs [Non EWNII countries]"
label variable non_ewn2_smallofcsperc     "Memo: small OFCs / Total *100"
label variable non_ewn2_other             "Other [Non EWNII countries]"

label variable international_orga         "International organisations"
label variable total_securities_liabilities "Total securities liabilities"
label variable ewn2_perc                  "EWNII liabilities / Total liabilities *100"





label data "Table A2: Global Cross-Border Securities Liabilities"


// ------------------
// Save final dataset
// ------------------
save "$work\Table_A2_Global_Cross_Border_Securities_Liabilities.dta", replace
*use "$work\Table_A2_Global_Cross_Border_Securities_Liabilities.dta", clear
// Export to Excel
export excel using "$myexcel", sheet("Table A2") firstrow(varlabels) sheetmodify



