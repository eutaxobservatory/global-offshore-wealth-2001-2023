// =============================================================================
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: build a simpler dataset of each country offshore wealth in total, 
// in haven groups (american, european, caribbean, asian and swiss), and the 
// total wealth attracted by each haven
// 
// databases used: - "$raw/AJZ2017bData.xlsx", sheet(T.A1)
//                 - "$work/global_portfolio_gap.dta"
//                 - "$raw/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_2.csv"
//                 - "$work/offshore_wealth_in_switzerland_yearly.dta"
//                 - "$work/bisdepbyhaven_hh.dta"
//                 - "$work/offshore`i'"
//                 - "$work/assembled_gdp_series.dta"
//                 - "$work/countries"
//                 - "$raw/dta/country_frame"
// 
// outputs:        - "$work/ofw_aggregate"
//                 - "$raw/AJZ2017DataUpdated.xlsx",sheet(ctrybyctry01-23) 
//                 - "$work/countries"
//                 
// =============================================================================


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

// compute each haven's offshore wealth in USD bn
foreach region in "americ" "asia" "europ" {
gen `region'_pct = bis_`region' / bis_total * ofw_other / ofw * 100
label var `region'_pct "OFW attracted by region in % of total OFW"
}
	foreach ofc in "PA" "KY" "US"{
		gen `ofc'_pct = americ_pct * dep`ofc' / bis_americ
		label var `ofc'_pct "OFW attracted in % of total"
		gen `ofc'_usd	  = `ofc'_pct * ofw / 100
		label var `ofc'_usd "OFW attracted in USD bn"
	}
	
	foreach ofc in "AE" "AN" "BH" "BM" "BS" "CW" "HK" "MO" "MY" "SG"{
		gen `ofc'_pct = asia_pct * dep`ofc' / bis_asia
		gen `ofc'_usd	  = `ofc'_pct * ofw / 100
		label var `ofc'_usd "OFW attracted in USD bn"
	}

	foreach ofc in "AT" "BE" "CY" "GB" "GG" "IM" "JE" "LU"{
		gen `ofc'_pct = europ_pct * dep`ofc' / bis_europ
		gen `ofc'_usd	  = `ofc'_pct * ofw / 100
		label var `ofc'_usd "OFW attracted in USD bn"
	}
	
keep year ofw_CH ofw_europ ofw_asia ofw_americ *usd
rename *_usd *

forvalues i = 2001/2023 {
	preserve
	keep if year == `i'
	save "$temp/attracted_`i'.dta", replace
	restore
}

