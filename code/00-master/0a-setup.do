//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
// 
// Purpose: create working directories macros necessary to run all programs
//	
//----------------------------------------------------------------------------//



**---------------------------PROGRAMS-----------------------------------------** <------- TO COMPLETE IF NEED
*ssc install isocodes mmerge wbopendata carryforward
*ssc install estout


**------------------------------PATHS-----------------------------------------** <------- TO CHANGE 
* Setting main directories
else if "`c(username)'" == "sgodar" {							// For Sarah
	global dropbox		= "C:/Users/sgodar/Dropbox"	
}
else if "`c(username)'" == "c.moura" {							// For Carolina 
	global dropbox		= "C:/Users/c.moura/Dropbox"	

}

// main directory
global root "$dropbox/FGZ2023OffshoreWealth/replication/package_for_github"

// code files macro
global do "$root/code"

// data created macro
global work "$root/work-data"

// raw data macro
global raw "$root/raw-data"

// figures
global fig "$root/figures"

// tables
global tables "$root/tables"

// raw data macro
global temp "$root/temp" 

/*
*-----------------------EXTRACT ZIPPED DATA FILE------------------------------**
cd "$raw/zucman"
unzipfile "$raw/zucman/data_gravity.zip", replace
*erase "$raw/Zucman/data_gravity.zip"
cd "$raw/Gravity_dta_V202211"
unzipfile "$raw/Gravity_dta_V202211/Gravity_V202211.zip", replace
*erase "$raw/Gravity_dta_V202211/Gravity_V202211.zip"
*===============================================================================
*/