//----------------------------------------------------------------------------//
// Project: Offshore financial wealth database, 2001-2023
//
// Purpose: produce TABLE A1 "Global Cross-Border Securities Assets" (total assets and corrections)
//
// databases used: - "$temp\data_toteq_update.dta"
//                 - "$temp\data_totdebt_update.dta"
//                 - "$temp\data_full_matrices.dta"
//
// outputs:        - "$work\Table_A1_Global_Cross_Border_Securities_Assets.dta"
//                 - $tables\FGMZ_2025_Appendix_Tables_A1_to_A3.xlsx" sheet(Table A1)
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


// ------------------
// CPIS Equities
// ------------------
use "$temp\data_toteq_update.dta", clear
replace sumeqasset = sumeqasset / 1000
collapse (sum) sumeqasset, by(year)
rename sumeqasset total_cpis
merge 1:1 year using `main_eq', nogen

tempfile temp1
save `temp1'

// ------------------
// CPIS Debt
// ------------------
use "$temp\data_totdebt_update.dta", clear
replace sumdebtasset = sumdebtasset / 1000
collapse (sum) sumdebtasset, by(year)
rename sumdebtasset total_cpis
merge 1:1 year using `main_debt', nogen

merge 1:1 year asset_type using `temp1', nogen

tempfile main
save `main'

// ------------------
// Source-based collapse for major countries/entities
// ------------------
use "$temp\data_full_matrices.dta", clear
collapse (sum) eqasset debtasset augmeqasset augmdebtasset, by(year source)

// Create panel from specific sources

keep if inlist(source, 93, 377, 924, 456, 419, 443, 453, 9994, 112)
reshape wide eqasset debtasset augmeqasset augmdebtasset, i(year) j(source)
foreach v of varlist eqasset* debtasset* augmeqasset* augmdebtasset* {
    replace `v' = `v'/1000
}

// Middle East (aggregate variables)
gen eq_ME_cpis = eqasset419 + eqasset443 + eqasset456
gen debt_ME_cpis = debtasset419 + debtasset443 + debtasset456
gen eq_ME = eq_ME_cpis + augmeqasset453
gen debt_ME = debt_ME_cpis + augmdebtasset453

* Column E: "Of which: SEFER + SSIO"
// Equities
*eqasset93
// Debt 
*debtasset93

* Column F: Cayman islands
// Equities
*augmeqasset377
// Debt
*augmdebtasset377

* Column G: Cayman islands of which reported in CPIS
// Equities
*eqasset377
// Debt
*debtasset377

// Column H: UK
*augmeqasset112
*augmdebtasset112

// Column I: UK of which reported in CPIS 
*eqasset112
*debtasset112

// Column J: 

// Column K: China
*augmeqasset924
*augmdebtasset924

// Column L: 

// Column M: China of which reported in CPIS
*eqasset924
*debtasset924

* Column N: "Middle-East oil exporters (onshore)"
// Equities 
*eq_ME
// Debt 
*debt_ME 

* Column O: 

* Column P: "Middle-East oil exporters (onshore): of which: reported in CPIS"
// Equities 
*eq_ME_cpis 
// Debt 
*debt_ME_cpis 

* Column Q:

* Column R:

* Column S: "Other: of which: reserve"
// Equities 
 *augmeqasset9994
//Debt 
*augmdebtasset9994


// equities 
preserve 
keep  year *eq* 
rename eqasset93 cpis_sefer_ssio
rename augmeqasset377 correction_caymanislands_nonbank
rename eqasset377 caymanislands_reported_in_cpis
rename augmeqasset112 correction_uk
rename eqasset112 uk_in_cpis
rename augmeqasset924 correction_china
rename eqasset924 china_in_cpis
rename eq_ME correction_me
rename eq_ME_cpis me_in_cpis
rename augmeqasset9994 nonrep_other_reserves
keep year *_*
merge 1:1 year using `main_eq', nogen
tempfile temp2
save `temp2'
restore 

// debt 
keep  year *debt* 
rename debtasset93 cpis_sefer_ssio
rename augmdebtasset377 correction_caymanislands_nonbank
rename debtasset377 caymanislands_reported_in_cpis
rename augmdebtasset112 correction_uk
rename debtasset112 uk_in_cpis
rename augmdebtasset924 correction_china
rename debtasset924 china_in_cpis
rename debt_ME correction_me
rename debt_ME_cpis me_in_cpis
rename augmdebtasset9994 nonrep_other_reserves
keep year *_*
merge 1:1 year using `main_debt', nogen
merge 1:1 year asset_type using `temp2', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'





// ------------------
// CPIS Correction
// ------------------

use "$temp\data_full_matrices.dta", clear
preserve
keep if cpis == 1
collapse (sum) eqasset debtasset augmeqasset augmdebtasset, by(year)
gen eq_corr_cpis = augmeqasset - eqasset
gen debt_corr_cpis = augmdebtasset - debtasset
keep year eq_corr_cpis debt_corr_cpis
tempfile correction
save `correction'
restore

// Corrections for subset of sources
keep if inlist(source, 377, 924, 112)
collapse (sum) augmeqasset eqasset augmdebtasset debtasset, by(year)
gen corr_eq = augmeqasset - eqasset
gen corr_debt = augmdebtasset - debtasset
keep year corr_eq corr_debt
merge 1:1 year using `correction', nogen
gen eq_othercpis = (eq_corr_cpis - corr_eq) / 1000
gen debt_othercpis = (debt_corr_cpis - corr_debt) / 1000

// Merge these into main file
keep year eq_othercpis debt_othercpis

* Column J
*eq_othercpis_mat debt_othercpis_mat

