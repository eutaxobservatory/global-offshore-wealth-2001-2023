//----------------------------------------------------------------------------//
//Project: Global Offshore Wealth, 2001-2023
//
//Purpose: import from different sources and formats
//
// databases used: - "$raw\IMF_20241229_Table_15_All_Economies_Reported_Por_`asset'.xlsx", sheet("Table 15") (asset in "eq" "debt")
//                 - "$raw\dta\iso3_ifs.dta" 
//                 - "$raw\IMF_20241229_International_Investment_Position_`liab'.xlsx", sheet("Annual") (liab in "eq" "debt")
//                 - "$raw\ticdata\foreign_holdings_of_US_securities.txt"
//                 - "$raw\IMF_20243012_International_Investment_Position_China.xlsx", sheet("Annual")
//                 - "$raw\IMF_20240318_IFS_China_reserves.xlsx"
//                 - "$raw\International_Liquidity_Reserves.xlsx",
//                 - "$raw\ifdp1113_data\bertaut_judson_positions_liabs_2021.csv"
//                 - "$raw\ticdata\ticdata.liabilities.ftot.txt"
//                 - "$raw\TIC_20250113_US_Financial_Firms_Liabilities_Cayman.xlsx"
//                 - "$raw\IMF_20241230_Assets_Cayman_Banking.xlsx"
//                 - "$raw\IMF_20241230_Assets_Cayman_Insurance.xlsx"
//                 - "$raw\IMF_20241230_Exchange_Rates_incl_USD_eop.xlsx"
//                 - "$raw\TIC_20250113_US_Financial_Firms_Liabilities_China.xlsx"
//                 - "$raw\TIC_202403_US_Financial_Firms_Liabilities_China.xlsx", sheet("before2003")
//                 - "$raw\ticdata\bltype_history.csv"
//                 - "$raw\ifdp1113_data\ticdata.liabilities.foiadj.txt"
//                 - "$raw\ticdata\slt2d_history.csv"
//                 - "$raw/ticdata/tic_slt_table1.xlsx"
//                 - "$raw\BIS_20240227_table-c1.csv"
//				   - "$raw\beck_et_al\Holders_of_IRL_and_LUX_Fund_Shares_by_Counterparty_Country.dta"
//				   - "$raw\dta\KY_liab_nfc.dta"
//
// outputs:        - "$temp\data_tot`asset'_update.dta" (asset in "eq" "debt")
//                 - "$temp\adjustfactor_cpis.dta"
//                 - "$temp\IIP_`liab'liab.dta" (liab in "eq" "debt")
//                 - "$temp\IIP_`liab'liab_host.dta" (liab in "eq" "debt")
//                 - "$temp\data_TIC_update.dta"
//                 - "$temp\data_IMF_China.dta"
//                 - "$temp\data_foreignexchange_update.dta"
//                 - "$temp\TIC_liab_monthly_complete.dta"
//                 - "$temp\Cayman_TIC_Dec.dta"
//                 - "$temp\KY_banks.dta"
//                 - "$temp\TIC_China_Dec.dta"
//                 - "$temp\shortterm_ratio_FOI.dta"
//                 - "$temp\adjust_period.dta"
//                 - "$temp\TIC_update_middleast.dta"
//                 - "$temp\Bertaut_Judson_middleeast_Dec.dta"
//                 - "$temp\BIS_total_debt_IO.dta"
//				   - "$temp\missing_uk_eqassets.dta"
//				   - "$temp\missing_fundshares.dta"
//				   - "$temp\p_netfinwealth.dta"
//
//----------------------------------------------------------------------------//


//----------------------------------------------------------------------------//
// import aggregates from CPIS data
//----------------------------------------------------------------------------//


*use  "$raw\dta\iso3_ifs.dta", clear // from "$raw\dta\matching_iso_ifscode.dta" 


