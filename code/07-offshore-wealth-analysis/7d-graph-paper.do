// =============================================================================
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: generate graphs included in the paper
//
// databases used: - "$work/locational.dta"
//                 - "$raw/dta/bis_AN.dta"
//                 - "$work/ofw_aggregate"
//                 - "$work/countries"
//                 - "$work/fiduciary-87-23_uncorr.dta"
//                 - "$work/offshore2023.dta"
//                 - "$raw/dta/crs_all.dta"
//                 - "$raw\dta\CRS_German.dta"
//                 - "$raw/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_2.csv"
//                 - "$raw\zucman\Zucman2013AppendixTables.xlsx", sheet("Table A22") 
//                 - "$raw\zucman\Zucman2015TablesFigures.xlsx", sheet("Data-Fig1")
//				   - "$raw/dta/crs_all.dta"
//
// outputs:        - Fig1: "$fig/world-offshore-gdp-2001-2023.pdf"
//                 - Fig2: "$fig/offshore-location-global-wealth.pdf"
//                 - Fig3: "$fig/ofw-owned-income-level-total-ofw.pdf"
//                 - Fig4: "$fig/countries-offshore-gdp-2007-2023.pdf"
//                 - Fig5: "$fig/ofw-historic.pdf"
//                 - Fig6: "$fig/update-swiss-fiduciary-87-23.pdf" and "$fig/swiss-fiduciary-corrected-87-23.pdf"
//                 - Fig7: "$fig/russia-deposits-uncorrected_noSTD.pdf" and "$fig/russia-deposits-corrected.pdf"
//                 - Fig8: "$fig/countries-offshore-gdp-2023-fdi.pdf"
//                 - Fig9: "$fig/GB_allocation.pdf"
//                 - Fig10: "$fig/benchmark-cty.pdf"
//                 - Fig11: "$fig/crs-scatter.pdf"
//                 - Fig12: "$fig/bis-crs-match_DE2019.pdf"
//                 - Fig13: "$fig/share-gdp-income-country-groups.pdf"
//                 - Fig14: "$fig/corr-ofw-gdp.pdf"
//                 - Fig15: "$fig/ofw-regions1.pdf"
//                 - Fig16: "$fig/ofw-regions2.pdf"
//                 - Fig17: "$fig/ofw_africa.pdf"
//                 - Fig18: "$fig/ofw_americas.pdf"
//                 - Fig19: "$fig/ofw_asia.pdf"
//                 - Fig20: "$fig/ofw_europe.pdf"
//                 - Fig21: "$fig/ofw-owned-income-level-total-ofw-fdi.pdf"
//                 - Fig22: "$fig/ofw-owned-by-region-total-ofw-fdi.pdf"
//                 
// =============================================================================

********************************************************************************
* Figure 1: Evolution of Global Offshore Wealth (as a % of world GDP), 2001-2023
********************************************************************************
**-----------Graph: Evolution of Global Offshore Wealth 2001-2023-------------**
use "$work/ofw_aggregate", clear
keep year ofw
rename ofw offshore_wealth

preserve
	import delimited using "$raw/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_2.csv",  clear
	keep if v2 == "WLD" | v2 == "Country Code"
	drop v1-v45 
	drop v69
	drop in 1
	gen help = _n
	reshape long v, i(help) j(year)
	replace year = year + 1955
	rename v world_gdp
	replace world_gdp = world_gdp / 1000000000
	drop help
	tempfile gdp
	save `gdp'
restore
merge 1:1 year using `gdp', nogenerate

gen offshore_gdp = offshore_wealth*100/world_gdp


#delimit;
twoway connected offshore_gdp year, 
msymbol(circle) mcolor(black) mlcolor(black) mlwidth(medthick) lwidth(medium) 
msize(medsmall) plotregion(margin(none)) graphregion(col(white)) lcolor(black)
ylabel(
0 "0%" 2 "2%" 4 "4%" 6 "6%" 8 "8%" 10 "10%" 12 "12%" 14 "14%" 16 "16%", grid glcolor(black%20) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
xlabel(
2001(1)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
xtitle("")
ytitle("% of world GDP", size(small))
yscale(range(17));
#delimit cr
graph export "$fig/world-offshore-gdp-2001-2023.pdf", replace 

********************************************************************************
* Figure 2: Where is the World's Offshore Household Wealth Located?
********************************************************************************

**----Evolution of offshore wealth in Switzerland and other haven groups-----*
use "$work/ofw_aggregate", clear
foreach var of varlist ofw_americ ofw_asia ofw_europ ofw_CH{
	gen Ofwhich_`var' = `var' / ofw * 100
}
label var Ofwhich_ofw_CH "Switzerland"
label var Ofwhich_ofw_americ "American financial centers"
label var Ofwhich_ofw_asia "Asian financial centers"
label var Ofwhich_ofw_europ "Other European financial centers"

* in % of global offshore household financial wealth
#delimit;
twoway connected Ofwhich_ofw_CH Ofwhich_ofw_americ Ofwhich_ofw_asia
Ofwhich_ofw_europ year, 
msymbol(circle triangle square plus) msize(small small small small) 
mcolor(red*1.5 lavender*1.5 midblue*1.5 emerald*1.5) mlcolor() mlwidth(thin thin thin thin) 
lwidth(vthin vthin vthin vthin) lcolor(red*1.5 lavender*1.5 midblue*1.5 emerald*1.5)
graphregion(col(white)) plotregion(margin(none))
legend(nobox ring(0) position(2) cols(1) size(vsmall) region(lstyle(none))) 
xlabel(2001(1)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) nogmin labgap(1) tstyle(minor)
)
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%" 30 "30%" 35 "35%" 40 "40%" 45 "45%" 50 "50%" 55 "55%" 60 "60%", grid 
glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) glwidth(thin) 
tstyle(minor) labgap(1)
)
xtitle("")
ytitle("% of the wealth held in all financial centers", size(small));
#delimit cr
graph export "$fig/offshore-location-global-wealth.pdf", replace 


********************************************************************************
* Figure 3: Offshore Wealth Owned by High-Income vs. Middle- and Lower-Income Countries (% of total offshore wealth)
********************************************************************************

**------Fraction of global household ofw owned by income country groups--------*
use "$work/countries", clear

* compute the % owned by each income level countries
keep if indicator == "total_russia_adjustment"

gen world_gdp = 0
forvalues j = 2001/2023 {
	su gdp if year == `j'
	replace world_gdp = r(sum) if year == `j' 
}

collapse (sum) gdp value, by(year incomelevelname world_gdp)
replace incomelevelname = "upper_middle" if incomelevelname == "Upper middle income"
replace incomelevelname = "high" if incomelevelname == "High income"
replace incomelevelname = "low" if incomelevelname == "Low income"
replace incomelevelname = "lower_middle" if incomelevelname == "Lower middle income"
replace incomelevelname = "unclassified" if incomelevelname == "Unclassified"
gen sh_ofw_total = 0
gen sh_ofw_gdp = 0
gen sh_world_gdp = 0
forvalues i = 2001/2023 {
	sum value if year == `i'
	local ofw`i' r(sum)
	replace sh_ofw_total = value*100/`ofw`i'' if year == `i'
	replace sh_ofw_gdp = value*100/(world_gdp/1e+9) if year == `i'
	replace sh_world_gdp = gdp*100/(world_gdp) if year == `i'
}  
drop value gdp
reshape wide sh_ofw_total sh_ofw_gdp sh_world_gdp, i(year) j(incomelevelname) string
foreach var in sh_ofw_gdp sh_ofw_total sh_world_gdp {
gen `var'_low_middle_inc = `var'low + `var'lower_middle + `var'upper_middle + `var'unclassified
}

keep year sh_ofw_gdphigh sh_ofw_totalhigh sh_ofw_gdp_low_middle_inc ///
sh_ofw_total_low_middle_inc sh_world_gdphigh sh_world_gdp_low_middle_inc ///
sh_ofw_totallow sh_ofw_totallower_middle sh_ofw_totalupper_middle

