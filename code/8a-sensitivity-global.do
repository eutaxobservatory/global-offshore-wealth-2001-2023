//----------------------------------------------------------------------------//
//Project: Global Offshore Wealth, 2001-2023
//
//Purpose: Sensitivity analysis for global offshore wealth estimates
// runs relevant do-files with different assumptions
//
//----------------------------------------------------------------------------//

use "$work/ofw_aggregate.dta", clear
rename ofw ofw_baseline
save "$work/ofw_aggregate_baseline.dta", replace


// Cayman Islands

global KYfile lowerbound
do "$do/02-bilateral-portfolio-assets-matrices/2a_do_full_matrices.do"
do "$do/07-offshore-wealth-analysis/7c-build-global.do"
keep year ofw
rename ofw ofw_KYlb
merge 1:1 year using "$work/ofw_aggregate_baseline.dta", nogen
save "$work/sensitivity_global.dta", replace

global KYfile upperbound
do "$do/02-bilateral-portfolio-assets-matrices/2a_do_full_matrices.do"
do "$do/07-offshore-wealth-analysis/7c-build-global.do"
keep year ofw
rename ofw ofw_KYub
merge 1:1 year using "$work/sensitivity_global.dta", nogen
save "$work/sensitivity_global.dta", replace


// Missing UK assets

global KYfile baseline
global UKfile lowerbound
do "$do/02-bilateral-portfolio-assets-matrices/2a_do_full_matrices.do"
do "$do/07-offshore-wealth-analysis/7c-build-global.do"
keep year ofw
rename ofw ofw_UKlb
merge 1:1 year using "$work/sensitivity_global.dta", nogen
save "$work/sensitivity_global.dta", replace


global UKfile upperbound
do "$do/02-bilateral-portfolio-assets-matrices/2a_do_full_matrices.do"
do "$do/07-offshore-wealth-analysis/7c-build-global.do"
keep year ofw
rename ofw ofw_UKub
merge 1:1 year using "$work/sensitivity_global.dta", nogen
save "$work/sensitivity_global.dta", replace


// Alternative deposit ratio (OECD)

use "$work/ofw_aggregate_baseline.dta", replace
keep year ofw_baseline deposits
gen portfolio = ofw - deposits
gen dep_share_orig = deposits / ofw
merge 1:1 year using "$temp/dep_share.dta", nogen
gen deposits2 = portfolio * dep_share / (1 - dep_share)
gen ofw_dep2 = portfolio + deposits2

/*alternative: let deposits grow at the same rate as deposits estimated based on dep_ratio
gen deposits3 = deposits if year == 2013
sort year
foreach y in 2012 2011 2010 2009 2008 2007 2006 2005 2004 2003 2002 2001{
replace deposits3 = deposits3[_n+1] * deposits2 / deposits2[_n+1] if year == `y'
}
replace deposits3 = deposits[_n-1] * deposits2 / deposits2[_n-1] if year > 2013
gen ofw_dep3 = portfolio + deposits3
merge 1:1 year using "$work/sensitivity_global.dta", nogen
save "$work/sensitivity_global.dta", replace
*/

* alternative: Deposit share of U.S. top 10% (FRED)
gen deposits3 = portfolio * dep_share_top10 / (1 - dep_share_top10)
gen ofw_dep3 = portfolio + deposits3
keep year ofw_dep2 ofw_dep3
merge 1:1 year using "$work/sensitivity_global.dta", nogen
save "$work/sensitivity_global.dta", replace


// restore baseline version
global KYfile baseline
global UKfile baseline
use "$work/ofw_aggregate_baseline.dta", clear
rename ofw_baseline ofw 
save "$work/ofw_aggregate.dta", replace


// Add potentially recorded intra-euro area offshore wealth
*extract xrate
import excel "$raw\IMF_20241230_Exchange_Rates_incl_USD_eop.xlsx", clear // 2001-2023
foreach v of varlist E-AB {
    rename `v' v_`=`v'[7]'
}
drop in 1/7
reshape long v_, i(B) j(year) string
rename (v_ B) (xrate country)
keep country year xrate
replace xrate = "." if xrate == "..."
destring year xrate, replace ignore(-)

keep if country == "Euro Area"
keep year xrate
rename xrate xrate_eur
gen tph = 400 if year == 2014 // third-party holdings of Euro Area custodians now correctly attributed to Euro Area investors
replace tph= tph / xrate_eur
sum tph
local mean_tph = r(mean)
display `mean_tph'
*485.46

keep if year > 2000
merge 1:1 year using "$work/ofw_aggregate.dta", nogen

gen portfolio = ofw - deposits
gen depshare = deposits / ofw

* Compute TPH share of OFW in 2014
gen tph_share = tph / ofw if year == 2014

* Carry 2014 share to all years
egen tph_share_2014 = max(tph_share)

* Impute TPH for all years
gen tph_new = tph_share_2014 * ofw

* Add TPH to portfolio assets
gen portfolio_new = portfolio 
replace portfolio_new = portfolio + tph_new if year > 2012

* Recompute total offshore wealth holding deposit share constant
gen ofw_tph_ea = portfolio_new / (1 - depshare)
replace ofw_tph_ea = ofw_tph_ea / worldgdp
keep year ofw_tph_ea 
merge 1:1 year using "$work/sensitivity_global.dta", nogen
save "$work/sensitivity_global.dta", replace


//----------------------------------------------------------------------------//