// total equity and total debt
foreach asset in "eq" "debt"{
	import excel "$raw\IMF_20241229_Table_15_All_Economies_Reported_Por_`asset'.xlsx", sheet("Table 15") clear
	drop A

		foreach v of varlist C - AJ {
			replace `v' = subinstr(`v',". ","_",.) in 4
			rename `v' `=`v'[4]'
		}
	drop in 1/4
	format B %16s
	drop JUN*
	reshape long DEC_, i(B) j(year)
	drop if B == ""
	rename B country
	rename DEC_ `asset'
	merge m:1 country using "$raw\dta\iso3_ifs.dta"
	drop if _merge == 2
	drop _merge country_v2 zcode
	rename (ifscode country) (ifscode_orig country_v2)
	merge m:1 country_v2 using "$raw\dta\iso3_ifs.dta"
	drop if _merge == 2
	drop _merge iso3
	replace ifscode_orig = ifscode if ifscode_orig == . & ifscode != . 
	replace ifscode_orig = 93 if country_v2=="SEFER + SSIO (**)"
	drop if ifscode_orig == . // rows with dataset notes
	rename (ifscode_orig country `asset') (source cname sum`asset'asset)
	drop country_v2 ifscode
	destring sum`asset'asset, replace
	drop zcode
	save "$temp\data_tot`asset'_update.dta", replace
 }
 
// gen adjustment factor for equity growth between June and December
import excel "$raw\IMF_20241229_Table_15_All_Economies_Reported_Por_eq.xlsx", sheet("Table 15") clear
drop A

foreach v of varlist C - AJ {
    replace `v' = subinstr(`v',". ","_",.) in 4
    rename `v' `=`v'[4]'
}
drop in 1/4
keep if B == "SEFER + SSIO (**)" | B == "Value of Total Investment"
drop DEC_200* DEC_2010 DEC_2011 DEC_2012

destring DEC* JUN*, replace
replace B = "SEFER_SSIO" in 1
replace B = "Total" in 2
forvalues j = 2013(1)2023{
	gen adj_`j' = DEC_`j'/JUN_`j'
	}
keep B adj*
reshape long adj_, i(B) j(year) 
reshape wide adj_, i(year) j(B) string
save "$temp\adjustfactor_cpis.dta", replace


// total liabilities
foreach liab in "eq" "debt"{
import excel "$raw\IMF_20241229_International_Investment_Position_`liab'.xlsx", sheet("Annual") clear

*million USD
keep A-Y
drop in 1/4
foreach v of varlist B - Y {
	replace `v' = "v_" + `v' in 1
       rename `v' `=`v'[1]'
}
drop in 1
reshape long v_, i(A) j(year)
drop if A==""
rename (A v_) (country `liab')
merge m:1 country using "$raw\dta\iso3_ifs.dta"
drop if _merge == 2
drop _merge country_v2 zcode iso3
rename (ifscode country) (ifscode_orig country_v2)
merge m:1 country_v2 using "$raw\dta\iso3_ifs.dta"
drop if _merge == 2
replace ifscode = 355 if country_v2 == "Curaçao, Kingdom of the Netherlands"
replace ifscode = 355 if country_v2 == "Sint Maarten, Kingdom of the Netherlands"
replace ifscode = 186 if country_v2=="Türkiye, Rep. of"
replace ifscode_orig = ifscode if ifscode != .
drop _merge zcode ifscode iso3 country

drop if ifscode_orig == . // regions or non-existent countries
format country_v2 %12s
rename (ifscode_orig country_v2 `liab') (host cname `liab'liab_IIP)
replace `liab'liab_IIP = "" if `liab'liab_IIP == "..."
destring `liab'liab_IIP, ignore ("K" ",") replace
collapse (sum) `liab'liab_IIP, by(host year)
rename `liab'liab_IIP `liab'liab_IIP_host
drop if year < 2001 | year > 2023
save "$temp\IIP_`liab'liab_host.dta", replace
collapse (sum) `liab'liab_IIP, by(year)
rename `liab'liab_IIP_host `liab'liab_IIP
save "$temp\IIP_`liab'liab.dta", replace
}

//----------------------------------------------------------------------------//
// import U.S. data from TIC
//----------------------------------------------------------------------------//
// source: https://home.treasury.gov/data/treasury-international-capital-tic-system/us-liabilities-to-foreigners-from-holdings-of-us-securities
import delimited using "$raw\ticdata\foreign_holdings_of_US_securities.txt", clear
keep v1-v5 v*3 v*4 v*5
gen nvals = _n
keep if nvals == 10 | nvals > 11
*keep years 2023-2000
keep v1-v225

foreach var of varlist v*{
	replace `var' = subinstr(`var', "Total securities", "Total", .) in 2
		replace `var' = subinstr(`var', "Total long-term Debt", "Debtl", .) in 2
}
rename (v1 v2) (countryid country)
foreach v of varlist v* {
   local vname = strtoname(`v'[2])
   rename `v' `v'_`vname'
}

drop in 2

foreach var of varlist v*{
	replace `var' = subinstr(`var', "Jun", "", .)
	replace `var' = subinstr(`var', "Mar", "", .)
}
rename v223_Total__1_ v223_Total

foreach v of varlist v* {
   local vname = strtoname(`v'[1])
   rename `v' `v'`vname'
}
drop in 1
drop if country == ""

reshape long v, i(countryid) j(help) string
split help, p(_)
drop help help1
rename help3 year
destring v year countryid, ignore("*" "n.a.") replace 
reshape wide v, i(countryid year) j(help2) string
rename v* *

// 2001 is missing: take average of 2000 and 2002
foreach var of varlist Debtl Equity Total{
	bysort countryid: egen mean_`var' = mean(`var') if year == 2000 | year == 2002
	replace `var' = mean_`var' if year == 2000
	drop mean_`var'
}
replace year = 2001 if year == 2000
gen flag_TIC = "2001 is estimated as the mean of 2000 and 2002" if year == 2001
save "$temp\data_TIC_update.dta", replace



//----------------------------------------------------------------------------//
// import China's assets
//----------------------------------------------------------------------------//
// 1. Public assets: est. 85-95% of foreign exchange reserves
import excel using "$raw\IMF_20243012_International_Investment_Position_China.xlsx", sheet("Annual") clear
keep if A == "Other reserve assets" | B == "2004" | A == "Equity and investment fund shares" & A[_n-1] == "Portfolio investment" & A[_n-11] == "Assets" | A == "Debt securities" & A[_n-7] == "Portfolio investment" & A[_n-17] == "Assets"
keep A - U

foreach v of varlist B - U {
	forvalues k = 2004/2023{
		replace `v' = subinstr(`v',"`k'","v_`k'",.) in 1
	}
}

foreach v of varlist B - U {
   local vname = strtoname(`v'[1])
   rename `v' `vname'
}
drop in 1
replace A = "Equity" if A == "Equity and investment fund shares"
replace A = "Debt" if A == "Debt securities"
replace A = "Reserves" if A == "Other reserve assets"

reshape long v_, i(A) j(year)
destring v_, ignore("," "K ") replace

reshape wide v_, i(year) j(A) string
rename v_* *_IMF

// foreign exchange reserves pre-2004
preserve
import excel using "$raw\IMF_20240318_IFS_China_reserves.xlsx", clear

foreach v of varlist C-Y{
   local vname = strtoname(`v'[2])
   rename `v' v`vname'
}
drop in 1/2
reshape long v_, i(A) j(year) string
drop A B
destring v_ year, replace
rename v_ reserves_2001
tempfile reserves_2001
save `reserves_2001'
restore
merge 1:1 year using `reserves_2001'
replace Reserves_IMF = reserves_2001 if year < 2004
drop *2001 _merge
save "$temp\data_IMF_China.dta", replace

//----------------------------------------------------------------------------//
// import foreign exchange data
//----------------------------------------------------------------------------//
import excel using "$raw\International_Liquidity_Reserves.xlsx", clear
// International Reserves and Liquidity, Liquidity, Total Reserves excluding Gold, Foreign Exchange, US Dollar, millions
drop A C D
rename B country
foreach v of varlist E-AB{
   local vname = strtoname(`v'[7])
   rename `v' v`vname'
}
drop in 1/7
reshape long v_, i(country) j(year) string
replace v_ = "." if v_ == "..." | v_ == "-"
destring year v_, replace
rename v_ reserveIFS


merge m:1 country using "$raw\dta\iso3_ifs.dta"
drop if _merge == 2
drop _merge country_v2 zcode
rename (ifscode country) (ifscode_orig country_v2)
merge m:1 country_v2 using "$raw\dta\iso3_ifs.dta"
drop if _merge == 2
drop _merge iso3
replace ifscode_orig = ifscode if ifscode_orig == . & ifscode != . 
drop if ifscode_orig == . // country groups, e.g. "Advanced Economies"
rename ifscode_orig source
drop ifscode country* zcode
drop if year < 2001
save "$temp\data_foreignexchange_update.dta", replace


//----------------------------------------------------------------------------//
// import TIC U.S. cross-border securities positions 
//
// (Bertaut and Judson 2011-2020 
// link: https://www.federalreserve.gov/econres/ifdp/estimating-us-cross-border-securities-positions-new-data-and-new-methods.htm
// + new monthly TIC data for 2021f)
// link: https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/slt_table1.txt
// + Bertaut and Tyron 2001-2011
// https://www.federalreserve.gov/pubs/ifdp/2007/910/ifdp910appendix.htm
//----------------------------------------------------------------------------//


	// U.S. long-term securities held by foreign residents
		// most recent (2021f)
		import delimited "https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/slt_table1.txt", clear
		keep v1-v4 v7 v10 v13 v16 /*Holdings*/
		// for_lt_total_pos  "Total U.S. Securities"
		// for_lt_treas_pos "U.S. Treasuries"
		// for_lt_agcy_pos "U.S. Agency Bonds"
		// for_lt_corp_pos "U.S. Corp. & Other Bonds"
		// for_lt_eqty_pos "U.S. Corp. Equity"
		drop in 1/8

		foreach v of varlist v* {
			local vname = strtoname(`v'[1])
			rename `v' `vname'
		}
		drop in 1
		split date, p(-)
		rename (date1 date2) (year month)
		drop date
		destring year month, replace
		keep if month == 6 | month == 12
		destring for* country_code, ignore("n.a.") replace
		drop if country_code == 72907 | country_code == 76929 // International and regional organizations already included in 79995 "Total IROs"
		drop if country_code > 79995 & country_code < 99996
		rename country country_name
		tempfile TIC_liab_monthly_2020f
		save `TIC_liab_monthly_2020f'

		// 2011-2020
		import delimited "$raw\ifdp1113_data\bertaut_judson_positions_liabs_2021.csv", clear
		split date, p(/)
		drop date date2
		rename (date1 date3) (month year)
		destring month year, replace
		keep year month country_code country_name *est_pos month year
		rename ftot_* *
		keep if month == 6 | month == 12
		merge 1:1 country_code month year using `TIC_liab_monthly_2020f'
		sort country_code year month
		drop _merge
		tempfile TIC_liab_monthly_2011f
		save `TIC_liab_monthly_2011f'

		// 2001-2011
		import delimited "$raw\ticdata\ticdata.liabilities.ftot.txt", clear
		split date, p(/)
		drop date date2
		rename (date1 date3) (month year)
		destring month year, replace
		keep if month == 12 | month == 6
		keep if year > 2000
		keep countrycode countryname *est_pos month year
		destring ftot_agcy_est_pos ftot_corp_est_pos ftot_stk_est_pos ftot_treas_est_pos, ignore ("ND") replace
		rename (countryname countrycode) (country_name country_code)
		rename ftot_* *
		drop if year == 2011
		append using `TIC_liab_monthly_2011f'
		sort country_code year month

		replace for_lt_treas_pos = treas_est_pos if for_lt_treas_pos == .
		replace for_lt_agcy_pos = agcy_est_pos if for_lt_agcy_pos == .
		replace for_lt_corp_pos = corp_est_pos if for_lt_corp_pos == .
		replace for_lt_eqty_pos = stk_est_pos if for_lt_eqty_pos == .
		drop *_est_* for_lt_tot*
		rename for_lt_*_pos *
		gen debtl = treas + agcy + corp
		rename eqty equity
		label var debtl "long-term debt"
		keep country_code country_name year month equity debtl
		save "$temp\TIC_liab_monthly_complete.dta", replace



//----------------------------------------------------------------------------//
// Cayman Islands
//----------------------------------------------------------------------------//

// TIC
use "$temp\TIC_liab_monthly_complete.dta", clear
keep if country_code == 36137 // Cayman Islands
keep if month == 12
gen source = 377
gen host = 111
drop country_code country_name month
tempfile TIC_lt_monthly_Cayman_complete
save `TIC_lt_monthly_Cayman_complete'

// import TIC short-term debt for Cayman Islands
// source: https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/lb_36137.txt
import excel "$raw\TIC_20250113_US_Financial_Firms_Liabilities_Cayman.xlsx", clear
keep A B I J
rename (A B I J) (countrycode date shortterm_official shortterm_other)
drop in 1/9
split date, p(-)
keep if date2 == "12"
rename date1 year
keep shortterm* year
destring *, replace
egen shortterm_debt = rowtotal (shortterm_official  shortterm_other)
keep year shortterm_debt
merge 1:1 year using `TIC_lt_monthly_Cayman_complete'
drop _merge

// Data are unavailable prior to 2003, so for 2001 and 2002 Zucman (2013) uses the 2003 figure and the percent change of U.S. long term debt liabilities vis-a-vis the Cayman Islands.
replace shortterm_debt = 4712 if year == 2001
replace shortterm_debt = 11018 if year == 2002
gen debt = shortterm + debtl
sort year
rename (shortterm_debt debtl equity debt) (debts_KY_TIC debtl_KY_TIC eq_KY_TIC debt_KY_TIC)
save "$temp\Cayman_TIC_Dec.dta", replace

// CPIS banking and insurance holdings
import excel "$raw\IMF_20241230_Assets_Cayman_Banking.xlsx", clear // source: Enhanced CPIS by sector of holder: Depositary Corporations except the Central Bank

foreach v of varlist B - T {
 forvalues k = 2004/2023{
 replace `v' = subinstr(`v',"Dec. `k'","v_`k'",.) in 3
 }
}
foreach v of varlist B - T {
   local vname = strtoname(`v'[3])
   rename `v' `vname'
}
drop in 1/3
reshape long v_, i(A) j(year)
destring v_, replace
rename v_ bank
tempfile KY_banks
save `KY_banks'

import excel "$raw\IMF_20241230_Assets_Cayman_Insurance.xlsx", clear // source: Enhanced CPIS by sector of holder: Other Financial Corporations: Insurance Corporations and Pension Funds"
foreach v of varlist B - I {
 forvalues k = 2016/2023{
 replace `v' = subinstr(`v',"Dec. `k'","v_`k'",.) in 3
 }
}
foreach v of varlist B - H {
   local vname = strtoname(`v'[3])
   rename `v' `vname'
}
drop in 1/3
reshape long v_, i(A) j(year)
destring v_, replace
rename v_ ins
merge 1:1 year using `KY_banks'
drop _merge
sort year
gen KY_assets_bank = ins + bank
replace KY_assets = bank if ins == .
keep year KY_assets
gen host = 377
save "$temp\KY_banks.dta", replace


// estimate equity liabilities of non-financial corporations located in Cayman islands
import excel "$raw\IMF_20241230_Exchange_Rates_incl_USD_eop.xlsx", clear // 2001-2023
foreach v of varlist E - AB {
 forvalues k = 2001/2023{
 replace `v' = subinstr(`v',"`k'","v_`k'",.) in 7
 }
}
foreach v of varlist E - AB {
   local vname = strtoname(`v'[7])
   rename `v' `vname'
}
drop in 1/7
reshape long v_, i(B) j(year) string
rename (v_ B) (xrate country)
keep country year xrate
replace xrate = "." if xrate == "..."
destring year xrate, replace ignore(-)


gen currency = ""
replace cu = "USD" if country == "United States"
replace cu = "AUD" if country == "Australia"
replace cu = "BRL" if country == "Brazil"
replace cu = "CNY" if country == "China, P.R.: Mainland"
replace cu = "EUR" if country == "Euro Area"
replace cu = "GBP" if country == "United Kingdom"
replace cu = "HKD" if country == "China, P.R.: Hong Kong"
replace cu = "ILS" if country == "Israel"
replace cu = "JPY" if country == "Japan"
replace cu = "KRW" if country == "Korea, Rep. of"
replace cu = "MXN" if country == "Mexico"
replace cu = "NOK" if country == "Norway"
replace cu = "SGD" if country == "Singapore"
replace cu = "TWD" if country == "Taiwan Province of China"
drop if cu == ""
tempfile xrates
save `xrates'

/* Confidential data
import delimited "$raw\cayman-compustat-2025.csv", parselocale(en_US) clear // Compustat Global – Security Daily for the end-of-year market value of all listed firms incorporated in the Cayman Islands. 

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
*/

//----------------------------------------------------------------------------//
// China's assets
//----------------------------------------------------------------------------//

// long-term
use "$temp\TIC_liab_monthly_complete.dta", clear
keep if country_code == 41408
keep if month == 12
tempfile TIC_longterm_monthly_China
save `TIC_longterm_monthly_China'

// short term
 // short-term 2003-2023 // Source: https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/lb_41408.txt
	import excel "$raw\TIC_20250113_US_Financial_Firms_Liabilities_China.xlsx", clear

	keep A B I J // Negotiable CDs and short-term securities "[7] held by foreign official institutions and foreign banks"; "[8] held by all other foreigners"
	rename (A B I J) (countrycode date shortterm_official shortterm_other)
	drop in 1/19
	split date, p(-)
	keep if date2 == "12"
	rename date1 year
	keep shortterm* year
	destring *, replace
	egen shortterm_debt = rowtotal (shortterm_official  shortterm_other)
	keep year shortterm_debt
	tempfile TIC_China_short
	save `TIC_China_short'

	// short term 2001-2003
	import excel "$raw\TIC_202403_US_Financial_Firms_Liabilities_China.xlsx", sheet("before2003") clear
	keep A B I J
	rename (A B I J) (countrycode date shortterm_official shortterm_other)
	drop in 1/18
	split date, p(-)
	keep if date2=="12"
	rename date1 year
	keep shortterm* year
	destring year, replace
	keep if year > 2000
	destring *, replace
	egen shortterm_debt = rowtotal(shortterm_official  shortterm_other)
	keep year shortterm_debt
	append using `TIC_China_short'
	sort year

// merge
merge 1:1 year using `TIC_longterm_monthly_China'
drop _merge
gen source = 924 // ifs country code for China
gen host = 111 // ifs country code for USA

// total liabilities
gen total_China_TIC = equity + debtl + shortterm_debt
label var total_China_TIC "total securities est. based on TIC"
gen total_lt_China_TIC = equity + debtl
label var total_lt_China_TIC "total long term securities -TIC"
rename equity eq_China_TIC 
label var eq_China "equity TIC"
rename debtl debtl_China_TIC
label var debtl_China_TIC "long-term debt securities - TIC"
rename shortterm_debt debts_China_TIC
label var debts_China_TIC "short-term debt securities - TIC"
gen debt_China_TIC = debtl_China_TIC + debts_China_TIC
save "$temp\TIC_China_Dec.dta", replace


//----------------------------------------------------------------------------//
// Assets of Middle Eastern Oil Exporters
//----------------------------------------------------------------------------//

// Note: Bertaut & Judson report for "Middle Eastern Oil Exporters" on aggregate. In 2010 reporting switches to country-level but comprises only Kuwait and Saudi Arabia -> we switch to TIC June series after 2010 to include all Middle East oil exporters and need to make an adjustment for equity growth between June and December)
use "$temp\data_TIC_update.dta", clear
keep if country == " Middle Eastern Oil Exporters" | country == "Kuwait" | country == "Saudi Arabia" | country == "Bahrain" | country == "Iran" | country == "Iraq" | country == "Oman" | country == "Qatar" |country == "United Arab Emirates"
save "$temp\TIC_update_middleast.dta", replace
collapse (sum) Total (sum) Equity (sum) Debtl, by(year)
tempfile TIC_update_middleeast_total
save `TIC_update_middleeast_total'


// calculate short-term long-term ratio of foreign official institutions' holdings of U.S. securities
	//import short-term liabilities of foreign official institutions
	// source: https://home.treasury.gov/data/treasury-international-capital-tic-system/us-liabilities-to-foreigners-from-holdings-of-us-securities
	
	import delimited "$raw\ticdata\bltype_history.csv", clear
	keep v1 v6 v7 // ST Treas securities held by FOI [5] + Oth ST Neg secs held by FOI [6]
	drop in 1/18
	split v1, p(-)
	drop v1
	destring v11, replace
	rename v11 year
	drop if year == .
	rename v12 month
	keep if month == "Dec" | month == "Jun"
	destring v6, replace
	destring v7, replace
	egen shortterm_FOI = rowtotal (v6 v7)
	keep year month shortterm_FOI
	keep if year > 2000
	replace month = "12" if month == "Dec"
	replace month = "6" if month == "Jun"
	destring month, replace
	save "$temp\TIC_shortterm_FOI.dta", replace

	// import long-term liabilities of foreign official institutions (FOI) -> from Bertaut & Judson 
		// 2001-2011
		import delimited "$raw\ifdp1113_data\ticdata.liabilities.foiadj.txt", clear 
		keep date foi_*_est_pos
		egen longterm_debt_FOI=rowtotal(foi_agcy* foi_corp* foi_treas*)
		egen longterm_FOI = rowtotal(foi_agcy* foi_corp* foi_treas* foi_stk)
		split date, p(/)
		keep if date1 == "12" | date1 == "06"
		replace date1 = "6" if date1 == "06"
		rename date3 year
		rename date1 month
		destring year, replace
		keep if year > 2000
		drop date date2
		rename *_est_pos *
		tempfile TIC_longterm_FOI_2001_11
		save `TIC_longterm_FOI_2001_11'

		// 2011-2022
		import delimited "$raw\ticdata\slt2d_history.csv", clear
		keep v1 v3 v6 v9 v14 v27 /*Holdings of foreign official institutions*/
		rename (v3 v6 v9 v14 v27) (foi_total foi_treas foi_agcy foi_corp foi_stk)
		gen nvals = _n
		keep if nvals > 17
		drop nvals
		split v1, p(-)
		drop v1
		rename (v11 v12) (year month)
		destring year, replace
		drop if year==.
		keep if month == "Jun" | month == "Dec"
		replace month = "6" if month == "Jun"
		replace month = "12" if month == "Dec"
		destring foi*, replace
		append using `TIC_longterm_FOI_2001_11'
		destring month, replace
		sort year month
		replace longterm_FOI = foi_total if longterm_FOI == .
		drop foi_total longterm_debt
		tempfile TIC_liabs_monthly_FOIs
		save `TIC_liabs_monthly_FOIs'
		
		
		// most recent data only available in new format
		import excel "$raw/ticdata/tic_slt_table1.xlsx", clear
		keep A C D  G J M P // Total U.S. Securities Holdings for_lt_total_pos, treasury bonds, agency bonds, other corporate bonds, equity
		rename (D G J M P) (foi_total_update foi_treas_update foi_agcy_update foi_corp_update foi_stk_update)
		keep if A == "Of Which: Foreign Official"
		split C, p(-)
		drop C
		rename (C1 C2) (year month)
		destring year month foi_total foi_treas foi_agcy foi_corp foi_stk, replace
		keep if month == 6 | month == 12
		drop A
		
		merge 1:1 year month using `TIC_liabs_monthly_FOIs'
		sort year month
		replace longterm_FOI = foi_total_update if foi_total_update != .
		foreach liab in "treas" "agcy" "corp" "stk"{
			replace foi_`liab' = foi_`liab'_update if foi_`liab'_update != .
		}

		drop _merge *update
		merge 1:1 year month using "$temp\TIC_shortterm_FOI.dta"
		drop _merge
		tempfile TIC_liabs_monthly_FOIs
		save `TIC_liabs_monthly_FOIs', replace

	// gen short_long_ratio=shortterm/longterm_debt
	gen short_long_ratio = shortterm / longterm_FOI
	keep if month == 12
	keep year month longterm_FOI short_long_ratio
	save "$temp\shortterm_ratio_FOI.dta", replace


	// compute adjustment ratio based on TIC reporting for Saudi Arabia & Kuwait to uprate June values to December (because we switch from December to June reporting for Middle Eastern Oil Exporters after 2010)
	use "$temp\TIC_liab_monthly_complete.dta", clear
	keep if country_code == 46612 | country_code == 45608 | country_code == 43109 | country_code == 46604
	gen help = 1 if country_code == 46612 /*Middle East aggregate*/
	replace help = 0 if help == .
	collapse (sum) equity, by(year month help)
	reshape wide equity, i(year help) j(month)
	gen adj_eq = equity12 / equity6
	keep if help == 0 //drop Middle East aggregate available only before 2011
	keep year adj*
	tempfile adjustfactor
	save `adjustfactor'

	// generate adjustment ratio based on International Organisations' assets to uprate June values to December because data for Saudi Arabia and Kuwait starts only in 2012
	use `TIC_liabs_monthly_FOIs', clear
	keep year month foi_stk
	reshape wide foi_stk, i(year) j(month)
	gen adj_eq=foi_stk12/foi_stk6
	keep year adj*
	label var adj_eq "adjusts reporting period from 6 to 12 based on US liabilities to FOIs"
	rename adj_eq adj_eq_foiUS
	merge 1:1 year using `adjustfactor'
	replace adj_eq = adj_eq_foiUS if year == 2011
	keep year adj_eq
	keep if year < 2024
	save "$temp\adjust_period.dta", replace


// extract middle east aggregate from Bertaut & Judson
// Zucman (2013) uses December values for 2001-2010 and switches to June afterwards because Bertaut & Judson middle east aggregate is discontinued
use "$temp\TIC_liab_monthly_complete.dta", clear
keep if country_name ==" Middle Eastern Oil Exporters"
keep if month == 12
rename country_name country
rename eq Equity
rename debtl Debtl
gen Total = Equity + Debtl
save "$temp\Bertaut_Judson_middleeast_Dec.dta", replace



//----------------------------------------------------------------------------//
// BIS debt securities of international organizations
//----------------------------------------------------------------------------//
// Source: https://www.bis.org/statistics/secstats_to180923.htm
import delimited using "$raw\BIS_20240227_table-c1.csv", clear
keep v2 v4 v6 v234-v325
keep if v6 == "Issue market" | v6 == "C:International markets"
keep if v4 == "Issuer sector - immediate borrower" | v4 == "1:All issuers"
keep if v2 == "Issuer residence" | v2 == "1C:International organisations"

rename v2 A
drop v4 v6

foreach var of varlist v*{
	replace `var'="v_"+`var' in 1
}

foreach v of varlist v* {
	   local vname = strtoname(`v'[1])
   rename `v' `vname'
}
drop in 1


reshape long v, i(A) j(date) string
split date, p(_)
drop date date1 date2
keep if date3=="12"
drop date3
rename (date4 v) (year total_debt_BIS)
destring year total_debt_BIS, replace
gen host = 91 if A == "1C:International organisations"

drop A
save "$temp\BIS_total_debt_IO.dta", replace



//----------------------------------------------------------------------------//
// Beck et al. UK Holders of Irish Fund Shares
//----------------------------------------------------------------------------//
// Source: https://www.globalcapitalallocation.com/data-hub

*Beck et al. amounts in EUR billions
use "$raw\beck_et_al\Holders_of_IRL_and_LUX_Fund_Shares_by_Counterparty_Country.dta", clear
keep if counter == "GBR"

*convert to million USD
gen currency = "EUR"
merge 1:1 year currency using `xrates'
keep if _merge == 3
replace holdings_of_irl_funds = holdings_of_irl_funds / xrate * 1000
keep year holdings_of_irl_funds xrate
gen source = 112 // UK
gen host = 178  // IRL

tempfile beck
save `beck'

* merge to cpis-reported uk-ie equity assets
use "$temp\cpis_merge.dta", clear
keep if source == 112 & host == 178
// 2020 in line with Beck et al. "UK reports EUR 336 bn eq assets towards Ireland"

merge 1:1 year using `beck', nogen

// Irish investment funds have more liabilities towards UK than what UK reports 
// in assets towards Ireland in the CPIS
gen missing_eqasset = holdings_of_irl_funds - eqasset
label var missing_eqasset "Irish fund shares without owner in CPIS (Beck et al.)"
// Some of these missing assets are likely owned by UK residents = "onshore":
// According to Beck et al. (Table 1: Fund unwind: summary statistics) Irish 
// investment fonds have bond holdings worth EUR 1,2 tn bn on behalf of 
// non-EA investors. They also state that EUR 474 bn of these bond holdings were
// denominated in GBP. This corresponds to 40% of total bond 
// holdings of Irish investment funds on behalf of non-EA investors 
// We assume that 95% of pound-denominated are ultimately owned by UK residents 
// -> 36% of total Irish fund bond holdings
gen bonds_gbp = 474000 if year == 2020
replace bonds_gbp = bonds_gbp / xrate
replace bonds_gbp = bonds_gbp * 0.95

// on top of that we assume that the ratio of equity to bond holdings of Irish investment 
// fund holdings on behalf of UK residents corresponds to the ratio of equity to bond holdings 
// ratio of Irish investment fund holdings vis-à-vis non-EA countries
// as reported in Beck et al. "Table 1: Fund unwind: summary statistics" 783/1,354 = 0.58
gen equity_gb = 0.58 * bonds_gb
* total IRL fund shares ultimately owned by UK residents
gen fundshares_gb = bonds_gb + equity_gb	// USD 873 bn
label var fundshares_gb "Irish fund shares owned by UK residents (est)"

// for a lower-bound of missing UK-owned IRL fund shares we subtract all 
// CPIS-reported UK equity (incl. fund share) assets vis-a-vis Ireland
// from IRL fund shares with UK counterparty minus all CPIS
gen fundshares_gb_missing = fundshares_gb - eqasset if year == 2020
label var fundshares_gb_missing "Missing Irish fund shares owned by UK residents (est)"

* compute share of missing UK-IE assets which are likely onshore
gen onshore_share = fundshares_gb_missing / missing_eqasset // 31% 

* assume fixed share of onshore in missing Irish fund holdings 
// (not reported in CPIS) to create series for 2014-2021 and correct cpis assets
sum onshore_share
local onshore_share r(mean)
replace onshore_share = `onshore_share' if onshore_share == .
replace fundshares_gb_missing = missing_eqasset * onshore_share

* fill missing years based on assumed share in total UK equity assets
merge 1:1 source year using "$temp\data_toteq_update.dta"
keep if _merge == 3	
drop _merge
	
gen missing_uk_share = fundshares_gb_missing / sumeqasset
/*view share
graph bar (asis) missing_uk_share if year > 2013, over(year) title(`"Missing Irish fund shares owned by UK residents in % of total CPIS-reported UK assets"', size(medsmall))
*/

*predict missing years based on share of missing in total UK assets
reg missing_uk_share year
predict missing_uk_share_hat

label var missing_uk_share "missing uk assets"
label var missing_uk_share_hat "fitted values"

replace missing_uk_share_hat = missing_uk_share if year > 2013 & year <=2021

/*view prediction
graph bar (asis) missing_uk_share missing_uk_share_hat, over(year, label(angle(ninety))) title(`"Missing UK-owned Irish fund shares as a share of total CPIS-reported UK assets"', size(medsmall)) legend(nobox ring(0) position(10) cols(1) size(small) region(lstyle(none)))
*/
gen missing_eqasset_uk = missing_uk_share_hat * sumeqasset
label var missing_eqasset_uk "Irish fund shares managed in UK on behalf of UK residents"

/*check
preserve
gen missing_eqasset_uk_fitted = missing_eqasset_uk / 1000
label var missing_eqasset_uk_fitted "fitted values"
graph bar (asis) missing_eqasset_uk_fitted , over(year, label(angle(ninety))) ytitle(`"USD bn"') title(`"Missing UK-owned Irish investment fund shares, USD bn"', size(medsmall))
graph export "$fig/UK_IE_onshore.pdf", replace
restore
*/
preserve
keep host source year missing_eqasset_uk
save "$temp\missing_uk_eqassets.dta", replace
restore

* prepare benchmark for OFW series
gen ofw_uk_beck = missing_eqasset - fundshares_gb_missing
label var ofw_uk_beck "Irish fund shares managed in UK on behalf of non-residents"
*convert to USD bn
foreach var in ofw_uk_beck missing_eqasset{
	replace `var' = `var' / 1000
}
keep year missing_eqasset ofw_uk_beck 
save "$temp\missing_fundshares.dta", replace



//----------------------------------------------------------------------------//
// World Inequality Database: Global personal financial wealth
//----------------------------------------------------------------------------//

wid, indicators(mpwfin mpwdeb inyixx)  clear
bys country: gen p_finasset = value if var =="mpwfin999i"
bys country: gen p_liab = value if var =="mpwdeb999i"
bys country : gen price_index = value if var=="inyixx999i" 
collapse p_finasset p_liab price_index, by(country year)
keep if country == "WO-MER"
keep if year >= 2001 & year < 2024
foreach var in p_finasset p_liab{
	replace `var' = `var' * price_index
}
gen p_netfinwealth = p_finasset - p_liab
keep year p_netfinwealth
save "$temp\p_netfinwealth.dta", replace

//----------------------------------------------------------------------------//
