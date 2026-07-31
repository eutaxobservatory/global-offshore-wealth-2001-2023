//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023, revision
//
// Purpose: Extract tables and figures for paper revision
//----------------------------------------------------------------------------//

// global estimate
use "$work/sensitivity_global.dta", clear
keep year ofw_baseline ofw_dep2 ofw_dep3 ofw_KY* ofw_UK* worldgdp
foreach var of varlist ofw_dep* ofw_UK* ofw_KY* ofw_base{
	replace `var' = `var' / worldgdp 
}

order year ofw_tph ofw_baseline ofw_dep2 ofw_dep3 ofw_KY* ofw_UK*
label var ofw_tph "Including Intra-Euro Area Third Party Holdings"
label var ofw_dep2 "Deposit Ratio OECD"
label var ofw_dep3 "Deposit Ratio US Top 10"
label var ofw_KYub "Cayman Upper Bound (portfolio share 0.85)"
label var ofw_KYlb "Cayman Lower Bound (portfolio share 0.65)"
label var ofw_UKlb "UK Upper Bound (Onshore share 0.21)" // note: lower onshore share generates upper bound ofw estimate
label var ofw_UKub "UK Lower Bound (Onshore share 0.41)" // note higher onshore share generates lower bound ofw estimate
save "$work/sensitivity_global.dta", replace



// allocation of offshore wealth to financial centers
use "$work/ofw_aggregate.dta", clear
foreach var of varlist ofw_CH ofw_americ ofw_asia ofw_europ{
	gen Ofwhich_`var' = `var' / ofw * 100
}

keep year Ofwhich*
rename Ofwhich_ofw_* *
rename (americ asia europ CH) (baseline_americ baseline_asia baseline_europ baseline_swiss)
merge 1:1 year using "$work/ofw_aggregate_hh_allone.dta", nogen
foreach var of varlist ofw_americ ofw_asia ofw_europ{
	gen Ofwhich_`var' = `var' / ofw * 100
}
keep year baseline* Ofwhich*
rename Ofwhich_ofw_* hh_allone_*
merge 1:1 year using "$work/ofw_aggregate_hh_freeze.dta", nogen
foreach var of varlist ofw_americ ofw_asia ofw_europ{
	gen Ofwhich_`var' = `var' / ofw * 100
}

keep year baseline* hh_allone* Ofwhich*
rename Ofwhich_ofw_* hh_freeze_*

reshape long baseline_ hh_allone_ hh_freeze_, i(year) j(ofc) string
rename (baseline hh_allone hh_freeze) (baseline hh_allone hh_freeze) 
replace ofc = "American Financial Centers" if ofc == "americ"
replace ofc = "Asian Financial Centers" if ofc == "asia"
replace ofc = "European Financial Centers" if ofc == "europ"
replace ofc = "Switzerland" if ofc == "swiss"


#delimit ;
twoway ///
(line baseline year, 
    lcolor(midblue*1.5) lwidth(medthick) lpattern(solid)) ///
(line hh_allone year, 
    lcolor(red*1.5) lwidth(medthick) lpattern(dash)) ///
(line hh_freeze year, 
    lcolor(emerald*1.5) lwidth(medthick) lpattern(longdash)), ///
by(ofc, 
    graphregion(col(white)) plotregion(margin(none)) note("")
) ///
legend(nobox ring(0) position(2) cols(1) size(small) region(lstyle(none))
    order(1 "Baseline" 2 "No Adjustment" 3 "Frozen Household Shares")
) ///
xlabel(2001(2)2023, 
    grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) angle(90) 
    labsize(small) nogmin labgap(1) tstyle(minor)
) ///
ylabel(0(10)60,
    grid glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) 
    glwidth(thin) tstyle(minor) 
    labgap(1)
) ///
xtitle("") ///
ytitle("% of Global Offshore Financial Wealth", size(small));

#delimit cr
graph export "$fig/sensitivity/sensitivity_ofc_hh_shares.pdf", replace 



