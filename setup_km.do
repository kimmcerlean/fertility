global homedir "G:\Other computers\My Laptop\Documents"

* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global code "$homedir/GitHub/fertility"

* This locations of folders containing the original data files
global PSID "/data/PSID" // PSID main data
global states "$homedir/Dissertation/Policy data/Structural support measure" // structural support variable

* Note that these directories will contain all "created" files - including intermediate data, results, and log files.

* created data files
global created_data "$homedir/Research Projects/Policy and Fertility/Stata/created data"

* results
global results "$homedir/Research Projects/Policy and Fertility/results"

* logdir
global logdir "$homedir/Research Projects/Policy and Fertility/Stata/logs"

* temporary data files (they get deleted without a second thought)
global temp "$homedir/Research Projects/Policy and Fertility/Stata/temp data"