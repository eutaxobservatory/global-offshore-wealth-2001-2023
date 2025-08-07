//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: construct bilateral non-bank deposits spanning 2001 to 2023
//
// databases used: - "$raw/assumptions/ofc_and_dep_assumptions.xlsx", sheet(ofc_list)
//                 - "$raw/assumptions/ofc_and_dep_assumptions.xlsx", sheet(sharehouseholddep) 
//                 - "$work/locational.dta"
//                 - "$raw/dta/bis_AN.dta"
//                 - "$raw/dta/AJZ_bisshares0607.dta"
//                 - "$work/bank_deposits_in_uae_allocated.dta"
//                 - "$raw/assumptions/ofc_and_dep_assumptions.xlsx"
//                 - "$raw/bank_deposits_in_uae_cleaned_q4.xlsx", sheet(data) 
//
// outputs:        - "$work/havens_list.dta"
//                 - "$work/bis-deposits-all-01-23.dta"
//                 - "$work/bisdepbyhaven_hh.dta"
//                 - "$work/distributions_1R.dta"
//                 - "$work/distributions_1R_adjust_ATCA.dta"
//                 - "$work/distributions_1R_adjust_ES.dta"
//                 - "$work/distributions_1R_adjust_MO.dta"
//                 - "$work/distributions_1R_adjust_HKIT.dta"
//                 - "$work/distributions_1R_china.dta"
//----------------------------------------------------------------------------//


*###############################################################################*
* TAX HAVEN LIST 
*###############################################################################*
import excel "$raw/assumptions/ofc_and_dep_assumptions.xlsx", sheet(ofc_list) firstrow cellrange(A2:H72) clear

* drop empty rows 
egen miss = rowmiss(*)
drop if miss>=9
drop miss
rename countryname name_excel
isocodes iso3, gen(cntryname)
rename cntryname cntryname_isocodes
rename name_excel cntryname_excel
rename iso2 iso2c 
rename iso3 iso3c
order iso2c iso3c  cntryname_excel ofc_reporter ofc_pure_haven ofc_hybrid_haven ofc_conduit shell_share  cntryname_isocodes