label var sh_ofw_totalhigh "High income countries"
label var sh_ofw_total_low_middle_inc "Middle- and low-income countries"
label var sh_ofw_totallow "Low income countries"
label var sh_ofw_totallower_middle "Lower middle income countries"
label var sh_ofw_totalupper_middle "Upper middle income countries"


#delimit;
twoway connected sh_ofw_totalhigh sh_ofw_total_low_middle_inc year, 
msymbol(circle circle) msize(small small) mcolor(midblue*2.5 red*1.5) 
mlwidth(thin thin)
lcolor(midblue*2.5 red*1.5) lwidth(medthick medthick)
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)))
xlabel(2001(1)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
xtitle("")
ytitle("% of total offshore wealth", size(small));
#delimit cr
graph export "$fig/ofw-owned-income-level-total-ofw.pdf", replace 


********************************************************************************
* Figure 4: Offshore Wealth in Large Economies: 2007 vs. 2023 (% of GDP)
********************************************************************************

**---------------Graph: Offshore Wealth in % of GDP 2007-2023-----------------**
*calculate World Averages
use "$work/ofw_aggregate", clear
sum worldgdp if year == 2007
local gdp2007 = r(mean)
sum worldgdp if year == 2023
local gdp2023 = r(mean)
use "$work/countries.dta", clear
keep if indicator == "total_russia_adjustment"
keep if year == 2007|year==2023
collapse (sum) value, by(year)
gen ofw_pct = value/`gdp2007' if year == 2007
replace ofw_pct = value / `gdp2023' if year == 2023
*World average weighted: 2007: 11%, 2023 13%*
replace ofw_pct= int(ofw_pct*100 )
levelsof ofw_pct if year == 2007, local(world_av_2007)
levelsof ofw_pct if year == 2023, local(world_av_2023)

* Countries with > 200 billion USD in 2007 as in AJZ(2018)
use "$work/countries", clear
keep if year == 2007 & indicator == "total_russia_adjustment"
keep if gdp > 200*1e+9
drop if value == 0 | gdp == .
sort value
rename gdp_current_dollars gdp2007
rename value value2007
tempfile countries2007
save `countries2007'
use "$work/countries", clear
keep if year == 2023 & indicator == "total_russia_adjustment"
merge 1:1 iso3 using "`countries2007'", keep(match) nogenerate 
drop unit label indicator year
rename gdp_current_dollars gdp2023
rename value value2023
gen ratio_offshore_GDP2007 = value2007/(gdp2007/1e+9)
gen ratio_offshore_GDP2023 = value2023/(gdp2023/1e+9)
gen country = ""
replace country = "UAE" if iso3 == "ARE"
replace country = "UK" if iso3 == "GBR"
replace country = "Iran" if iso3 == "IRN"
replace country = "Korea" if iso3 == "KOR"
replace country = "Netherlands" if iso3 == "NLD"
replace country = "Russia" if iso3 == "RUS"
replace country = "Taiwan" if iso3 == "TWN"
replace country = "USA" if iso3 == "USA"
replace country = "Venezuela" if iso3 == "VEN"
replace country = country_name if country == ""
#delimit;
graph bar ratio_offshore_GDP2007 ratio_offshore_GDP2023,
over(country, sort(ratio_offshore_GDP2007) label(angle(90) labsize(small)
labgap(1))) 
graphregion(col(white)) 
ylabel(0 "0%" 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" 0.5 "50%" 0.6 "60%" 
0.7 "70%" 0.8 "80%" 0.9 "90%" 1.0 "100%" 1.1 "110%" 1.2 "120%" 1.3 "130%" 1.4 "140%"
, tstyle(minor) grid angle(horizontal) glcolor(grey%10) 
labsize(small) labgap(1)) 
yline(.11, lcolor(black)) 
yline(.12, lcolor(black)) 
ytitle("share of GDP", size(small))  
text(0.40 31.25 "World Average in 2007: `world_av_2007'%", color(blue*2) size(small))
text(0.30 31.25 "World Average in 2023: `world_av_2023'%", color(red*1.3) size(small))
bargap(15)
outergap(30)
bar(1, color() lcolor(black) lwidth(vthin))
bar(2, color(red*1.3) lcolor(black) lwidth(vthin))
legend(nobox ring(0) position(9) cols(1) size(vsmall) 
label(1 "Offshore wealth in 2007") label(2 "Offshore wealth in 2023"));
#delimit cr
graph export "$fig/countries-offshore-gdp-2007-2023.pdf", replace


/*calculate World Averages
use "$work/ofw_aggregate", clear
sum worldgdp if year == 2007
local gdp2007 = r(mean)
sum worldgdp if year == 2023
local gdp2023 = r(mean)
use "$work/countries.dta", clear
keep if indicator == "total_russia_adjustment"
keep if year == 2007|year==2023
collapse (sum) value, by(year)
gen ofw_pct = value/`gdp2007' if year == 2007
replace ofw_pct = value / `gdp2023' if year == 2023
*World average weighted: 2007: 11%, 2023 12%*
*/
********************************************************************************
* Figure 5: Historic Offshore Wealth, 1980-2023 (% of GDP)
********************************************************************************

import excel "$raw\zucman\Zucman2013AppendixTables.xlsx", sheet("Table A22") cellrange(L6:W47) clear
keep L S T U W
rename (L S T U W) (year yield invinc_gap mportwealth capitalized)
keep if year >= 1980 & year <= 2008
destring yield invinc_gap capitalized mportwealth, replace
// capitalized = -invinc_gap / yield

tempfile capitalized
save `capitalized'

use "$work/ofw_aggregate", clear
keep year ofw_ajz deposits_ajz deposits ofw ofw_CH
merge 1:1 year using `capitalized', nogen
sort year

// Assume that deposits grow at the same rate as portfolio assets
forvalues y = 2000(-1)1980 {
replace deposits = deposits[_n+1] * capitalized / capitalized[_n+1] if year == `y'
}
gen ofw_bop = capitalized + deposits if year < 2009

// import world gdp
preserve
	import delimited using "$raw/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_2.csv",  clear
	keep if v2 == "WLD" | v2 == "Country Code"
	drop v1-v24 
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

foreach var in ofw ofw_bop ofw_ajz{
	gen `var'_pct = `var' / worldgdp * 100
}
preserve
// Import Swiss OFW
import excel "$raw\zucman\Zucman2015TablesFigures.xlsx", sheet("Data-Fig1") firstrow cellrange(A2:P15) clear
keep A Totaloffshore
rename (A Total) (year swiss_historic)
label var swiss_historic "Total ofw in CH in USD bn. 10y-avg"
destring year, replace ignore( (euros))
keep if year > 1970 & year < 2013
replace year = year+5
tempfile swiss_hist
save `swiss_hist'

restore
merge 1:1 year using `swiss_hist', nogen
gen help2 = 1 if year >=1980 & year < 1990
replace help2 = 2 if year >= 1990 & year < 2000
replace help2 = 3 if year >= 2000 & year < 2010
replace help2 = 4 if year >= 2010 & year < 2020
egen gdp_avg = mean(worldgdp), by(help2)
gen swiss_hist_pct = swiss_hist / gdp_avg*100

gen ofw_CH_pct = ofw_CH / worldgdp*100
replace ofw_CH_pct = swiss_hist_pct if year < 2001


replace ofw_bop_pct = . if year > 2001
label var ofw_bop_pct "Capitalized global offshore wealth"
label var ofw_pct "Global offshore wealth"
label var ofw_CH_pct "Offshore wealth in Switzerland"

* OFW historic
#delimit;
twoway (connected ofw_bop_pct year, msymbol(circle) msize(small) mcolor(red*1.5) mlcolor() mlwidth(thin) lwidth(vthin) lcolor(red*1.5))
(connected ofw_pct year, msymbol(triangle) msize(small) mcolor(lavender*1.5) mlcolor() mlwidth(thin) lwidth(vthin) lcolor(lavender*1.5))
(scatter ofw_CH_pct year, msymbol(square) msize(small) mcolor(emerals*1.5) mlcolor() mlwidth(thin) lwidth(vthin) lcolor(emerald*1.5)),
graphregion(col(white)) plotregion(margin(none))
legend(nobox ring(0) position(11) cols(1) size(vsmall) region(lstyle(none))) 
xlabel(1980(3)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) nogmin labgap(1) tstyle(minor)
)
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%", grid 
glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) glwidth(thin) 
tstyle(minor) labgap(1)
)
xtitle("")
ytitle("% GDP", size(small));
#delimit cr
graph export "$fig/ofw-historic.pdf", replace 


