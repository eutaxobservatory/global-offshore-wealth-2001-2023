// ==============================================================================
// Paper: Global Offshore Wealth, 2001-2023
// 
// Purpose: merge swiss fiduciary and bis bank deposits; construct country 
// shares (using a 5-year smoothing method) and value of offshore wealth in 
// Switzerland and several haven groups.
//
// databases used: - "$work/bis-deposits-all-01-23"
//				   - "$raw/assumptions/ofc_and_dep_assumptions.xlsx"
//				   - "$work\assembled_gdp_series.dta"
//				   - "$work/fiduciary-87-23.dta"
//				   - "$work/fdi-havens"
//
// outputs:        - "$work/offshore"year".dta" files (files take 2001 to 2023 as "year")
//                 
//===============================================================================

********************************************************************************

**************** I ---- Load BIS locational banking stats -----*****************

********************************************************************************

**--------- I.1 - Adjustments to non-bank and bank deposit data---------------**
forvalues i = 2001/2023 { 
	
	* Read BIS data
	use "$work/bis-deposits-all-01-23", clear	
	replace saver = "IO" if saver == "1W" // 1W - British Overseas Territories "British Antarctic Territory, British Indian Ocean Territory, Chagos, Pitcairn Islands, South Georgia and South Sandwich Islands" in BIS. We park it in "IO" because both BIS and SNB created their own country codes for this island group (1W / TAA).
	
	* Countries that have disappeared, almost always 0 deposits 
	drop if saver == "DD" | saver=="YU" | saver=="SU" 
	drop if saver == "C9" 
	
	* we drop Serbia and Montenegro as a united jurisdiction from the analysis
	drop if saver == "CS"
	
	* All counterparty countries
	drop if saver == "5J"
	order bank saver year
	
	* Take year deposits
	keep if year == `i'
	collapse (mean) dep OFC year, by(bank saver)
	
	* Transform 1N haven aggregate into Asian tax haven aggregate
	reshape wide dep, i(saver) j(bank) string

		foreach bank in AE CH KY MY PA GG IM JE LU CL MO BE AT US GB 5A 1R CY {
			replace dep`bank'= 0 if dep`bank' == .
			}
			
			tempfile bisbilat`i'
			save `bisbilat`i'', replace

			* Fractions of non-bank deposits which are tax evading household
			import excel "$raw/assumptions/ofc_and_dep_assumptions.xlsx", ///
			clear firstrow cellrange(A1:X24) sheet(sharehouseholddep)
			keep if year == `i' 
			merge 1:m year using `bisbilat`i'', nogenerate
			gen AS = 0.7															// assumption: 70% of deposits in Asian tax havens (not bilaterally available) belong to households
			foreach bank in CH AE AS GG IM JE PA LU CY MO MY KY BE AT BH BM BS ///
			HK SG GB US CL AN CW { 
				replace dep`bank' = `bank'*dep`bank' if year == `i' 
				drop `bank'
				}																	// this step reduces the tax haven deposits as not all of them belong to households
				* Compute deposits in haven aggregates: Caribbean havens, 
				* European havens, Asian haven is done above from 1N
					gen depCR = depKY + depPA + ///
					depCL + depUS
					label variable depCR "Deposits in Caribbean havens"
					gen depEU =depGG + depIM + ///
					depJE + depLU + depAT + depBE ///
					+ depGB + depCY
					label variable depEU "Deposits in European havens"
					replace depAS = depAS + depAE

					reshape long dep, i(saver) j(bank) string
					tempfile bisbilat`i'
					save `bisbilat`i'', replace

**-------------- I.2 - Merge to country codes iso-3 --------------------------** 

* Add iso3 and country names (saver)
isocodes saver, gen(iso3c) //1W, 5J, PU
rename iso3c iso3saver	
* US Pacific Islands now part of United States Minor Outlying Islands
replace iso3saver = "UMI" if saver == "PU"
replace saver = "UM" if saver == "PU"
isocodes saver, gen(cntryname) //1W, 5J
rename cntryname namesaver
order namesaver saver iso3saver
tempfile bisbilat`i'
save `bisbilat`i'', replace
  
 * Add GDP. The main source is the World Bank, but we make use of different 
 * ones when no info is available for a specific countries
