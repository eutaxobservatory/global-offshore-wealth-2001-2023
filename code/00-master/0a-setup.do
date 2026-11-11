//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
// 
// Purpose: create working directories macros necessary to run all programs
//	
//----------------------------------------------------------------------------//



**---------------------------PROGRAMS-----------------------------------------** <------- TO COMPLETE IF NEED
*ssc install isocodes mmerge wbopendata carryforward wid fastreshape
*ssc install estout 


**------------------------------PATHS-----------------------------------------** <------- TO CHANGE 
* Setting main directories
else if "`c(username)'" == "sgodar" {							// For Sarah
	global dropbox		= "C:/Users/sgodar/Dropbox"	
	// main directory
	global root "$dropbox/FGZ2023OffshoreWealth/replication/update-to-2023"

}
else if "`c(username)'" == "carolinamoura" {							// For Carolina 
	global root		= "/Users/carolinamoura/Library/CloudStorage/Dropbox-CREST/Carolina Moniz De Moura/Carolina/EUTAX_projects/global-offshore-wealth-2001-2023"	

}



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