********************************************************************************
* Figure 6: Who Owns Swiss Fiduciary Deposits?
********************************************************************************
* Read fiduciary accounts data
use "$work/fiduciary-87-23_uncorr.dta", clear

* create country groups shares of fiduciary deposits in Swiss Banks
rename ofc haven
gen tot_haven = .
gen tot_europe= .
gen tot_middle_east = .
gen tot_latin_am = .
gen tot_asia = .
gen tot_africa = .
gen tot_north_am = .
gen tot_caribbean = .
gen all = 1
gen tot_rich = .
gen tot_developing = .

* create country groups shares of fiduciary deposits, corrected for Foreign 
* Direct Investment statistics, in Swiss Banks.

gen tot_haven_corrected = .
gen tot_europe_corrected= .
gen tot_middle_east_corrected = .
gen tot_latin_am_corrected = .
gen tot_asia_corrected = .
gen tot_africa_corrected = .
gen tot_north_am_corrected = .
gen tot_caribbean_corrected = .
gen all_corrected = 1
gen tot_rich_corrected = .
gen tot_developing_corrected = .


* total fiduciary deposits, by country
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean rich developing {
	forval i = 1987/2023  {
		sum(lfidudol) if `countryg' == 1 & year == `i'
		replace tot_`countryg' = r(sum) if year == `i' & `countryg' == 1
		}
		}
		
* total corrected using FDI, by country
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean rich developing {
	forval i = 2001/2023  {
		sum(lfidu2dol_fdi_adjustment) if `countryg' == 1 & year == `i'
		replace tot_`countryg'_corrected = r(sum) if year == `i' & `countryg' == 1
		}
		}
		
		
* total fiduciary deposits
gen tot_all = .
forval i = 1987/2023 {
	sum(lfidudol) if year == `i' 
	replace tot_all = r(sum) if year == `i'
	}

	
* compute share fiduciary deposits
gen sh_haven = .
gen sh_europe= .
gen sh_middle_east = .
gen sh_latin_am = .
gen sh_asia = .
gen sh_africa = .
gen sh_north_am = .
gen sh_caribbean = .
gen sh_all = .
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean all {
	forval i = 1987/2023  {
		replace sh_`countryg' = tot_`countryg'/tot_all if year == `i' & ///
		`countryg' == 1
		}
		}
		
* compute share fiduciary deposits corrected using FDI
gen sh_haven_corrected = .
gen sh_europe_corrected = .
gen sh_middle_east_corrected = .
gen sh_latin_am_corrected = .
gen sh_asia_corrected = .
gen sh_africa_corrected = .
gen sh_north_am_corrected = .
gen sh_caribbean_corrected = .
gen sh_all_corrected = .
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean {
	forval i = 1987/2023  {
		replace sh_`countryg'_corrected = tot_`countryg'_corrected/tot_all if year == `i' & ///
		`countryg' == 1
		}
		}

* in percentage
gen pct_haven = .
gen pct_europe = .
gen pct_middle_east = .
gen pct_latin_am = .
gen pct_asia = .
gen pct_africa = .
gen pct_north_am = .
gen pct_caribbean = .
gen pct_all = .
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean all {
	forval i = 1987/2023  {
		replace pct_`countryg' = sh_`countryg'*100 if year == `i' & ///
		`countryg' == 1
		}
		}
		
* in percentage corrected using FDI
gen pct_haven_corrected = .
gen pct_europe_corrected = .
gen pct_middle_east_corrected = .
gen pct_latin_am_corrected = .
gen pct_asia_corrected = .
gen pct_africa_corrected = .
gen pct_north_am_corrected = .
gen pct_caribbean_corrected = .
gen pct_all_corrected = .
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean all {
	forval i = 1987/2023  {
		replace pct_`countryg'_corrected = sh_`countryg'_corrected*100 if year == `i' & ///
		`countryg' == 1
		}
		}

label var pct_haven "Financial Centers"
label var pct_europe "Europe"
label var pct_middle_east "Middle East"
label var pct_latin_am "Latin and South America"
label var pct_asia "Asia"
label var pct_africa "Africa"
label var pct_north_am "North America"

label var pct_haven_corrected "Financial Centers"
label var pct_europe_corrected "Europe"
label var pct_middle_east_corrected "Middle East"
label var pct_latin_am_corrected "Latin and South America"
label var pct_asia_corrected "Asia"
label var pct_africa_corrected "Africa"
label var pct_north_am_corrected "North America"


* We graph the country groups shares of fiduciary accounts, uncorrected

#delimit;
twoway connected pct_haven pct_europe pct_middle_east pct_latin_am
pct_asia pct_africa pct_north_am year, sort msymbol(S dh sh th i i Oh) msize(medsmall medsmall medsmall medsmall medsmall medsmall medsmall) 
lpattern(solid solid dash solid dash solid solid) scheme(s1mono) lwidth(medium medium medium medium medium medium medium) plotregion(margin(none))
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%", 
grid labsize(small) angle(horizontal) labgap(1) tstyle(minor)
) 
xlabel(1984(4)2024, grid angle(90) labsize(small) labgap(1) tstyle(minor)
) 
legend(nobox ring(0) position(10) cols(1) size(vsmall) region(lstyle(none))) 
xtitle("") ytitle("% of total foreign-owned Swiss bank deposits", size(small));
#delimit cr
graph export "$fig/update-swiss-fiduciary-87-23.pdf", replace

* We graph the country groups shares of fiduciary accounts, corrected using FDI
*check what this graph represents!
#delimit;
twoway connected pct_haven_corrected pct_europe_corrected pct_middle_east_corrected pct_latin_am_corrected
pct_asia_corrected pct_africa_corrected pct_north_am_corrected year if year >= 2001, sort msymbol(S dh sh th i i Oh) msize(medsmall medsmall medsmall medsmall medsmall medsmall medsmall) 
lpattern(solid solid dash solid dash solid solid) scheme(s1mono) lwidth(medium medium medium medium medium medium medium) plotregion(margin(none))
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%", 
grid labsize(small) angle(horizontal) labgap(1) tstyle(minor)
) 
xlabel(2000(4)2024, grid angle(90) labsize(small) labgap(1) tstyle(minor)
) 
legend(nobox ring(0) position(10) cols(1) size(vsmall) region(lstyle(none))) 
xtitle("") ytitle("% of total foreign-owned Swiss bank deposits", size(small));
#delimit cr
graph export "$fig/swiss-fiduciary-corrected-87-23.pdf", replace



********************************************************************************
* Figure 7: Unrecorded Share of Bank Deposits in Switzerland Belonging to Russian Households
********************************************************************************

* Read data 
use "$work/fiduciary-87-23_uncorr.dta", clear

* We compute for each country the share in total fiduciary accounts, for the 
* three indicators (uncorrected, FDI, Russia Cyprus)
gen share_total_fiduciary = 0
gen share_total_fidu_rus = 0
gen share_total_fidu_fdi = 0
forvalues i = 1992/2023 {
	sum(lfidu2dol) if year == `i'
	replace share_total_fiduciary = lfidu2dol/r(sum) if year == `i'
	sum(lfidu2dol_fdi_adjustment) if year == `i'
	replace share_total_fidu_fdi = lfidu2dol_fdi_adjustment/r(sum) if year == `i'
	sum(lfidu2dol_russia_adjustment) if year == `i'
	replace share_total_fidu_rus = lfidu2dol_russia_adjustment/r(sum) if year == `i'
}

