//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: construct foreign owned time series of swiss fiduciary deposits 
// spanning 1987 to 2023
//
// databases used: - "$raw/snb/snb-data-fiduciary-yearly.csv"
//                 - "$raw\dta\iso3_ifs.dta"
//                 - "$raw/Exchange_Rates_incl_Switzerland.xlsx"
//                 - "$raw/fiduciary_1976-2014.dta"
//                 - "$raw/snb/snb-data-fiduciary-yearly-domestic.csv"
//                 - "$raw/snb/Multiplicative_FactorSNB.xlsx"
//                 - "$work/fdi-havens"
//                 - "$work/havens_list.dta"
//
// outputs:        - "$work/fiduciary-87-23_uncorr.dta"
//                 - "$work/fiduciary-87-23.dta", replace
//----------------------------------------------------------------------------//



********************************************************************************
****** I ---- Cleaning and country code merge of SNB fiduciary data -----*******
********************************************************************************

*--------------I.1 - Adjust swiss fiduciary variables name---------------------*
import delimited "$raw/snb/snb-data-fiduciary-yearly.csv", clear
rename (v1 v3 v6) (year iso3 lfidu)
keep year iso3 lfidu
drop in 1/3
destring year lfidu, replace
tempfile fiduciary1
save `fiduciary1'
*---------------I.2 - Merge fiduciary accounts to ISO codes---------------------*
use "$raw\dta\iso3_ifs.dta", clear
keep iso3 region region_name chart_name 
drop if iso3 == ""
duplicates drop
merge 1:m iso3 using `fiduciary1', nogenerate keep(2 3)
rename chart_name cn
rename iso3 ccode

*-----------------I.3 - Minor adjustements to the data-------------------------*	
drop if ccode=="A"
replace cn = "France" if ccode == "BIZ_FR"
replace cn = "United States Minor Outlying Islands" if ccode == "BIZ_PU"
replace cn = "West Indies UK" if ccode == "BIZ_1Z"
* drop various countries and not assignable
drop if ccode == "XVU"
replace ccode = "FRA" if cn == "France"
replace ccode = "UMI" if cn == "United States Minor Outlying Islands"
* west indies is BIZ_1Z in the BIS
replace ccode = "VGB" if ccode == "BIZ_1Z"
* British overseas territories is TAA
replace ccode = "IOT" if ccode == "TAA" 						// IOT is part of British Overseas Territories in BIS definition
replace cn = "British Overseas Territories" if ccode == "IOT"
* Jersey
replace cn = "Jersey" if ccode == "JEY"
* congo
replace cn = "Congo" if ccode == "COG"
tempfile fiduciary2
save `fiduciary2'

*--------------------I.4 - MERGE TO CONVERSION RATES---------------------------*
import excel "$raw/Exchange_Rates_incl_Switzerland.xlsx", ///
sheet(usd_chf) firstrow clear 
destring Year, replace
drop if Year < 1987
rename (Year DomesticCurrencyperUSDolla) (year uschf_end)
merge 1:m year using `fiduciary2', nogenerate
tempfile fiduciary3
save `fiduciary3'

*-----------I.5 - MERGE USD FIDUCIARY ACCOUNTS TO IFS COUNTRY CODES------------*
use "$raw\dta\iso3_ifs.dta", clear
keep ifscode iso3
*replace ifscode = 371 if iso3 == "VGB"
rename iso3 ccode
drop if ccode == "GLP"
*drop if ifscode == 353 & ccode == "CUW"
drop if ccode == ""
drop if ifscode == .
merge 1:m ccode using `fiduciary3', nogenerate keep(2 3)
drop if ccode == "UMI" & year >= 2001 & year <= 2004
drop if ccode == "SRB" & year >= 2001 & year <= 2006
*replace ifscode = 1017 if ccode == "JEY"
*replace ifscode = 634 if ccode == "COG"
*replace ifscode = 585 if ccode == "IOT"			
drop region
drop region_name
sort ifs year
tempfile fiduciary4
save `fiduciary4'

********************************************************************************
*** II--- Append havens not present anymore in Swiss fiduciary data ************
********************************************************************************
*-----------------II.1 - Minor adjustements to the data------------------------*
* Append havens in the XXth century not present in current publicly 
* available version of Swiss fiduciary deposits
use "$raw/fiduciary_1976-2014.dta", clear
keep if cn == "Netherlands Antilles"| cn=="St. Kitts and Nevis" | ///
cn == "Monaco" | cn == "France" & year <= 2004 & year >=1987 | ///
cn == "Yugoslavia" | cn == "USSR" | cn == "British Antilles" | ///
cn == "Antigua and Barbuda" | cn == "German Democratic Republic" | ///
cn=="Tchecoslovakia" | cn=="Western Sahara" | ///
iso3 == "UMI" & year >= 2001 & year <= 2004 | ///
iso3 == "SRB" & year >= 2001 & year <= 2006
replace cn = "United States Minor Outlying Islands" if iso3 == "UMI"
append using `fiduciary4'
drop if year < 1987
drop lfidu_usd
replace ccode = iso3 if ccode == ""
drop iso3
drop if lfidu==. & ccode=="FRA"
drop if lfidu==. & cn=="West Indies UK"
foreach ctry in ANT KNA MCO YUG USSR ATG GDR Tcheco ESH {
	replace lfidu = lfidu*1000 if ccode == "`ctry'"
	}
