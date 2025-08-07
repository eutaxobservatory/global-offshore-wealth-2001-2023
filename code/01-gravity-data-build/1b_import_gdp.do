//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: create a complete 2000-2023 GDP series 
//
// databases used: - "$raw/input/WEOOct2024all.xls"
//                 - "$raw/input/UNdata.csv"
//                 - "$raw\ewn\EWN-database-January-2025.xlsx", sheet("Dataset")
//                 - "$raw/dta/country_frame.dta"
//
// outputs:        - "$work\assembled_gdp_series.dta"
//
//----------------------------------------------------------------------------//


*****************************
* 1. Loading GDP series GDP * 
*****************************
* For GDP, we are using GDP in current US dollars (from 2000 to 2023)


* * * A. Our preferred source is IMF WEO
import delimited "$raw/input/WEOOct2024all.xls", clear
keep if weosubjectcode == "NGDPD" //= "Gross domestic product, current prices"; Values are based upon GDP in national currency converted to U.S. dollars using market exchange rates (yearly average). Exchange rate projections are provided by country economists for the group of other emerging market and developing countries. Exchanges rates for advanced economies are established in the WEO assumptions for each WEO exercise. Expenditure-based GDP is total final expenditures at purchasers' prices (including the f.o.b. value of exports of goods and services), less the f.o.b. value of imports of goods and services. [SNA 1993]



* Changing structure to panel
local y = 1980
forvalues v = 10/59 {
	rename v`v' gdp`y'
	local y = `y' + 1
}
keep iso gdp* estimates
reshape long gdp, i(iso) j(year)

* Converting from billions to units 
destring gdp, ignore("n/a" ",") replace
replace  gdp = gdp * 1000000000
rename   gdp gdp_weo 

* Creating a new variable to hold estimates (projections) in case we need them 
gen     gdp_weo_estimates = gdp_weo
replace gdp_weo           = . if year > estimatesstart 
tempfile imfgdp 
save `imfgdp', replace 


* * * B. Next we use World Bank
wbopendata, indicator(ny.gdp.mktp.cd) clear long
keep if region != ""
drop if region == "NA"
keep if year >= 2000 & year <= 2023
drop if countrycode == "CHI"
keep countrycode year  ny_gdp_mktp_cd
rename   ny gdp_wb
rename countrycode iso3
tempfile wbgdp
save    `wbgdp', replace 

* * * C. Third preference is UNSD
import delimited "$raw/input/UNdata.csv", clear

* Formatting iso codes for counterparts
isocodes countryarea, gen(iso3c)
drop if countryarea == "Former Ethiopia" | countryarea == "Former USSR"
drop if countryarea == "United Republic of Tanzania: Zanzibar"
drop if countryarea == "Former Yugoslavia"
drop if iso3c == "YEM" & countryarea != "Yemen"
drop if iso3c == "SDN" & countryarea != "Sudan"

replace        iso3c = "CUW" if countryarea == "CuraÃ§ao"
replace        iso3c = "TUR" if countryarea == "TÃ¼rkiye"
replace		   iso3c = "ANT" if countryarea == "Former Netherlands Antilles"
replace 	   iso3c = "XKX" if countryarea == "Kosovo"
rename iso3c iso3
rename gdp gdp_un
keep   iso3 gdp_un year 
replace gdp = "." if gdp == "..."
destring gdp, replace
tempfile ungdp
save    `ungdp', replace 


* * * D. Fourth is External Wealth of Nations (which is largely sourced from above)
import excel "$raw\ewn\EWN-database-January-2025.xlsx", sheet("Dataset") firstrow clear 

* Cleaning country codes
isocodes Country, gen(iso3c)
replace 	   iso3c = "XKX" if Country == "Kosovo"
rename iso3c iso3

* Converting to units
gen gdp_ewn = GDPUS * 1000000

drop if iso3 == "" 
rename Year year
keep iso3 year gdp_ewn 
tempfile ewngdp 
save    `ewngdp', replace



***********************************
* 2. Knitting everything together * 
***********************************

* Loading frame produced by frame_assignment
use "$raw/dta/country_frame.dta", clear

* Expanding it into a panel from 2000-2023
expand 24 
bys iso3: gen year = 1999 + _n

* Merging in the above datasets 
mmerge iso3 year using `wbgdp'    , type(1:1) umatch(iso year)
mmerge iso3 year using `imfgdp'   , type(1:n) umatch(iso year) unmatched(master)
mmerge iso3 year using `ungdp'   , type(1:n) umatch(iso year) unmatched(master)
mmerge iso3 year using `ewngdp'   , type(1:n) umatch(iso year) unmatched(master)
*mmerge iso3 year using `financial', type(1:n) umatch(iso year) 
assert _merge != 2

* Filling in missing GDP obs - we want to choose the (*series*) that has the best coverage (but not switch between series if we can help it)
drop if year <2000 | year > 2023


* * * Next we need to choose which series we prefer. 
* First: we prefer series that give us the greatest number of observations between 2000-2022 (leaving out IMF extrapolations for now
* Among those that have equal coverage, our current order of preference is: 
* i. WEO
* ii. WB
* iii. UNSD
* iv. EWN
* v.  WID


gen gdp_final = . 
gen gdp_source = ""
foreach var of varlist gdp_weo gdp_wb gdp_un gdp_ewn  {				
	cap bys iso3 (year): egen count_`var' = count(`var')						// Counting coverage
}
egen max_count = rowmax(count_*)
foreach var of varlist gdp_weo gdp_wb gdp_un gdp_ewn {                 	// Change this order to change the order of preference
	replace gdp_final = `var'    if count_`var' == max_count & gdp_final == .   
	replace gdp_source = subinstr("`var'","gdp_","",1)  if count_`var' == max_count & gdp_source == "" 
}

* If coverage doesn't extend to 2023, we are going to use the growth in GDP as estimated by changes in IMF projections 
bys iso3 (year): gen ratio = gdp_weo_estimates[_N] / gdp_weo_estimates[_N-1]
bys iso3 (year): replace gdp_final = gdp_final[_N-1] * ratio if year == 2023 & gdp_final == . 

* The rest we extrapolate
bys iso3 (year): ipolate gdp_final year, epolate gen(gdp_current_dollars)
replace gdp_source = gdp_source + "- Extrapolated" if gdp_current_dollars != . & gdp_final == . 

keep iso3 year gdp_current_dollars gdp_source
save "$work\assembled_gdp_series.dta", replace 