* We graph the evolution of the Russian-owned share in fiduciary accounts as
* reported by Swiss National Bank.
#delimit;
twoway (connected share_total_fiduciary  year if ccode == "RUS" & year >= 1992,
msymbol(S) msize(medlarge) mcolor(emerald) mlcolor(black) mlwidth(medthin)
lcolor(black) lwidth(medium))
(connected share_total_fiduciary  year if ccode == "CYP" & year >= 1992,
msymbol(Sh) msize(medlarge) mcolor(cranberry) mlcolor(cranberry) mlwidth(medthin)
lcolor(cranberry) lwidth(medium)),
plotregion(margin(none)) graphregion(col(white)) 
xtitle("", size(medsmall)) 
ytitle("Share of Foreign-Owned Swiss Fiduciary Deposits", size(small))  
xlabel(1992(4)2024, grid angle(90) labsize(small) labgap(1) tstyle(minor)
) 
ylabel(0 "0%" .005 "0.5%" .01 "1%" .015 "1.5%" .02 "2%" .025 "2.5%" .03 "3%" .035 "3.5%" 0.04 "4%" 0.045 "4.5%" 0.05 "5%", 
grid glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) 
glwidth(thin) tstyle(minor) labgap(1)  
)
legend(nobox ring(0) position(9) cols(1) size(small) region(lstyle(none)) order(1 "Russian households" 2 "Cypriot households"));
#delimit cr 
graph export "$fig/russia-deposits-uncorrected_noSTD.pdf", replace

* We graph the evolution of the Russian-owned share in fiduciary accounts when 
* we add what we assume to be only virtually owned by Cypriot households, i.e
* 80% of Cypriot fiduciary deposits.
#delimit;
twoway connected share_total_fidu_rus year if ccode == "RUS" & year >= 1992,
msymbol(S) msize(medlarge) mcolor(emerald) mlcolor(black) mlwidth(medthin)
lcolor(black) lwidth(medium)
plotregion(margin(none)) graphregion(col(white)) 
xtitle("", size(medsmall)) 
ytitle("Share of Foreign-Owned Swiss Fiduciary Deposits", size(small))  
xlabel(1992(4)2024, grid angle(90) labsize(small) labgap(1) tstyle(minor)
) 
ylabel(0 "0%" .005 "0.5%" .01 "1%" .015 "1.5%" .02 "2%" .025 "2.5%" .03 "3%" .035 "3.5%", 
grid glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) 
glwidth(thin) tstyle(minor) labgap(1)  
)
legend(nobox ring(0) position(1) cols(1) size(vsmall) region(lstyle(none)));
#delimit cr 
graph export "$fig/russia-deposits-corrected.pdf", replace





********************************************************************************
* Figure 8: Offshore Wealth in 2023: FDI-Corrected Estimates for Large Economies (% of GDP)
********************************************************************************
**---------------Graph: Offshore Wealth in % of GDP 2023-----------------**


*calculate World Averages
use "$work/ofw_aggregate", clear
sum worldgdp if year == 2023
local gdp2023 = r(mean)
use "$work/countries.dta", clear
keep if indicator == "total_russia_adjustment"
keep if year==2023
collapse (sum) value, by(year)
gen ofw_pct = value / `gdp2023' if year == 2023
replace ofw_pct= int(ofw_pct*100 )
levelsof ofw_pct if year == 2023, local(world_av_2023)

* Countries with > 200 billion USD 
use "$work/countries", clear
keep if year == 2023 & indicator == "total_russia_adjustment"
keep if gdp > 200*1e+9
drop if value == 0 | gdp == .
sort value
rename gdp_current_dollars gdp2023
rename value value23russ
tempfile countries23russ
save `countries23russ'
use "$work/countries", clear
keep if year == 2023 & indicator == "total_corrected"
merge 1:1 iso3 using "`countries23russ'", keep(match) nogenerate 
drop unit label indicator year
*rename gdp_current_dollars gdp2023
rename value value23fdi
gen ratio_offshore_GDP23russ = value23russ/(gdp2023/1e+9)
gen ratio_offshore_GDP23fdi = value23fdi/(gdp2023/1e+9)
gen country = ""
replace country = "UAE" if iso3 == "ARE"
replace country = "UK" if iso3 == "GBR"
replace country = "Iran" if iso3 == "IRN"
replace country = "Korea" if iso3 == "KOR"
replace country = "Netherlands" if iso3 == "NLD"
replace country = "Russia" if iso3 == "RUS"
replace country = "Taiwan" if iso3 == "TWN"
replace country = "USA" if iso3 == "USA"
replace country = "Venezuela" if iso3 == "VEN"
replace country = country_name if country == ""
#delimit;
graph bar ratio_offshore_GDP23russ ratio_offshore_GDP23fdi,
over(country, sort(ratio_offshore_GDP23russ) label(angle(90) labsize(small)
labgap(1))) 
graphregion(col(white)) 
ylabel(0 "0%" 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" 0.5 "50%" 0.6 "60%" 
0.7 "70%" 0.8 "80%" 0.9 "90%" 1.0 "100%" 1.1 "110%" 1.2 "120%" 1.3 "130%" 
, tstyle(minor) grid angle(horizontal) glcolor(grey%10) 
labsize(small) labgap(1)) 
yline(.13, lcolor(black)) 
ytitle("Share of GDP", size(small)) 
yline(.13, lcolor(black)) 
text(0.16 9 "World Average: `world_av_2023'%", color(black*2) size(small))
bargap(15)
outergap(30)
bar(1, color() lcolor(black) lwidth(vthin))
bar(2, color(red*1.3) lcolor(black) lwidth(vthin))
legend(nobox ring(0) position(9) cols(1) size(vsmall) 
label(1 "Preferred offshore wealth estimates") label(2 "FDI-corrected offshore wealth estimates"));
#delimit cr
graph export "$fig/countries-offshore-gdp-2023-fdi.pdf", replace


********************************************************************************
* Figure 9: Development and Ownership of UK-Hosted Offshore Wealth
********************************************************************************
// Share of UK in global offshore wealth
use "$work/ofw_aggregate", clear

// calculate share UK
gen share_GB = depGB / bis_total * ofw_other / ofw * 100
gen share_GGJE = (depGG + depJE) / bis_total * ofw_other / ofw *100 
gen share_GBplus = (depGB + depGG + depJE) / bis_total * ofw_other / ofw *100 

foreach ofc in "HK" "SG" "US" {
gen share_`ofc' = dep`ofc' / bis_total * ofw_other / ofw * 100
}

label var share_GB "UK"
label var share_GBplus "UK incl. Guernsey and Jersey"

#delimit;
twoway connected share_GB share_GBplus year,
msymbol(circle triangle) msize(small small) 
mcolor(lavender*1.5 emerald*1.5) mlcolor() mlwidth(thin thin) 
lwidth(vthin vthin) lcolor(lavender*1.5 emerald*1.5)
graphregion(col(white)) plotregion(margin(none))
legend(nobox ring(0) position(5) cols(1) size(small) region(lstyle(none))) 
xlabel(2001(2)2023, nogrid 
)
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%", grid 
glcolor(grey%10) labsize(small) angle(horizontal) glwidth(thin) 
tstyle(minor) labgap(1)
)
xtitle("")
title("Offshore wealth hosted by the United Kingdom", size(medsmall))
name(trend, replace);
#delimit cr



// Allocation of offshore wealth hosted by the UK
use "$work/offshore2023.dta", clear
keep if namebank == "European havens" | bank =="GB"
keep saver iso3saver namesaver bank amt_bis sh_bis year rawsh_bis europe

reshape wide sh_bis amt_bis rawsh_bis, i(saver iso3saver namesaver year europe) j(bank) string


// undo shell company correction

foreach saver in GB CH BE NL IE US {
replace saver = "`saver'" if saver == "`saver'H"
}
replace europe = europe[_n-1] if saver == saver[_n-1]

collapse (sum) amt_bisEU sh_bisEU rawsh_bisEU amt_bisGB sh_bisGB rawsh_bisGB, by(saver year europe)
// sh_bisGB and sh_bisEU remain the same because the shell-company share was set to zero!

