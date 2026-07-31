//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: build global offshore wealth estimate and 
// total wealth attracted by each financial center group
// 
// databases used: - "$raw/AJZ2017bData.xlsx", sheet(T.A1)
//                 - "$work/global_portfolio_gap.dta"
//                 - "$raw/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_2.csv"
//                 - "$work/offshore_wealth_in_switzerland_yearly.dta"
//                 - "$work/bisdepbyhaven_hh.dta"
// 
// outputs:        - "$work/ofw_aggregate"
//                 
//----------------------------------------------------------------------------//

********************************************************************************

*************************** I -- Global deposits -------************************

*******************************************************************************

* add deposits total offshore portfolio financial wealth


import excel "$raw/AJZ2017bData.xlsx", clear firstrow ///
	cellrange(A5:E20) sheet(T.A1)
	
rename (A Offshorewealth Ofwhichport Ofwhichbankdeposits) (year ofw_ajz port_ajz deposits_ajz)

keep year WorldGDP ofw_ajz port_ajz deposits_ajz
drop if year < 2001
merge 1:1 year using "$work/global_portfolio_gap.dta", nogenerate
rename gapport_total portfolio
replace portfolio = portfolio / 1000 // convert to billions

gen deposits = deposits_ajz if year == 2013 // Zucman's (2015) number for end-2013, $1500 billion

// Assume that deposits grow at the same rate as portfolio assets

foreach y in 2012 2011 2010 2009 2008 2007 2006 2005 2004 2003 2002 2001{
replace deposits = deposits[_n+1] * portfolio / portfolio[_n+1] if year == `y'
}

replace deposits = deposits[_n-1] * portfolio / portfolio[_n-1] if year > 2013

gen ofw = deposits + portfolio

// import world gdp
preserve
	import delimited using "$raw/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_2.csv",  clear
	keep if v2 == "WLD" | v2 == "Country Code"
	drop v1-v45 
	drop v69
	drop in 1
	gen help = _n
	reshape long v, i(help) j(year)
	replace year = year + 1955
	rename v worldgdp
	replace worldgdp = worldgdp / 1000000000
	tempfile gdp
	save `gdp'
restore
merge 1:1 year using `gdp', nogenerate
gen ofw_pct = ofw / worldgdp


// import offshore wealth held in Switzerland

preserve 
use "$work/offshore_wealth_in_switzerland_yearly.dta", clear
rename total_offshore_wealth ofw_CH
keep year ofw_CH
tempfile CH
save `CH'
restore

merge 1:1 year using `CH', nogenerate

gen ofw_other = ofw - ofw_CH

merge 1:1 year using "$work/bisdepbyhaven_hh.dta", nogenerate
egen bis_americ = rowtotal(depPA depKY depUS)
egen bis_asia = rowtotal(depAE depAN depBH depBM depBS depCW depHK depMO depMY depSG)			
egen bis_europ = rowtotal(depAT depBE depCY depGB depGG depIM depJE depLU)
egen bis_total = rowtotal(bis_americ bis_asia bis_europ)
*gen bis_AE = depAE

foreach group in "americ" "asia" "europ"{														
	gen sh_`group' = bis_`group' / bis_total
	gen ofw_`group' = ofw_other * sh_`group'
	gen ofw_`group'_pct = ofw_`group' / worldgdp
}
gen ofw_CH_pct = ofw_CH / worldgdp

keep year ofw ofw_ajz ofw_CH ofw_other ofw_americ ofw_asia ofw_europ dep* bis*  worldgdp								
save "$work/ofw_aggregate", replace
	
//----------------------------------------------------------------------------//
			
