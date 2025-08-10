
//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: confidential dataset "bilateral BIS data provided by AJZ"
//
// databases used: - $root/BISdepositsAll.dta",
//
// outputs:        - "$root/Output/bisbilat.dta"
//				   - "$raw\dta\AJZ_bisshares0607.dta"
//
//----------------------------------------------------------------------------//


****************************************************************************************************************************************************************
*
* LOAD BIS BILATERAL DEPOSITS DATA
*
****************************************************************************************************************************************************************
clear
* Bring 2006-2007 non-bank and bank deposit data
  use "$root/BISdepositsAll.dta", clear
  replace saver="AG" if saver=="1W" // 1W= British Overseas Territories (small islands like Antigua) and 1Z=West Indies UK (= BVI)
  replace saver="VG" if saver=="1Z"
  drop if saver=="G1" // UK including islands 
  drop if saver=="DD"|saver=="YU"|saver=="SU" //countries that have disappeared, 0 deposits 
  drop if saver=="C9" // Czecoslovakia 

* Take 2006-2007 average
* keep if year== 2007
  collapse (mean) dep OFC, by(bank saver)
  save "$root/Output/bisbilat.dta", replace

* Add Cyprus (started reporting in 2008; assumes follows EU haven evolution backwards)
* Assumes Russia = 90%, Greece = 10% 
  clear
  set obs 2
  gen bank = "CY"
  gen saver = "RU" 
  replace saver = "GR" if _n == 2
  gen dep = 0.9 * 27000
  replace dep = 0.1 * 27000 if _n == 2
  gen OFC = 0
  append using "$root/Output/bisbilat.dta"
  save "$root/Output/bisbilat.dta", replace
  
* Add Saint Barth to France
  reshape wide dep OFC, i(bank) j(saver) string
  foreach deposit in dep {
	replace `deposit'BL=0 if `deposit'BL==.
	replace `deposit'FR=`deposit'FR+`deposit'BL
	drop `deposit'BL
  }
  reshape long dep OFC, i(bank) j(saver) string
  drop if OFC==.

* Transform 1N haven aggregate (Bahamas, Bahrain, Bermuda, Cayman, Guernsey, HK, Isle of Man, Jersey, Macao, Neth Antilles, Panama, Singapore) into Asian tax haven aggregate
  reshape wide dep, i(saver) j(bank) string
  *not individually included BS BH BM HK AN SG
  br saver dep1N depKY depGG depIM depJE depMO depPA
  foreach deposit in dep {
	foreach bank in CH KY GG IM JE PA LU CL MO MY BE AT US GB 1N 5A CY  {
	replace `deposit'`bank'= 0 if `deposit'`bank' == .
	}
  }
  gen depAS = dep1N + depMY - depKY - depGG - depIM - depJE - depPA 
	label variable depAS "Deposit in Asian haven: HK, Singapore, Macao, Malaysia, Bahrain, Bahamas, Bermuda, Nethd Antilles" 


  keep saver depAS depKY depPA
  foreach bank in "AS" "KY" "PA"{
	egen all`bank' = total(dep`bank')
	gen share_`bank'_ajz = dep`bank'/all`bank'
	drop all dep`bank'
	}
	rename * *0607
	rename saver* saver
  save "$raw\dta\AJZ_bisshares0607.dta", replace
	