gsort -sh_bisGB
gen top10_shGB = _n

gsort -rawsh_bisGB
gen top10_rawshGB = _n

label var sh_bisGB "corrected share"
label var rawsh_bisGB "raw share"

foreach var in sh_bisGB rawsh_bisGB{
	replace `var' = `var'*100
}

#delimit;
graph bar (asis) sh_bisGB rawsh_bisGB
if saver=="US"|saver=="IE"|saver=="KY"|saver=="NL"|saver=="CH"|saver=="HK"
|saver=="LU"|saver=="JP"|saver=="SG"|saver=="SG"|saver=="SA"|saver=="QA"
|saver=="DE"|saver=="FR"|saver=="AU"|saver=="CA"|saver=="AE",
over(saver, sort(top10_shGB) label(angle(90) labsize(small)
labgap(1))) 
graphregion(col(white)) 
ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 
, tstyle(minor) grid angle(horizontal) glcolor(grey%10) glwidth(thin) 
labsize(small) labgap(1)) 
bargap(15)
outergap(30)
bar(1, color(emerald) lcolor(black) lwidth(vthin))
bar(2, color(lavender) lcolor(black) lwidth(vthin))
legend(nobox ring(0) position(3) cols(1) size(small) 
label(1 "corrected share") label(2 "raw share"))
title("Location of Ultimate Owners: UK (2023)", size(medsmall))
name(GB, replace);
#delimit cr

// Allocation of offshore wealth hosted by the UK incl. Guernsey and Jersey
use "$work/offshore2023.dta", clear
keep if bank =="GB"|bank=="JE"|bank=="GG"
keep saver iso3saver namesaver bank amt_bis sh_bis year rawsh_bis europe
egen total=total(amt_bis), by(bank)
gen amt_bis_adj = sh_bis * total


// undo shell company correction

foreach saver in GB CH BE NL IE US {
replace saver = "`saver'" if saver == "`saver'H"
}
sort saver
replace europe = europe[_n-1] if saver == saver[_n-1]

collapse (sum) amt_bis amt_bis_adj, by(saver europe year)
egen total=total(amt_bis)


gen rawsh_bis = amt_bis/total*100
gen sh_bis = amt_bis_adj/total*100

gsort -sh_bis
gen top10_sh = _n

gsort -rawsh_bis
gen top10_rawsh= _n

#delimit;
graph bar (asis) sh_bis rawsh_bis
if saver=="US"|saver=="IE"|saver=="KY"|saver=="NL"|saver=="CH"|saver=="HK"
|saver=="LU"|saver=="JP"|saver=="SA"|saver=="QA"|saver=="DE"|saver=="FR"
|saver=="AU"|saver=="CA"|saver=="GB"|saver=="AE"|saver=="SG"|saver=="GB",
over(saver, sort(top10_sh) label(angle(90) labsize(small)
labgap(1))) 
graphregion(col(white)) 
ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 
, tstyle(minor) grid angle(horizontal) glcolor(grey%10) glwidth(thin) 
labsize(small) labgap(1)) 
bargap(15)
outergap(30)
bar(1, color(emerald) lcolor(black) lwidth(vthin))
bar(2, color(lavender) lcolor(black) lwidth(vthin))
legend(nobox ring(0) position(3) cols(1) size(small) 
label(1 "corrected share") label(2 "raw share"))
title("Location of Ultimate Owners: UK incl. Guernsey and Jersey (2023)", size(medsmall))
name(GBplus, replace);
#delimit cr


graph combine trend GB GBplus , col(1) xsize(5) ysize(7)
graph export "$fig/GB_allocation.pdf", replace

********************************************************************************
* Figure 10: Offshore Wealth and Country Studies
********************************************************************************
use "$work/countries.dta", clear 
keep if iso3 == "COL" | iso3 == "ARG" | iso3 == "USA"
keep if indicator == "total_russia_adjustment" | indicator == "total_corrected"

replace indicator = "total" if indicator == "total_russia_adjustment"
replace indicator = "total_fdi" if indicator == "total_corrected"
gen ofw = value / gdp * 1000000000 * 100
keep year iso3 indicator gdp_current ofw
reshape wide gdp ofw, i(year iso3) j(indicator) string
drop gdp_current_dollarstotal_fdi
rename gdp gdp

gen benchmark = 80.8 if iso3 == "ARG" & year == 2016
gen benchmark_pct = benchmark * 1000000000 / gdp * 100
// Source: Londoño-Vélez & Tortarolo 2022
// includes cash deposits and investments abroad, potentially also incl. direct investment and full company ownership in USD bn.

replace benchmark_pct = 2.8 if iso3 == "COL" & year == 2017
//Source: Avila-Mahecha & Londoño-Vélez 2021

replace benchmark = 1940 if year == 2018 & iso3 == "USA"
replace benchmark_pct = benchmark * 1000000000 / gdp * 100  if year == 2018 & iso3 == "USA"
// "In FY 2017, total offshore wealth reported by individuals in tax return #160 for foreign assets amounts to 2.8% of GDP. That is, less than one-third
// of the baseline measure of offshore wealth is reported to the tax authorities. Half of this amount (1.4% of GDP) was disclosed thanks to the voluntary 
// disclosure program. This means 6.2% of GDP remains concealed offshore." (Assuming AJZ offshore wealth of 9%) (Online Appendix C3).

keep if benchmark_pct != .
gen label = iso3 + " 2016" if iso3 == "ARG"
replace label = iso3 + " 2017" if iso3 == "COL"
replace label = iso3 + " 2018" if iso3 == "USA"

 
 #delimit;
graph bar (asis) ofwtotal ofwtotal_fdi benchmark_pct,
over(label, label(labsize(small)))
graphregion(col(white)) 
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 
, tstyle(minor) grid angle(horizontal) glcolor(grey%10) glwidth(thin) 
labsize(small) labgap(1)) 
ytitle("% of GDP", size(small)) 
bargap(5)
outergap(70)
bar(1, color(emerald) lcolor(black) lwidth(vthin))
bar(2, color(lavender) lcolor(black) lwidth(vthin))
bar(3, color(red*1.5) lcolor(black) lwidth(vthin))
legend(nobox ring(0) position(2) cols(1) size(small) 
label(1 "Offshore wealth estimate") label(2 "FDI-corrected offshore wealth estimate") label(3 "Offshore wealth according to benchmark study"))
name(benchmark, replace);
#delimit cr

graph export "$fig/benchmark-cty.pdf", replace


********************************************************************************
* Figure 11: Offshore Wealth and CRS-Reported Foreign Wealth
********************************************************************************
use "$raw/dta/crs_all.dta", clear
rename country iso3
rename referenceyear year
merge 1:m iso3 year using "$work/countries.dta"
keep if _merge == 3
keep if indicator == "total_russia_adjustment"

gen crs = crsreportedforeignwealthinusd / gdp_current * 1000000000 * 100
gen ofw_est = value/gdp_current*1000000000 * 100

label var ofw_est "Offshore wealth vs. CRS-reported wealth"
label var crs "CRS-reported wealth"