//equities 
preserve 
keep year eq_othercpis
rename eq_othercpis correction_reporters_other
merge 1:1 year using `main_eq', nogen
tempfile temp4
save `temp4'
restore 
*debt 
keep year debt_othercpis
rename debt_othercpis correction_reporters_other
merge 1:1 year using `main_debt', nogen
*both
merge 1:1 year asset_type using `temp4', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'




// ------------------
// China Reserves
// ------------------
use "$temp\data_full_matrices.dta", clear
keep year totaleq_China_public totaldebt_China_public
collapse (mean) totaleq_China_public totaldebt_China_public, by(year)
replace totaleq_China_public = totaleq_China_public / 1000
replace totaldebt_China_public = totaldebt_China_public / 1000
rename totaleq_China_public eq_China_reserves
rename totaldebt_China_public debt_China_reserves
* Column L
*totaleq_China_public_mat totaldebt_China_public_mat
//equities 
preserve 
keep year *eq*
rename eq_China_reserves china_reserves
merge 1:1 year using `main_eq', nogen
tempfile temp6
save `temp6'
restore 
*debt 
keep year *debt*
rename debt_China_reserves china_reserves
merge 1:1 year using `main_debt', nogen
*both
merge 1:1 year asset_type using `temp6', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'

// ------------------
// Private Equity
// ------------------
use "$temp\data_full_matrices.dta", clear
keep if cpis != 1 & !inlist(source, 924, 9994, 449, 453, 456, 466, 429, 433)
gen help_aequity = !missing(aequity)
collapse (sum) augmeqasset, by(year help_aequity)
reshape wide augmeqasset, i(year) j(help_aequity)
gen other_private_eq = (augmeqasset0 + augmeqasset1) / 1000
keep year other_private_eq
* Column R - Equities
*other_private_eq_mat
rename other_private_eq nonrep_other_privateportfolio
merge 1:1 year using `main_eq', nogen
tempfile temp7
save `temp7'

// ------------------
// Private Debt
// ------------------
use "$temp\data_full_matrices.dta", clear
keep if cpis != 1 & !inlist(source, 924, 9994, 449, 453, 456, 466, 429, 433)
gen help_aportif = !missing(aportif_debt)
collapse (sum) augmdebtasset, by(year help_aportif)
reshape wide augmdebtasset, i(year) j(help_aportif)
gen other_private_debt = (augmdebtasset0 + augmdebtasset1) / 1000
keep year other_private_debt
* Column R - Debt
*other_private_debt_mat
rename other_private_debt nonrep_other_privateportfolio
merge 1:1 year using `main_debt', nogen
*both
merge 1:1 year asset_type using `temp7', nogen
merge 1:1 year asset_type using `main', nogen
tempfile main
save `main'



// ------------------
// Total "Other" Assets (Q)
// ------------------
// Column Q= column R+ column S - "Other"
gen correction_nonrep_other = nonrep_other_privateportfolio + nonrep_other_reserves

// ------------------
// Order columns 
// ------------------
order year asset_type total_cpis cpis_sefer_ssio correction_caymanislands_nonbank caymanislands_reported_in_cpis correction_uk uk_in_cpis correction_reporters_other correction_china china_reserves china_in_cpis correction_me me_in_cpis correction_nonrep_other nonrep_other_privateportfolio nonrep_other_reserves
sort  asset_type year

// ------------------
// Total assets (T) = D + F - G + H - I + J + K - M + N - P + Q
// ------------------

gen total_securities_assets= total_cpis+ correction_caymanislands_nonbank- caymanislands_reported_in_cpis+ correction_uk- uk_in_cpis+ correction_reporters_other+ correction_china- china_in_cpis+ correction_me- me_in_cpis+ correction_nonrep_other


preserve 
drop asset_type
collapse (sum) *_* , by(year )
gen asset_type="All Securities"
tempfile temp8
save `temp8'
restore 
merge 1:1 * using `temp8', nogen


////////////////////////////////Dataset Cleaning\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
sort  asset_type year
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

label variable total_cpis "CPIS assets"
label variable cpis_sefer_ssio "Of which: SEFER + SSIO (CPIS)"

////////////////"Correction for CPIS reporting countries"
label variable correction_caymanislands_nonbank "Cayman Islands non-bank sector [reporting country]"
label variable caymanislands_reported_in_cpis "Of which: reported in CPIS (Cayman Islands)"

label variable correction_uk "UK corrected for Irish investment fund assets [reporting country]"
label variable uk_in_cpis "Of which: reported in CPIS (UK)"

label variable correction_reporters_other "Other [reporting countries]"

label variable correction_china "China [not or only partially reporting country]"
label variable china_reserves "Of which: held as reserve (China)"
label variable china_in_cpis "Of which: reported in CPIS (China)"

label variable correction_me "Middle-East oil exporters onshore [not or only partially reporting country]"
label variable me_in_cpis "Of which: reported in CPIS (Middle East)"

////////////////"Correction for countries not or partially reporting to the CPIS"
label variable correction_nonrep_other "Other [not or only partially reporting countries]"
label variable nonrep_other_privateportfolio "Of which: private portfolios (Other, not or partially reporting)"
label variable nonrep_other_reserves "Of which: reserve (Other, not or partially reporting)"

label variable total_securities_assets "Total securities assets"


label data "Table A1: Global Cross-Border Securities Assets"


// ------------------
// Save final dataset
// ------------------
save "$work\Table_A1_Global_Cross_Border_Securities_Assets.dta", replace
*use "$work\Table_A1_Global_Cross_Border_Securities_Assets.dta", clear
// Export to Excel
export excel using "$myexcel", sheet("Table A1") firstrow(varlabels) sheetmodify


