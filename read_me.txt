//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
// Purpose: instructions on how to run the codes for the replication 	
//----------------------------------------------------------------------------//

1. Data
A short description of the required datasets is available in: ~data_for_replication.xlsx.
The corresponding data files are placed in the folder: ~raw-data/.
Some input files are too big for the github repository. Download links to the original datasets can be found in the raw-data folder.
For an exact replication request the files
 * BIS Locational Banking Statistics (Dec 2024 version)
 * IMF CDIS direct-investment-position (April 2025 version)
 * IMF CPIS (Sep 2024 version)
 from:
 Name: [Sarah Godar]
 Email: sgodar [at] diw.de

2. Running the Code in Stata
To replicate the results, follow these steps:
	1) Open the Stata script:~code/00-master/0a-setup.do. Edit the file to set the correct path to your working directory, then run it.
	2) Once the setup is complete, open and run: ~code/00-master/0b-run.do.
This script runs all the code needed for replication. Note that it may take several minutes to complete.

3. Figures from the paper
After running all the code, the paper's figures will be in the folder: ~figures/.