twoway (scatter ofw_est crs , mcolor(midblue*1.5) mlabel(iso3) mlabcolor(midblue)) (lfit ofw_est crs, lcolor(gray) lwidth(thin)) , ///
ytitle(`"Offshore wealth estimate in % of GDP"', size(small)) ///
xtitle(`"CRS-reported wealth in % of GDP"', size(small)) ///
name(test, replace) legend(position(6) size(small)) ///
xlabel(0 10 20 30 40 50) ///
xsize(6) ysize(5) ///
text(21 46 "← fitted values", color(gray) size(vsmall)) ///
legend(off)
graph export "$fig/crs-scatter.pdf", replace 

********************************************************************************
* Figure 12: BIS-Reported Foreign Bank Deposits and CRS-Reported Foreign Wealth of German Residents, 2019
********************************************************************************

** Match German bilateral CRS data to BIS deposits
* Read BIS locational data
use "$work/locational.dta", clear
rename counter saver
rename value dep

* Keep non bank, liabilities, all instruments, all parent countries
keep if sector == "N" & position == "L" & instrument == "A" & ///
		parent == "5J" & year >= 2001 & year <= 2023
		
* Netherlands Antilles have been removed as a reporting country but global totals have not been adjusted: -> add AN from 2023 version
append using "$raw/dta/bis_AN.dta"
	br bank saver year quarter if saver == "5J" & bank == "5A"
	sum dep if saver == "5J" & bank == "5A" & year == 2001 & quarter == 1
	sum dep if saver == "5J" & bank == "5A_23" & year == 2001 & quarter == 1
	drop if bank =="5A_23"
	replace dep = . if bank == "AN" & saver == "5J" & year == 2010 // Curacao already in dataset
	
keep if quarter == 4
drop quarter

* drop BIS aggregates
drop if ///
saver == "5R" | saver == "4W" | saver == "4Y" | saver == "3C" | ///
saver == "4U" | saver == "4T" | saver == "2D" | saver == "2C" | ///
saver == "2T" | saver == "2S" | saver == "5M" | saver == "2T" | ///
saver == "2R" | saver == "5C" | saver == "2R" | saver == "5K" | ///
saver == "4L" | saver == "2B" | saver == "2H" | saver == "2O" | ///
saver == "2W" | saver == "2N" | saver == "1C" | saver == "2U" | ///
saver == "2Z" | saver == "C9"
sum dep if saver == "DE" & bank == "MX" & year == 2021
local mx2021=r(mean)
keep if year == 2019
keep if saver == "DE"
replace dep = `mx2021' if bank == "MX"

rename iso3bank iso3
merge 1:1 iso3 using "$raw\dta\CRS_German.dta"
replace usd = usd / 1000000
rename usd crs_rep
label var crs_rep "crs reported"
label var dep "bis reported"

graph bar (asis) dep crs_rep if _merge == 3 & crs != ., over(iso3, label(angle(ninety)))
sort dep
keep if _merge == 3 & crs !=.
keep namebank bank iso3 saver year dep crs
gen help = _n
gen group = 1 if help < 11
replace group = 2 if help > 10 

replace dep = dep / 1000
replace crs = crs/1000

#delimit;
graph bar dep crs_rep,
over(iso3, sort(dep) label(angle(90) labsize(small)
labgap(1))) 
graphregion(col(white)) 
ylabel(0 "0" 25 "25" 50 "50" 75 "75" 100 "100" 125 "125" 
, tstyle(minor) grid angle(horizontal) glcolor(grey%10) 
labsize(small) labgap(1)) 
ytitle("USD bn", size(small))  
bargap(15)
outergap(30)
bar(1, color() lcolor(black) lwidth(vthin))
bar(2, color(red*1.3) lcolor(black) lwidth(vthin))
legend(nobox ring(0) position(9) cols(1) size(vsmall) 
label(1 "BIS reported") label(2 "CRS reported"))
name(large, replace);
#delimit cr
graph export "$fig/bis-crs-match_DE2019.pdf", replace


********************************************************************************
* Figure 13: Shares of world GDP of High-Income vs. Middle- and Lower-Income Countries
********************************************************************************
**------Fraction of global household ofw owned by income country groups--------*
use "$work/countries", clear

* compute the % owned by each income level countries
keep if indicator == "total_russia_adjustment"

gen world_gdp = 0
forvalues j = 2001/2023 {
	su gdp if year == `j'
	replace world_gdp = r(sum) if year == `j' 
}

collapse (sum) gdp value, by(year incomelevelname world_gdp)
replace incomelevelname = "upper_middle" if incomelevelname == "Upper middle income"
replace incomelevelname = "high" if incomelevelname == "High income"
replace incomelevelname = "low" if incomelevelname == "Low income"
replace incomelevelname = "lower_middle" if incomelevelname == "Lower middle income"
replace incomelevelname = "unclassified" if incomelevelname == "Unclassified"
gen sh_ofw_total = 0
gen sh_ofw_gdp = 0
gen sh_world_gdp = 0
forvalues i = 2001/2023 {
	sum value if year == `i'
	local ofw`i' r(sum)
	replace sh_ofw_total = value*100/`ofw`i'' if year == `i'
	replace sh_ofw_gdp = value*100/(world_gdp/1e+9) if year == `i'
	replace sh_world_gdp = gdp*100/(world_gdp) if year == `i'
}  
drop value gdp
reshape wide sh_ofw_total sh_ofw_gdp sh_world_gdp, i(year) j(incomelevelname) string
foreach var in sh_ofw_gdp sh_ofw_total sh_world_gdp {
gen `var'_low_middle_inc = `var'low + `var'lower_middle + `var'upper_middle + `var'unclassified
}

keep year sh_ofw_gdphigh sh_ofw_totalhigh sh_ofw_gdp_low_middle_inc ///
sh_ofw_total_low_middle_inc sh_world_gdphigh sh_world_gdp_low_middle_inc ///
sh_ofw_totallow sh_ofw_totallower_middle sh_ofw_totalupper_middle


label var sh_world_gdphigh "High income countries"
label var sh_world_gdp_low_middle_inc "Middle and low income countries"
#delimit;
twoway connected sh_world_gdphigh sh_world_gdp_low_middle_inc year, 
msymbol(circle circle) msize(small small) mcolor(midblue*2.5 red*1.5) 
mlwidth(thin thin)
lcolor(midblue*2.5 red*1.5) lwidth(medthick medthick)
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)))
ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
)
xlabel(2000(1)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ytitle("% of world GDP", size(small)) 
xtitle("");
#delimit cr
graph export "$fig/share-gdp-income-country-groups.pdf", replace 


********************************************************************************
* Figure 14: Average Growth of Offshore Wealth and GDP by Country, 2001-2023
********************************************************************************
use "$work/countries", clear
keep if indicator == "total_russia_adjustment"
replace regionname = "Latin America & Caribbean" if regionname == "Latin America & Carribean"

gen ofw_pct = value / gdp_current*1000000000 * 100
rename value ofw
rename gdp_current gdp
keep iso3 country_name ofw ofw_pct gdp year regionname indicator
sort iso3 year
foreach var in ofw ofw_pct gdp{
	sort iso3 year
	gen growth_`var' = (`var'/`var'[_n-1] - 1) * 100 if iso3==iso3[_n-1]
	by iso3, sort: egen avg_growth_`var'= mean(growth_`var')
}

histogram avg_growth_gdp
histogram avg_growth_ofw if avg_growth_ofw
histogram avg_growth_ofw if avg_growth_ofw < 50
 
tab iso3 if avg_growth_ofw > 50 & avg_growth_ofw!=.
twoway (scatter avg_growth_ofw avg_growth_gdp) if year==2023, name(scatter, replace)
twoway (scatter avg_growth_ofw avg_growth_gdp) (lfitci avg_growth_ofw avg_growth_gdp) if year==2023 & iso3!="PLW"&iso3!="TUV", name(scatter2, replace)
twoway (scatter avg_growth_ofw avg_growth_gdp) if year==2023 & iso3!="PLW" & iso3!="SSD"&iso3!="TUV"

