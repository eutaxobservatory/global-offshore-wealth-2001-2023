//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: Redistribute offshore wealth held in European OFCs to non Euro Area 
// countries
//----------------------------------------------------------------------------//


// Euro area share in total ofw
/*
// Share of each EA OFC in global offshore wealth
use "$work/ofw_aggregate", clear
*Austria, Belgium, Cyprus, Luxembourg, Malta (n.a.) 

// calculate shares
foreach ofc in "AT" "BE" "CY" "LU" {
gen share_`ofc' = dep`ofc' / bis_total * ofw_other / ofw * 100
}

egen depEA = rowtotal( depAT depBE depCY depLU)
gen share_EA = depEA / bis_total * ofw_other / ofw * 100
*share_EA has declined from 9% in 2013 to 5% in 2023.
gen ofw_EA = share_EA* ofw / 100
*EUR 760 Bn in 2013; 645 bn in 2023
gen share_EA_europ = ofw_EA / ofw_europ
keep year share_EA_europ
save "$temp\share_EA_europ.dta", replace
*/

// Offshore wealth held in European OFCs
use "$work/countries", clear

keep if indicator == "europe" 
gen eurozone = 0

* Members from 2014 onwards
replace eurozone = 1 if ///
    (iso3 == "AUT" | iso3 == "BEL" | iso3 == "CYP" | ///
     iso3 == "DEU" | iso3 == "EST" | iso3 == "ESP" | ///
     iso3 == "FIN" | iso3 == "FRA" | iso3 == "GRC" | ///
     iso3 == "IRL" | iso3 == "ITA" | iso3 == "LUX" | ///
	 iso3 == "MLT" | iso3 == "NLD" | ///
     iso3 == "PRT" | iso3 == "SVK" | iso3 == "SVN") ///
    & year >= 2013

* Lativa joins in 2014
replace eurozone = 1 if iso3 == "LVA"& year >= 2014

* Lithuania joins in 2015
replace eurozone = 1 if iso3 == "LTU" & year >=2015

* Croatia joins in 2023
replace eurozone = 1 if iso3 == "HRV" & year >= 2023

egen ofc_europe = total(value), by(year)
gen share = value/ofc_europe
bys year: egen ez_share = total(share * eurozone)
* Redistribute
gen ofw_europ_new = 0
replace ofw_europ_new = value / (1 - ez_share) if eurozone == 0
by year, sort: egen test= total(ofw_europ_new)

keep year iso3 indicator ofw_europ_new 
rename ofw_europ_new value2
merge 1:1 iso3 year indicator using "$work/countries"

keep if indicator == "total_russia_adjustment" | indicator == "europe"
keep year iso3 country_name value2 value indicator regionname gdp_current_dollars
reshape wide value value2, i(year iso3 regionname gdp) j(indicator) string
replace value2total_russia_adjustment = valuetotal_russia_adjustment - valueeurope + value2europe

keep year iso3 value2total_russia_adjustment valuetotal_russia_adjustment regionname country_name gdp
rename (valuetotal value2) (value value2)
gen ofw = value / gdp * 1000000000 * 100
gen ofw_corr = value2 / gdp * 1000000000 * 100
label var value "ofw baseline"
label var value2 "ofw EA redistribution"
save "$work/countries_EA.dta"
//----------------------------------------------------------------------------//