describe
foreach var of varlist ofc_reporter ofc_pure_haven ofc_hybrid_haven ofc_conduit shell_share{
	destring `var', replace
}

save "$work/havens_list.dta", replace


********************************************************************************
**** I - Creating BIS vis-a-vis non-bank counterparties only, 2001-2023 --*****
********************************************************************************

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
	
* mean amount unstanding over quarters 		// memo: bank 5A "All BIS-reporting banks"; saver 5J "All"
collapse (mean) dep, by(bank year saver)

* drop BIS aggregates
drop if ///
saver == "5R" | saver == "4W" | saver == "4Y" | saver == "3C" | ///
saver == "4U" | saver == "4T" | saver == "2D" | saver == "2C" | ///
saver == "2T" | saver == "2S" | saver == "5M" | saver == "2T" | ///
saver == "2R" | saver == "5C" | saver == "2R" | saver == "5K" | ///
saver == "4L" | saver == "2B" | saver == "2H" | saver == "2O" | ///
saver == "2W" | saver == "2N" | saver == "1C" | saver == "2U" | ///
saver == "2Z" | saver == "C9"


* We add French Southern Territories to France,
* Greenland to Denmark, Montserrat and Anguilla to British West Indies (for consistency with SNB where BVI, Anguilla and Montserrat are lumped together )
reshape wide dep, i(year bank) j(saver) string
egen depFRX = rowtotal(depFR depTF), missing
replace depFR = depFRX 
drop depFRX depTF
egen dep1ZX = rowtotal(depAI depVG depMS), missing
replace depVG = dep1ZX 
drop dep1ZX depAI depMS
egen depDKX = rowtotal(depGL depDK), missing
replace depDK = depDKX
drop depDKX depGL 
reshape long dep, i(year bank) j(saver) string

// Note that bank == "AN" has disappeared

* Create 1R residual countries (all reporting - countries with bilateral data)
reshape wide dep, i(year saver) j(bank) string 
egen negative1R = rowtotal(depAU depBE depBR depCH depCL ///
depDK depFI depFR depGB depGG depGR depIE depIM ///						// removed: DE does not report bilaterally!
depJE depJP depKR depLU depMX depNL depPH depSE depTW depUS depZA), missing			// do not subtract AT CA ES HK IT and MO, yet, because we do not know their distributions for certain periods. If we subtract them here, we create a break in the distribution of 1R
gen dep1R = dep5A - negative1R
br if dep1R<0

// Imputation Netherlands
// Some bilateral deposits in NL are missing: US deposits in the NL are missing between 2017 and 2022, French deposits in the Netherlands are missing in 2022 -> This might be problematic because they seem to be included in 5A
gen dum = 1
by saver, sort: egen help=total(dum) if depNL!=.
by saver, sort: egen obs_NL = mean(help)
*close small gaps in the series by linear interpolation to avoid meaningless spikes: 
by saver, sort: ipolate depNL year if obs_NL > 17 & obs_NL !=., gen(help_NL)

sort saver year
replace help_NL = . if depNL != .
*clean 1R from the missing bilateral NL deposits in the respective years
gen dep1R_adj = dep1R 
replace dep1R_adj = dep1R_adj - help_NL if help_NL!=.


sort saver year
replace dep1R = dep1R_adj
br if dep1R <0
replace dep1R = 0 if dep1R < 0
drop dep1R_adj
drop dum help *_NL


********************************************************************************
**** Solving 1R distribution discontinuities
********************************************************************************
/*Problem: we have several breaks in the 1R distribution that we might want to correct:
Countries that report aggregate deposits but not bilaterally:
AT 2001-2006
CA 2001-2006
ES 2001-2011
MO 2003-2012
HK 2001-2013 
IT 2001-2013
*/

// Model bilateral deposits of jurisdiction that report only partly bilaterally and subtract them from 1R.

	* Country distribution on the global residual 1R
		gen share1R = 1 if saver == "5J"
		forvalues y = 2001/2023 {
			sum(dep1R) if saver == "5J" & year == `y'
			local dep_sum1R`y' = r(sum)
			replace share1R = dep1R/`dep_sum1R`y'' if year == `y'
		}
		
			* save 1R distributions to document how the following adjustments affect the distribution of Asian havens' deposits
		preserve
			keep saver year dep1R share1R
			save "$work/distributions_1R.dta", replace
		restore
		
	* Austria and Canada
		sort saver year
		gen growth = share1R / share1R[_n-1] if saver==saver[_n-1]


		foreach iso in "AT" "CA"{
			gen help = dep`iso' if saver == "5J"
			by year, sort: egen dep`iso'_world = mean(help)
			drop help
			gen share`iso' = dep`iso' / dep`iso'_world
			gen dep`iso'_est = dep`iso' if year > 2006
		
			* Let bilateral deposits in missing years grow backwards at the same rate as global residual deposits

				sort saver year
				gen share`iso'_est = share`iso' if year > 2006
				foreach year in "2006" "2005" "2004" "2003" "2002" "2001" {
					replace share`iso'_est = share`iso'_est[_n+1] / growth[_n+1] if year == `year' & saver != "5J"
				}
			
						
			replace dep`iso'_est = share`iso'_est * dep`iso'_world if saver != "5J" & year < 2007
		}

	
		replace depAT = depAT_est if year < 2007 & saver != "5J"
		replace depCA = depCA_est if year < 2007 & saver != "5J"

		drop dep*_est dep*_world share* share*_est growth

		* Iteratively clean 1R from estimated bilateral distributions
		replace dep1R = dep1R - depAT if depAT != .
		replace dep1R = dep1R - depCA if depCA != .
		replace dep1R = 0 if dep1R < 0

		* Adjusted 1R distribution
		gen share1R = 1 if saver == "5J"
		forvalues y = 2001/2023 {
			sum(dep1R) if saver == "5J" & year == `y'
			local dep_sum1R`y' = r(sum)
			replace share1R = dep1R/`dep_sum1R`y'' if year == `y'
		}
	
		preserve
			keep saver year share1R
			rename share1R share1R_adjATCA
			save "$work/distributions_1R_adjust_ATCA.dta", replace
		restore
		

	* Spain 2001-2011
		sort saver year
		gen growth = share1R / share1R[_n-1] if saver==saver[_n-1]


		foreach iso in "ES"{
			gen help = dep`iso' if saver == "5J"
			by year, sort: egen dep`iso'_world = mean(help)
			drop help
			gen share`iso' = dep`iso' / dep`iso'_world
			gen dep`iso'_est = dep`iso' if year > 2011
		
			* Let bilateral deposits in missing years grow backwards at the same rate as global residual deposits

				sort saver year
				gen share`iso'_est = share`iso' if year > 2011
				foreach year in "2011" "2010" "2009" "2008" "2007" "2006" "2005" "2004" "2003" "2002" "2001"{
					replace share`iso'_est = share`iso'_est[_n+1] / growth[_n+1] if year == `year' & saver != "5J"
				}
			
						
			replace dep`iso'_est = share`iso'_est * dep`iso'_world if saver != "5J" & year < 2012
		}

					
		replace depES = depES_est if year < 2012 & saver != "5J"
		drop dep*_est dep*_world share* share*_est growth

		* iteratively clean 1R from estimated and orginial bilateral distributions
		replace dep1R = dep1R - depES if depES != .
		replace dep1R = 0 if dep1R < 0
		
		* Adjusted 1R distribution
		gen share1R = 1 if saver == "5J"
		forvalues y = 2001/2023 {
			sum(dep1R) if saver == "5J" & year == `y'
			local dep_sum1R`y' = r(sum)
			replace share1R = dep1R/`dep_sum1R`y'' if year == `y'
		}

		preserve
			keep saver year share1R
			rename share1R share1R_adjES
			save "$work/distributions_1R_adjust_ES.dta", replace
		restore


	* Macao
		sort saver year
		gen growth = share1R / share1R[_n-1] if saver==saver[_n-1]


		foreach iso in "MO"{
			gen help = dep`iso' if saver == "5J"
			by year, sort: egen dep`iso'_world = mean(help)
			drop help
			gen share`iso' = dep`iso' / dep`iso'_world
			gen dep`iso'_est = dep`iso' if year > 2012
		
			* Let bilateral deposits in missing years grow backwards at the same rate as global residual deposits

				sort saver year
				gen share`iso'_est = share`iso' if year > 2012
				foreach year in "2012" "2011" "2010" "2009" "2008" "2007" "2006" "2005" "2004" "2003" "2002" "2001"{
					replace share`iso'_est = share`iso'_est[_n+1] / growth[_n+1] if year == `year' & saver != "5J"
				}
			
						
			replace dep`iso'_est = share`iso'_est * dep`iso'_world if saver != "5J" & year < 2013
		}


			
		replace depMO = depMO_est if year < 2013

		drop dep*_est dep*_world share* share*_est growth

		* iteratively clean 1R from estimated and original bilateral distributions
		replace dep1R = dep1R -depMO if depMO != .
		replace dep1R = 0 if dep1R < 0

		* Adjusted 1R distribution
		gen share1R = 1 if saver == "5J"
		forvalues y = 2001/2023 {
			sum(dep1R) if saver == "5J" & year == `y'
			local dep_sum1R`y' = r(sum)
			replace share1R = dep1R/`dep_sum1R`y'' if year == `y'
		}
		
		preserve
			keep saver year share1R
			rename share1R share1R_adjMO
			save "$work/distributions_1R_adjust_MO.dta", replace
		restore		
		
		
	* Italy, Hong Kong 2001-2013
		sort saver year
		gen growth = share1R / share1R[_n-1] if saver==saver[_n-1]


		foreach iso in "HK" "IT"{
			gen help = dep`iso' if saver == "5J"
			by year, sort: egen dep`iso'_world = mean(help)
			drop help
			gen share`iso' = dep`iso' / dep`iso'_world
			gen dep`iso'_est = dep`iso' if year > 2013
		
			* Let bilateral deposits in missing years grow backwards at the same rate as global residual deposits

				sort saver year
				gen share`iso'_est = share`iso' if year > 2013
				foreach year in "2013" "2012" "2011" "2010" "2009" "2008" "2007" "2006" "2005" "2004" "2003" "2002" "2001"{
					replace share`iso'_est = share`iso'_est[_n+1] / growth[_n+1] if year == `year' & saver != "5J"
				}
			
						
			replace dep`iso'_est = share`iso'_est * dep`iso'_world if saver != "5J" & year < 2014
		}

					
		replace depHK = depHK_est if year < 2014
		replace depIT = depIT_est if year < 2014
		drop dep*_est dep*_world share* share*_est growth


		* iteratively clean 1R from estimated and orginial bilateral distributions
		replace dep1R = dep1R - depIT if depIT != .
		replace dep1R = dep1R - depHK if depHK != .
		replace dep1R = 0 if dep1R < 0




	// check result of cleaning of 1R	
	sort saver year
	gen share1R = 1 if saver == "5J"
	forvalues y = 2001/2023{
		sum(dep1R) if saver == "5J" & year == `y'
		local dep_sum1R`y' = r(sum)
		replace share1R = dep1R / `dep_sum1R`y'' if year == `y'
	}

		preserve
		keep year saver dep1R share1R
		rename *1R *1R_adjHKIT
		save "$work/distributions_1R_adjust_HKIT.dta", replace
		restore

		*Clean 1R distribution from the jump caused by China joining only in 2016. Esp. in AE, US, HK, LU
gen china_effect = depCN / dep1R if saver == "5J"  // China adds 30% - 42% of deposits to the global total -> contamination of individual countries' share of the global residual may be substantial!


	// Freeze 2016 share in 1R at 2015 levels and let grow as in 1R afterwards.
	sort saver year
	gen growth = share1R / share1R[_n-1] if saver == saver[_n-1]
	gen share1R_adj = share1R[_n-1] if year == 2016
	replace share1R_adj = share1R_adj[_n-1] * growth if year > 2016

	gen help = dep1R if saver == "5J" 
	by year, sort: egen dep1R_world = mean(help)
	drop help
	gen dep1R_adj = dep1R if year < 2016
	replace dep1R_adj = share1R_adj * dep1R_world if year > 2015


	sort saver year
	replace share1R_adj = share1R if year == 2015
	replace dep1R = dep1R_adj 	

	preserve
		replace share1R_adj = share1R if year < 2015
		keep year saver dep1R_adj share1R_adj
		rename *1R_adj *1R_china
		save "$work/distributions_1R_china.dta", replace
	restore
	
	drop dep1R_adj share* growth china_effect



* We still lack a distribution for the aggregate of "Asian" havens (comprising all not bilaterally reporting havens)
* Compute shares in the residual aggregate // share: "share of each wealth-owning jurisdiction in total residual" //share of each saver country in total deposits held in jurisdictions which do not report bilaterally // share of deposits of each saver country in total deposits that cannot be bilaterally allocated

	gen share = 1 if saver == "5J"
	forvalues y = 2001/2023 {
		sum(dep1R) if saver ~= "5J" & year == `y'
		local dep_sum1R`y' = r(sum)
		replace share = dep1R/`dep_sum1R`y'' if year == `y'
	}



