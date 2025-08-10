//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose:This script creates a cleaned dataset of cbuae non-residents deposits 
* 	- apply exchange rate AED to USD using BIS exchange rates
* 	- uniform the old and new categories
* 	- impute share of categories for year 2014
* 	- impute quarterly data (q1,q2,q3) for years 2009/2017
*   - mean of variables by year 
//
// databases used: - "$raw\uae\bis_e_r_aed_usd.xlsx"
//				   - "$raw\uae\bank_deposits_in_uae_march_2001_to_june_2024.xlsx"
//
// outputs:        - "$raw/bank_deposits_in_uae_cleaned_q4.xlsx"
//
//----------------------------------------------------------------------------//

*###############################################################################*
**---------------------------EXCHANGE RATES-----------------------------------**
*###############################################################################*

* Source: Bank for International Settlements (2024), Bilateral exchange rates, BIS WS_XRU 1.0 (data set), https://data.bis.org/topics/XRU/BIS,WS_XRU,1.0/M.AE.AED.E (accessed on 24 September 2024).
	//- monthly data (average of the days of the month) 
	//- 1966-01 to 2024-08
* The cleaned version, has only the year, month, and value of currency; 
import excel "$raw\uae\bis_e_r_aed_usd.xlsx", firstrow sheet(timeseries observations) clear

*cleaning
keep if COLLECTIONCollection=="A:Average of observations through period"
gen date_var = date(TIME_PERIODPeriod, "YMD")
format date_var %td
gen year=year(date_var)
gen month=month(date_var)
drop DATAFLOW_IDDataflowID KEYTimeseriesKey FREQFrequency REF_AREAReferencearea COLLECTIONCollection TIME_PERIODPeriod date_var OBS_CONFConfidentiality OBS_PRE_BREAKPrebreakvalue OBS_STATUSStatus CURRENCYCurrency Unit Unitmultiplier
gen currency="1 USD = x AED dirhams"
rename OBS_VALUEValue currency_value
order year month currency_value currency
*export excel "$temp/bis_e_r_aed_usd_cleaned.xlsx", firstrow(variables) replace

*import excel "$temp/bis_e_r_aed_usd_cleaned.xlsx", firstrow clear
*drop years and months I do not use
keep if year>=2001
keep if inlist(month,3,6,9,12)
save "$temp/bis_e_r_aed_usd_cleaned_filtered.dta", replace

*use "$root/uae_cbuae/bis_e_r_aed_usd_cleaned_filtered.dta",clear

*###############################################################################*
**----------------------------DEPOSITS----------------------------------------**
*###############################################################################*

import excel "$raw\uae\bank_deposits_in_uae_march_2001_to_june_2024.xlsx", firstrow sheet(merge_pivot) clear

/*Create line graph in Stata which shows the following, all on the same figure:
•	Non-resident deposits (total), per year (end of year for quarterly data): 2001-2024
•	Business and industry non-resident deposits (old categories) 2001-2013
•	Corporate and individual deposits (new categories) 2015-2024

	Then we can look and see if there are any weird jumps between the aggregated old categories and aggregated new categories
•	And if not - they are probably close enough
•	We can then just impute the 2014 value
*/
keep if inlist(month,3,6,9,12)


* I merge with the exchange rate dataset 
merge 1:1 year month using "$temp/bis_e_r_aed_usd_cleaned_filtered.dta"

* I take quarters value for each year:
keep if inlist(month,3,6,9,12)

drop _merge
// deposits are in millions of AED
// so I need to multiply the value of deposits by 1/currency_value 
foreach var in non_residents non_res_corporate non_res_nonbankfininsti non_res_individuals non_res_govnoncom non_res_old_govdipl non_res_old_fininst non_res_old_busiind non_res_old_indivothers total_deposits{
	replace `var'=`var'*(1/currency_value)
}
gen unity="millions of USD"
drop currency_value currency
sort year month

save "$temp/bank_deposits_in_uae_filtered_usd.dta", replace




*###############################################################################*
* I will make old and new categories correspond to each other 
*###############################################################################*	
*use "$temp/bank_deposits_in_uae_filtered_usd.dta", clear

* NEW Corporate <=>  OLD  Business and Industry => corporate
gen corporate=.
replace corporate=non_res_corporate if !missing(non_res_corporate) &missing(non_res_old_busiind)
replace corporate=non_res_old_busiind if !missing(non_res_old_busiind) & missing(non_res_corporate)

	   
* NEW Non Banking Financial Institutions <=>  OLD Financial Institutions => financial_institutions
gen financial_institutions=.
replace financial_institutions=non_res_nonbankfininsti if !missing(non_res_nonbankfininsti) & missing(non_res_old_fininst)
replace financial_institutions=non_res_old_fininst if !missing(non_res_old_fininst) & missing(non_res_nonbankfininsti)

