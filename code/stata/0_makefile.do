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

if c(username)=="aoimo"	    global dropbox ///
"C:/Users/aoimo/Dropbox/Universidad/Tesis"
if c(username)=="fam2175"	global dropbox ///
"/Users/fam2175/Library/CloudStorage/Dropbox/Universidad/Tesis"

*-------------------------------------------------------------------------------
* 1. Directories and Log 
*-------------------------------------------------------------------------------

global DIR "$dropbox"
global code "$DIR/transgender_chile/code"
global data "$DIR/data"
global LOG "$DIR/log"
cap mkdir $LOG
global results "$DIR/results"
cap mkdir $results
global figures "$DIR/figures"
cap mkdir $figures
global tables "$DIR/tables"
cap mkdir $tables

global src 	"$data/src"
global tmp 	"$data/tmp"
global dta "$data/dta"
global proc 

cd "$tmp"

// Adopath 
adopath ++ "$code/ado_files"  // Remember to deactivate it after running all the code :) 

// Set scheme 
which scheme-bluegray_tnr.scheme
discard
set scheme bluegray_tnr

// adopath - "$code/ado_files"     // remove from search path

// ssc install rcall
ssc install rsource
*-------------------------------------------------------------------------------
* 2. Codes + Globals 
*-------------------------------------------------------------------------------

* Globals to run regressions.
global genders "cis_woman trans_woman trans_man nb_male nb_female"
global demographics "imr edad_alu edad_alu2 i.income_decile i.mother_education_cat immigrant_parents indigenous_parents school_change"
global final_controls "$demographics math_norm_4to math_confidence_4to dependencia4* prom_gral4_norm asistencia4_norm"

* Data Construction 
do "$code/1_data_construction.do"
// run R code 

* Descriptives 
do "$code/2_descriptives.do"

* Main Results
do "$code/3_results.do"

* Mechanisms
do "$code/4_mechanisms.do"

* Robustness Checks 
do "$code/5_robustness.do"

* Appendix: Selection Correction 
do "$code/6_selection.do"
