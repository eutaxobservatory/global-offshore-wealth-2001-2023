//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: build a dataset of total offshore wealth in switzerland
//
// databases used:- "$raw/snb_mona.xlsx"
//				  - "$raw/snb_2e.xlsx"
//				  - "$raw/snb_d4_1a.xlsx"
//				  - "$raw/snb_fx"
//				  - "$raw/snb_d5_1a_m33"
//
// outputs:       - "$work/offshore_wealth_in_switzerland_yearly.dta"                
//----------------------------------------------------------------------------//


********************************************************************************
* compute swiss fiduciary deposits 
********************************************************************************
*https://data.snb.ch/fr/warehouse/BSTA/cube/BSTA@SNB.MONA_B.ABI.TRE.PAS?fromDate=2001-01&toDate=2023-01&dimSel=INLANDAUSLAND(T),WAEHRUNG(T,CHF,EM,EUR,JPY,USD,U)

	
import excel "$raw/snb/snb_mona.xlsx", clear
keep A B
drop in 1/24

describe

gen year=substr(A,1,4)
gen month=substr(A,6,7)
destring year, replace
destring month, replace


*keep december values
*keep if month==12

rename B swiss_fidu_chf
drop A
destring swiss_fidu_chf, replace

save "$temp/snb_mona.dta", replace


* snb_2e 
*https://data.snb.ch/fr/topics/banken/cube/batreuhbm?fromDate=2001-01&toDate=2023-01&dimSel=INLANDAUSLAND(I),WAEHRUNG(T,CHF,EUR,USD)
import excel "$raw/snb/snb_2e.xlsx", clear
keep A F
drop in 1/26
gen year=substr(A,1,4)
gen month=substr(A,6,7)
destring year, replace
destring month, replace
*keep if month==12	
rename F snb_2e
destring snb_2e, replace	
drop A	
save "$temp/snb_2e.dta", replace
	
*snb_d4_1a
*https://data.snb.ch/fr/topics/banken/cube/batreuhbm?fromDate=2001-01&toDate=2023-01&dimSel=D0(PAS),INLANDAUSLAND(A),WAEHRUNG(T,CHF,EUR,USD)
	
	import excel "$raw/snb/snb_d4_1a.xlsx", clear
keep A B
drop in 1/26
gen year = substr(A,1,4)
gen month = substr(A,6,7)
destring year, replace
destring month, replace
*keep if month==12	
rename B snb_d4_1a
destring snb_d4_1a, replace	
drop A	
save "$temp/snb_d4_1a.dta", replace
	
	
	
* exchange rate dataset 
	* https://data.snb.ch/fr/topics/ziredev/cube/devkum?fromDate=2001-01&toDate=2023-01
import excel "$raw/snb/snb_fx", clear 
keep A L
drop in 1/21

gen year=substr(A,1,4)
gen month=substr(A,6,7)
destring year, replace
destring month, replace

*keep december values
*keep if month==12

rename L chf_usd
destring chf_usd, replace
drop A


save "$temp/snb_fx.dta", replace


* merge both datasets
use "$temp/snb_mona.dta", clear

merge 1:1  year month using "$temp/snb_fx.dta"

drop _merge 


merge 1:1  year month using "$temp/snb_2e.dta"

drop _merge 


merge 1:1  year month using "$temp/snb_d4_1a.dta"

drop _merge 

gen swiss_fidu = .

replace swiss_fidu= (snb_d4_1a/1000 + snb_2e/1000)/chf_usd if year<=2014 & !(year==2014 & inlist(month,07,08,09,10,11,12)) // (SNB_D4_1a!I192/1000+SNB_2E!H193/1000)/SNB_FX!L60  until june 2013 

replace swiss_fidu = (swiss_fidu_chf/1000000)/chf_usd if year>2014 // (SNB.MONA!B127/1000)/SNB_FX!L312 if year >2014 june

replace swiss_fidu = (swiss_fidu_chf/1000000)/chf_usd if (year==2014 & inlist(month,07,08,09,10,11,12))

keep year month swiss_fidu
save "$temp/swiss_fidu.dta", replace



********************************************************************************
* compute foreign securities belonging to foreigners in switzerland 
********************************************************************************

* foreign securities dataset: 
	* https://data.snb.ch/fr/topics/banken/cube/bawebewa?fromDate=2001-02&toDate=2023-01&dimSel=D0(AD),D2(EA)
	
import excel "$raw/snb/snb_d5_1a_m33", clear 
keep A B
drop in 1/37