replace lfidu = lfidu*1000 if cn == "British Antilles"
replace lfidu = lfidu*1000 if ccode == "FRA" & year <=2004
drop if cn=="British Antilles" & year>=2005
replace lfidu = lfidu*1000 if ccode == "UMI" & year >=2001 & year <= 2004
replace lfidu = lfidu*1000 if ccode == "SRB" & year >=2001 & year <= 2006
* The file "data_fiduciary_accounts87-21" contains the raw data on Swiss 
* fiduciary deposits coming from the 1987-2022 editions of the Swiss National 
* Bank's "Banks in Switzerland" lfidu = fiduciary deposits as recorded in 
* "Banks in Switzerland" 

*-----------------II.2 - Minor adjustements to the data------------------------*
* Fill some missing  country names
replace cn="St Helen" if ccode=="SHN"
drop if cn == ""
tempfile fiduciary5
save `fiduciary5'

********************************************************************************
************** III ------- The case of Liechtenstein  **************************
********************************************************************************
* Before 1984, Liechtenstein is considered as a foreign country (and it is the 
* biggest foreign holder of deposits). After 1984, deposits from Liechenstein 
* are considered to be Swiss deposits For the post 1984 period, I compute 
* deposits from Liechtenstein as 45% of Swiss-owned fiduciary deposits 
* (45%=share of Liechtenstein deposits in (Liechtenstein + Switzerland) 
* deposits in 1983) (NB: virtually 100% of the "Swiss-owned" fiduciary deposits 
* may have foreign beneficial owners)
import delimited "$raw/snb/snb-data-fiduciary-yearly-domestic.csv", ///
clear rowrange(5:41)
rename v7 lfidu
gen ccode = "LIE"
rename cubeid year
rename v8 uschf_end
keep year ccode lfidu uschf_end
forvalues i = 1987/2023 {
	preserve
	keep if year == `i'
	local fiduLIE`i' = lfidu
	restore
}
forvalues y = 1987/2023 {
replace lfidu = 0.45*`fiduLIE`y'' if year == `y' 
}
gen cn = "Liechtenstein"
*gen ifscode = 9006 // 9006= country code used in Zucman's paper
gen ifscode=147
append using "`fiduciary5'"

********************************************************************************
************** IV ------ Bank-office level fiduciary deposits ******************
********************************************************************************
// By-country breakdown of SNB data follows the parent company level consolidation principle, which excludes deposits held by foreign subsidiaries. For instance, UBS Switzerland could locate deposits in UBS Jersey. We thus scale-up the liabilities at parent company level by the ratio of the total fiduciary deposits consolidated at the bank office level and the total fiduciary deposits consolidated at the parent company level. This does not affect the ownership distribution but just the overall level.
label variable lfidu ///
"Fiduciary liabilities at the parent company level, thousands of CHF" 
gen lfidudol=lfidu/uschf_end
label variable lfidudol ///
"Fiduciary liabilities at the parent company level, thousands of US$ (end of p. exch)" 
sort year
tempfile fiduciary6
save `fiduciary6'
import excel "$raw/snb/Multiplicative_FactorSNB.xlsx", ///
clear firstrow cellrange(A24:D61)
keep year factor
destring year, replace
merge 1:m year using `fiduciary6', nogenerate
label variable factor ///
"Aggregate scale-up factor for deposits, from Parent Company to Bank Office level"
gen lfidu2 = lfidu*factor
label variable lfidu2 ///
"Fiduciary liabilities at the bank office level, thousands of CHF"
gen lfidu2dol=lfidu2/uschf_end
label variable lfidu2dol ///
"Fiduciary liabilities at the bank office level, thousands US$ (end of p. exch)"
drop factor uschf_end

