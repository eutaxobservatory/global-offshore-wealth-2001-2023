//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: create a dataset of the distribution of foreign direct investment
// in several havens
// takes inward direct investment in tax havens (+ Ireland, UK, Netherlands, Belgium)
// and outward direct investment reported by their counterpart in tax havens (when 
// the inward data is unavailable). We delete tax havens (+ aforementioned countries) 
// from this dataset and proceed to compute the shares seen in total direct investment 
// in a specific haven.   
//  
// databases used: - "$raw/IMF_CDIS_direct-investment-position-20250402"
//       		   - "$work/havens_list.dta"
//       
// outputs:        - "$work/fdi-havens.dta"
//----------------------------------------------------------------------------//



********************************************************************************
* Clean the completed direct investment position dataset: 
	* website:https://data.imf.org/en/Data-Explorer?datasetUrn=IMF.STA:DIP(12.0.0)  , IMF, Dataset: "Direct Investment Positions by Counterpart Economy (formerly CDIS)"
	import delimited using "$raw/IMF_CDIS_direct-investment-position-20250402", clear 
********************************************************************************

	* keep only official reported data 
	keep if dv_type=="Reported official data"
	
	* select inward and outward direct investment 
	keep if indicator=="Inward Direct investment, Net (liabilities less assets), All financial instruments, All entities" ///
	| indicator=="Outward Direct investment, Net (assets less liabilities), All financial instruments, All entities"
	
	*drop scale //same units as before (millions)
	keep country  counterpart_country  indicator v33-v47
	
	forvalues i =33/47{
		local year = 1976+`i'
		rename v`i' inward_direct_invest`year'
	}
	
	* depending on the indicator we need to harmonize the countries variables 
gen receiving=""
gen country_new=""
replace receiving=country	if indicator=="Inward Direct investment, Net (liabilities less assets), All financial instruments, All entities"
replace country_new=counterpart_country	if indicator=="Inward Direct investment, Net (liabilities less assets), All financial instruments, All entities"	

replace receiving=counterpart_country if indicator=="Outward Direct investment, Net (assets less liabilities), All financial instruments, All entities"
replace country_new=country	if indicator=="Outward Direct investment, Net (assets less liabilities), All financial instruments, All entities"

drop country counterpart_country
rename country_new country
assert !missing(receiving)
assert !missing(country)


	* drop aggregates
drop if country=="Central and South Asia" | country=="East Asia" | country=="Economies of Persian Gulf" ///
 | country=="Europe"  | country=="North Africa"  | country=="North Atlantic and Caribbean"  | country=="North and Central America"  | country=="Oceania and Polar Regions"  | country=="Other Near and Middle East Economies"  | country=="South Africa"  | country=="South America"  | country=="Sub-Saharan Africa"  | country=="World" |  country == "Not Specified (including Confidential)"
	

drop if receiving=="Central and South Asia" | receiving=="East Asia" | receiving=="Economies of Persian Gulf" ///
 | receiving=="Europe"  | receiving=="North Africa"  | receiving=="North Atlantic and Caribbean"  | receiving=="North and Central America"  | receiving=="Oceania and Polar Regions"  | receiving=="Other Near and Middle East Economies"  | receiving=="South Africa"  | receiving=="South America"  | receiving=="Sub-Saharan Africa"  | receiving=="World" |  receiving == "Not Specified (including Confidential)"
	
	
	* code iso3 for country 
isocodes country, gen(iso3c)
rename iso3c country_iso3 

replace country_iso3 = "CUW" if country == "Curaçao, Kingdom of the Netherlands" 
replace country_iso3 = "XKX" if country == "Kosovo, Republic of"
replace country_iso3 = "BES" if country == "Bonaire, St. Eustatius and Saba"
replace country_iso3 = "PUS" if country == "US Pacific Islands" 
replace country_iso3 = "TLS" if country == "Timor-Leste, Dem. Rep. of"
replace country_iso3 = "MSR" if country == "Montserrat, United Kingdom-British Overseas Territory"
replace country_iso3 = "AIA" if country == "Anguilla, United Kingdom-British Overseas Territory"

assert !missing(country_iso3)
duplicates list receiving country_iso3 indicator


	* code iso3 for receiving
isocodes receiving, gen(iso3c)
rename iso3c receiving_iso3 

replace receiving_iso3 = "CUW" if receiving == "Curaçao, Kingdom of the Netherlands" 
replace receiving_iso3 = "XKX" if receiving == "Kosovo, Republic of"
replace receiving_iso3 = "BES" if receiving == "Bonaire, St. Eustatius and Saba"
replace receiving_iso3 = "PUS" if receiving == "US Pacific Islands" 
replace receiving_iso3 = "TLS" if receiving == "Timor-Leste, Dem. Rep. of"
replace receiving_iso3 = "MSR" if receiving == "Montserrat, United Kingdom-British Overseas Territory"
replace receiving_iso3 = "AIA" if receiving == "Anguilla, United Kingdom-British Overseas Territory"

assert !missing(receiving_iso3)
duplicates list country receiving_iso3 indicator

duplicates list country_iso3 receiving_iso3 indicator


			reshape long inward_direct_invest, i(country receiving indicator) j(year)
			
			duplicates list country_iso3 receiving_iso3  year indicator