gen year=substr(A,1,4)
gen month=substr(A,6,7)
destring year, replace
destring month, replace

*keep december values
*keep if month==12

rename B foreign_securities_chf
destring foreign_securities_chf, replace
drop A


save "$temp/snb_d5_1a_m33.dta", replace


* merge with foreign exchange dataset 
	
use 	"$temp/snb_d5_1a_m33.dta",  clear
	
merge 1:1  year month using "$temp/snb_fx.dta"

drop _merge 

gen foreign_securities_foreigners = .
replace foreign_securities_foreigners = (foreign_securities_chf / 0.968)/chf_usd/(1-0.06) if year<=2012 & !(year==2012 & month==12) //until nov 2012 
replace foreign_securities_foreigners = (foreign_securities_chf / 0.968)/chf_usd if year>2012 // starting in dec 2012 

replace foreign_securities_foreigners = (foreign_securities_chf / 0.968)/chf_usd  if (year==2012 & month==12)

keep year month foreign_securities_foreigners
save "$temp/swiss_foreign_securities_foreigners.dta", replace


********************************************************************************
* completing securities dataset  
********************************************************************************

use "$temp/swiss_foreign_securities_foreigners.dta",clear

gen swiss_securities_foreigners=.
gen swiss_foreign_sec_wrongswiss=. 

* given values 
replace swiss_securities_foreigners=77 if year==2011 & month==12 //december 2011 is given 
replace swiss_foreign_sec_wrongswiss=100 if year==2013 & month==05 //mai 2013 is given 


* complete with the same growth rate as foreign_securities_foreigners
	* after the given value
replace swiss_securities_foreigners=swiss_securities_foreigners[_n-1]*foreign_securities_foreigners[_n]/foreign_securities_foreigners[_n-1] if year>2011 & !(year==2011 & month==12)
	* before the given value
gen target_id=(_n) if (year==2011 & month==12)
quietly sum target_id
local target= r(max)
display `target'

forvalues i=1/`target'{
replace swiss_securities_foreigners=swiss_securities_foreigners[_n+1]*foreign_securities_foreigners[_n]/foreign_securities_foreigners[_n+1] if year<=2011 & !(year==2011 & month==12)
}

* complete the same way but for swiss_foreign_sec_wrongswiss
	* after the given value
replace swiss_foreign_sec_wrongswiss=swiss_foreign_sec_wrongswiss[_n-1]*foreign_securities_foreigners[_n]/foreign_securities_foreigners[_n-1]	if year >=2013 & !(year==2013 & inlist(month,01,02,03,04,05))
	
capture drop target_id 
gen target_id=_n if year==2013 & month==05
quietly sum target_id 
local target_id=r(max)

forvalues i=1/`target_id'{
	replace swiss_foreign_sec_wrongswiss=swiss_foreign_sec_wrongswiss[_n+1]*foreign_securities_foreigners[_n]/foreign_securities_foreigners[_n+1] if year <= 2013 & !(year==2013 & inlist(month,05,06,07,08,09,10,11,12))
	
}	
drop target_id	
	
save "$temp/swiss_securities_cleaned.dta", replace	
	
	
	
	
********************************************************************************
* merging securities and fiduciary datasets 
********************************************************************************
	
use "$temp/swiss_securities_cleaned.dta", clear
merge 1:1 year month using "$temp/swiss_fidu.dta"
drop _merge 	

* compute total offshore wealth	
generate total_offshore_wealth=  foreign_securities_foreigners + ///
								swiss_securities_foreigners + ///
								swiss_foreign_sec_wrongswiss + ///
								swiss_fidu
	
order year month total_offshore_wealth foreign_securities_foreigners swiss_securities_foreigners swiss_foreign_sec_wrongswiss swiss_fidu
	
label var total_offshore_wealth "Total offshore wealth in Switzerland"
label var foreign_securities_foreigners "Foreign securities belonging to foreigners"
label var swiss_securities_foreigners "Swiss securities belonging to foreigners"
label var swiss_foreign_sec_wrongswiss "Foreign securities wrongly attributed to Switzerland"
label var swiss_fidu "Fiduciary deposits"

notes: "The unity is bn current US$"
notes: "Formulas and datasets were used as in sheet T.A7 of AJZ2017DataUpdated.xlsx"
	
save "$work/offshore_wealth_in_switzerland_monthly.dta", replace	

keep if month == 12
save "$work/offshore_wealth_in_switzerland_yearly.dta", replace	
	

//----------------------------------------------------------------------------//

	
	