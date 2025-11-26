use "$data/proc/simce_mineduc_elsoc_2022_full", clear 
					 
gen rbd_4to_nomissing = rbd_4to!=.
gen math_norm_4to_nomissing = math_norm_4to!=.
gen math_confidence_4to_nomissing = math_confidence_4to!=.

label var final_sample "Share in Final Sample" 
label var rbd_not_sample_out "Leave-One-Out Non Response Rate"
binscatter final_sample rbd_not_sample_out, nq(50) ylabel(.4(.1).9) ///
ytitle("Share in Final Sample") xtitle("Leave-One-Out Non Response Rate")
graph export "$figures/binsreg_final_sample_rbd_not_sample_out.pdf", replace

reghdfe math_norm rbd_not_sample_out math_norm_4to if final_sample==1, absorb(rbd)

hist rbd_not_sample_out, percent
graph export "$figures/hist_rbd_not_sample_out.pdf", replace

// Regression on outcomes
use "$data/proc/main", clear 

reghdfe math_norm math_confidence_2do $final_controls i.gender w2
keep if e(sample)

eststo clear 
eststo m1: reghdfe math_norm rbd_not_sample_out math_norm_4to math_confidence_4to, absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

eststo m2: reghdfe math_confidence_2do rbd_not_sample_out math_norm_4to math_confidence_4to, absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 

esttab m1 m2 using "$tables/reg_selection_math_norm_rbd_not_sample_out.tex", /// 
nobase noobs mtitle("10th grade Mathematics Score" "10th grade Mathematics Confidence") ///
collabels(none) label replace nonotes nodepvar booktabs ///
s(fixeds r2 N, fmt( %12.0f a2  %12.0f) ///
label("School FE" "R-Squared" "Observations")) ///
 b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) drop(_cons)
 
