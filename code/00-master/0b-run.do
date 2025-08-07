//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
//
// Purpose: This master file runs all programs, create data in work folder 
// and figures.
//
//----------------------------------------------------------------------------//

clear
set graphics off
set more off
cap log close

********************************************************************************
/// Part I: The global portfolio asset liability gap
********************************************************************************

 // 1. Import and merge data sources

	// Reproduce and extend the dataset "data_gravity.dta"
	do "$do/01-gravity-data-build/1a_import_EWN.do"
	do "$do/01-gravity-data-build/1b_import_gdp.do"
	do "$do/01-gravity-data-build/1c_rebuild_gravity_dataset.do"

	//Import other data sources
	do "$do/01-gravity-data-build/1d_import_auxiliary_data.do"

 // 2. Construct matrices of bilateral portfolio assets
	do "$do/02-bilateral-portfolio-assets-matrices/2_do_full_matrices.do"

********************************************************************************	
/// Part II: Offshore deposits and by-country allocation
********************************************************************************

 // 3. UAE deposits 
	do "$do/03-uae-deposits/3-uae-deposits.do"

 // 4. BIS bilateral deposits
 
	// import bilateral deposits
	do "$do/04-bis-deposits-build/4a-import-bis" 

	// construct bilateral deposits non-banks & all counterparty for 2001-2022
	do "$do/04-bis-deposits-build/4b-build-bis-01-23.do" 
	

 // 5. CDIS 
	do "$do/05-cdis/5a-build-inward-investment-shares.do"
	

 // 6. Swiss fiduciary deposits
	// construct fiduciary accounts from SNB data
	do "$do/06-swiss-fiduciary-build/6a-build-fiduciary.do"	
	
	
 // 7. Merge BIS and Swiss data, Estimate countries offshore wealth amounts

	// build bilateral data on offshore wealth
	do "$do/07-offshore-wealth-analysis/7a-build-offshore.do"

	// build swiss offshore wealth data 
	do "$do/07-offshore-wealth-analysis/7b-build-offshore_switzerland.do"	
	
	// build country offshore wealth data 
	do "$do/07-offshore-wealth-analysis/7c-build-countries.do"

/// . Erase datasets 	

		***** Temporary datasets folder
		local folder "$temp"
		local keep "data_toteq_update.dta data_totdebt_update.dta data_full_matrices.dta IIP_eqliab.dta IIP_debtliab.dta"
		local files : dir "`folder'" files "*.dta"
		foreach f of local files {
			* Trim and lowercase filename
			local f_clean = lower(trim("`f'"))

			* Flag: assume we will delete unless matched
			local found = 0

			foreach k of local keep {
				local k_clean = lower(trim("`k'"))
				if "`f_clean'" == "`k_clean'" {
					local found = 1
				}
			}

			if `found' == 0 {
				di "Deleting temporary dataset: `f'..."
				erase "`folder'/`f'"
			}
		}
		

	***** Work datasets folder
	local folder "$work"
	* Explicit list of .dta files to keep
	local keep "global_portfolio_gap.dta locational.dta ofw_aggregate.dta countries.dta fiduciary-87-23_uncorr.dta Table_A1_Global_Cross_Border_Securities_Assets.dta Table_A2_Global_Cross_Border_Securities_Liabilities.dta Table_A3_Global_Discrepancy_Between_Cross_Border_Securities_Assets_and_Liabilities.dta"
	* Get all .dta files in the folder
	local files : dir "`folder'" files "*.dta"
	* Loop through all files
	foreach f of local files {
		* Clean the filename (remove spaces, lowercase)
		local f_clean = lower(trim("`f'"))
		* Start by assuming the file should be deleted
		local keep_file = 0
		* Check if file is in the keep list
		foreach k of local keep {
			local k_clean = lower(trim("`k'"))
			if "`f_clean'" == "`k_clean'" {
				local keep_file = 1
			}
		}
		* Check if file is offshoreYYYY.dta, with 2001 ≤ YYYY ≤ 2023
		if substr("`f_clean'", 1, 8) == "offshore" & substr("`f_clean'", -4, .) == ".dta" {
			local year = real(substr("`f_clean'", 9, 4))
			if `year' >= 2001 & `year' <= 2023 {
				local keep_file = 1
			}
		}
		* If not marked for keeping, delete
		if `keep_file' == 0 {
			di  "Deleting work dataset: `f'..."
			erase "`folder'/`f'"
		}
	}

		
	// graph offshore wealth estimates
	do "$do/07-offshore-wealth-analysis/7d-graph-paper.do"
	
********************************************************************************
/// Others:
********************************************************************************


/// X. Produce output tables bilateral portfolio assets
	//produce output tables
	do "$do/03-produce-output-tables/3_do_table_A1_dta.do"
	do "$do/03-produce-output-tables/3_do_table_A2_dta.do"
	do "$do/03-produce-output-tables/3_do_table_A3_dta.do"
	
/*
/// Y. Produce public datasets from confidential ones
	//Compustat Global – Security Daily for the end-of-year market value of all listed firms incorporated in the Cayman Islands  => "$raw\dta\KY_liab_nfc.dta"
	do "$do/01-gravity-data-build/1_memo-export_Cayman_Islands_Compustat.do"
	//Bilateral BIS data provided by AJZ  => "$raw\dta\AJZ_bisshares0607.dta"
	do "$do/04-bis-deposits-build/4_memo_export_AJZ_bisshares0607.do"
	
	
*/


	