* Then we add the amount attracted by each tax haven
forvalues i = 2001/2023 {
	use "$temp/attracted_`i'", clear
	merge 1:m year using "$work/offshore`i'", nogenerate
	replace year = `i'
	* Compute country level offshore wealth using the shares (from offshore)
	* and the aggregates (from AJZ), including for our three indicators 
	gen offshore_switzerland = (ofw_CH*sh_fidu_smthg`i')
	gen offshore_switzerland_corrected = ///
	(ofw_CH*sh_fidu_fdi_adjustment_smthg`i')
	gen offshore_swiss_rus_adjustment= ///
	(ofw_CH*sh_fidu_rus_adjustment_smthg`i')
	gen offshore_EU_Havens = (ofw_europ*sh_EU_smthg`i')
	gen offshore_AS_Havens = (ofw_asia*sh_AS_smthg`i')
	gen offshore_CR_Havens = (ofw_americ*sh_CR_smthg`i')
	egen offshore_total = rowtotal(offshore_switzerland offshore_EU_Havens ///
	offshore_AS_Havens offshore_CR_Havens), missing
	egen offshore_total_corrected = ///
	rowtotal(offshore_switzerland_corrected offshore_EU_Havens ///
	offshore_AS_Havens offshore_CR_Havens), missing
	egen offshore_total_rus_adjustment= ///
	rowtotal(offshore_swiss_rus_adjustment offshore_EU_Havens ///
	offshore_AS_Havens offshore_CR_Havens)
	gen ratio_offshore_GDP = offshore_total/(gdp`i'/1000000000)
	gen ratio_offshore_GDP_corrected = ///
	offshore_total_corrected/(gdp`i'/1000000000) 
	gen ratio_offshore_GDP_rus_adjust= ///
	offshore_total_rus_adjustment/(gdp`i'/1000000000) 
	keep if bank == "CH"
	keep iso3saver year offshore_total offshore_total_corrected ///
	offshore_switzerland offshore_switzerland_corrected offshore_EU_Havens ///
	offshore_AS_Havens offshore_CR_Havens latin_am offshore_total_rus_adjustment ///
	europe asia africa offshore_swiss_rus_adjustment KY PA US HK SG MO MY BH BS BM ///
	GG JE IM LU CY GB AT AN BE AT CW AE ofw_CH

		
	gen off6 = .
	replace off6 = ofw_CH if iso3saver == "CHE"
	replace off6 = KY if iso3saver == "CYM"
	replace off6 = PA if iso3saver == "PAN"
	replace off6 = US if iso3saver == "USA"
	replace off6 = HK if iso3saver == "HKG"
	replace off6 = SG if iso3saver == "SGP"
	replace off6 = MO if iso3saver == "MAC"
	replace off6 = MY if iso3saver == "MYS"
	replace off6 = BH if iso3saver == "BHR"
	replace off6 = BS if iso3saver == "BHS"
	replace off6 = BM if iso3saver == "BMU"
	replace off6 = GG if iso3saver == "GGY"
	replace off6 = JE if iso3saver == "JEY"
	replace off6 = IM if iso3saver == "IMN"
	replace off6 = LU if iso3saver == "LUX"
	replace off6 = CY if iso3saver == "CYP"
	replace off6 = GB if iso3saver == "GBR"
	replace off6 = AT if iso3saver == "AUT"
	replace off6 = BE if iso3saver == "BEL"
	replace off6 = AN ///
	if iso3saver == "ANT" & year <= 2009
	replace off6 = CW ///
	if iso3saver == "CUW" & year > 2009
	replace off6 = AE if iso3saver == "ARE"

	* We make adjustment and reshape the file
	rename offshore_swiss_rus_adjustment off9
	rename offshore_total_rus_adjustment off10
	rename offshore_switzerland_corrected off7
	rename offshore_total_corrected off8
	rename offshore_total off5
	rename offshore_switzerland off4
	rename offshore_EU_Havens off3
	rename offshore_AS_Havens off2
	rename offshore_CR_Havens off1
	reshape long off, i(iso3saver) j(haven_group)
	gen haven_group1 = "total" if haven_group == 5
	replace haven_group1 = "total_attracted" if haven_group == 6
	replace haven_group1 = "swiss" if haven_group == 4
	replace haven_group1 = "europe" if haven_group == 3
	replace haven_group1 = "asian" if haven_group == 2
	replace haven_group1 = "americ" if haven_group == 1
	replace haven_group1 = "total_corrected" if haven_group == 8
	replace haven_group1 = "swiss_corrected" if haven_group == 7
	replace haven_group1 = "swiss_russia_adjustment" if haven_group == 9
	replace haven_group1 = "total_russia_adjustment" if haven_group == 10
	gen unit = "USD Bn"
	gen label = ""
	replace label = "offshore wealth in American tax havens" ///
	if haven_group1 == "americ"
	replace label = "offshore wealth in Asian tax havens" ///
	if haven_group1 == "asian"
	replace label = "offshore wealth in European tax havens" ///
	if haven_group1 == "europe"
	replace label = "total offshore wealth" if haven_group1 == "total"
	replace label = "offshore wealth in Switzerland" if haven_group1 == "swiss"
	replace label = "total offshore wealth attracted by this jurisdiction" ///
	if haven_group1 == "total_attracted"
	replace label = "offshore wealth in Switzerland, corrected amounts" ///
	if haven_group1 == "swiss_corrected"
	replace label = "total offshore wealth, corrected amounts" ///
	if haven_group1 == "total_corrected"
	replace label = "total offshore wealth, rus_adjustment estimate" ///
	if haven_group1 == "total_russia_adjustment"
	replace label = "offshore wealth in Switzerland, rus_adjustment estimate" ///
	if haven_group1 == "swiss_russia_adjustment"
	drop haven_group
	rename off value
	keep iso3saver value haven_group1 year unit label latin_am ///
	europe asia africa 
	rename haven_group1 indicator
	rename iso3saver iso3
	* drop shell 
	drop if iso3 == "BEH" | iso3 == "CHH" | iso3 == "GBH" | ///
	iso3 == "IEH" | iso3 == "NLH" | iso3 == "USH" | iso == "TWH"
	if year == 2001 {
		save "$work/countries", replace
		}
		if year ~= 2001 {
			append using "$work/countries"
			save "$work/countries", replace
			}
			sleep 500
			erase "$temp/attracted_`i'.dta"
			}
			

// merge GDP and clean
			use "$work/assembled_gdp_series.dta", clear
			keep iso3 year gdp_current_dollars
			merge 1:m year iso3 using "$work/countries", keep(2 3) nogenerate
			merge m:1 iso3 using "$raw/dta/country_frame", keepusing(country_name incomelevel regionname) keep(1 3) nogenerate
			* give to Netherlands Antilles the incomelevelgroup and region of curaçao
			replace country_name = "Netherlands Antilles" if iso3 == "ANT"
			replace incomelevelname = "High income" if iso3 == "ANT"
			replace regionname = "Latin America & Carribean" if iso3 == "ANT"
			* labels
			label var value "Offshore wealth, in bn USD"
			label var gdp "GDP, current prices"
			label var year "Year"
			label var country_name "Country"
			label var iso3 "Country ISO alpha-3 code"
			label var unit "Unit and currency"
			label var indicator "Abbr. of location of offshore wealth"
			label var label "Location of offshore wealth"
			drop europe asia latin_am africa
			order year iso3 country_name indicator label unit value gdp regionname incomelevelname
			sort year iso3 indicator
			export excel using "$raw/AJZ2017DataUpdated.xlsx", ///
			sheet(ctrybyctry01-23) firstrow(variables) sheetreplace
			save "$work/countries", replace
			
			
********************************************************************************
			
