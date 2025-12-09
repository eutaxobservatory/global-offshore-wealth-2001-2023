//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: import BIS locational banking statistics 
//
// databases used: - "$raw/full_lbs_d_pub_csv/WS_LBS_D_PUB_csv_col.csv"
//
// outputs:        - "$work/locational.dta" 
//----------------------------------------------------------------------------//



********************************************************************************
****** I ---- Import and clean BIS locational banking stats -----******
********************************************************************************

// import online BIS banking statistics 

insheet using "$raw/full_lbs_d_pub_csv/WS_LBS_D_PUB_csv_col.csv", clear
// note:  Q:S:C:D:USD:F:GB:A:DE:N:FR:N
// refers to quarterly (Q) outstanding (S) claims (C) of debt securities
// (D) denominated in USD (USD) as a foreign currency (F) 
// by British (GB) banks (A) in Germany (DE) vis-a-vis non-banks (N) 
// in France (FR), which are cross border positions (N).

// harmonize deposits value variables names
rename q3 v35
rename q2 v34 
rename q1 v33 
rename q4 v32


// transform value variables names in the following form "value'quarter''year'"
local q=4
local y=1977
foreach var of varlist v* {
rename `var' value`q'_`y'
if `q'<4 {
local q=`q'+1
}
else {
local q=1
local y=`y'+1
}
}

// keep only quarterly, outstanding, all currency, in bank, hold by non-bank 
keep if freq == "Q"
drop freq
keep if l_measure == "S"
drop l_measure
keep if l_denom == "TO1"
drop l_denom
keep if l_curr_type == "A"
drop l_curr_type
keep if l_rep_bank_type == "A"
drop l_rep_bank_type
keep if l_pos_type == "N"
drop l_pos_type

// reshape the data to one deposit value line per quarter 
fastreshape long value, i(series) j(quarter) string

// adjustments
gen year = substr(quarter,-4,4)
replace quarter=substr(quarter,1,2)
replace quarter=substr(quarter,1,1) if quarter!="12"
destring(quarter year), replace
destring(value), replace  i(NaN)
sort year quarter position l_rep_cty l_cp_country
rename l_rep_cty bank
rename l_cp_country counter
rename series code
rename l_cp_sector sector 
rename l_parent_cty parent 
rename l_position position 
rename l_instr instrument
order quarter year instrument position parent bank sector counter value code

format position instrument position bank sector counter parent  %5s
compress

** locational already has iso2 => Add iso3 + names 
// counter 
	// isoname => namecounter 
	// iso2 => counter 
	// iso3 => iso3counter
	
// Add iso-3 to BIS locational banking stats counterparty countries
isocodes counter, gen(iso3c)
//US Pacific Islands	PU	PUS
replace iso3c="PUS" if counter=="PU"
rename iso3c iso3counter
isocodes counter, gen(cntryname)
replace cntryname="US Pacific Islands" if counter=="PU"
rename cntryname namecounter
order namecounter counter iso3counter
replace namecounter="Serbia and Montenegro	" if counter=="CS"
replace iso3counter="SCG" if counter=="CS"
label var namecounter "Name of the counter country"
label var counter "iso2 of the counter country"
label var iso3counter "iso3 of the counter country"
rename iso3counter threecounter //because of command isocodes 

// bank 
	// iso2 bank
	// isoname namebank
	// iso3 iso3bank

isocodes bank, gen(iso3c)
rename iso3c iso3bank
rename threecounter iso3counter
isocodes bank, gen(cntryname)
rename cntryname namebank
order namebank bank iso3bank
format name* %20s
replace namebank = "All BIS-reporting banks" if bank == "5A"
replace namecounter = "All" if counter == "5J"
save "$work/locational.dta", replace


//----------------------------------------------------------------------------//