* NEW Individuals <=>  OLD Individuals and Others => individuals
gen individuals=.
replace individuals=non_res_individuals if !missing(non_res_individuals) & missing(non_res_old_indivothers)
replace individuals=non_res_old_indivothers if !missing(non_res_old_indivothers) & missing(non_res_individuals)

* NEW Government and Non Commercial Entities<=>  OLD Government and Diplomatic Missions => government
gen government=.
replace government=non_res_govnoncom if !missing(non_res_govnoncom) & missing(non_res_old_govdipl)
replace government=non_res_old_govdipl if !missing(non_res_old_govdipl) & missing(non_res_govnoncom)
	
drop 	non_res_corporate non_res_nonbankfininsti non_res_individuals non_res_govnoncom non_res_old_govdipl non_res_old_fininst non_res_old_busiind non_res_old_indivothers
	
*save "$temp/bank_deposits_in_uae_filtered_usd_categoriescleaned.dta", replace



*###############################################################################*
* For yearly categories missing data of 2014, 
*=> linear extrapolation of the share of each category  
* I apply 50 percent of the variation between 2013 and 2015 of the share of the category
*###############################################################################*
*use "$root/uae_cbuae/temp/bank_deposits_in_uae_filtered_usd_categoriescleaned.dta", clear

list year  non_residents corporate if inlist(year,2013,2014,2015) & month==12
/*
     +-----------------------------+
     | year   non_res~s   corpor~e |
     |-----------------------------|
 52. | 2013   30433.492   13434.17 |
 56. | 2014   41933.288          . |
 60. | 2015   46696.256   19824.91 |
     +-----------------------------+
*/
replace corporate=((13434.17/30433.492) + 0.5*((19824.91/46696.256)-(13434.17/30433.492)))*41933.288 if year==2014 & month==12

list year  non_residents financial_institutions if inlist(year,2013,2014,2015) & month==12
/*
     +-----------------------------+
     | year   non_res~s   financ~s |
     |-----------------------------|
 52. | 2013   30433.492   9755.752 |
 56. | 2014   41933.288          . |
 60. | 2015   46696.256   15685.77 |
     +-----------------------------+


*/
replace financial_institutions=((9755.752/30433.492) + 0.5*((15685.77/46696.256)-(9755.752/30433.492)))*41933.288 if year==2014 & month==12

list year  non_residents individuals if inlist(year,2013,2014,2015) & month==12
/*

     +-----------------------------+
     | year   non_res~s   indivi~s |
     |-----------------------------|
 52. | 2013   30433.492   6091.491 |
 56. | 2014   41933.288          . |
 60. | 2015   46696.256   7485.909 |
     +-----------------------------+

*/
replace individuals=((6091.491/30433.492) + 0.5*((7485.909/46696.256)-(6091.491/30433.492)))*41933.288 if year==2014 & month==12

list year  non_residents government if inlist(year,2013,2014,2015) & month==12
/*
     +-----------------------------+
     | year   non_res~s   govern~t |
     |-----------------------------|
 52. | 2013   30433.492   1152.076 |
 56. | 2014   41933.288          . |
 60. | 2015   46696.256    3699.66 |
     +-----------------------------+

*/

display ((1152.076/30433.492) + 0.5*((3699.66/46696.256)-(1152.076/30433.492)))*41933.288 //2454.8528
//year	non_residents corporate	financial_institutions	individuals
//2014	41933.288     18156.64	13763.98	7557.808
display 41933.288 -   18156.64	-13763.98	-7557.808 //2454.86   so I will keep the remaining 
replace government=non_residents -corporate-financial_institutions-individuals    if year==2014 & month==12

gen imputed_categories= .
replace imputed_categories= 1 if year==2014 & month==12




*###############################################################################*
* For yearly data, 
*=> linear extrapolation of each quarter. 
* Assign to Q1 in t = value Q4 in t-1 + 0.25*(value Q4 in t -value Q4 in t)     
* [all already in nominal USD] 
* ( Negleting the seazonal effect)
*###############################################################################*
*for missing quarters, I create a dummy to indicate that I will impute the values
gen imputed_non_residents=.
replace imputed_non_residents=1 if missing(non_residents)
replace imputed_non_residents=0 if !missing(non_residents)

* what are the years with only yearly data? 
bysort year: list year if imputed_non_residents!=0  //2009, 2010,2011,2012,2013,2014,2015,2016,2017

