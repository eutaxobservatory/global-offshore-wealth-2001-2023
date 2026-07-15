//----------------------------------------------------------------------------//
// Paper: Global Offshore Wealth, 2001-2023
//
// Purpose: Apply a household-share sensitivity scenario to the current dataset.
// Auxiliary do file that calls immediately after importing sharehouseholddep 
//in 4b-build-bis-01-23.do, and after gen AS=0.7in 7a-build-offshore.do.
//
//----------------------------------------------------------------------------//

local scenario "$hh_scenario"
if "`scenario'" == "" local scenario "preferred"

if !inlist("`scenario'", "preferred", "minus10", "plus10", "allone", "freeze2007", "hk_low", "hk_high") {
	di as error "Unknown household-share scenario: `scenario'"
	exit 198
}

// Do not shock CH: Switzerland is allocated from SNB data in the final method.
local hhvars "AN AT BE BH BM BS CL CW CY GB GG HK IM JE KY LU MO MY PA SG US AE AS"

if "`scenario'" == "freeze2007" {
	local freeze_AN = .7
	local freeze_AT = .3
	local freeze_BE = .3
	local freeze_BH = .7
	local freeze_BM = .7
	local freeze_BS = .7
	local freeze_CL = 0
	local freeze_CW = .7
	local freeze_CY = 1
	local freeze_GB = .2
	local freeze_GG = 1
	local freeze_HK = .7
	local freeze_IM = 1
	local freeze_JE = 1
	local freeze_KY = .3
	local freeze_LU = 1
	local freeze_MO = .7
	local freeze_MY = .7
	local freeze_PA = 1
	local freeze_SG = .7
	local freeze_US = .1
	local freeze_AE = .685450553894043
	local freeze_AS = .7
}

foreach v of local hhvars {
	capture confirm numeric variable `v'
	if !_rc {
		if "`scenario'" == "minus10" {
			replace `v' = max(`v' - .10, 0) if !missing(`v')
		}
		else if "`scenario'" == "plus10" {
			replace `v' = min(`v' + .10, 1) if !missing(`v')
		}
		else if "`scenario'" == "allone" {
			replace `v' = 1 if !missing(`v')
		}
		else if "`scenario'" == "freeze2007" {
			if "`freeze_`v''" != "" {
				replace `v' = `freeze_`v'' if !missing(`v')
			}
		}
		else if "`scenario'" == "hk_low" & "`v'" == "HK" {
			replace `v' = .60 if !missing(`v')
		}
		else if "`scenario'" == "hk_high" & "`v'" == "HK" {
			replace `v' = .80 if !missing(`v')
		}
	}
}