********************************************************************************
************** V ------ Other adjustments ****************************
********************************************************************************

*-----------------V.1 - Greece ------------------------------------------------*
* Use 2021 share for Greece as 2022 and 2023 as Greek deposits suddenly increase 
* by a factor of 3

foreach var in lfidu lfidudol lfidu2 lfidu2dol{
	by year, sort: egen `var'_total = total(`var')
	gen `var'_share = `var'/`var'_total
}
sort ccode year

foreach var in lfidu lfidudol lfidu2 lfidu2dol{
	replace `var'_share =  `var'_share[_n-1] if ccode == "GRC" & year == 2022
	replace `var'_share =  `var'_share[_n-1] if ccode == "GRC" & year == 2023
	replace `var' = `var'_share * `var'_total if ccode == "GRC" & year > 2021
}

drop *total *share

*-----------------V.2 - STD adjustment------------------------*
* correct distribution of fiduciary deposits in the years 2005-2006 as it is 
* contaminated by the effects of the STD
sort ccode year

foreach var in lfidu lfidudol lfidu2 lfidu2dol{
	by ccode, sort: egen help = mean(`var') if year==2003|year==2004
	by ccode, sort: egen `var'_0304 = mean(help)
	gen `var'_adj = `var' if year < 2005
	replace `var'_adj = `var'_0304 if (year == 2005 | year==2006) & ccode != "VEN" // for consistency with AJZ we use the 2003/04 average for the years 2005-2007 to avoid contamination of the STD but keep the 2006 value for Venezuela because of big Chavez fund held in Swiss bank at the time 										
	gen help2 = `var' if year == 2006 & ccode == "VEN"
	by ccode, sort: egen `var'_chavez = mean(help2)
	replace `var'_adj = `var'_chavez if (year == 2005 | year == 2006) & ccode == "VEN" // For consistency with AJZ who use 2006 value for the mean of 2006/2007 Venezuela
	drop hel* `var'_0304 `var'_chavez
	replace `var'_adj = `var' if ccode == "PNG" | ccode == "BOL"  // Papua New Guinea and Bolivia have exceptional spikes in Swiss deposits in 2003 or 2004 -> better use original data instead of artificially inflating 2005-2006.
}


foreach var in lfidu lfidudol lfidu2 lfidu2dol{
sort ccode year
* let deposits grow at orginal growth rates after 2007
gen g_`var' = `var' / `var'[_n-1] if ccode==ccode[_n-1]
replace `var'_adj = `var'_adj[_n-1] * g_`var' if year > 2006

* Ensure that 0 fiduciary deposits in one year does not lead to 0 fiduciary 
* deposits in all following years (affects very small jurisdictions)
replace `var'_adj = `var' if `var'_adj == . & `var' != 0

* rescale such that overall growth of fiduciary deposits is preserved
by year, sort: egen `var'_total = total(`var')
gen `var'_share = `var'/`var'_total
by year, sort: egen `var'_total_adj = total(`var'_adj)
gen `var'_share_adj = `var'_adj/`var'_total_adj
replace `var'_adj = `var'_share_adj * `var'_total // apply adjusted shares to original total
replace `var'_adj = 0 if `var'_adj == . & `var' == 0
replace `var'_share_adj = 0 if `var'_share_adj == . & `var' == 0
*drop `var'_total* g_`var' 
}

		
/* visual check adjustment effects: plot orig fidu vs. adj fidu
twoway (line lfidu2dol_share year) (line lfidu2dol_share_adj year) if (ccode == "LIE" | ccode == "VGB" |ccode == "PAN"|ccode=="ITA"|ccode=="SAU"|ccode=="GBR"|ccode=="FRA"|ccode=="VEN" |ccode == "ARE" |ccode=="JEY"|ccode =="CYP" |ccode=="DEU"), by(ccode) name("orig", replace)

foreach iso in "BIH" "BTN" "COM" "CUB" "FJI" {
twoway (line lfidu2dol_share year) (line lfidu2dol_share_adj year) if ccode == "`iso'" & year > 2000, title("`iso'") name("`iso'_2", replace)
}

foreach iso in "GNB" "ISR" "KAZ" "KGZ" "LAO" "LSO" "MDA" "MNG" "MRT" "NIC" "PNG" "SLB" "SOM" "THA" "UZB"{
twoway (line lfidu2dol_share year) (line lfidu2dol_share_adj year) if ccode == "`iso'" & year > 2000, title("`iso'") name("`iso'_2", replace)
}

preserve
	label var lfidu2dol "lfidu2dol"
	twoway (line lfidu2dol year) (line lfidu2dol_adj year) if ccode == "LIE" | ccode == "VGB" |ccode == "PAN"|ccode=="ITA"|ccode=="SAU"|ccode=="GBR"|ccode=="FRA"|ccode=="VEN" |ccode == "ARE" |ccode=="JEY"|ccode =="CYP" |ccode=="DEU", by(ccode)
restore
*/
	