use "$work\assembled_gdp_series.dta", clear
drop gdp_source
keep if year == `i'
rename gdp_current_dollars gdp`i'
rename iso3 iso3saver 
merge 1:m year iso3saver using `bisbilat`i'', nogenerate
su gdp`i' if bank=="5A"
local worldgdp=r(sum)
gen shgdp  =gdp`i'/`worldgdp'
tempfile bisbilat`i'
save `bisbilat`i'', replace

* Add isocodes
isocodes bank, gen(iso3c) //1R, 1R_world, 5A
rename iso3c iso3bank
isocodes bank, gen(cntryname) // 1R, 1R_world, 5A
rename cntryname namebank
replace namebank="Caribbean havens" if bank=="CR"
replace namebank="Asian havens" if bank=="AS"
replace namebank="European havens" if bank=="EU"
replace namebank="All BIS-reporting banks" if bank=="5A"
replace namebank= "Residual countries" if bank == "1R"
format name* %20s
replace iso3bank="" if bank=="CR"|bank=="AS"|bank=="EU"|bank=="HA"|bank=="OC"
order namebank bank iso3bank
sort bank saver
compress
tempfile bisbilat`i'
save `bisbilat`i'', replace

********************************************************************************

********************* II ---- Load Fiduciary data -----*************************

********************************************************************************

**------------------ I.2 - Adjustments to fiduciary --------------------------** 
* Read fiduciary accounts in Switzerland
use "$work/fiduciary-87-23.dta", clear

* Collapse fiduciary to one year
keep if year == `i'
rename ccode iso3
drop if length(iso3)>3
tempfile fiduciary
save `fiduciary'

* Homogeneize country grouping with those used in Zucman UCP 2015
cap drop continent group
rename ofc haven

* GCC states (excluding bahrain = haven): 0 capital tax 
gen gcc=0
replace gcc=1 if iso3=="SAU"|iso3=="ARE"|iso3=="KWT"|iso3=="QAT"|iso3=="OMN"

* EU members in 2005
gen eu=0
#delimit ;
replace eu=1 if 
iso3=="BEL" |
iso3=="FRA" |
iso3=="ITA" |
iso3=="LUX" |
iso3=="NLD" |
iso3=="DEU" |
iso3=="DNK" |
iso3=="IRL" |
iso3=="GBR" |
iso3=="GRC" |
iso3=="PRT" |
iso3=="ESP" |
iso3=="AUT" |
iso3=="FIN" |
iso3=="SWE" |
iso3=="HUN" |
iso3=="CYP" |
iso3=="CZE" |
iso3=="EST" |
iso3=="LVA" |
iso3=="LTU" |
iso3=="MLT" |
iso3=="POL" |
iso3=="SVK" |
iso3=="SVN";
#delimit cr

* Merge Middle East into Africa 
replace africa=1 if iso3=="EGY"|iso3=="IRN"|iso3=="IRQ"|iso3=="ISR"| ///
iso3=="JOR"|iso3=="SYR"|iso3=="YEM"
drop middle_east
* Move Caribbean into Latin America
replace latin_am=1 if caribbean==1
drop caribbean
* Guyana http://www.lseg.com/sites/default/files/content/
* portogallo%20appendix%20A.pdf
replace latin_am=0 if iso3=="GUY" 
* Isolate Russia
replace asia= 0 if iso3 == "RUS"
gen russia = 0
replace russia= 1 if iso3 == "RUS"

