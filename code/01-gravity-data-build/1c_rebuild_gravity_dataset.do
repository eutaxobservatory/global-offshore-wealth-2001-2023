//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: reproduce and extend the dataset "data_gravity.dta". It combines:
	* identifiable bilateral portfolio assets from IMF CPIS (2024)
	* gravity variables from  CEPII (Conte, Cotterlaz & Mayer, 2022) 
	* gravity variables from the GeoDist database (Mayer and Zignago 2011)
	* GDP from World Bank WDI / EWN / World Inequality Database / UN / extrapolation	
//
// databases used: - "$raw\cpis/CPIS_09-17-2024 19-05-25-63_timeSeries.csv"
//                 - "$raw\Gravity_dta_V202211\Gravity_V202211.dta"
//                 - "$raw\Gravity_dta_V202211\Countries_V202211.dta"
//                 - "$raw\cepii\geo_cepii.dta"
//                 - "$raw\dta\iso3_ifs.dta"
//                 - "$work\assembled_gdp_series.dta"
//                 - "$raw\API_SP.POP.TOTL_DS2_en_csv_v2_900.csv"
//                 - "$raw\Guernsey_Historic_population_and_employment_data.xlsx"
//                 - "$raw\Jersey_total-population-annual-change-natural-growth-net-migration-per-year.csv"
//                 - "$raw\zucman\data_gravity.dta"
// 
// outputs:        -  "$temp\data_gravity_update.dta"
//
//----------------------------------------------------------------------------//


//----------------------------------------------------------------------------//
// 1. bilateral portfolio assets from cpis
//----------------------------------------------------------------------------//

import delimited "$raw\IMF_CPIS_09-17-2024 19-05-25-63_timeSeries.csv", varnames(nonames) clear // row 17 (no update)