*the list of variables I need to impute
local varlist non_residents corporate financial_institutions individuals government total_deposits

* Loop over each variable in varlist
foreach var of local varlist {
    
    * Shorten variable name prefixes to avoid exceeding the 32-character limit
    * Value for month 12 in t
    bysort year (month): gen v_t_`var'=`var' if month==12

    * Sort by year month to ensure proper ordering
    sort year month
    
    * Value for month 12 in t-1
    gen v_tmin1_`var' = v_t_`var'[_n-4] if month==12

    * Calculate evolution between t and t-1
    gen v_diff_`var' = v_t_`var' - v_tmin1_`var' if month==12

    * Fill missing values for t-1
    bysort year : replace v_tmin1_`var' = v_tmin1_`var'[_n+1] if missing(v_tmin1_`var')
    bysort year : replace v_tmin1_`var' = v_tmin1_`var'[_n+1] if missing(v_tmin1_`var')
    bysort year : replace v_tmin1_`var' = v_tmin1_`var'[_n+1] if missing(v_tmin1_`var')

    * Fill missing values for t using a while loop
    bysort year : replace v_t_`var' = v_t_`var'[_n+1] if missing(v_t_`var')
    bysort year : replace v_t_`var' = v_t_`var'[_n+1] if missing(v_t_`var')
    bysort year : replace v_t_`var' = v_t_`var'[_n+1] if missing(v_t_`var')

    * Fill missing values for var_t_tmin1
    bysort year : replace v_diff_`var' = v_diff_`var'[_n+1] if missing(v_diff_`var')
    bysort year : replace v_diff_`var' = v_diff_`var'[_n+1] if missing(v_diff_`var')
    bysort year : replace v_diff_`var' = v_diff_`var'[_n+1] if missing(v_diff_`var')

    * Generate variable for interpolated values
    gen `var'_chk = .

    * Impute missing values for each quarter
    forvalues year = 2009/2017 {
        replace `var' = v_tmin1_`var' + 1 * 0.25 * v_diff_`var' if month == 3 & year == `year'
        replace `var' = v_tmin1_`var' + 2 * 0.25 * v_diff_`var' if month == 6 & year == `year'
        replace `var' = v_tmin1_`var' + 3 * 0.25 * v_diff_`var' if month == 9 & year == `year'
        replace `var'_chk = v_tmin1_`var' + 4 * 0.25 * v_diff_`var' if month == 12 & year == `year'
    }
    * Generate a check difference variable
	gen `var'_chk_diff = `var'_chk - `var'

    * List any rows where the difference is greater than 0.01
    list if `var'_chk_diff > 1 & !missing(`var'_chk_diff)


}

*the list of variables I need to impute
local varlist non_residents corporate financial_institutions individuals government total_deposits

* Loop over each variable in varlist
foreach var of local varlist {
      drop `var'_chk_diff `var'_chk v_tmin1_`var' v_t_`var' v_diff_`var'

}	
  
save "$temp/bank_deposits_in_uae_filtered_usd_categoriescleaned_quarters.dta", replace

use "$temp/bank_deposits_in_uae_filtered_usd_categoriescleaned_quarters.dta", clear