*Shares seen in the residual to allocate amount of havens without bilateral data // Netherlands Antilles, Panama, Malaysia, Bahrain, Bermuda, Bahamas, Curacao, Singapore 
	forvalues i=2001/2023 {
		foreach ctry in AN PA MY BH BM BS CW SG {
			preserve
				keep dep`ctry' year saver
				keep if year == `i' & saver == "5J"
				local Alldep`ctry'`i' = dep`ctry'
			restore 
		}
	}


// fill in missing bilateral liabilities of financial centers, e.g. replace Panama's missing bilateral deposits by an amount of deposits estimated under the assumption that each country holds the same share in Panama's deposits (liabilities) as it holds in global not bilaterally allocated deposits
	forvalues i=2001/2023 {
		foreach ctry in AN PA MY BH BM BS CW SG {
			replace dep`ctry' =  `Alldep`ctry'`i''*share ///
			if year == `i' & saver ~= "5J"
		}
	}



reshape long dep, i(year saver) j(bank) string
order year bank saver dep
sort bank saver year 
drop share



* Add Cayman Islands, assumes same country distribution of KY deposits as in AJZ
	merge m:1 saver using "$raw/dta/AJZ_bisshares0607.dta"
	drop if _merge == 2 
	drop _merge


	forvalues i=2001/2023 {
		preserve 
			keep if bank == "KY" & year == `i' & saver == "5J"
			local AlldepKY`i' = dep
		restore
	}

	forvalues i=2001/2023 {
		replace dep = share_KY* `AlldepKY`i'' ///
		if bank == "KY" & saver ~= "5J" & year == `i'
	}
	drop share*

* Assume Bermuda, Chile, and Panama deposits in 2001 equal those in 2002 
	foreach b in CL PA BM {
		drop if bank == "`b'" & year == 2001
		preserve 
			keep if bank == "`b'" & year == 2002
			replace year = 2001
			tempfile deposits`b'
			save "`deposits`b''", replace
		restore
		append using "`deposits`b''"
	}


********************************************************************************
**** Adding UAE deposits
********************************************************************************

// add UAE here unit of BIS and UAE is USD million
	preserve
		keep if bank == "5A"
		replace bank = "AE"
		replace dep = .
		tempfile UAE_empty
		save `UAE_empty'
	restore

	append using `UAE_empty'
	merge 1:1 bank saver year using "$work/bank_deposits_in_uae_allocated.dta", update
	// _merge == 2 Anguilla (0 deposits), French Guayana (0 deposits), Kosovo, Monaco, Puerto Rico 
	*add Puerto Rico to US because does not exist as separate jurisdiction in BIS
	drop if saver == "AI" | saver == "GF"
	replace saver = "US" if saver == "PR" & bank == "AE"
	replace saver = "RS" if saver == "XK" & bank == "AE"
	collapse (sum) dep, by(year bank saver)
	// add UAE-reported deposits to each saver country's total deposits (reported by all banks 5A)
	gen UAE = dep if bank == "AE"
	by year saver, sort: egen help = mean(UAE)
	replace dep = dep + help if bank == "5A"
	drop help UAE
	
	
********************************************************************************
**** Deposits in European havens
********************************************************************************	

* Construct missing bilateral haven deposits
	reshape wide dep, i(year saver) j(bank) string

	tempfile bis
	save `bis'
	import excel "$raw/assumptions/ofc_and_dep_assumptions.xlsx", ///
	clear firstrow cellrange(A1:W23) sheet(sharehouseholddep) // no need of UAE for the moment 
	merge 1:m year using "`bis'", nogenerate	
	
	foreach bank in GG IM JE LU AT BE GB{										// European OFCs (Cyprus' share =1, so no need to adjust )
		gen adjusted_dep`bank' = `bank'*dep`bank' 
		drop `bank'
}

		egen depEU = rowtotal(adjusted_depGG adjusted_depIM adjusted_depJE ///
		adjusted_depLU adjusted_depAT adjusted_depBE adjusted_depGB depCY), missing
		drop adjusted*																	

		* Cyprus started reporting in 2008; assumes follows EU havens backwards
		forvalues y= 2007(-1)2001 {
			local y_1 = `y' + 1
			preserve
				keep if saver == "5J" & year == `y_1'
				keep depEU 
				local EUdeposits = depEU
			restore
			preserve
				keep if saver == "5J" & year == `y_1'
				keep depCY
				local CYdeposits = depCY
			restore
			replace depCY = (`CYdeposits'*depEU)/`EUdeposits' ///
			if saver == "5J" & year == `y'
			}
		drop depEU BH BM CH CL BS CY HK KY MO MY PA SG US AN CW

		reshape long dep, i(year saver) j(bank) string

		// Allocate Cyprus; assumes Russia = 90%, Greece = 10%
		gen share_CY = 0
		replace share_CY = 0.9 if saver == "RU" & bank == "CY"
		replace share_CY = 0.1 if saver == "GR" & bank == "CY"

		forvalues i=2001/2023 {
			preserve 
				keep if bank == "CY" & year == `i' & saver == "5J"
				local AlldepCY`i' = dep
			restore
		}

		forvalues i=2001/2023 {
		replace dep = share_CY* `AlldepCY`i'' ///
		if bank == "CY" & year == `i' & saver ~= "5J"
		}
		drop share_CY


*******tempfile to merge to haven list 
tempfile tempfile_to_merge_to_haven
save `tempfile_to_merge_to_haven'

use "$work/havens_list.dta", clear 
rename iso2c saver
keep saver ofc_pure_haven ofc_reporter 
merge 1:m saver using `tempfile_to_merge_to_haven'
drop if _merge==1
drop _merge
*******

gen OFC = 0
replace OFC = 1 if ofc_pure_haven==1 
drop ofc_reporter ofc_pure_haven



* drop deposits held by household in the same country
drop if bank == saver

* labels
label var bank "Reporting country"
label var saver "Counterparty country"
label var dep "Non-bank deposits, liabilities side"
label var OFC "Offshore financial centres"

order year bank saver dep
sort bank saver year 	

********************************************************************************
**** Deposits in Asian havens 
********************************************************************************

* adjust deposits in Asian havens to match the AJZ country distribution in 2006-07
	reshape wide dep, i(year saver) j(bank) string
	egen depAS = rowtotal(depAN depBH depBM depBS depCW depHK depMO depMY depSG), missing
	label variable depAS ///
	"Deposit in Asian haven: HK, Singapore, Macao, Malaysia, Bahrain, Bahamas, Bermuda, Netherlands Antilles / Curacao" 
			
	*correct shares of each saver in AS according to AJZ here
		merge m:1 saver using "$raw/dta/AJZ_bisshares0607.dta"
		drop if _merge == 2 // BL and GL
		drop _merge
			
		replace share_AS_ajz = 0 if share_AS_ajz<0
		by year, sort: egen allAS = total(depAS) if saver != "5J"
		gen shareAS = depAS/allAS
		gen shareAS_adj = share_AS_ajz if year == 2006 | year == 2007 // adjust each country's deposits such that they match AJZ country share in 2006/07.
		sort saver year
		// Let adjusted shares in Asian deposits grow at the same rate as unadjusted
		gen growth = shareAS / shareAS[_n-1] if saver==saver[_n-1]
		replace shareAS_adj = shareAS_adj[_n-1] * growth if year > 2007 & saver==saver[_n-1]
		foreach year in "2005" "2004" "2003" "2002" "2001"{
			replace shareAS_adj = shareAS_adj[_n+1] / growth[_n+1] if year == `year'
		}
			
		gen depAS_adj = shareAS_adj * allAS
		drop growth 
		sort saver year
			
		
		replace depAS = depAS_adj if saver != "5J"
			
*correct shares of each saver in Panama according to AJZ
		replace share_PA_ajz = 0 if share_PA_ajz < 0
		by year, sort: egen allPA = total(depPA) if saver != "5J"
		gen sharePA = depPA/allPA
		gen sharePA_adj = share_PA_ajz if year == 2006 | year == 2007 // adjust each country's deposits such that they match AJZ country share in 2006/07.
		sort saver year
		// Let adjusted shares in Panama deposits grow at the same rate as unadjusted
			gen growth = sharePA / sharePA[_n-1] if saver==saver[_n-1]
			replace sharePA_adj = sharePA_adj[_n-1] * growth if year > 2007
			foreach year in "2005" "2004" "2003" "2002" "2001"{
				replace sharePA_adj = sharePA_adj[_n+1] / growth[_n+1] if year == `year'
			}
			
			gen depPA_adj = sharePA_adj * allPA
			
			drop share* all* growt* dep*_adj

reshape long dep, i(year saver) j(bank) string
save "$work/bis-deposits-all-01-23.dta", replace

********************************************************************************
********** II - COMPUTE HOUSEHOLD DEPOSITS IN EACH BIS-REPORTING OFC ----*******
********************************************************************************
use "$work/locational.dta", clear
keep if position=="L" & instrument=="A" & sector=="N" ///
/* N=non bank; P=non-bank nonfinancial */ & parent=="5J" & quarter == 4



append using "$raw/dta/bis_AN.dta"
	br bank saver year quarter if saver == "5J" & bank == "5A"
	sum dep if saver == "5J" & bank == "5A" & year == 2001 & quarter == 1
	sum dep if saver == "5J" & bank == "5A_23" & year == 2001 & quarter == 1
	drop if bank =="5A_23"
	replace dep = . if bank == "AN" & saver == "5J" & year == 2010 // Curacao already in dataset
	replace counter=saver if bank=="AN"
	replace value=dep if bank=="AN"


keep if bank == "AN" | bank == "AT" | bank == "BE" | bank == "BH" | ///
bank == "BM" | bank == "BS" | bank == "CH" | bank == "CL" | bank == "CW" | ///
bank == "CY" | bank == "KY" | bank == "GB" | bank == "GG" | bank == "IM" | ///
bank == "JE" | bank == "LU" | bank == "MO" | bank == "MY" | bank == "PA" | ///
bank == "HK" | bank == "SG" | bank == "US"
keep if counter == "5J" 
collapse (mean) value, by(bank year)
drop if year < 2001
preserve
	import excel using "$raw/bank_deposits_in_uae_cleaned_q4.xlsx", sheet(data) firstrow clear
	keep year non_residents
	rename non_residents value
	keep year value
	gen bank = "AE"
	drop if year > 2023
	tempfile uae
	save `uae'
restore
append using `uae'

preserve
	import excel using "$raw/assumptions/ofc_and_dep_assumptions.xlsx",	clear firstrow cellrange(A1:X24) sheet(sharehouseholddep)
	rename * v_*
	rename v_year year
	reshape long v_, i(year) j(bank) string
	rename v_ hhshare
	tempfile hhshare
	save `hhshare'
restore
merge 1:1 year bank using `hhshare', nogenerate
gen dep = value * hhshare
keep bank year dep
reshape wide dep, i(year) j(bank) string 
save "$work/bisdepbyhaven_hh.dta", replace

********************************************************************************
/*Document changes in the distribution of 1R

use "$work/distributions_1R.dta", clear
merge 1:1 year saver using "$work/distributions_1R_adjust_ATCA.dta", nogenerate

merge 1:1 year saver using "$work/distributions_1R_adjust_ES.dta", nogenerate
merge 1:1 year saver using "$work/distributions_1R_adjust_MO.dta", nogenerate
merge 1:1 year saver using "$work/distributions_1R_adjust_HKIT.dta", nogenerate

merge 1:1 year saver using "$work/distributions_1R_china.dta", nogenerate


* check results of adjustment 
			foreach saver in "US" "HK" "GB" "NL" "CN" "SG" "TW" "FR" "DE" "JP" "AE" "SA" "BR" "DK" {
			twoway ///
			(line share1R year) (line share1R_adjATCA year) (line share1R_adjES year) (line share1R_adjMO year) (line share1R_adjHKIT year) (line share1R_china year) ///
			if saver == "`saver'", 													///
			ylabel(, labsize(small)) xtitle(, size(zero)) xline(2007 2012 2013 2014 2016)								///
			xlabel(, angle(ninety) labsize(small)) by(, legend(size(small))) 						///
			legend(order(1 "orig" 2 "adj AT CA (2007)" 3 "adj ES (2012)" 4 "adj MO (2013)" 5 "adj HK IT (2014)" 6 "china (2016)")) by(saver) name(`saver', replace)
			}
			graph combine BR CN DE FR
			graph export "$fig\comparison\distributions\distr_1R_1.pdf", as(pdf) name("Graph") replace
			graph combine GB JP NL SA
			graph export "$fig\comparison\distributions\distr_1R_2.pdf", as(pdf) name("Graph") replace
			graph combine SG US TW
			graph export "$fig\comparison\distributions\distr_1R_3.pdf", as(pdf) name("Graph") replace
				*/
						
			