* Add Swiss fiduciary deposits (for consistency with BIS): CHE = 55% of CHE+LIE
expand 2 if iso3=="LIE", gen(che)
replace iso3="CHE" if che==1
replace ifscode=146 if che==1 
replace cn="Switzerland" if che==1
drop che
local fiduvar "lfidu lfidudol lfidu2 lfidu2dol lfidu2dol_fdi_adjustment lfidu2dol_russia_adjustment"
foreach var of local fiduvar {
	replace `var'=(1-0.45)/0.45*`var' if iso3 == "CHE"
	}
	tempfile fiduciary
	save `fiduciary'
	
	use "$work/fdi-havens", clear											// start new code element (fdi-corrected fidu2 series)
	drop inward receiving country
	keep if year == `i'
	reshape wide share, i(country_iso3 year) j(receiving_iso3) string
	keep country_iso3 year shareCHE
	rename country_iso3 iso3
	merge 1:1 iso3 year using "`fiduciary'", keep(2 3) nogenerate

	* reallocate swiss amounts
    // Sum the share multiplied by the corresponding country's total_lfidu2dol
    quietly sum lfidu2dol if iso3 == "CHE" & year == `i'
	local amount = r(sum)
    replace lfidu2dol_fdi_adjustment = lfidu2dol_fdi_adjustment + (shareCHE * `amount') if shareCHE ~= . & `amount' ~= 0 & year == `i'
	replace lfidu2dol_fdi_adjustment = 0 if iso3 == "CHE" & year == `i'
	drop shareCHE
																			// end new code element
	rename iso3 iso3saver
	drop lfidu lfidudol lfidu2 
	rename lfidu2dol amt_fidu1 
	rename lfidu2dol_fdi_adjustment amt_fidu2
	rename lfidu2dol_russia_adjustment amt_fidu3								
	collapse (mean) amt_fidu1 amt_fidu2 amt_fidu3 (first) euro16 rich developing haven north_am ///
	latin_am gcc russia asia africa europe eu, by(iso3)
	gen bank = "CH"
	tempfile fiduciary`i'
	save `fiduciary`i'', replace
	
**------------------ II.2 - Merge BIS and fiduciary --------------------------** 
	use `bisbilat`i'', clear
	merge 1:1 iso3saver bank using `fiduciary`i'', nogenerate
	sort bank saver
	replace namebank="Switzerland" if bank=="CH"
	replace iso3bank="CHE" if bank=="CH"
	drop if bank==""
	save "$work/offshore`i'.dta", replace
	merge m:1 iso3saver using `fiduciary`i'', ///
	keepusing(euro16 rich developing haven north_am latin_am gcc russia ///
	asia africa europe eu) update nogenerate 
	* Update saver continent dummies (saved in fiduciary87-23.dta) 
	* for all bank-saver pair
	rename dep amt_bis
	order bank iso3bank namebank saver iso3saver namesaver amt_bis ///
	amt_fidu1 gdp shgdp rich developing haven OFC
	replace OFC = haven if haven!= . & OFC==.
	replace haven = OFC if OFC != . & haven == .
	drop OFC
	replace europe = 1 if iso3saver == "MNE" | ///
	iso3saver == "GRL" 
	replace africa = 1 if iso3saver == "PSE"
	
	foreach var in europe developing africa rich euro16 north_am latin_am ///
	russia asia eu gcc {
		replace `var' = 0 if iso3saver == "ANT" | iso3saver == "CHE" | ///
		iso3saver == "ATG" | iso3saver == "KNA"
		}
		replace haven = 1 if iso3saver == "ANT" | iso3saver == "CHE" | ///
		iso3saver == "ATG" | iso3saver == "KNA"
		
		foreach var in africa rich euro16 north_am latin_am ///
		russia asia eu gcc haven {
			replace `var' = 0 if iso3saver == "SCG" 
			}
			replace europe = 1 if iso3saver == "SCG"
			replace developing = 1 if iso3saver == "SCG"
				
				sort bank saver
				sleep 3000
				save "$work/offshore`i'", replace

********************************************************************************

*********** III ---- COMPUTE AND MERGE SHARE OF DEPOSITS -----******************

