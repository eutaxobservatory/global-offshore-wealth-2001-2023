* ==============================================================================
* Date: 2024-09-27
* Paper: Global Offshore Wealth, 2001-2023
* Researcher: Carolina Moniz De Moura 
* This folder builds the dataset of UAE bank deposits from non-residents.
*
*===============================================================================

* bank_deposits_in_uae_march_2001_to_june_2024.xlsx : all the data from "/source"


* bank_deposits_in_uae.do: 
	- select only quarter values from the dataset on non-residents deposits (cbuae)
	- apply monthly exchange rates AED to USD using BIS exchange rates dataset
 	- uniform the old and new categories: 
		- NEW Corporate <=>  OLD  Business and Industry => corporate 
		- NEW Non Banking Financial Institutions <=>  OLD Financial Institutions => financial_institutions
		- NEW Individuals <=>  OLD Individuals and Others => individuals
		- NEW Government and Non Commercial Entities<=>  OLD Government and Diplomatic Missions => government
 	- impute share of categories for year 2014: I apply 50 percent of the variation between 2013 and 2015 of the share of the category
 	- impute quarterly data (q1,q2,q3) for years 2009/2017 : Assign to Q1 in t = value Q4 in t-1 + 0.25*(value Q4 in t -value Q4 in t)     
	- mean of variables by year 


* bank_deposits_in_uae_cleaned_q4(yearly).xlsx: final output from bank_deposits_in_uae.do

* non_resident_deposits_imputed_categories.png: allows to observe the data we have and the imputations made. 

* /source:	
	For data 1999-2008
	- title: Statistical Bulletin, Table 11: "Deposits by Ownership"
	- provider: Central Bank of the U.A.E.
	- periodicity: yearly
	- periodicity of the data: yearly
 	- last release: July 2024 (released in 31 July 2008)
	- first release: January 2001 (released in 31 January 2001)
	- link: https://www.centralbank.ae/en/news-and-publications/archived-reports/
	
	For data 2009-2013
	- title: CBUAE annual report, Table (A-10) "Deposits distributed Residents / Non Residents "
	- provider: Central Bank of the U.A.E.
	- periodicity: yearly
	- periodicity of the data: yearly
 	- last release I took: 2013 (released in 31 December 2013)
	- first release I took: 2009 (released in 31 December 2009)
	- link: https://www.centralbank.ae/en/news-and-publications/publications/

	For data 2014
	- title: CBUAE annual report 2016, Table 3.2.a.Deposits at UAE Banks
	- provider: Central Bank of the U.A.E.
	- periodicity: yearly	

	For data 2015-2024
	- title: Statistical Bulletin, Table 30: "Deposits distributed Residents / Non Residents  (All Banks)"
	- provider: Central Bank of the U.A.E.
	- periodicity: monthly
	- last release: June 2024 (released in 13 September 2024)
	- first release: January 2020 (released in 31 January 2020)
	- link: https://www.centralbank.ae/en/research-and-statistics/ 
	- date of extraction: 2024-09-16



PS: I found in the "UAE Banking Indicators" data for the bank deposits from non-resident but they are not at the individual level but rather aggregated. So I decided to not take it. If data was at individual level it could help us for Feb-2020 and all the months of 2019.


