//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: impute share of each country for non-residents deposits in UAE
//
// databases used: - "$raw\CDIS_12-11-2024 21-24-20-45_timeSeries.csv"
//                 - "$raw/per_purchases_all.dta"
//                 - "$raw/bank_deposits_in_uae_cleaned_q4.xlsx"
//
// outputs:        - "$temp/shares_deposits_in_uae.dta"
//                 - "$work/bank_deposits_in_uae_allocated.dta"
//
//----------------------------------------------------------------------------//


*###############################################################################*
**---------------------------FDI/CDIS/FMI-------------------------------------**
*###############################################################################*
/*Source:
// source: IMF,	CDIS
// website: https://data.imf.org/?sk=40313609-f037-48c1-84b1-e1f1ce54d6d5
*/
import delimited "$raw\CDIS_12-11-2024 21-24-20-45_timeSeries.csv", clear 

* UAE does not report to the CDIS so we have to use outward investment by other country towards UAE
keep if counterpartcountryname == "United Arab Emirates"
*select outward direct investments :
keep if indicatorcode == "IOW_BP6_USD" 
drop v23
*v8 = 2009
reshape long v, i(countryname  attribute) j(year)
destring v, replace ignore(C)

replace year = year + 2001
drop if attribute == "Status"


rename countryname country 
rename v value 
gen variable= "outward_direct_investment_positions_towards_uae"
gen source="CDIS"
gen currency="Nominal USD"
keep year country variable value source currency 

* we drop aggregates
drop if country=="Central and South Asia" | country=="East Asia" | country=="Economies of Persian Gulf" ///
 | country=="Europe"  | country=="North Africa"  | country=="North Atlantic and Caribbean"  | country=="North and Central America"  | country=="Oceania and Polar Regions"  | country=="Other Near and Middle East Economies"  | country=="South Africa"  | country=="South America"  | country=="Sub-Saharan Africa"  


* drop world because it will give a different total value, because we need to winsorize
drop if country=="World" 

* percentiles to winsorized
local p_lower "5"
local p_upper "95"

* loop over all the possible combinations
foreach lower in `p_lower'{
	foreach upper in `p_upper'{
		local varname value_wins_`lower'_`upper'
		* gen the new var
		gen `varname'=.
		*summarize and replace
		summarize value, detail
		replace `varname'=min(value,r(p`upper'))
		replace `varname'=max(`varname',r(p`lower'))
		replace `varname'=. if missing(value)
		* summ to check
		summarize `varname',detail
	}
}

**** need to do the share variables
local varlist value_wins_5_95

foreach var of local varlist{
	* Create total variable, and total by year (~"world") 
	egen `var'_total= total(`var') //total of all countries, all years 
	by year, sort: egen `var'_total_year = total(`var') // total of all countries for a single year 
	* Create total values for each country
	bysort country: egen `var'_by_country = total(`var') // total of 1 country all years


	*  Create the share of 1 country by year variable 
	gen share_by_year_`var' = `var' / `var'_total_year

	*  Create the share variable
	gen share_`var' = `var'_by_country / `var'_total
	  
   drop `var'_by_country  `var'_total `var'_total_year
}   
      

* we just use the average FDI share over the sample period
drop share_by_year_value_wins_5_95 value value_wins_5_95 year currency
gen year="2009-2023"

duplicates drop
order year country 

egen check=total(share_value_wins_5_95)
tab check
drop check 

gsort -share_value_wins_5_95

* add isocodes
isocodes country, gen(iso2c)
rename iso2c country_iso2
replace country_iso2 = "XK" if country == "Kosovo, Rep. of"

label var share_value_wins_5_95 "Share Over the Sample Period 2009-2023 with Data previously Winsorized at 5%"

tempfile shares_outward_uae //shares_outward_declared_by_foreign_countries_towards_uae
save `shares_outward_uae' 



*###############################################################################*
**--------------------------REAL ESTATE---------------------------------------**
*###############################################################################*
/*Source:
// What: National shares of all purchases made of property between 2006-2019
// e_purchases_aed = total of each country over all the period 
// total_purchases = total value over all the period
// per_total = share of each country over all the sample period
*/


use "$raw/per_purchases_all.dta", clear

drop e_purchases_aed total_purchases
rename per_total share_real_estate

isocodes iso3, gen(iso2c)
rename iso2c country_iso2
replace country_iso2 = "XK" if iso3 == "XKX"
drop iso3

gen year="2006-2019"
gen variable= "national_purchases_made_of_property_in_uae"
gen source="real_estate"

label var share_real_estate "Share of each country of all purchases made of property between 2006-2019"

tempfile shares_real_estate_uae
save `shares_real_estate_uae'




*###############################################################################*
**------------------MERGING FDI/CDIS/FMI & REAL ESTATE------------------------**
*###############################################################################*

use `shares_outward_uae', clear
drop year variable source

merge 1:1  country_iso2 using `shares_real_estate_uae', keepusing(country_iso2 share_real_estate)
drop _merge

	
* need to generate a share that is 50% of the share of fdi and 50% of the share of real estate
gen share_fdi_realestate= 0.5*(share_value_wins_5_95) +0.5*(share_real_estate) 
replace share_fdi_realestate= 0.5*(share_value_wins_5_95) if missing(share_real_estate) // otherwise the formula above does not work because of missing values 
replace share_fdi_realestate= 0.5*(share_real_estate) if missing(share_value_wins_5_95)

capture drop check
egen check=total(share_fdi_realestate)
tab check
drop check 		
drop share_value_wins_5_95 share_real_estate
label var share_fdi_realestate "Share computed with 50% FDI(winsorized at 5% level) and 50% real estate"
drop country // because the names in fdi are not the same when we use isocodes 

gen bank = "AE"
rename country_iso2 saver
		
* create year variable 
gen year = .

* expand the dataset for each year from 2001 to 2023
gen id = _n // create a unique ID for each observation
expand 23 // expand the dataset to have 23 times as many rows (one for each year)

* create the 'year' variable
bysort id: replace year = 2000 + _n // this will create the year variable from 2001 to 2023
drop id

order year bank saver
save "$temp/shares_deposits_in_uae.dta", replace


			
			
			
			
*###############################################################################*
**------------------------YEARLY DEPOSITS-------------------------------------**
*###############################################################################*
/*Source:
Yearly data on non-resident deposits provided by Central Bank of UAE.
*/

import excel using "$raw/bank_deposits_in_uae_cleaned_q4.xlsx", clear firstrow sheet(data)
keep year non_residents
gen bank = "AE"
gen saver = "5J"
gen dep=. 
order year bank saver
drop if year > 2023

			
*###############################################################################*
**------------------MERGE YEARLY DEPOSITS & SHARES ---------------------------**
*###############################################################################*	

merge 1:1 year bank saver using "$temp/shares_deposits_in_uae.dta"

drop _merge 

gen dep_total_year =. 

forvalues i=2001/2023 {
	preserve
	keep non_residents year saver
	keep if year == `i' & saver == "5J"
	local Alldep`i' = non_residents
	restore 
	}
	
forvalues i =2001/2023 {
	replace dep_total_year = `Alldep`i'' ///
	if year == `i'
}	
	
replace dep=dep_total_year*share_fdi_realestate if saver ~= "5J"


replace dep=non_residents if saver=="5J"	
	
drop non_residents share_fdi_realestate dep_total_year

save "$work/bank_deposits_in_uae_allocated.dta", replace

//----------------------------------------------------------------------------//

		
		
		
		
		
		