********************************************************************************

**-------------------------------- III.1 - -----------------------------------**
* rawsh: share not taking into account shell companies
* sh: corrected share taking into account wealth held through shell companies
use "$work/offshore`i'", clear

* Deal with shell and financial companies incorporated in GB, US, NL, etc. 		// Without this correction we would probably distribute a lot of offshore wealth to these countries as they own a lot of tax-haven deposits but we believe they are not the actual owners -> we reduce their 'real' share without dropping the shell-company share from the aggregates (by creating additional rows for the shell company-owned deposits instead of just dropping them). We classify the shell company owned deposits as tax havens and thereby include them in the redistribution mechanism below where they are distributed back to non-havens.
foreach saver in GB CH BE NL IE US {
	if "`saver'" == "CH" local share_shell = 1.00 // treat Switzerland as tax haven
	if "`saver'" == "IE" local share_shell = 0.75 // financial companies
	if "`saver'" == "GB" local share_shell = 0.5  // shells + financial companies + non-doms
	if "`saver'" == "NL" local share_shell = 0.75 // shells + financial companies
	if "`saver'" == "BE" local share_shell = 0.5  // shells + financial companies
	if "`saver'" == "US" local share_shell = 0.2  // Delaware shell + financial companies
	expand 2 if saver == "`saver'", gen(new`saver')										// duplicate deposits in shell company countries
	replace saver = "`saver'H" if new`saver' == 1 
	drop new`saver'
	replace namesaver = "Shell corp `saver'" if saver == "`saver'H"
	replace gdp = 0 if saver == "`saver'H"
	replace shgdp = 0 if saver == "`saver'H"
	replace haven = 1 if saver == "`saver'H"
	foreach var of varlist north_am europe rich {
		replace `var' = 0 if saver == "`saver'H"
		}
		replace iso3saver = "`saver'H" if saver == "`saver'H"
		foreach var in amt_bis amt_fidu1 amt_fidu3 {
			replace `var' = `var' * `share_shell' if  saver == "`saver'H" // generate amount of deposits which are reported as owned by CH, IE, GB etc (shell-company countries) but which actually belong to residents in non-havens 
			replace `var' = `var' * (1 - `share_shell') if  saver == "`saver'" // reduce amount of deposits which are actually owned by residents of IE, GB, NL, ... // reduce original deposits to non-shell company share in saver jurisdictions that are themselves tax havens (because we assume that the share_shell of deposits actually belongs to residents of other countries)
			}
			}  
			
			
			replace amt_fidu2 = 0 if saver == "CHH" | saver == "IEH" ///				
			| saver == "GBH" | saver == "NLH" | saver == "BEH" | saver == "USH" ///
			| saver == "CH"																
			
			* Create shares of deposits 
			foreach y in fidu1 fidu2 fidu3 bis {								
				gen rawsh_`y'=0
				gen sh_`y'=0
				foreach b in 5A 1R US GB CL GG IM JE KY LU MO MY PA CH ///		/
				AT BE EU CR AS HA OC CY AE {
					su amt_`y' if bank=="`b'"
					local tot`y'`b'=r(sum)										// sum of global deposits reported by haven b
					su amt_`y' if haven==1 & bank=="`b'"
					local tothaven`y'`b'=r(sum)									// sum of tax haven-owned deposits reported by haven b
					su amt_`y' if eu==1 & haven!=1 & bank=="`b'"
					local toteu`y'`b'=r(sum)									// sum of EU-owned deposits reported by haven b
					replace rawsh_`y'= amt_`y'/`tot`y'`b'' if bank=="`b'" 			// generate each country's share in haven b's total reported deposits
					
					
					
						// increase each non-haven country's share in tax haven deposits by 1 + the ratio of haven-owned deposits to non-haven-owned deposits (as reported by US, GB, GG etc.) 
						replace sh_`y'= ///			
						rawsh_`y'*(1+(`tothaven`y'`b'')/ ///
						(`tot`y'`b''-`tothaven`y'`b'')) if /// 
						haven!=1 & bank=="`b'"
						}
						}
						save "$work/offshore`i'", replace
						
						* Compute share BIS deposits in all tax havens 		
						* (needs to be done post allocation of shell)
						tempfile total
						keep bank iso3saver sh_bis amt_bis
						drop if iso3saver == ""
						reshape wide sh_bis amt_bis, ///
						i(iso3saver) j(bank) string
						foreach var of varlist sh* amt* {
							replace `var' = 0 if `var'== .
							}
							
							
							gen sh_bisOC = (sh_bisAS * `totbisAS' + ///
							sh_bisCR * `totbisCR' + sh_bisEU * `totbisEU' ) ///
							/ (`totbisAS' + `totbisCR' + `totbisEU')
							gen sh_bisHA = (sh_bisOC * (`totbisAS' + ///
							`totbisCR' + `totbisEU') + sh_bisCH * ///
							`totbisCH') / (`totbisAS' + `totbisCR' + ///
							`totbisEU' + `totbisCH')							
							
							* uncorrected amounts, just as memo item
							gen amt_bisOC = amt_bisAS + amt_bisCR + amt_bisEU 
							gen amt_bisHA = amt_bisOC + amt_bisCH
							reshape long sh_bis amt_bis, ///
							i(iso3saver) j(bank) string
							keep if bank == "OC" | bank == "HA"
							save `total', replace
							use "$work/offshore`i'", clear
							append using `total'
							keep if bank=="OC" | bank == "CH" | bank =="HA"
							replace namebank="All havens" if bank=="HA"
							replace namebank="Havens other than CH" ///
							if bank=="OC"
							sort iso3saver bank
							foreach var of varlist saver namesaver gdp ///
							shgdp rich developing gdp* north* lat* gcc ///
							russia asia africa europe eu* haven  {
								replace `var'=`var'[_n-1] if bank=="HA"
								replace `var'=`var'[_n-2] if bank=="OC"
								}
								save `total', replace
								* Offshore is a dataset of bilateral deposits and fiduciary accounts
								use "$work/offshore`i'", clear
								merge 1:1 bank iso3saver using `total', ///
								update nogenerate
								replace namesaver = "US Minor Islands" ///
								if iso3saver == "UMI"
								drop if namesaver == ""
								replace year = `i'
								replace sh_fidu2 = rawsh_fidu2
								drop rawsh_fidu2
								rename sh_fidu1 sh_fidu
								rename sh_fidu2 sh_fidu_fdi_adjustment
								rename sh_fidu3 sh_fidu_russia_adjustment
								order bank iso3bank namebank saver ///
								iso3saver namesaver amt_bis ///
								amt_fidu* sh*  
								gsort namesaver
								order saver iso3saver namesaver sh_fidu* /// 
								shgdp gdp* 
								sort namesaver
								save "$work/offshore`i'", replace
 
