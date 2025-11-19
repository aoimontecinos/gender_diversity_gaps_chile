use "$data/proc/simce_mineduc_elsoc_2022_full", clear 


global demographics edad_alu edad_alu2 immigrant_mother school_change i.income_decile i.mother_education_cat 

global final_controls "$demographics math_norm_4to math_confidence_4to"
					 
gen rbd_4to_nomissing = rbd_4to!=.
gen math_norm_4to_nomissing = math_norm_4to!=.
gen math_confidence_4to_nomissing = math_confidence_4to!=.

label var final_sample "Share in Final Sample" 
label var rbd_repitente_out "Leave-One-Out Grade Repetition Rate"
binscatter final_sample rbd_repitente_out, nq(50) ylabel(.5(.1).8) ///
ytitle("Share in Final Sample") xtitle("Leave-One-Out Grade Repetition Rate")
graph export "$figures/binsreg_final_sample_rbd_repitente_out.pdf", replace


hist rbd_repitente_out, percent
graph export "$figures/hist_rbd_repitente_out.pdf", replace

// Regression on outcomes
reghdfe math_norm math_confidence_2do $final_controls i.gender 
keep if e(sample)

eststo clear 
eststo m1: reghdfe math_norm rbd_repitente_out  $final_controls , absorb(rbd)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

eststo m2: reghdfe math_confidence_2do rbd_repitente_out  $final_controls if final_sample==1, absorb(rbd)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

esttab m1 m2 using "$tables/reg_selection_math_norm_rbd_repitente_out.tex", /// 
nobase noobs mtitle("10th grade Mathematics Score" "10th grade Mathematics Confidence") ///
collabels(none) label replace nonotes nodepvar booktabs ///
s(fixeds icontrols school4 r2 N, fmt( %12.0f %12.0f %12.0f a2  %12.0f) ///
label("School FE" "Demographics" "4th grade Math" "R-Squared" "Observations")) ///
 b(3) se(3) star(* 0.1 ** 0.05 *** 0.01)
 
 
// Regression on each control  
global demographics edad_alu edad_alu2 immigrant_mother school_change income_decile mother_education_cat 

global final_controls "$demographics math_norm_4to math_confidence_4to"

eststo clear 
foreach var of varlist $final_controls {
	eststo: reghdfe `var' rbd_repitente_out, absorb(rbd)
}
 
coefplot est1 est2 est3 est*, drop(_cons) label
 