twoway (scatter avg_growth_ofw avg_growth_gdp) (lfitci avg_growth_ofw avg_growth_gdp) if year==2023 & iso3!="PLW" & iso3!="SSD"&iso3!="TUV"
  
  
twoway (lfitci avg_growth_ofw avg_growth_gdp, lcolor(gray) lwidth(thin)) (scatter avg_growth_ofw avg_growth_gdp, mcolor(lavender*1.5)) ///
if year==2023 & iso3!="PLW" & iso3!="TUV", ///
ytitle(`"Average annual offshore wealth growth in %"', size(small)) ///
xtitle(`"Average annual GDP growth in %"', size(small)) ///
name(test2, replace) legend(position(6) size(small)) ///
legend(off) ///
xsize(6) ysize(5)
graph export "$fig/corr-ofw-gdp.pdf", replace 

********************************************************************************
* Figure 15 and 16: Offshore Wealth by World Region
********************************************************************************

use "$work/countries", clear
keep if indicator == "americ" | indicator == "asian" | indicator == "europe" | indicator== "swiss_russia_adjustment"
replace indicator = "swiss" if indicator == "swiss_russia_adjustment"
replace regionname = "Latin America & Caribbean" if regionname == "Latin America & Carribean"
collapse (sum) gdp value, by(year indicator regionname)

gen ofw = value / gdp_current*1000000000 * 100
keep ofw year regionname indicator
reshape wide ofw, i(year regionname) j(indicator) string

label var ofwameric "American financial centers"
label var ofwasia "Asian financial centers"
label var ofweurope "European financial centers"
label var ofwswiss "Switzerland"

* Regions 
local call
forvalues j = 1/23 {
local show = `j' + 2000
if mod(`j', 2) == 1 local call `call' `j' "`show'"
else local call `call' `j' " "
}

#delimit;
graph bar (asis) ofwswiss ofweurope ofwasia ofwameric 
if  regionname == "East Asia & Pacific" 
| regionname == "Europe & Central Asia"
| regionname == "Latin America & Caribbean"
| regionname == "Middle East & North Africa",
over(year, relabel(`call') label(angle(ninety) labsize(vsmall))) 
stack 
bar(1, fcolor(red*0.8) lcolor(red*0.8)) 
bar(2, fcolor(midblue*1.5) lcolor(midblue*1.5)) 
bar(3, fcolor(emerald*0.7) lcolor(emerald*0.7)) 
bar(4, fcolor(lavender*1.8) lcolor(lavender*1.8)) 
ytitle(`"% of GDP"', size(small))
ylabel(, labsize(vsmall))
by(, legend(position(6))) 
legend(cols(2) size(vsmall))
xsize(5) ysize(6)
by(regionname, imargin(small) note(""))
subtitle(, size(small));
#delimit cr
graph export "$fig/ofw-regions1.pdf", replace



local call
forvalues j = 1/23 {
local show = `j' + 2000
if mod(`j', 2) == 1 local call `call' `j' "`show'"
else local call `call' `j' " "
}

#delimit;
graph bar (asis) ofwswiss ofweurope ofwasia ofwameric 
if regionname == "North America"
| regionname == "South Asia"
| regionname == "Sub-Saharan Africa",
over(year, relabel(`call') label(angle(ninety) labsize(vsmall))) 
stack 
bar(1, fcolor(red*0.8) lcolor(red*0.8)) 
bar(2, fcolor(midblue*1.5) lcolor(midblue*1.5)) 
bar(3, fcolor(emerald*0.7) lcolor(emerald*0.7)) 
bar(4, fcolor(lavender*1.8) lcolor(lavender*1.8)) 
ytitle(`"% of GDP"', size(small))
ylabel(, labsize(vsmall))
by(, legend(position(6))) 
legend(cols(2) size(vsmall))
xsize(5) ysize(6)
by(regionname, imargin(small) note(""))
subtitle(, size(small));
#delimit cr
graph export "$fig/ofw-regions2.pdf", replace




********************************************************************************
* Figure 17 to 20: Offshore Wealth by World Region
********************************************************************************



use "$work/countries", clear
keep if indicator == "americ" | indicator == "asian" | indicator == "europe" | indicator== "swiss_russia_adjustment"
replace indicator = "swiss" if indicator == "swiss_russia_adjustment"
gen ratio_offshore_GDP = (value/(gdp_current_dollars/1000000000))*100
keep ratio_offshore_GDP iso3 country_name year indicator
rename ratio ofw
reshape wide ofw, i(year iso3 country_name) j(indicator) string

label var ofwameric "American financial centers"
label var ofwasia "Asian financial centers"
label var ofweurope "European financial centers"
label var ofwswiss "Switzerland"



// Individual countries by region

* Europe  
local call
forvalues j = 1/23 {
local show = `j' + 2000
if mod(`j', 2) == 1 local call `call' `j' "`show'"
else local call `call' `j' " "
}

#delimit;
graph bar (asis) ofwswiss ofweurope ofwasia ofwameric 
if  iso3=="DEU"|iso3=="GBR"|iso3=="ITA"|iso3=="FRA" |iso3 == "ESP" |iso3 == "NLD",
over(year, relabel(`call') label(angle(ninety) labsize(vsmall))) 
stack 
bar(1, fcolor(red*0.8) lcolor(red*0.8)) 
bar(2, fcolor(midblue*1.5) lcolor(midblue*1.5)) 
bar(3, fcolor(emerald*0.7) lcolor(emerald*0.7)) 
bar(4, fcolor(lavender*1.8) lcolor(lavender*1.8)) 
ytitle(`"% of GDP"', size(vsmall)) 
ylabel(, labsize(vsmall))
by(, legend(position(6))) 
legend(cols(2) size(vsmall))
xsize(5) ysize(6)
by(iso3, rows(2) imargin(small) note(""))
subtitle(, size(small));
#delimit cr
graph export "$fig/ofw_europe.pdf", replace

* Africa & Middle East
local call
forvalues j = 1/23 {
local show = `j' + 2000
if mod(`j', 2) == 1 local call `call' `j' "`show'"
else local call `call' `j' " "
}

#delimit;
graph bar (asis) ofwswiss ofweurope ofwasia ofwameric 
if  iso3=="SAU"|iso3=="ISR"|iso3=="EGY"|iso3=="ZAF"|iso3=="IRN"|iso3=="NGA",
over(year, relabel(`call') label(angle(ninety) labsize(vsmall))) 
stack 
bar(1, fcolor(red*0.8) lcolor(red*0.8)) 
bar(2, fcolor(midblue*1.5) lcolor(midblue*1.5)) 
bar(3, fcolor(emerald*0.7) lcolor(emerald*0.7)) 
bar(4, fcolor(lavender*1.8) lcolor(lavender*1.8)) 
ytitle(`"% of GDP"', size(vsmall)) 
ylabel(, labsize(vsmall))
by(, legend(position(6))) 
legend(cols(2) size(vsmall))
xsize(5) ysize(6)
by(iso3, rows(2) imargin(small) note(""))
subtitle(, size(small));
#delimit cr

graph export "$fig/ofw_africa.pdf", replace


* Asia 
local call
forvalues j = 1/23 {
local show = `j' + 2000
if mod(`j', 2) == 1 local call `call' `j' "`show'"
else local call `call' `j' " "
}

#delimit;
graph bar (asis) ofwswiss ofweurope ofwasia ofwameric 
if iso3 == "CHN"|iso3=="IND"|iso3=="JPN"|iso3=="RUS"|iso3=="KOR"|iso3=="IDN",
over(year, relabel(`call') label(angle(ninety) labsize(vsmall))) 
stack 
bar(1, fcolor(red*0.8) lcolor(red*0.8)) 
bar(2, fcolor(midblue*1.5) lcolor(midblue*1.5)) 
bar(3, fcolor(emerald*0.7) lcolor(emerald*0.7)) 
bar(4, fcolor(lavender*1.8) lcolor(lavender*1.8)) 
ytitle(`"% of GDP"', size(vsmall)) 
ylabel(, labsize(vsmall))
by(, legend(position(6))) 
legend(cols(2) size(vsmall))
xsize(5) ysize(6)
by(iso3, rows(2) imargin(small) note(""))
subtitle(, size(small));
#delimit cr
graph export "$fig/ofw_asia.pdf", replace




* Americas
local call
forvalues j = 1/23 {
local show = `j' + 2000
if mod(`j', 2) == 1 local call `call' `j' "`show'"
else local call `call' `j' " "
}

#delimit;
graph bar (asis) ofwswiss ofweurope ofwasia ofwameric 
if iso3=="CAN"|iso3=="USA"|iso3=="BRA"|iso3=="MEX"|iso3=="ARG"|iso3=="COL",
over(year, relabel(`call') label(angle(ninety) labsize(vsmall))) 
stack 
bar(1, fcolor(red*0.8) lcolor(red*0.8)) 
bar(2, fcolor(midblue*1.5) lcolor(midblue*1.5)) 
bar(3, fcolor(emerald*0.7) lcolor(emerald*0.7)) 
bar(4, fcolor(lavender*1.8) lcolor(lavender*1.8)) 
ytitle(`"% of GDP"', size(vsmall)) 
ylabel(, labsize(vsmall))
by(, legend(position(6))) 
legend(cols(2) size(vsmall))
xsize(5) ysize(6)
by(iso3, rows(2) imargin(small) note(""))
subtitle(, size(small));
#delimit cr
graph export "$fig/ofw_americas.pdf", replace







********************************************************************************
* Figure 21: FDI-Corrected Shares in Offshore Wealth of High-Income vs. Middle- and Lower-Income Countries
********************************************************************************
**------FDI-corrected: Fraction of global household ofw owned by income country groups--------*
use "$work/countries", clear

* compute the % owned by each income level countries
keep if indicator == "total_corrected"

gen world_gdp = 0
forvalues j = 2001/2023 {
	su gdp if year == `j'
	replace world_gdp = r(sum) if year == `j' 
}

collapse (sum) gdp value, by(year incomelevelname world_gdp)
replace incomelevelname = "upper_middle" if incomelevelname == "Upper middle income"
replace incomelevelname = "high" if incomelevelname == "High income"
replace incomelevelname = "low" if incomelevelname == "Low income"
replace incomelevelname = "lower_middle" if incomelevelname == "Lower middle income"
replace incomelevelname = "unclassified" if incomelevelname == "Unclassified"
gen sh_ofw_total = 0
gen sh_ofw_gdp = 0
gen sh_world_gdp = 0
forvalues i = 2001/2023 {
	sum value if year == `i'
	local ofw`i' r(sum)
	replace sh_ofw_total = value*100/`ofw`i'' if year == `i'
	replace sh_ofw_gdp = value*100/(world_gdp/1e+9) if year == `i'
	replace sh_world_gdp = gdp*100/(world_gdp) if year == `i'
}  
drop value gdp
reshape wide sh_ofw_total sh_ofw_gdp sh_world_gdp, i(year) j(incomelevelname) string
foreach var in sh_ofw_gdp sh_ofw_total sh_world_gdp {
gen `var'_low_middle_inc = `var'low + `var'lower_middle + `var'upper_middle + `var'unclassified
}

keep year sh_ofw_gdphigh sh_ofw_totalhigh sh_ofw_gdp_low_middle_inc ///
sh_ofw_total_low_middle_inc sh_world_gdphigh sh_world_gdp_low_middle_inc ///
sh_ofw_totallow sh_ofw_totallower_middle sh_ofw_totalupper_middle

label var sh_ofw_totalhigh "High income countries"
label var sh_ofw_total_low_middle_inc "Middle- and low-income countries"
label var sh_ofw_totallow "Low income countries"
label var sh_ofw_totallower_middle "Lower middle income countries"
label var sh_ofw_totalupper_middle "Upper middle income countries"


#delimit;
twoway connected sh_ofw_totalhigh sh_ofw_total_low_middle_inc year, 
msymbol(circle circle) msize(small small) mcolor(midblue*2.5 red*1.5) 
mlwidth(thin thin)
lcolor(midblue*2.5 red*1.5) lwidth(medthick medthick)
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)))
xlabel(2001(1)2023, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
xtitle("")
ytitle("% of total offshore wealth", size(small));
#delimit cr
graph export "$fig/ofw-owned-income-level-total-ofw-fdi.pdf", replace 


********************************************************************************
* Figure 22: Offshore Wealth Robustness Estimates by World Region
********************************************************************************


***our preferred estimates
**------Fraction of global household ofw owned by region groups--------*
use "$work/countries", clear

* compute the % owned by each income level countries
keep if indicator == "total_russia_adjustment"

gen world_gdp = 0
forvalues j = 2001/2023 {
	su gdp if year == `j'
	replace world_gdp = r(sum) if year == `j' 
}
 levelsof regionname
 replace regionname="Latin America & Caribbean" if regionname=="Latin America & Carribean"


collapse (sum) gdp value, by(year regionname world_gdp)

encode regionname, gen(region)
drop regionname

gen sh_ofw_total = 0
gen sh_ofw_gdp = 0
gen sh_world_gdp = 0
forvalues i = 2001/2023 {
	sum value if year == `i'
	local ofw`i' r(sum)
	replace sh_ofw_total = value*100/`ofw`i'' if year == `i'
	replace sh_ofw_gdp = value*100/(world_gdp/1e+9) if year == `i'
	replace sh_world_gdp = gdp*100/(world_gdp) if year == `i'
}  
drop value gdp

reshape wide sh_ofw_total sh_ofw_gdp sh_world_gdp, i(year) j(region)


label var sh_ofw_total1 "East Asia & Pacific"
label var sh_ofw_total2 "Europe & Central Asia"
label var sh_ofw_total3 "Latin America & Caribbean"
label var sh_ofw_total4 "Middle East & North Africa"
label var sh_ofw_total5 "North America"
label var sh_ofw_total6 "South Asia"
label var sh_ofw_total7 "Sub-Saharan Africa"

save "$temp/sh_ofw_total_russia_adjustement.dta", replace

*** fdi correction
**------Fraction of global household ofw owned by region groups--------*
use "$work/countries", clear

* compute the % owned by each income level countries
keep if indicator == "total_corrected"

gen world_gdp = 0
forvalues j = 2001/2023 {
	su gdp if year == `j'
	replace world_gdp = r(sum) if year == `j' 
}
 levelsof regionname
 replace regionname="Latin America & Caribbean" if regionname=="Latin America & Carribean"


collapse (sum) gdp value, by(year regionname world_gdp)

encode regionname, gen(region)
drop regionname

gen sh_ofw_total_corr = 0
gen sh_ofw_gdp_corr = 0
gen sh_world_gdp_corr = 0
forvalues i = 2001/2023 {
	sum value if year == `i'
	local ofw`i' r(sum)
	replace sh_ofw_total_corr = value*100/`ofw`i'' if year == `i'
	replace sh_ofw_gdp_corr = value*100/(world_gdp/1e+9) if year == `i'
	replace sh_world_gdp_corr = gdp*100/(world_gdp) if year == `i'
}  
drop value gdp

reshape wide sh_ofw_total sh_ofw_gdp sh_world_gdp, i(year) j(region)

label var sh_ofw_total_corr1 "East Asia & Pacific"
label var sh_ofw_total_corr2 "Europe & Central Asia"
label var sh_ofw_total_corr3 "Latin America & Caribbean"
label var sh_ofw_total_corr4 "Middle East & North Africa"
label var sh_ofw_total_corr5 "North America"
label var sh_ofw_total_corr6 "South Asia"
label var sh_ofw_total_corr7 "Sub-Saharan Africa"

save "$temp/sh_ofw_total_corrected.dta", replace

***Merge datasets

use "$temp/sh_ofw_total_russia_adjustement.dta", clear
merge 1:1 year world_gdp using "$temp/sh_ofw_total_corrected.dta"

save "$temp/sh_ofw_total_russia_adjustement_or_corrected.dta", replace
***

use  "$temp/sh_ofw_total_russia_adjustement_or_corrected.dta", clear



****

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
label(1 "Preferred offshore wealth estimates") label(2 "FDI-corrected offshore wealth estimates"))
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
label(1 "Preferred offshore wealth estimates") label(2 "FDI-corrected offshore wealth estimates"))
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
label(1 "Preferred offshore wealth estimates") label(2 "FDI-corrected offshore wealth estimates"))
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
label(1 "Preferred offshore wealth estimates") label(2 "FDI-corrected offshore wealth estimates"))
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
label(1 "Preferred offshore wealth estimates") label(2 "FDI-corrected offshore wealth estimates"))
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
label(1 "Preferred offshore wealth estimates") label(2 "FDI-corrected offshore wealth estimates"))
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
label(1 "Preferred offshore wealth estimates") label(2 "FDI-corrected offshore wealth estimates"))
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


graph export "$fig/ofw-owned-by-region-total-ofw-fdi.pdf", replace 











