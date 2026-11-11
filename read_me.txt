//----------------------------------------------------------------------------//
// Project: Global Offshore Wealth, 2001-2023
// Purpose: instructions on how to run the codes for the replication 	
//----------------------------------------------------------------------------//

1. Data
A short description of the required datasets is available in: ~data_for_replication.xlsx.
The corresponding data files are placed in the folder: ~raw-data/.

2. Running the Code in Stata
To replicate the results, follow these steps:
	1) Open the Stata script:~code/00-master/0a-setup.do. Edit the file to set the correct path to your working directory, then run it.
	2) Once the setup is complete, open and run: ~code/00-master/0b-run.do.
This script runs all the code needed for replication. Note that it may take several minutes to complete.

3. Figures from the paper
After running all the code, the paper's figures will be in the folder: ~figures/.
The corresponding scripts with details for each figure are: ~code/07-offshore-wealth-analysis/7e-graph-paper.do and ~code/08-sensitivity/8e-sensitivity-output.do.

4. Tables from the paper
After running all the code, the paper's tables will be in the folder: ~tables/.
The corresponding script with details for each table is: ~code/08-sensitivity/8e-sensitivity-output.do.
