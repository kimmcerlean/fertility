**********************************************************************************
* Personal computer
**********************************************************************************
if `"`c(hostname)'"' == "LAPTOP-TP2VHI6B"{
	global homedir "G:\Other computers\My Laptop\Documents"

	* This is the base directory with the setup files.
	* It is the directory you should change into before executing any files
	global code "$homedir/GitHub/fertility"

	* This locations of folders containing the original data files
	global PSID "$homedir/Research Projects/Data/PSID" // PSID main data
	global states "$homedir/Dissertation/Policy data/Structural support measure" // structural support variable
	global fam_history "$homedir/Research Projects/Data/PSID - Family Files" 

	* Note that these directories will contain all "created" files - including intermediate data, results, and log files.

	* created data files
	global created_data "$homedir/Research Projects/Policy and Fertility/Stata/created data"
	global created_data_large "C:/Users/mcerl/OneDrive - Istituto Universitario Europeo/projects/Policy and Fertility/large data files"

	* results
	global results "$homedir/Research Projects/Policy and Fertility/results"

	* model output
	global models "$homedir/Research Projects/Policy and Fertility/Stata/models"
	
	* logdir
	global logdir "$homedir/Research Projects/Policy and Fertility/Stata/logs"

	* temporary data files (they get deleted without a second thought)
	global temp "$homedir/Research Projects/Policy and Fertility/Stata/temp data"
}

**********************************************************************************
* Stats server
**********************************************************************************
if `"`c(hostname)'"' == "PPRC-STATS-P01"{
	global homedir "T:" // PRC server

	global code "$homedir/github/fertility"

	* This locations of folders containing the original data files
	global PSID "$homedir/data/PSID" // PSID main data
	global states "$homedir/data/structural support measure" // structural support variable
	global fam_history "$homedir/data/PSID"

	* created data files
	global created_data "$homedir/Research Projects/Policy and Fertility/Stata/created data"

	* results
	global results "$homedir/Research Projects/Policy and Fertility/results"

	* model output
	global models "$homedir/Research Projects/Policy and Fertility/Stata/models"

	* logdir
	global logdir "$homedir/Research Projects/Policy and Fertility/Stata/logs"

	* temporary data files
	global temp "$homedir/Research Projects/Policy and Fertility/Stata/temp data"
}

set maxvar 10000