use "$work/ofw_aggregate_hh_freeze.dta", clear
foreach ofc in "HK" "SG" "US" "GB" "LU" {
gen share_`ofc' = dep`ofc' / bis_total * ofw_other / ofw * 100
}
gen share_CH = ofw_CH / ofw * 100

sum share* if year == 2023

label var share_CH "Switzerland"
label var share_GB "United Kingdom"
label var share_HK "Hong Kong"
label var share_SG "Singapore"
label var share_US "United States"
label var share_LU "Luxembourg"


// Offshore wealth hosted by individual financial center
#delimit;
twoway connected share_HK share_SG share_CH share_GB share_US share_LU year,
msymbol(circle triangle square plus diamond) msize(small small small small small) 
mcolor(gray lavender*1.5 midblue*1.5 red*1.5 emerald*1.5) mlcolor() mlwidth(thin thin thin thin thin) 
lwidth(vthin vthin vthin vthin vthin) lcolor(gray lavender*1.5 midblue*1.5 red*1.5 emerald*1.5)
graphregion(col(white)) plotregion(margin(none))
legend(nobox ring(0) position(2) cols(1) size(vsmall) region(lstyle(none))) 
xlabel(2001(1)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) nogmin labgap(1) tstyle(minor)
)
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%" 30 "30%" 35 "35%" 40 "40%" 45 "45%" 50 "50%" 55 "55%" , grid 
glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) glwidth(thin) 
tstyle(minor) labgap(1)
)
xtitle("")
ytitle("% of the wealth held in all financial centers", size(small))
name(trendofc2, replace);
#delimit cr

graph export "$fig/sensitivity/sensitivity_ofc_hh_shares2.pdf", replace 




// Euro area correction
*Austria, Belgium, Cyprus, Luxembourg, Malta, 
// calculate shares
foreach ofc in "AT" "BE" "CY" "LU" {
gen share_`ofc' = dep`ofc' / bis_total * ofw_other / ofw * 100
}

egen depEA = rowtotal( depAT depBE depCY depLU)
gen share_EA = depEA / bis_total * ofw_other / ofw * 100
*share_EA has declined from 9% in 2013 to 5% in 2023.
gen ofw_EA = share_EA* ofw / 100
*EUR 760 Bn in 2013; 645 bn in 2023
gen share_tph = `mean_tph'/ ofw_EA if year == 2014 	//60% 
gen share_EA_europ = ofw_EA / ofw_europ
keep year share_EA_europ
tempfile share_EA_europ
save `share_EA_europ', replace


** redistribute OFW of EA OFCs owned by EA countries

use "$work/countries", clear

keep if indicator == "europe" 
merge m:1 year using `share_EA_europ', nogen

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


/*
collapse (sum) value gdp_current_dollars, by(year eurozone)
egen ofc_europ = total(value), by(year)
gen share = value / ofc
*share declines from 36% in 2013 to 23% in 2023
*/

egen ofc_europe = total(value), by(year)
gen share = value/ofc_europe

* Eurozone share of total wealth
bys year: egen ez_share = total(share * eurozone)
gen value_new = value

* Eurozone countries lose the EA-held portion
replace value_new = value * (1 - share_EA_europ) if eurozone

* Non-Eurozone countries receive it proportionally
replace value_new = value * ///
    (1 + share_EA_europ * ez_share / (1 - ez_share)) ///
    if !eurozone

*by year, sort: egen test= total(value_new)

keep year iso3 indicator value_new 
rename value_new value2
merge 1:1 iso3 year indicator using "$work/countries"

keep if indicator == "total_russia_adjustment" | indicator == "europe"
keep year iso3 country_name value2 value indicator regionname gdp_current_dollars
reshape wide value value2, i(year iso3 regionname gdp) j(indicator) string
replace value2total_russia_adjustment = valuetotal_russia_adjustment - valueeurope + value2europe

keep year iso3 value2total_russia_adjustment valuetotal_russia_adjustment regionname country_name gdp
rename (valuetotal value2) (value value2)

preserve
keep if year == 2023
gsort -value
gen change = (value2-value) / value
gen nobs=_n
gen select = 1 if nobs < 22
replace select = 1 if iso3 == "BEL"| iso3=="RUS"
keep if select == 1
export excel year iso3 value change using "$tables\sensitivity_country_allocation_EA.xlsx", sheetmodify firstrow(variables)

*** plot both versions

**------Fraction of global household ofw owned by region groups--------*

* compute the % owned by each income level countries
 levelsof regionname
 replace regionname="Latin America & Caribbean" if regionname=="Latin America & Carribean"


collapse (sum) value value2, by(year regionname)

encode regionname, gen(region)
drop regionname


gen sh_ofw_total = 0
forvalues i = 2001/2023 {
	sum value if year == `i'
	local ofw`i' r(sum)
	replace sh_ofw_total = value*100/`ofw`i'' if year == `i'
}  
drop value