**-------------------------------- III.2 - -----------------------------------**
* In this section, we keep country deposits in haven groups (OC is 
* havens other than Switzerland, AS asian havens, etc.) and later merge
* them. The goal is to have a dataset of only countries and their shares 
* in each haven group
preserve
keep if bank == "CH"
	gen continent = 1*africa + 2*europe + 3*gcc + 4*asia + 5*russia + ///
	6*latin_am + 7*north_am + 8*haven
	  replace continent=8 if continent==0
	  replace continent=9 if saver=="NO"
	  replace continent=10 if saver=="CR"
  keep saver iso3saver namesaver sh_fidu* shgdp gdp sh_bis continent
  tempfile countries1
  save `countries1', replace
  restore 
  preserve
  keep if bank=="OC" 
  keep iso3saver saver namesaver sh_bis 
  rename sh_bis sh_OC
  merge 1:1 iso3saver using  `countries1', nogenerate
  tempfile countries2
  save `countries2', replace
  restore 
  preserve
  keep if bank=="AS" 
  keep iso3saver saver namesaver sh_bis 
  rename sh_bis sh_AS
  merge 1:1 iso3saver using `countries2', nogenerate
  tempfile countries3
  save  `countries3', replace
  restore 
  preserve
  keep if bank=="EU" 
  keep iso3saver saver namesaver sh_bis 
  rename sh_bis sh_EU
  merge 1:1 iso3saver using `countries3', nogenerate
  tempfile countries4
  save  `countries4', replace
  restore 
  *preserve
  keep if bank=="CR" 
  keep iso3saver saver namesaver sh_bis 
  rename sh_bis sh_CR
  merge 1:1 iso3saver using  `countries4', nogenerate
  gsort namesaver
  order saver iso3saver namesaver sh_fidu* sh_OC sh_CR sh_AS sh_EU shgdp ///
  gdp* continent 
  sort continent namesaver
  rename sh_fidu sh_fidu`i'
  rename sh_fidu_fdi_adjustment sh_fidu_fdi_adjustment`i'
  rename sh_fidu_russia_adjustment sh_fidu_rus_adjustment`i'
  rename sh_AS sh_AS`i'
  rename sh_CR sh_CR`i'
  rename sh_EU sh_EU`i'
  rename sh_OC sh_OC`i'
  rename sh_bis sh_bis`i'
  tempfile countries`i'
  save `countries`i'', replace
 }
 
 *******************************************************************************

**************** IV ---- COMPUTE 5-YEARS SMOOTHED ESTIMATES -----***************

********************************************************************************
 forvalues x=2003/2021 {
 	local x_1 = `x' - 2
	local x_2 = `x' - 1
	local x_3 = `x' + 1
	local x_4 = `x' + 2
 	* Here we compute 5-years smoothed estimates. The smoothed share at year t 
	* is 40% of the share at year t, 20% at year t-1 t+1, 10% at year t-2 t+2
	use `countries`x'', replace
	merge 1:1 iso3saver using `countries`x_1'', nogenerate
	merge 1:1 iso3saver using `countries`x_2'', nogenerate
	merge 1:1 iso3saver using `countries`x_3'', nogenerate
	merge 1:1 iso3saver using `countries`x_4'', nogenerate
	foreach b in fidu CR EU AS OC bis fidu_fdi_adjustment fidu_rus_adjustment {
	gen sh_`b'_smthg`x' = (sh_`b'`x_1' + sh_`b'`x_4')*0.1 + ///
	(sh_`b'`x_2'+ sh_`b'`x_3')*0.2 + sh_`b'`x'*0.4
	replace sh_`b'_smthg`x' = sh_`b'`x' if sh_`b'_smthg`x' == .
	drop sh_`b'`x_1' sh_`b'`x_4' sh_`b'`x_2' sh_`b'`x_3' sh_`b'`x'
	}
	merge 1:m namesaver using "$work/offshore`x'", nogenerate
	drop gdp`x_1' gdp`x_2' gdp`x_3' gdp`x_4' 
	
	* labels
	label var year "Year"
	label var namesaver "Counterparty country name"
	label var iso3saver "Counterparty ISO alpha-3 code"
	label var saver "Counterparty ISO alpha-2 code"
	label var year ""
	label var bank "Reporting country ISO alpha-2 code"
	label var iso3bank "Reporting country ISO alpha-3 code"
	label var namebank "Reporting country name"
	label var amt_bis "Bank deposits owned by counterparty households in reporting country"
	label var amt_fidu1 "Fiduciary deposits owned by counterparty households in reporting country"
	label var rawsh_bis "Share of total deposits owned by counterparty households"
	label var rawsh_fidu1 "Share of total fiduciary deposits owned by counterparty households"
	label var sh_bis "Corrected share of deposits owned by counter households in reporting country"
	label var sh_fidu "Corrected share of Swiss fiduciary deposits owned by counterparty households"
	label var sh_bis_smthg "Weighted moving avg sh. of deposits owned by counter households in rep. country"
	label var sh_AS_smthg "Weighted moving avg sh. of deposits owned by counter households in Asian havens"
	label var sh_CR_smthg "Weighted mov. avg sh. of deposits owned by count. households in Caribbean havens"
	label var sh_EU_smthg "Weighted mov. avg sh. of deposits owned by count. households in European havens"
	label var sh_OC_smthg "Weight. mov. avg sh. of dep. owned by count. households in havens ex Switzerland"
	label var sh_fidu_smthg "Weighted moving avg sh. of deposits owned by counter households in Switzerland"
	label var gdp "Counterparty country GDP, various sources"
	label var shgdp "Share of counterparty in World GDP"
	label var continent "Continent of counterparty country"
	label define cont_label 1 "africa" 2 "europe" 3 "gcc" 4 "asia" ///
	5 "russia" 6 "latin_am" 7 "north_am" 8 "haven" 
	label values continent cont_label
	label var rich "High income countries"
	label var developing "Developing countries"
	label var haven "Countries that exhibit a salient activity in financial wealth managed offshore"
	label var europe "European countries"
	label var asia "Asian countries"
	label var russia "Russia"
	label var north_am "North American countries"
	label var latin_am "Latin American countries"
	label var gcc "Gulf countries"
	label var africa "African and Middle-Eastern countries"
	drop eu euro16
	gsort namesaver
    order year saver iso3saver namesaver bank iso3bank namebank ///
	amt_fidu1 rawsh_bis rawsh_fidu1 sh_bis sh_fidu_fdi_adjustment sh_fidu_rus_adjustment sh_fidu ///
	sh_bis_smthg sh_AS_smthg sh_CR_smthg ///
	sh_EU_smthg sh_OC_smthg sh_fidu_smthg sh_fidu_fdi_adjustment_smthg sh_fidu_rus_adjustment_smthg gdp shgdp continent rich developing haven ///
	europe asia russia north_am latin_am gcc africa  
    sort namesaver
	save "$work/offshore`x'", replace 
 }
 
	* We adapt the computation when we can't use t-2, t-1, t+1, or t+2. 
	* In our case it's for 2001, 2002, 2022, 2023
	* We also deal with missing values for certain years
 	use `countries2001', replace
	merge 1:1 iso3saver using `countries2002', nogenerate
	merge 1:1 iso3saver using `countries2003', nogenerate
	merge 1:1 iso3saver using `countries2004', nogenerate
	merge 1:1 iso3saver using `countries2022', nogenerate
	merge 1:1 iso3saver using `countries2023', nogenerate
	merge 1:1 iso3saver using `countries2020', nogenerate
	merge 1:1 iso3saver using `countries2021', nogenerate
	foreach b in fidu fidu_fdi_adjustment fidu_rus_adjustment CR EU AS OC bis {
	gen sh_`b'_smthg2001 = ///
	((sh_`b'2003)*0.1 + (sh_`b'2002)*0.2 + sh_`b'2001*0.4) / 0.7
	gen sh_`b'_smthg2002 = ///
	((sh_`b'2004)*0.1 + (sh_`b'2003 + sh_`b'2001)*0.2 + sh_`b'2002*0.4) / 0.9
	gen sh_`b'_smthg2022 = ///
	(sh_`b'2020*0.1 + (sh_`b'2023 + sh_`b'2021)*0.2 + sh_`b'2022*0.4) / 0.9
	gen sh_`b'_smthg2023 = ///
	(sh_`b'2021*0.1 + 0.2*sh_`b'2022 + 0.4*sh_`b'2023) / 0.7
	replace sh_`b'_smthg2001 = ///
	sh_`b'2001 if sh_`b'_smthg2001 == . 
	replace sh_`b'_smthg2002 = ///
	(sh_`b'2002*0.4 + sh_`b'2004*0.1) / 0.5 if sh_`b'_smthg2002 == . 
	replace sh_`b'_smthg2002 = ///
	sh_`b'2002 if sh_`b'_smthg2002 == . 
	drop sh_`b'2002 sh_`b'2003 sh_`b'2004 sh_`b'2022 sh_`b'2023 sh_`b'2020 ///
	sh_`b'2021 
	}
	
	* 
	forvalues i = 2001/2023 {
	if inlist(`i', 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, ///
	2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021 ) continue
	preserve
	keep namesaver saver sh_fidu_rus_adjustment_smthg`i' sh_fidu_fdi_adjustment_smthg`i' sh_fidu_smthg`i' sh_CR_smthg`i' sh_EU_smthg`i' ///
	sh_AS_smthg`i' sh_OC_smthg`i' sh_bis_smthg`i' gdp`i' shgdp continent
	merge 1:m namesaver using "$work/offshore`i'", nogenerate
	
	* labels
	label var year "Year"
	label var namesaver "Counterparty country name"
	label var iso3saver "Counterparty ISO alpha-3 code"
	label var saver "Counterparty ISO alpha-2 code"
	label var year ""
	label var bank "Reporting country ISO alpha-2 code"
	label var iso3bank "Reporting country ISO alpha-3 code"
	label var namebank "Reporting country name"
	label var amt_bis "Bank deposits owned by counterparty households in reporting country"
	label var amt_fidu1 "Fiduciary deposits owned by counterparty households in reporting country"
	label var rawsh_bis "Share of total deposits owned by counterparty households"
	label var rawsh_fidu1 "Share of total fiduciary deposits owned by counterparty households"
	label var sh_bis "Corrected share of deposits owned by counter households in reporting country"
	label var sh_fidu "Corrected share of Swiss fiduciary deposits owned by counterparty households"
	label var sh_bis_smthg "Weighted moving avg sh. of deposits owned by counter households in rep. country"
	label var sh_AS_smthg "Weighted moving avg sh. of deposits owned by counter households in Asian havens"
	label var sh_CR_smthg "Weighted mov. avg sh. of deposits owned by count. households in Caribbean havens"
	label var sh_EU_smthg "Weighted mov. avg sh. of deposits owned by count. households in European havens"
	label var sh_OC_smthg "Weight. mov. avg sh. of dep. owned by count. households in havens ex Switzerland"
	label var sh_fidu_smthg "Weighted moving avg sh. of deposits owned by counter households in Switzerland"
	label var gdp "Counterparty country GDP, various sources"
	label var shgdp "Share of counterparty in World GDP"
	label var continent "Continent of counterparty country"
	label define cont_label 1 "africa" 2 "europe" 3 "gcc" 4 "asia" ///
	5 "russia" 6 "latin_am" 7 "north_am" 8 "haven" 
	label values continent cont_label
	label var rich "High income countries"
	label var developing "Developing countries"
	label var haven "Countries that exhibit a salient activity in financial wealth managed offshore"
	label var europe "European countries"
	label var asia "Asian countries"
	label var russia "Russia"
	label var north_am "North American countries"
	label var latin_am "Latin American countries"
	label var gcc "Gulf countries"
	label var africa "African and Middle-Eastern countries"
	drop eu euro16
	gsort namesaver
    order year saver iso3saver namesaver bank iso3bank namebank amt_bis ///
	amt_fidu1 rawsh_bis rawsh_fidu1 sh_bis sh_fidu sh_fidu_fdi_adjustment sh_fidu_rus_adjustment ///
	sh_bis_smthg sh_AS_smthg sh_CR_smthg ///
	sh_EU_smthg sh_OC_smthg sh_fidu_smthg sh_fidu_fdi_adjustment_smthg sh_fidu_rus_adjustment_smthg gdp shgdp continent rich developing haven ///
    europe asia russia north_am latin_am gcc africa  
    sort namesaver
	sleep 6000
	save "$work/offshore`i'", replace 
	restore
	}
	