/*
**----------------------------GRAPHS------------------------------------------**

* Generate a quarterly date variable
gen quarter_date = yq(year, month/3)  // month/3 converts months to quarters
format quarter_date %tq

* Define the range of years or quarters to display on the x-axis
local start_year = 2001  // replace with your actual starting year
local end_year = 2024    // replace with your actual ending year
local xlabels ""
forval i = `start_year'/`end_year' {
    local xlabels `xlabels' `=yq(`i', 1)'
}

* Plot the graph for non_resident deposits over time, with lines and smaller points for imputed data
twoway ///
    (line non_residents quarter_date, lcolor(red) lwidth(medium) lpattern(solid) ///
     legend(label(1 "All Data")  ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small))   )) ///  /* Line for all data */
    (scatter non_residents quarter_date if imputed_non_residents == 1, mcolor(black) msymbol(circle) msize(tiny) ///
     legend(label(2 "Imputed Data")  ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small))  )), ///  /* Smaller points for imputed data */
    title("Non-Resident Deposits in UAE Over Time") ///
    xlabel(`xlabels', format(%tqCCYY) angle(45) labsize(small)) ///  /* Display all years on x-axis */
    xtitle("Time (Year-Quarter)", size(small)) ///
    ytitle("Non-Resident Deposits (in Millions USD)", size(small)) ///
    ylabel(, labsize(medium)) ///
	 graphregion(fcolor(white) margin(5 5 5 0)) ///
    xsize(12) ysize(6) ///  /* Extend the x-axis size */
    legend(order(1 "All Data" 2 "Imputed Data"))	///
	note("Source: Central Bank of UAE, Bilateral exchange rate from BIS", size(vsmall) ring(1) pos(7)  color(black) fcolor(white) lstyle(none)) 
graph export "$fig/non_resident_deposits_imputed.png", as(png) replace	
	
	
* Define the range of years or quarters to display on the x-axis
local start_year = 2001  // replace with your actual starting year
local end_year = 2024    // replace with your actual ending year
local xlabels ""
forval i = `start_year'/`end_year' {
    local xlabels `xlabels' `=yq(`i', 1)'
}

* Plot the graph for all categories over time, with one single legend for imputed data
twoway ///
    (line non_residents quarter_date, lcolor(red) lwidth(medium) lpattern(solid) ///
     legend(label(1 "Non-Residents Total") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for non-resident data */
    (line corporate quarter_date, lcolor(blue) lwidth(medium) lpattern(solid) ///
     legend(label(2 "Corporate") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for corporate data */
    (line financial_institutions quarter_date, lcolor(green) lwidth(medium) lpattern(solid) ///
     legend(label(3 "Financial Institutions") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for financial institutions data */
    (line individuals quarter_date, lcolor(purple) lwidth(medium) lpattern(solid) ///
     legend(label(4 "Individuals") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for individuals data */
    (line government quarter_date, lcolor(ltblue) lwidth(medium) lpattern(solid) ///
     legend(label(5 "Government") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for government data */
    (scatter non_residents quarter_date if imputed_non_residents == 1, mcolor(black) msymbol(circle) msize(tiny) ///
     legend(label(6 "Imputed Quartely Data") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///
	 (scatter non_residents quarter_date if imputed_categories == 1, mcolor(pink) msymbol(circle) msize(tiny) ///
     legend(label(7 "Imputed Categories Share") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))), ///  /* Single scatter for imputed data */
    title("Deposits by Non-Residents in UAE Banks") ///
    xlabel(`xlabels', format(%tqCCYY) angle(45) labsize(small)) ///  /* Display all years on x-axis */
    xtitle("Time (Year-Quarter)", size(small)) ///
    ytitle("Deposits (in Millions USD)", size(small)) ///
    ylabel(, labsize(medium)) ///
    graphregion(fcolor(white) margin(5 5 5 0)) ///
    xsize(12) ysize(6) ///  /* Extend the x-axis size */
    legend(col(1) order(1 2 3 4 5 6 7) size(small)) ///  /* Ensure the correct order in the legend */
    note("Source: Central Bank of UAE, Bilateral exchange rate from BIS", size(vsmall) ring(1) pos(7) color(black) fcolor(white) lstyle(none))
	
graph export "$fig/non_resident_deposits_imputed_categories.png", as(png) replace	

	
*/
	
**-------------------------SHARE OF EACH CATEGORY-----------------------------**

local varlist corporate financial_institutions individuals government

foreach var of local varlist{
	gen share_`var'=`var'/(corporate +financial_institutions+ individuals +government)
}
save "$temp/bank_deposits_in_uae_filtered_usd_categoriescleaned_quarters_share.dta", replace

	
/*
**----------------------------GRAPHS------------------------------------------**
* Define the range of years or quarters to display on the x-axis
local start_year = 2001  // replace with your actual starting year
local end_year = 2024    // replace with your actual ending year
local xlabels ""
forval i = `start_year'/`end_year' {
    local xlabels `xlabels' `=yq(`i', 1)'
}

twoway (line share_corporate quarter_date, lwidth(medium) lcolor(red)) ///
       (line share_financial_institutions quarter_date, lwidth(medium) lcolor(blue)) ///        
       (line share_individuals quarter_date, lwidth(medium) lcolor(purple)) ///
	   (line share_government quarter_date, lwidth(medium) lcolor(ltblue)), ///
       legend(label(1 "Corporate") ///  
			  label(2 "Financial Institutions ") ///
			  label(3 "Individuals") ///
			  label(4 "Government") ///			  
			  cols(2) ring(1) position(6) size(small) ///
       region(lstyle(none) fcolor(white) margin(small)) /// Further increase bottom margin for the legend
	   ) /// 
       xline(`=yq(2015, 1)', lcolor(black) lpattern(dash)) /// Add vertical line
       text(0.58 `=yq(2015, 1)' "Category Change", place(w) size(small)) /// Add annotation for the change
       title("Share of each Category in Non-Resident Deposits in UAE Banks", size(medium)) ///
       xtitle("Year (end of year)", size(small)) ///
	    xsize(12) ysize(6) ///  /* Extend the x-axis size */
		    xlabel(`xlabels', format(%tqCCYY) angle(45) labsize(small)) ///  /* Display all years on x-axis */
       ytitle("Share of each catefory", size(small)) ///
       graphregion(fcolor(white) margin(5 5 5 0))  // Increase bottom margin of the graph
	
graph export "$fig/evolution_share_categories.png", as(png) replace	
*/
	
	
	
	

*###############################################################################*
* Create a dataset with only yearly data. Year= value o Q4 (december)
*###############################################################################*	
use "$temp/bank_deposits_in_uae_filtered_usd_categoriescleaned_quarters_share.dta", clear


drop if month !=12
keep year non_residents total_deposits corporate financial_institutions individuals government share_corporate share_financial_institutions share_individuals share_government


gen unity="millions of USD"
export excel "$raw/bank_deposits_in_uae_cleaned_q4.xlsx", firstrow(variables) replace

/*
*###############################################################################*
* Create a dataset with only yearly data. Year= mean over quarters
*###############################################################################*	
use "$temp/bank_deposits_in_uae_filtered_usd_categoriescleaned_quarters_share.dta", clear


*Collapse the data to get the mean for each year
collapse (mean) non_residents total_deposits corporate financial_institutions individuals government share_corporate share_financial_institutions share_individuals share_government , by(year)

gen unity="millions of USD"

export excel "$raw/bank_deposits_in_uae_cleaned_yearly.xlsx", firstrow(variables) replace



*the evolution of deposits when we mean over quarters  

twoway ///
    (line non_residents year, lcolor(red) lwidth(medium) lpattern(solid) ///
     legend(label(1 "Non-Residents Total") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for non-resident data */
    (line corporate year, lcolor(blue) lwidth(medium) lpattern(solid) ///
     legend(label(2 "Corporate") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for corporate data */
    (line financial_institutions year, lcolor(green) lwidth(medium) lpattern(solid) ///
     legend(label(3 "Financial Institutions") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for financial institutions data */
    (line individuals year, lcolor(purple) lwidth(medium) lpattern(solid) ///
     legend(label(4 "Individuals") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) ///  /* Line for individuals data */
    (line government year, lcolor(ltblue) lwidth(medium) lpattern(solid) ///
     legend(label(5 "Government") ring(0) pos(11) size(small) region(lstyle(none) fcolor(white) margin(small)))) , ///  
    title("Deposits by Non-Residents in UAE Banks") ///    xtitle("Time (Year-Quarter)", size(small)) ///
    ytitle("Deposits (Means over the quarters, in Millions USD)", size(small)) ///
	xtitle("Year ", size(small)) ///
    ylabel(, labsize(medium)) ///
    graphregion(fcolor(white) margin(5 5 5 0)) ///
    xsize(12) ysize(6) ///  /* Extend the x-axis size */
    legend(col(1) order(1 2 3 4 5 ) size(small)) ///  /* Ensure the correct order in the legend */
    note("Source: Central Bank of UAE, Bilateral exchange rate from BIS", size(vsmall) ring(1) pos(7) color(black) fcolor(white) lstyle(none))
	
graph export "$fig/non_resident_deposits_imputed_categories_means.png", as(png) replace	


*the evolution of the shares of individuals and companies  
twoway (line share_corporate year, lwidth(medium) lcolor(red)) ///
       (line share_financial_institutions year, lwidth(medium) lcolor(blue)) ///        
       (line share_individuals year, lwidth(medium) lcolor(purple)) ///
	   (line share_government year, lwidth(medium) lcolor(ltblue)), ///
       legend(label(1 "Corporate") ///  
			  label(2 "Financial Institutions ") ///
			  label(3 "Individuals") ///
			  label(4 "Government") ///			  
			  cols(2) ring(1) position(6) size(small) ///
       region(lstyle(none) fcolor(white) margin(small)) /// Further increase bottom margin for the legend
	   ) /// 
       xline(2015, lcolor(black) lpattern(dash)) /// Add vertical line
       text(0.58 2015 "Category Change", place(w) size(small)) /// Add annotation for the change
       title("Share of each Category in Non-Resident Deposits in UAE Banks", size(medium)) ///
       xtitle("Year", size(small)) ///
	    xsize(12) ysize(6) ///  /* Extend the x-axis size */
       ytitle("Share of each Category (Mean over the quarters)", size(small)) ///
       graphregion(fcolor(white) margin(5 5 5 0))  // Increase bottom margin of the graph
	
graph export "$fig/uae_cbuae/evolution_means_share_categories.png", as(png) replace	
*/



	
	
	