// prepare dataset
 // varnames
 foreach v of varlist v1-v11 {
   local vname = strtoname(`v'[1])
   rename `v' `vname'
 }
 foreach v of varlist v12-v72 {
   local vname = strtoname(`v'[1])
   rename `v' v`vname'
 }
 drop in 1
 rename (Country_Name Country_Code Indicator_Name Indicator_Code Counterpart_Country_Name Counterpart_Country_Code) (hostname host indicatorname indicatorcode sourcename source)
 // drop semi-annual values and empty column
 drop *S1 *S2 v73-v75

 // keep total equity and total debt liabilities
 keep if indicatorcode == "I_L_D_T_T_BP6_DV_USD" | indicatorcode == "I_L_E_T_T_BP6_DV_USD"
 sort host source indicatorname
 replace indicatorname = "debtasset" if indicatorcode == "I_L_D_T_T_BP6_DV_USD"
 replace indicatorname = "eqasset" if indicatorcode == "I_L_E_T_T_BP6_DV_USD"
 keep if Attribute == "Value"

 keep hostname host indicatorname sourcename source v_2001-v_2023
 egen nmcount = rownonmiss(_all), strok
 drop if nmcount == 5 // empty rows
 drop nmcount
 reshape long v_, i(host source indicatorname) j(year)
 destring host source, replace
 drop if host == 1 // world
 drop if host == 31 // world minus 25 significant financial centers

 destring v_, replace
 reshape wide v, i(host source year) j(indicatorname) string
 rename v_* *
 
 // harmonise unit
 replace debtasset = debtasset / 1000000 // million USD
 replace eqasset = eqasset / 1000000
 
// cpis includes more host countries than source countries (reporting countries)
	// harmonise source and host jurisdictions 
	// (cpis includes host == 355 "Curacao and Sint Maarten"; 
	// source == 354 "Curacao, Kingdom of the Netherlands"; 
	// source == 352 "Sint Maarten, Kingdom of the Netherlands"

	preserve
		//collapse 2 host lines for Curacao and Sint Maarten into one
		keep if host == 354 | host == 352
		replace host = 355 /*Curacao and Sint Maarten*/
		collapse (first) hostname sourcename (sum) debtasset eqasset, by(host source year)
		replace hostname = "Curacao and Sint Maarten"
		tempfile cpis_curacao_bil_host
		save `cpis_curacao_bil_host'
	restore

	// drop individual lines for Curacao and Sint Maarten and append unified
	drop if host == 354 | host == 352
	append using `cpis_curacao_bil_host'
 
 // save cpis indicator variable for countries reporting to the cpis
 preserve
 sort source
 drop if source == source[_n-1]
 keep source
 gen cpis = 1
 save "$temp\cpis_source.dta", replace
 restore

	// Duplicate all relationships that exist as host source also as source host
	preserve
		rename (host hostname) (help helpname)
		rename (source sourcename) (host hostname)
		rename (help helpname) (source sourcename)
		keep year source host sourcename hostname
		tempfile missing_relationships
		save `missing_relationships'
	restore
 
	//merge with the original dataset and keep one part of the not matched relationships
	preserve
		merge 1:1 year source host using `missing_relationships'
		keep if _merge == 2
		drop _merge
		tempfile missing_relationships_append
		save `missing_relationships_append'
	restore	
	append using `missing_relationships_append'

save "$temp\cpis_merge.dta", replace



//----------------------------------------------------------------------------//
// 2. CEPII database gravity controls
//----------------------------------------------------------------------------//
use "$raw\Gravity_dta_V202211\Gravity_V202211.dta", clear

// prepare data
 rename country_id_d country_id
 merge m:1 country_id using "$raw\Gravity_dta_V202211\Countries_V202211.dta", nogenerate

 rename (country_id country) (country_id_d countryname_d)
 drop if last_year < 2001
 keep year country_id_o country_id_d iso3_o iso3_d country_exists_o country_exists_d dist comlang_off col45 pop_o pop_d countryname*
 rename country_id_o country_id
 merge m:1 country_id using "$raw\Gravity_dta_V202211\Countries_V202211.dta"
 drop _merge
 rename country_id country_id_o
 drop if last_year < 2001
 rename country countryname_o
 keep year country_id_o country_id_d iso3_o iso3_d countryname_o countryname_d country_exists* dist comlang_off col45 pop_o pop_d
 keep if year > 2000

// remove iso code duplicates
// in the gravity dataset the same iso codes for Indonesia and Sudan are assigned to two country ids respectively: 	
// e.g. IDN:  IDN.1 = "Indonesia + Timor Leste", IDN.2 = "Indonesia" 
// -> use only the line for the country that is defined as "country exists" in a
// given year. As a result IDN stands for "Indonesia+Timor-Leste" in 2001 but 
// only for Indonesia after 2001, "TLS" stands for Timor-Leste.

 sort year iso3_d
 drop if iso3_o == "IDN" & country_exists_o == 0 // Indonesia and Timor-Leste
 drop if iso3_d == "IDN" & country_exists_d == 0

 drop if iso3_o == "SDN" & country_exists_o == 0 // Sudan and South Sudan
 drop if iso3_d == "SDN" & country_exists_d == 0

	// Three different iso3 codes for Serbia and Montenegro: 
	// MNE = Montenegro; SCG = "Serbia and Montenegro"; SRB = "Serbia"; 
	// In IMF data there is no "Serbia and Montenegro" 
	// -> match "Serbia and Montenegro" in gravity dataset to "Serbia" in cpis before 2007 

	drop if iso3_o == "SCG" & country_exists_o == 0 // Serbia and Montenegro
	drop if iso3_d=="SCG" & country_exists_d == 0

	drop if iso3_o=="SRB" & country_exists_o == 0 // Serbia
	drop if iso3_d=="SRB" & country_exists_d == 0

	// in 2006 both SCG and SRB "exist" -> drop one
	drop if iso3_o == "SCG" & year == 2006
	drop if iso3_d == "SCG" & year == 2006 
	//replace Serbia and Montenegro by Serbia before 2007 to be able to match to IMF Serbia
	replace iso3_o = "SRB" if iso3_o == "SCG" & year < 2007	
	replace iso3_d = "SRB" if iso3_d == "SCG" & year < 2007

tempfile gravity_vars_1
save `gravity_vars_1'


// more gravity variables: gap_lon lat_source landlocked_source
	// merge missing gravity variables to source countries
	use "$raw\cepii\geo_cepii.dta",clear
	keep iso3 country landlocked lat lon city_en cap
	rename (landlocked lat lon) (landlocked_source lat_source lon_source)
	// remove iso code duplicates
	by iso3, sort: gen nvals = _n
	by iso3, sort: egen help = mean(nvals)
	// drop latitude and longitude referring to other cities but the capital
	drop if help! = 1 & cap != 1
	drop nvals help city cap

	replace iso3 = "TLS" if iso3 == "TMP"
	replace iso3 = "PSE" if iso3 == "PAL"
	replace iso3 = "ROU" if iso3 == "ROM"
	replace iso3 = "SRB" if iso3 == "YUG"
	replace iso3 = "COD" if iso3 == "ZAR"
 	tempfile geo_cepi
	save `geo_cepi'
	rename iso3 iso3_o
	merge 1:m iso3_o using `gravity_vars_1'
	drop if _merge==1 // "French Southern Antarctic Territories"
	drop _merge
	drop country
	tempfile gravity_vars_2
	save `gravity_vars_2'


	// merge latitude and longitude to host countries
	use `geo_cepi',clear
	keep iso3 lat lon
	rename (lat lon) (lat_host lon_host)
	rename iso3 iso3_d
	merge 1:m iso3_d using `gravity_vars_2'
	drop if _merge==1 // "French Southern Antarctic Territories"
	drop _merge
	drop country_id* country_exists* countryname*


// merge matching table iso3 ifs_code
preserve
	use "$raw\dta\iso3_ifs.dta", clear // from  "$raw\dta\matching_iso_ifscode.dta"
	drop if iso3 == ""
	save "$temp\iso_ifscode.dta", replace
restore 

	// source country
	rename iso3_o iso3
	merge m:1 iso3 using "$temp\iso_ifscode.dta"
	drop if _merge==2 // not in geo cepii: French Southern Territories, Guernsey, Isle of Man, Jersey, US Virgin Islands, Kosovo
	drop _merge country zcode
	rename iso3 iso3_source /*origin country = source country*/
	rename ifscode source 

	// host country
	rename iso3_d iso3
	merge m:1 iso3 using "$temp\iso_ifscode.dta"
	drop if _merge==2 // not in geo cepii: French Southern Territories, Guernsey, Isle of Man, Jersey, US Virgin Islands, Kosovo
	drop _merge country zcode
	rename iso3 iso3_host /*destination country = host country*/
	rename ifscode host
	
// collapse Curacao and Sint Maarten into one line (as in CPIS)
	sort source host year
	// source country dimension
	replace source = 355 if source == 352 | source == 354 //"Curacao and Sint Maarten"
	collapse (first) iso3_source iso3_host pop_d comlang_off col45 lon_host ///
	lat_host landlocked_source (mean) dist lon_source lat_source ///
	(sum) pop_o, by(source host year)
	replace pop_o = . if pop_o == 0
	
	// host country dimension
	replace host = 355 if host == 352 | host == 354 //"Curacao and Sint Maarten"
	collapse (first) iso3_source iso3_host lat_source lon_source pop_o ///
	comlang_off col45  landlocked_source (mean) dist lon_host ///
	lat_host (sum) pop_d, by(source host year)
	replace pop_d = . if pop_d == 0
	
	// variables not needed for same country pair
	foreach var of varlist dist comlang_off col45 pop* lat* lon* landlocked{
		replace `var' = . if host == 355 & source == 355
		replace `var' = . if (source == 355 & year < 2010) | (host == 355 & year < 2010) //did not exist as independent jurisdictions before 2010
	}

	// duplicate time-constant gravity variables for the missing year 2022 and 2023
	forvalues y = 2022/2023{
		preserve
			keep if year == 2021
			drop pop*
			replace year = `y'
			tempfile grav_`y'
			save `grav_`y''
		restore
		append using `grav_`y''
	}
 save "$temp\gravity_vars.dta", replace

// merge cpis and gravity vars
 merge 1:1 year source host using "$temp\cpis_merge.dta"
 drop _merge
 save "$temp\data_gravity_update.dta", replace



//----------------------------------------------------------------------------//
// 3. merge GDP
//----------------------------------------------------------------------------//
use "$temp\iso_ifscode.dta", clear
replace iso3 = "XKX" if iso3 == "XXK"
merge 1:m iso3 using "$work\assembled_gdp_series.dta"
keep if _merge == 3  
drop _merge
keep ifscode gdp_current year iso3
rename (ifscode iso3) (source iso3_source)
drop if year == 2000
br if source == 352
br if source == 354
br if source == 353
replace gdp = . if source == 353 & year > 2010 // does not exist anymore
replace gdp = . if (source == 352 | source == 354) & year < 2010 // does not exist, yet
replace source = 355 if source == 352 | source == 354 // Curacao + Sint Maarten
collapse (sum) gdp_current (first) iso3_source, by(year source)
replace gdp_current = gdp_current / 1000000
replace gdp_current = . if gdp_current == 0

	
// merge GDP to source and host country
preserve
	rename (source iso3_source) (host iso3_host)
 	tempfile gdp_host
	save `gdp_host'
restore
merge 1:m source year using "$temp\data_gravity_update.dta"
drop _merge
rename gdp_current gdp_source

merge m:1 host year using `gdp_host'
drop _merge
rename gdp_current gdp_host
save "$temp\data_gravity_update.dta", replace


//----------------------------------------------------------------------------//
// 4. merge population from world bank WDI
//----------------------------------------------------------------------------//
import delimited "$raw\API_SP.POP.TOTL_DS2_en_csv_v2_900.csv", clear 
keep v1 v2 v46-v68
rename (v1 v2) (country_wdi iso3)
drop in 1/2

reshape long v, i(country_wdi iso3) j(year)
replace year = year + 1955
rename v pop_wdi
label var pop_wdi "population (from World Bank WDI)"
replace iso3 = "XXK" if iso3 =="XKX"
merge m:1 iso3 using "$temp\iso_ifscode.dta"
keep if _merge == 3
drop _merge iso3 country
rename ifscode source

// collapse Curacao and Sint Maarten into one row
preserve
	keep if source == 354 | source == 352
	collapse (sum) pop_wdi, by(year)
	gen source = 355
	tempfile pop_355
	save `pop_355'
restore
append using `pop_355'
drop if source == 354 | source == 352
rename pop_wdi pop_wdi_source
drop country_wdi
tempfile pop_source
save `pop_source'
	
use "$temp\data_gravity_update.dta", clear
merge m:1 year source using `pop_source'
drop _merge

// harmonize
replace pop_wdi_source = pop_wdi_source / 1000
by source year, sort: egen help = mean(pop_o)
replace pop_o = help if pop_o == .
drop help


// replace pop_wdi by pop_o (gravity dataset) if missing in WDI
// Anguilla, Cook Islands, Guadeloupe, French Guiana, Martinique, Mayotte, Montserrat, Netherlands Antilles, Reunion, Saint Helena, Saint Pierre and Miquelon, Taiwan, Wallis and Futuna, Western Sahara
replace pop_wdi_source = pop_o if pop_wdi_source == .
rename pop_wdi_source pop_source
drop pop_d pop_o
tab sourcename if pop_source==.
tab sourcename if pop_source==. & gdp_source !=.

// complete population data for jurs with available gdp -> Anguilla, Cook Islands, Guernsey, Jersey, Montserrat, Netherlands Antilles, Taiwan

	// Anguilla 2010-2022
	replace pop_source = 15 if source==312 & year == 2021 // source: https://data.un.org/en/iso/ai.html

	// Cook Islands
	replace pop_source = 18 if source == 815 & year == 2021 // source: https://data.un.org/en/iso/ck.html
	
	// Montserrat 2010-2022
	replace pop_source = 5 if source == 351 & year == 2021 // source: https://data.un.org/en/iso/ms.html

	// Guernsey - https://www.gov.gg/census
	preserve
		import excel "$raw\Guernsey_Historic_population_and_employment_data.xlsx", clear
		keep A B
		drop if B == ""
		destring A, replace
		keep if A > 2000 & A < .
		destring B, replace
		replace B = B / 1000000
		rename (A B) (year pop_guernsey)
		set obs 5
		replace year = 2022 if year == .
		gen source = 113
		replace pop_guernsey = 0.06357 if year == 2022 // https://www.gov.gg/population
		tempfile pop_guernsey
		save `pop_guernsey'
	restore
	merge m:1 year source using `pop_guernsey'
	replace pop_source = pop_guernsey if source == 113
	drop pop_guernsey _merge
	
	
	// Jersey
	preserve
		import delimited "$raw\Jersey_total-population-annual-change-natural-growth-net-migration-per-year.csv", clear
		keep year endofyearpopulationestimate
		keep if year > 2000
		rename endofyearpopulationestimate pop_jersey
		replace pop_jersey = pop_jersey/1000000
		gen source = 117
		tempfile pop_jersey
		save `pop_jersey'
	restore
	merge m:1 year source using `pop_jersey'
	replace pop_source=pop_jersey if source == 117
	drop pop_jersey _merge

	// Fill gaps 
	bysort source: ipolate pop_source year, generate(pop_epo) epolate
	replace pop_source=pop_epo if source == 312 | source == 815 | source == 351 | source == 113 | source == 528
	
// merge population to host country
preserve
	keep year source pop_source
	rename (source pop_source) (host pop_host)
	by year host, sort: gen help = _n
	keep if help == 1
	drop help
	tempfile pop_host
	save `pop_host'
restore
merge m:1 host year using `pop_host'
drop _merge


//----------------------------------------------------------------------------//
// 5. compute gravity variables
//----------------------------------------------------------------------------//

	// latitude source country
	label variable lat_source "latitude of source ctry"
	
	// source country landlocked
	label variable landlocked_source "sce ctry landlocked"

	// distance
	gen logdist = ln(dist)
	label variable logdist "log distance"


	// longitude gap
	gen gap_lon = lon_host - lon_source
	replace gap_lon = gap_lon * -1 if gap_lon < 0
	label variable gap_lon "longitude gap"


	// calculate gdp variables
	gen gdppc_source = gdp_source / pop_source * 1000
	gen gdppc_host = gdp_host / pop_host * 1000
	label var gdppc_source "gdp per capita, current USD"
	label var gdppc_host "gdp per capita, current USD"

	gen gap_gdp = gdp_source - gdp_host
	replace gap_gdp = -1 * gap_gdp if gap_gdp < 0
	gen gap_gdppc = gdppc_source - gdppc_host
	replace gap_gdppc = -1 *gap_gdppc if gap_gdppc < 0

	// take logs
	foreach var of varlist eqasset debtasset pop_source gdppc_source gap_gdp gap_gdppc{
		gen log`var'=ln(`var')
	}

//----------------------------------------------------------------------------//
// 6. complete gravity dataset
//----------------------------------------------------------------------------//

// balance panel
tab host
fillin source host year



	// merge missing time-constant gravity variables from Zucman 2013 -> "industrial pair" and "sifc" for all jurisdictions and all gravity vars for Guernsey, Isle of Man, Jersey, Liechtenstein, Monaco
	preserve
		use "$raw\zucman\data_gravity.dta", clear
		by source host, sort: gen nvals=_n==1
		keep if nvals==1
		drop nvals
		foreach var of varlist gap_lon logdist col45 comlang_off lat_source landlocked {
			rename `var' `var'_2013
		}
		keep source sourcename host industrial *2013 sifc
		rename source zcode
		merge m:1 zcode using "$temp/iso_ifscode.dta"
		keep if _merge == 3
		rename ifscode source
		drop iso3 country country_v2 _merge zcode
		rename host zcode
		merge m:1 zcode using "$temp/iso_ifscode.dta"
		keep if _merge == 3
		rename ifscode host
		drop iso3 country country_v2 _merge zcode

		tempfile missing_gravity_vars
		save `missing_gravity_vars'
	restore

	merge m:1 source host using `missing_gravity_vars'
	drop _merge


	foreach var of varlist comlang_off col45 gap_lon logdist {
		replace `var' = `var'_2013 if source == 183 | host == 183 // Monaco
		replace `var' = `var'_2013 if source == 113 | host == 113 // Guernsey
		replace `var' = `var'_2013 if source == 118 | host == 118 // Isle of Man
		replace `var' = `var'_2013 if source == 117 | host == 117 // Jersey
		replace `var' = `var'_2013 if source == 147 | host == 147 // Liechtenstein
	}
	foreach var of varlist landlocked_source lat_source {
		replace `var' = `var'_2013 if source == 183 // Monaco
		replace `var' = `var'_2013 if source == 113 // Guernsey
		replace `var' = `var'_2013 if source == 118 // Isle of Man
		replace `var' = `var'_2013 if source == 117 // Jersey
		replace `var' = `var'_2013 if source == 147 // Liechtenstein
}
	
// Complete gravity variables for cpis-reporting jurisdictions (Curacao and Sint Maarten; Kosovo) 

	// Curacao and Sint Maarten - > recycle time-constant variables from Netherlands Antilles
		// comlang_off col45 lat_source landlocked industrial gap_lon
	
		// ensure consistency of dist and latitude and longitude variables
		replace dist = . if source == 355 | host == 355
		replace logdist = . if source == 355 | host == 355
	
		// extract source country vars
		preserve
			keep if source == 353
			keep source host year comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon
			drop if year>2010
			by source host, sort: gen nvals=_n
			keep if nvals==1
			drop nvals year
			replace source = 355
			foreach var of varlist comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon{
				rename `var' `var'_355_source
			}
			tempfile gravity_355_source
			save `gravity_355_source'
		restore
		
		// extract host country vars
		preserve
			keep if host == 353
			keep source host year comlang_off col45 industrial dist logdist gap_lon
			drop if year > 2010
			by source host, sort: gen nvals=_n
			keep if nvals == 1
			drop nvals year
			replace host = 355
			foreach var of varlist comlang_off col45 industrial dist logdist gap_lon{
				rename `var' `var'_355_host
			}
			tempfile gravity_355_host
			save `gravity_355_host'
		
		// merge to main dataset
		restore
		merge m:1 source host using `gravity_355_source'
		drop _merge
		foreach var of varlist comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon{
			replace `var' = `var'_355_source if `var' == . & `var'_355_source != . & year > 2009
			drop `var'_355_source
		}
		merge m:1 source host using `gravity_355_host'
		drop _merge
		foreach var of varlist comlang_off col45 industrial dist logdist gap_lon{
			replace `var' = `var'_355_host if `var' == . & `var'_355_host != .  & year > 2009
			drop `var'_355_host
		}
	
		// set to missing if country pair does not exist
		foreach var of varlist comlang_off col45 dist logdist gdp* pop* landlocked_source lat_source lon_source gap_lon industrial{
			replace `var' = . if source == 353 & year > 2009 | host == 353 & year > 2009
			replace `var' = . if source == 355 & year < 2010 | host == 355 & year < 2010
		}
		

		drop *2013

		
	// Kosovo -> recycle time-constant variables from Serbia
		// extract source country variables
		preserve
			keep if source == 942
			keep source host year comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon
			drop if year < 2010
			by source host, sort: gen nvals=_n
			keep if nvals == 1
			drop nvals year
			replace source = 967
			foreach var of varlist comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon{
				rename `var' `var'_967_source
			}
			tempfile gravity_967_source
			save `gravity_967_source'
		restore
		// extract host country variables
		preserve
			keep if host == 942
			keep source host year comlang_off col45 industrial dist logdist gap_lon
			drop if year < 2010
			by source host, sort: gen nvals=_n
			keep if nvals == 1
			drop nvals year
			replace host = 967
			foreach var of varlist comlang_off col45 industrial dist logdist gap_lon{
				rename `var' `var'_967_host
			}
			tempfile gravity_967_host
			save `gravity_967_host'
		restore
		// merge to main dataset
		merge m:1 source host using `gravity_967_source'
		drop _merge
		foreach var of varlist comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon{
			replace `var' = `var'_967_source if `var' == . & `var'_967_source != . & year > 2009
			drop `var'_967_source
		}
		merge m:1 source host using `gravity_967_host'
		drop _merge

		foreach var of varlist comlang_off col45 industrial dist logdist gap_lon{
			replace `var' = `var'_967_host if `var' == . & `var'_967_host != .  & year > 2009
			drop `var'_967_host
		}
		// set to missing if country pair does not exist
		foreach var of varlist comlang_off col45 dist logdist gdp* pop* landlocked_source lat_source lon_source gap_lon industrial{
			replace `var' = . if source == 967 & year < 2010 | host == 967 & year < 2010
		}