gen sh_ofw_total_corr = 0
forvalues i = 2001/2023 {
	sum value2 if year == `i'
	local ofw`i' r(sum)
	replace sh_ofw_total_corr = value2*100/`ofw`i'' if year == `i'
}  
drop value2

reshape wide sh_ofw_total sh_ofw_total_corr, i(year) j(region)

label var sh_ofw_total_corr1 "East Asia & Pacific"
label var sh_ofw_total_corr2 "Europe & Central Asia"
label var sh_ofw_total_corr3 "Latin America & Caribbean"
label var sh_ofw_total_corr4 "Middle East & North Africa"
label var sh_ofw_total_corr5 "North America"
label var sh_ofw_total_corr6 "South Asia"
label var sh_ofw_total_corr7 "Sub-Saharan Africa"

label var sh_ofw_total1 "East Asia & Pacific"
label var sh_ofw_total2 "Europe & Central Asia"
label var sh_ofw_total3 "Latin America & Caribbean"
label var sh_ofw_total4 "Middle East & North Africa"
label var sh_ofw_total5 "North America"
label var sh_ofw_total6 "South Asia"
label var sh_ofw_total7 "Sub-Saharan Africa"


#delimit;
twoway connected 
    sh_ofw_total1  
    sh_ofw_total_corr1   year, 
msymbol(circle none)
msize(*0.8)
mcolor(midblue*2.5 midblue*2.5)
mlwidth(thin thin )
lcolor(midblue*2.5 midblue*2.5)
lwidth(medthick medthick )
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(2) cols(1) size(vsmall) region(lstyle(none)) 
label(1 "Preferred offshore wealth estimates") label(2 "EA-corrected offshore wealth estimates"))
xlabel(2001(2)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%"  40 "40%" 50 "50%"  60 "60%" , 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
title("East Asia and Pacific", size(small) )
xtitle("")
ytitle("% of total offshore wealth", size(small))
name(g_east_asia_pacific, replace);
#delimit cr
*graph export "$fig/ofw-owned-east_asia_pacific-total-ofw.pdf", replace 

#delimit;
twoway connected 
    sh_ofw_total2  
    sh_ofw_total_corr2   year, 
msymbol(square none)
msize(*0.8)
mcolor(red*1.5  red*1.5 )
mlwidth(thin thin)
lcolor(red*1.5  red*1.5 )
lwidth(medthick medthick )
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)) 
label(1 "Preferred offshore wealth estimates") label(2 "EA-corrected offshore wealth estimates"))
xlabel(2001(2)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%"  40 "40%" 50 "50%" 60 "60%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
title("Europe and Central Asia", size(small) )
xtitle("")
ytitle("% of total offshore wealth", size(small))
name(g_europe_central_asia, replace);
#delimit cr
*graph export "$fig/ofw-owned-europe_central_asia-total-ofw.pdf", replace 

#delimit;
twoway connected 
    sh_ofw_total3  
    sh_ofw_total_corr3   year, 
msymbol(triangle none)
msize(*0.8)
mcolor(forest_green forest_green)
mlwidth(thin thin thin)
lcolor(forest_green forest_green)
lwidth(medthick medthick )
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)) 
label(1 "Preferred offshore wealth estimates") label(2 "EA-corrected offshore wealth estimates"))
xlabel(2001(2)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 2 "2%" 4 "4%" 6 "6%" 8 "8%" 10 "10%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
title("Latin America and Caribbean", size(small) )
xtitle("")
ytitle("% of total offshore wealth", size(small))
name(g_latin_america_caribbean, replace);
#delimit cr
*graph export "$fig/ofw-owned-latin_america_caribbean-total-ofw.pdf", replace 

#delimit;
twoway connected 
    sh_ofw_total4  
    sh_ofw_total_corr4   year, 
msymbol(diamond none)
msize(*0.8)
mcolor(orange orange)
mlwidth(thin thin )
lcolor(orange orange)
lwidth(medthick medthick )
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)) 
label(1 "Preferred offshore wealth estimates") label(2 "EA-corrected offshore wealth estimates"))
xlabel(2001(2)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
title("Middle East and North Africa", size(small) )
xtitle("")
ytitle("% of total offshore wealth", size(small))
name(g_middle_east_north_africa, replace);
#delimit cr
*graph export "$fig/ofw-owned-middle_east_north_africa-total-ofw.pdf", replace 

#delimit;
twoway connected 
    sh_ofw_total5  
    sh_ofw_total_corr5   year, 
msymbol(X none)
msize(*0.8)
mcolor(sienna sienna)
mlwidth(thin thin )
lcolor(sienna sienna)
lwidth(medthick medthick )
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)) 
label(1 "Preferred offshore wealth estimates") label(2 "EA-corrected offshore wealth estimates"))
xlabel(2001(2)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%" 30 "30%"  35 "35%" , 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
title("North America", size(small) )
xtitle("")
ytitle("% of total offshore wealth", size(small))
name(g_north_america, replace);
#delimit cr
*graph export "$fig/ofw-owned-north_america-total-ofw.pdf", replace 

#delimit;
twoway connected 
    sh_ofw_total6  
    sh_ofw_total_corr6   year, 
msymbol(T none)
msize(*0.8)
mcolor(purple purple)
mlwidth(thin thin)
lcolor(purple purple)
lwidth(medthick medthick )
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)) 
label(1 "Preferred offshore wealth estimates") label(2 "EA-corrected offshore wealth estimates"))
xlabel(2001(2)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 0.5 "0.5%" 1 "1%" 1.5 "1.5%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
title("South Asia", size(small) )
xtitle("")
ytitle("% of total offshore wealth", size(small))
name(g_south_asia, replace);
#delimit cr
*graph export "$fig/ofw-owned-south_asia-total-ofw.pdf", replace 

#delimit;
twoway connected 
    sh_ofw_total7  
    sh_ofw_total_corr7   year, 
msymbol(Oh none)
msize(*0.8)
mcolor(	eltblue*1.5 eltblue*1.5)
mlwidth(thin thin )
lcolor(	eltblue*1.2 eltblue*1.2)
lwidth(medthick medthick )
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)) 
label(1 "Preferred offshore wealth estimates") label(2 "EA-corrected offshore wealth estimates"))
xlabel(2001(2)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 0.5 "0.5%" 1 "1%" 1.5 "1.5%" 2 "2%" 2.5 "2.5%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
title("Sub-Saharan Africa", size(small) )
xtitle("")
ytitle("% of total offshore wealth", size(small))
name(g_sub_saharian_africa, replace);
#delimit cr
*graph export "$fig/ofw-owned-sub_saharian_africa-total-ofw.pdf", replace 


// Combine all saved graphs 
graph combine g_east_asia_pacific g_europe_central_asia g_latin_america_caribbean g_middle_east_north_africa g_north_america g_south_asia g_sub_saharian_africa, ///
    cols(2) title("")  rows(3)  ///
    graphregion(margin(5 5 5 5)) ///
    xsize(20) ysize(40)

graph export "$fig/sensitivity/ofw-owned-by-region-total-ofw-tph.pdf", replace 


//----------------------------------------------------------------------------//