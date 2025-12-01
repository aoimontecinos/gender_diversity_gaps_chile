*_______________________________________________________________________________
* Author: Francine Montecinos.
* Last edition date: August 7th, 2025. 
* Action: Make file directories, globals and log. 
* Note: This do file replicates the results provided in the paper ///
"The Gender Diversity Gaps in Mathematics" written by Francine Montecinos. ///
In certain cases, these results will require the estout, reghdfe, twang, and ///
other commands.   
*_______________________________________________________________________________

*-------------------------------------------------------------------------------
* 0. Preamble
*-------------------------------------------------------------------------------

clear all
set more off
capture log close
graph set window fontface "Times New Roman"
set matsize 11000
set seed 123

// Replace the following directory with your own replication package folder 
global DIR "C:\Users\aoimo\Dropbox\PROJECT_Gender_Diversity_Gaps\replication_package" 

*-------------------------------------------------------------------------------
* 1. Directories and Log 
*-------------------------------------------------------------------------------

global code "$DIR/code"
global data "$DIR/data"
global results "$DIR/results"
cap mkdir $results
global figures "$DIR/figures"
cap mkdir $figures
global tables "$DIR/tables"
cap mkdir $tables
global LOG "$DIR/log"
cap mkdir $LOG

global src 	"$data/src"
global tmp 	"$data/tmp"
global dta "$data/dta"
global proc 

cd "$tmp"

// Adopath 
adopath ++ "$code/stata/helpers"  // Remember to deactivate it after running all the code :) 

// Set scheme 
which scheme-bluegray_tnr.scheme
discard
set scheme bluegray_tnr

*-------------------------------------------------------------------------------
* 2. Codes + Globals 
*-------------------------------------------------------------------------------

* Globals to run regressions.
global genders "cis_woman trans_woman trans_man nb_male nb_female"
global demographics "imr edad_alu edad_alu2 i.income_decile i.mother_education_cat immigrant_parents indigenous_parents school_change"
global final_controls "$demographics math_norm_4to math_confidence_4to dependencia4* prom_gral4 asistencia4"
global final_covs "imr edad_alu edad_alu2 income_decile mother_education_cat mother_education_cat_1 mother_education_cat_2 mother_education_cat_3 mother_education_cat_4 mother_education_cat_5 mother_education_cat_6 mother_education_cat_7 mother_education_cat_8 immigrant_parents indigenous_parents school_change math_norm_4to math_confidence_4to asistencia4 prom_gral4 dependencia4_1 dependencia4_2 dependencia4_3"

/*

* Data Construction 
do "$code/stata/1_data_construction.do"

qui {
noisily: dis "====================================================="
noisily: dis "Stop Here." 
noisily: dis "Run code/R/01_ps_gbm.R"
noisily: dis "====================================================="	
noisily: dis as err "After running the R code, select all the code below and run"
}

* Final Dataset 
do "$code/stata/1a_final_dataset.do"

* Descriptives 
do "$code/stata/2_descriptives.do"

* Main Results
do "$code/stata/3_results.do"

* Mechanisms
do "$code/stata/4_mechanisms.do"

* Robustness Checks 
global final_covs "imr edad_alu edad_alu2 income_decile mother_education_cat mother_education_cat immigrant_parents indigenous_parents school_change math_norm_4to math_confidence_4to asistencia4 prom_gral4 dependencia4_1 dependencia4_2 dependencia4_3"

do "$code/stata/5_robustness.do"

* Appendix: Selection Correction 
global demographics "edad_alu edad_alu2 i.income_decile i.mother_education_cat immigrant_parents indigenous_parents school_change"

do "$code/stata/6_selection.do"

adopath - "$code/stata/helpers"     // remove from search path