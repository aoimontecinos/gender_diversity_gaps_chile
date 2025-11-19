rsource using "$code/R/01_ps_gbm.r"

*--------------------------------------------------------
* FINAL DATASET 
*--------------------------------------------------------
* Load Data
use "$data/proc/simce_mineduc_elsoc_2022a", clear
merge n:1 mrun using "$tmp/simce_mineduc_elsoc_2022_psm.dta", nogen ///
keepusing(w1 w2) keep(master match)

* Globals to run regressions.
global genders "cis_woman trans_woman trans_man nb_male nb_female"
global demographics "imr edad_alu edad_alu2 i.income_decile i.mother_education_cat immigrant_parents indigenous_parents school_change"
global final_controls "$demographics math_norm_4to math_confidence_4to dependencia4* prom_gral4_norm asistencia4_norm"

// Sample selection
qui reghdfe math_confidence_2do $genders w1 w2 math_norm $final_controls
keep if e(sample)

// Save new dataset
save "$tmp/simce_mineduc_elsoc_2022b", replace