// fill gaps in blank country rows

	// source-level variables
	foreach var of varlist landlocked_source gdp_source loggdppc_source logpop_source pop_source gdppc_source lat_source  sifc_source gdppc_source{
		by source year, sort: egen help_`var' = mean(`var')
		replace `var' = help_`var' if `var' == .
		drop help_`var'
	}


	// host-level variables
 	foreach var of varlist gdppc_host gdp_host pop_host lon_host lat_host{
		by host year, sort: egen help_`var' = mean(`var')
		replace `var' = help_`var' if `var' == .
		drop help_`var'
	}

	// for bilateral variables
	foreach var of varlist comlang_off col45 gap_lon logdist dist industrial loggap_gdp loggap_gdppc{
		by source host year, sort: egen help_`var' = mean(`var')
		replace `var' = help_`var' if `var' == .
		drop help_`var'
	}

// merge indicator for cpis-reporting countries
merge m:1 source using "$temp\cpis_source.dta"
drop _merge

/// harmonise country names 
	// source countries
	rename source ifscode
	merge m:1 ifscode using "$temp/iso_ifscode.dta"
	drop if _merge == 2 // Curacao; Sint Maarten
	rename ifscode source
	replace sourcename = country
	drop country
	drop _merge

	// host countries
	rename host ifscode 
	merge m:1 ifscode using"$temp/iso_ifscode.dta"
	drop if _merge == 2 // Curacao; Sint Maarten
	rename ifscode host
	replace hostname = country
	drop country iso3 _merge
	
// keep final variables
keep year source host sourcename eqasset debtasset hostname comlang_off col45 landlocked_source lat_source lat_host lon_host sifc_source cpis gdp_source gdppc_host gap_lon industrial logeqasset logdebtasset logdist loggap_gdp loggap_gdppc loggdppc_source logpop_source

label var logeqasset "Log equities"
label var logdebtasset "Log debt"
label var comlang_off "Common language"
label var col45 "Colony dummy"
label var logdist "Log distance"
label var logpop_source "Log of sce ctry population"
label var loggdppc_source "log gdp per capita sce ctry"
label var loggap_gdp "Log of GDP gap"
label var loggap_gdppc "Log of GDP p.c. gap"
label var industrial "industrial pair"
label var lon_host "longitude host ctry"
label var lat_source "latitude sce ctry"
label var cpis "cpis reporter"

order year source host sourcename eqasset debtasset hostname comlang_off col45 landlocked_source lat_source lat_host lon_host sifc_source gdp_source cpis gdppc_host gap_lon industrial logeqasset logdebtasset logdist loggap_gdp loggap_gdppc loggdppc_source logpop_source
compress
save "$temp\data_gravity_update.dta", replace


//----------------------------------------------------------------------------//