* replace original by corrected distribution (constant shares between 2005-2006)
foreach var in lfidu lfidudol lfidu2 lfidu2dol{
	gen `var'_orig = `var'
	replace `var' = `var'_adj
}

drop *_adj *_share*


tempfile fiduciary7
save `fiduciary7'

********************************************************************************
************ VI ------  Foreign Direct Investment Adjustment ********************
********************************************************************************
use "$work/fdi-havens", clear
drop inward receiving country
reshape wide share, i(country_iso3 year) j(receiving_iso3) string
rename country_iso3 ccode
merge 1:1 ccode year using "`fiduciary7'", nogenerate

* Iterate over each share column and allocate the lfidu2dol amounts
gen lfidu2dol_fdi_adjustment = lfidu2dol_orig if year >= 2001
ds share*
local share_columns `r(varlist)'
forvalues i = 2001/2023 {
foreach col in `share_columns' {  // Replace with your list of share columns
    local country_code = substr("`col'", 6, .)
    
    // Sum the share multiplied by the corresponding country's total_lfidu2dol
    quietly sum lfidu2dol if ccode == "`country_code'" & year == `i'
	local amount = r(sum)
    replace lfidu2dol_fdi_adjustment = lfidu2dol_fdi_adjustment + (`col' * `amount') if `col' ~= . & `amount' ~= . & year == `i'
	su `col' if year == `i'
	local total_share = r(sum)
	if `total_share' ~= 0 {
	replace lfidu2dol_fdi_adjustment = 0 if ccode == "`country_code'" & year == `i' 
	}
}
}

label variable lfidu2dol_fdi_adjustment ///
"Fiduciary liabilities at the bank office level, thousands US$ (end of p. exch), adjusted with FDI data"
drop share*

// fill the missing information because missing years      
sort ccode year
bysort ccode: replace cn=cn[_n-1] if missing(cn)  & !missing(cn[_n-1]) 
sort ccode year
bysort ccode: replace ifscode=ifscode[_n-1] if missing(ifscode)   & !missing(ifscode[_n-1]) 

gsort ccode -year
bysort ccode: replace cn=cn[_n-1] if missing(cn)  & !missing(cn[_n-1]) 
gsort ccode -year
bysort ccode: replace ifscode=ifscode[_n-1] if missing(ifscode)   & !missing(ifscode[_n-1]) 
     
