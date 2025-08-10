//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: confidential dataset "Compustat Global – Security Daily for the end-of-year market value of all listed firms incorporated in the Cayman Islands. "
//
// databases used: - "$raw\cayman-compustat-2025.csv",
//
// outputs:        - "$temp\KY_liab_nfc.dta"
//
//----------------------------------------------------------------------------//


import delimited "$raw\cayman-compustat-2025.csv", parselocale(en_US) clear 

// loc = headquarter
// cshoc = number of common shares outstanding
// prccd = end-of-day price
// curcdd = currency of price
// gvkey = identifier of company
// iid = identifier of stock issue (multiple issues per stock)
	
// Create market value	
gen mktcap = cshoc * prccd

// Keep one issue per share
gen issue = substr(iid, 1, 2)
destring issue, replace
tab issue
// Note: >= 90 = ADR: we drop them
drop if issue >= 90
// Keep only first issue of each stock
gsort gvkey datadate issue 
duplicates drop  gvkey datadate, force

// Keep only end-of-year observations
gen year = substr(datadate, 1, 4)
destring year, replace
gen month = substr(datadate, 6, 2)
destring month, replace
keep if month == 12

drop if year>2023 

// Number of firms per year: rising from <100 in 2001 to 1750 in 2022
tab year

// Merge with year-end exchange rates to US$ and compute total US$ market cap at year-end
tab curcdd
rename curcdd currency
drop if currency == "" & cshoc == . & prccd == .
merge m:1 currency year using `xrates'
drop if _merge == 2
drop _merge
gen mktcap_usd = mktcap / xrate
collapse (sum) mktcap_usd , by(year)
gen eqliab_nfc = 0.75 * mktcap_usd

save "$raw\dta\KY_liab_nfc.dta", replace