*--------------------------------------------------------
* FINAL DATASET 
*--------------------------------------------------------
* Load Data
use "$data/proc/simce_mineduc_elsoc_2022b", clear
merge n:1 mrun using "$tmp/simce_mineduc_elsoc_2022_psm.dta", nogen ///
keepusing(w1 w2) keep(master match)

// Sample selection
qui reghdfe math_confidence_2do $genders w1 w2 math_norm $final_controls
keep if e(sample)

winsor2 w1 w2, replace cuts(1 99)

// Save new dataset
save "$data/proc/main.dta", replace