*******tempfile to merge to haven list 
tempfile tempfile_to_merge_to_haven
save `tempfile_to_merge_to_haven'

use "$work/havens_list.dta", clear 
rename iso3c receiving_iso3
keep receiving_iso3 ofc_reporter ofc_pure_haven ofc_hybrid_haven ofc_conduit
drop if receiving_iso3==""
merge 1:m receiving_iso3 using `tempfile_to_merge_to_haven'
drop if _merge==1
drop _merge
*******

* I only keep havens (receiving_iso3): 
keep if (ofc_pure_haven==1 | ofc_conduit==1 ) & receiving_iso3!="USA"	


* list of havens reporting to CDIS
gen ofc_fdi_reporter=0

levelsof receiving_iso3 if (ofc_pure_haven==1 | ofc_conduit==1 ) & receiving_iso3!="USA" & indicator=="Inward Direct investment, Net (liabilities less assets), All financial instruments, All entities", local(havens_reporters)

foreach haven_country in `havens_reporters'{
	display "`haven_country'"
	replace ofc_fdi_reporter=1 if receiving_iso3=="`haven_country'"

}

* use Inward Direct Investment when available
drop if indicator=="Outward Direct investment, Net (assets less liabilities), All financial instruments, All entities" & ofc_fdi_reporter==1
duplicates report country receiving year


drop ofc_reporter ofc_pure_haven ofc_hybrid_haven ofc_conduit_haven

**************** delete countries not present in fiduciary accounts
foreach z in AIA ASM ATF BVT CCK CHE COK CXR GLP GUF GUM HMD MNP MSR MTQ MYT NFK NIU PCN PRI PUS REU SGS SPM TKL VIR XKX{
drop if country_iso3 == "`z'" 
}
	
**************** delete havens that invest in our havens 
*******tempfile to merge to haven list 
tempfile tempfile_to_merge_to_haven
save `tempfile_to_merge_to_haven'

use "$work/havens_list.dta", clear 
rename iso3c country_iso3
keep country_iso3  ofc_pure_haven ofc_conduit_haven
drop if country_iso3==""
merge 1:m country_iso3 using `tempfile_to_merge_to_haven'
drop if _merge==1
drop _merge
*******
drop if (ofc_pure_haven==1 | ofc_conduit==1 ) & country_iso3!="USA" // 
drop  ofc_pure_haven  ofc_conduit_haven



****************  set negative inward direct investment equal to zero, and then compute the shares
sort receiving year
sum inward_direct_invest
replace inward_direct_invest=0 if inward_direct_invest<0 & inward_direct_invest!=.
sum inward_direct_invest


*********************carryforward the inward of missing years 
sort receiving country year
bysort receiving country : carryforward inward_direct_invest, replace 
 
gsort receiving country -year
bysort receiving country : carryforward inward_direct_invest, replace 

		
**************** compute shares for each non haven investing in our havens 
***********************************************************************2009/2023
sort receiving country year

gen share = .
								
				levelsof receiving_iso3, local(receiving_countries)
				foreach country in `receiving_countries'{
					forvalues j = 2009/2023 {
				su inward_direct_invest if year == `j' & receiving_iso3 == "`country'"
			    local total_direct_invest`j'`country' = r(sum) 
				replace share =  inward_direct_invest/`total_direct_invest`j'`country'' if year == `j' & receiving_iso3 == "`country'"
					}
		}  


tempfile fdihavens1
save `fdihavens1'
**************** Assume share before 2009 is the average of the period 2009-2023
***********************************************************************2001/2008

**************** impute the inward value

		drop if year > 2016
		replace year = year - 8
		replace inward = .
		replace share = . 
		append using "`fdihavens1'"
		gen id = receiving_iso3 + "-" + country_iso3
		egen var1 = group(id)
		sort receiving country year
		
		sum var1
		display r(max)
		local max_id=r(max)
		display `max_id'
		
		
		forvalues i = 1/`max_id' {
		quietly: summarize inward if var1 == `i' & year >= 2009
		local avg_inward = r(mean) 
		replace inward = `avg_inward' if var1 == `i' & year < 2009
		replace inward = `avg_inward' if var1 == `i' & (year == 2009 | year == 2010) & receiving_iso3 == "IOT"
		replace inward = `avg_inward' if var1 == `i' & year == 2012 & receiving_iso3 == "BES"
		} 

**************** then the shares 
				
				// Create a local list of countries that meet the condition
	levelsof receiving_iso3, local(receiving_list)
	// Loop through each country in the local list
	foreach h of local receiving_list {
		forvalues j = 2001/2008 {
				sum inward_direct_invest if year == `j' & receiving_iso3 == "`h'" 
			    local total_direct_invest`j'`h' = r(sum)
				replace share =  inward_direct_invest/`total_direct_invest`j'`h'' if year == `j' & receiving_iso3 == "`h'"
				}
	} 		
	
sort receiving  country year
drop var1 id 
** drop indicator 
label var share "inward, and outward if the former NA"
drop indicator
drop ofc_fdi_reporter

duplicates drop
		save "$work/fdi-havens.dta", replace

//----------------------------------------------------------------------------//
		
		
		
		
	