********************************************************************************
************** VII ------ Russia-Cyprus adjustment ******************************
********************************************************************************
* Allocates 80% of Cyprus-owned Swiss deposits to Russian owners. 20% remain with 
*Cyprus households (and will be allocated to other non-haven countries in 7a-build-offshore)
gen lfidu2dol_russia_adjustment = lfidu2dol
forvalues i = 2001/2023 { 
	sum lfidu2dol if ccode == "CYP" & year == `i'
	local amount2 = r(sum)
	replace lfidu2dol_russia_adjustment = lfidu2dol_russia_adjustment + 0.8* `amount2' ///
	if ccode == "RUS" & year == `i'
	replace lfidu2dol_russia_adjustment = lfidu2dol_russia_adjustment - 0.8* `amount2' ///
	if ccode == "CYP" & year == `i'
}

label var lfidu2dol_orig "orig"
label var lfidu2dol "STD adj"
label var lfidu2dol_fdi_adjustment "FDI adj"
label var lfidu2dol_russia_adjustment "Cyprus adj"
sort ccode year

/* visual check adjustment effect
twoway (line lfidu2dol_orig year) (line lfidu2dol year) (line lfidu2dol_fdi_adjustment year) (line lfidu2dol_russia_adjustment year) if ccode == "RUS", title("Russian deposits in Switzerland")
*/
********************************************************************************
************** VIII----- Definition of Geographical areas ************************
********************************************************************************
/* Euro area members as of December 31st, 2010 */
/* 11 initial members of the euro area */
gen euro11 = 0 
#delimit;
replace euro11 = 1 if cn == "Austria" | cn == "Belgium" | cn == "Finland" | ///
cn == "France" | cn == "Germany" | cn == "Ireland" | cn == "Italy" | ///
cn == "Luxembourg"| cn == "Netherlands" | cn == "Portugal" | cn == "Spain";
/* All members as of July, 2011 */
gen euro17 = euro11;
replace euro17 = 1 if cn == "Cyprus" | cn == "Estonia" | cn == "Greece" | ///
cn == "Malta" | cn == "Slovak Republic" | cn == "Slovenia" ;
#delimit cr
/* All members as of December 31st, 2010 */
gene euro16 = euro17
replace euro16 = 0 if cn == "Estonia"
drop euro11 euro17
/* Set of rich countries */
gen rich = 0
replace rich = 1 if ifscode<200 | euro16 == 1
replace rich = 0 if cn == "San Marino" | cn == "South Africa" | ///
cn == "Turkey" | cn == "Vatican"
gen developing = 0
replace developing = 1 if rich == 0


*******tempfile to merge to haven list 
tempfile tempfile_to_merge_to_haven
save `tempfile_to_merge_to_haven'

use "$work/havens_list.dta", clear 
rename iso3c ccode
drop if ccode == "" 
keep ccode ofc_pure_haven 
merge 1:m ccode using `tempfile_to_merge_to_haven'
drop if _merge==1
drop _merge
*******

gen ofc = 0
replace ofc = 1 if ofc_pure_haven==1 
drop ofc_pure_haven

/* Continents */
gen north_am=0
replace north_am=1 if cn=="United States of America"|cn=="Canada"
gen latin_am=0
replace latin_am=1 if ifscode>=200&ifscode<300 | cn=="Falkland Islands"
replace latin_am = 0 if ccode == "PSE" | cn=="Yugoslavia" 
gen caribbean=0
replace caribbean=1 if ifscode>=300&ifscode<400
replace caribbean=1 if cn=="Cuba" |cn == "Sint Maarten (Dutch part)"
replace caribbean = 0 if cn == "Curacao"|cn=="Netherlands Antilles" | ///
cn=="St. Kitts and Nevis"| cn=="British Antilles"|cn=="Falkland Islands"| ///
cn=="Aruba" 
gen middle_east=0
replace middle_east=1 if ifscode>=400&ifscode<500 | ccode == "PSE"
replace middle_east=0 if cn=="Cyprus" /* euro area */
gen asia=0
replace asia=1 if ifscode>=500&ifscode<600 
replace asia=1 if cn=="Australia"|cn=="New Zealand"|cn=="Japan"| ///
cn=="China"| cn=="Korea, Dem. Rep." 
replace asia=1 if cn=="Mongolia"|cn=="Tuvalu"|cn=="French Polynesia" | ///
ccode=="UMI"
replace asia=1 if cn=="Vanuatu"|cn=="Tonga"|cn=="Papua New Guinea"|cn=="Nauru"
replace asia=1 if cn=="New Caledonia"|cn=="Wallis et Futuna"| ///
cn=="St Helena"|cn=="Kiribati"|cn=="Solomon Islands"|cn=="Fiji"| ///
cn=="Wallis and Futuna Islands"
replace asia=1 if cn=="Ouzbekistan"|cn=="Kyrgyz Republic"| ///
cn=="Turkmenistan"|cn=="Tajikistan"|cn=="Uzbekistan"| ///
cn=="Korea (Democratic People's Republic of)"| cn =="USSR" | cn == "Samoa"


/* Countries at the frontier between Europe and Asia: */
replace asia=1 if cn=="Georgia"|cn=="Russian Federation"|cn=="Armenia"| ///
cn=="Azerbaijan"|cn=="Kazakhstan"|cn=="Turkey" | cn =="Kyrgyzstan" ///
| cn =="St Helen"
replace asia=0 if cn=="Macao" | cn =="Bonaire, Sint Eustatius and Saba"| ///
cn=="Sint Maarten (Dutch part)"
gen africa=0
replace africa=1 if (ifscode>=600&ifscode<700)|(ifscode>=700&ifscode<800)
replace africa=1 if cn=="South Africa" | cn == "Western Sahara"
replace africa = 0 if ccode == "FRO" | cn == "Samoa" | cn == "Andorra"
gen europe=0
replace europe=1 if ifscode<200&north_am!=1&asia!=1&africa!=1&cn!="Turkey"
replace europe=1 if euro16==1
replace europe=0 if cn=="Luxembourg"
#delimit;
replace europe=1 if cn=="Croatia"|cn=="Estonia"|cn=="Ukraine"|cn=="Moldova"
|cn=="Serbia"| cn == "Montenegro" |cn=="Czech Republic"|cn=="Romania"| 
cn=="Belarus"|cn=="Bosnia and Herzegovina" | cn == "Andorra"
|cn=="Bulgaria"|cn=="Lithuania"|cn=="Latvia"| cn=="Slovakia"| 
cn=="Moldova (Republic of)"| cn == "San Marino" | ccode == "FRO" |
cn=="Albania"|cn=="Poland"|cn=="Hungary"|cn=="Macedonia (former Yugoslav)"| 
cn=="Yugoslavia" |cn=="Tchecoslovakia"| cn=="German Democratic Republic";
#delimit cr

/* other countries */
replace latin_am=1 if cn=="Cuba"
replace europe=1 if cn=="Greenland"
replace latin_am=1 if cn=="Guyana"
replace latin_am=1 if cn=="Jamaica"
replace asia=1 if cn=="Micronesia (Federated States of)"
replace latin_am=1 if cn=="Suriname"

/* Drop offshore financial centers from continents and groups */
replace rich=0 if rich==1&ofc==1
replace developing=0 if developing==1&ofc==1
replace europe=0 if europe==1&ofc==1
replace middle_east=0 if middle_east==1&ofc==1
replace africa=0 if africa==1&ofc==1
replace asia=0 if asia==1&ofc==1
replace caribbean=0 if caribbean==1&ofc==1
replace latin_am=0 if latin_am==1&ofc==1
replace north_am=0 if north_am==1&ofc==1
 
/* Define labels */
gen continent = ///
	1*africa + 2*europe + 3*middle_east + 4*asia + 5*caribbean + ///
	6*latin_am + 7*north_am + 8*ofc
label variable continent "Continent"
label define continentlbl ///
	1 "Africa" 2 "Europe" 3 "Middle East" 4 "Asia" ///
	5 "Caribbean" 6 "Latin and South America" 7 "North America" 8 "OFC"
label values continent continentlbl
gen group = 1*rich + 2*developing + 3*ofc
label variable group "Country groups"
label define grouplbl 1 "Rich" 2 "Developing" 3 "OFC"
label values group grouplbl
label var cn "Counterparty country name"
label var ccode "Counterparty country ISO alpha-2"
label var ofc "Offshore financial centre"
label var ifscode "Counterparty country international financial statistics code"

sort ifscode year

preserve
drop lfidu lfidudol lfidu2 lfidu2dol
rename *_orig *
save "$work/fiduciary-87-23_uncorr.dta", replace
restore
drop *orig
save "$work/fiduciary-87-23.dta", replace

//----------------------------------------------------------------------------//