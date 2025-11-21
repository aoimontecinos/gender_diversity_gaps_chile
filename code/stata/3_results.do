*______________________________________________________________
* Author: Francine Montecinos
* Last edition: November 19, 2025
* Action: Main Regressions for gender gaps in math
*______________________________________________________________
clear all
set more off

use "$data/proc/main.dta", clear

gen interaction = .
label var interaction "Interaction"

gen w0 = 1 

gen ps1 = 1/w1 
gen ps2 = 1/w2

*--------------------------------------------------------------------
* Tables 1, 2, and 3: Main Regressions.
*--------------------------------------------------------------------
* Table 1: Math scores gender gap.

foreach wx of varlist w0 w1 w2 {
eststo m0: qui reghdfe math_norm $genders [pw = `wx'], vce(cl codigocurso)
qui estadd local fixeds "", replace 
qui estadd local icontrols " ", replace 
qui estadd local school4 " ", replace 

eststo m1: qui reghdfe math_norm $genders [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols " ", replace 
qui estadd local school4 " ", replace 

eststo m2: qui reghdfe math_norm $genders imr [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols " ", replace 
qui estadd local school4 " ", replace 

eststo m3: qui reghdfe math_norm $genders ${demographics} [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 " ", replace 

eststo m4: qui reghdfe math_norm $genders ${final_controls} [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

esttab m0 m1 m2 m3 m4 using "$tables/reg1_`wx'.tex", ///
 b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) keep($genders imr) ///
mgroups("10th grade Mathematics Score", pattern (1 0 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
noobs nomtitles collabels(none) label replace nonotes nodepvar booktabs ///
s(fixeds icontrols school4 r2 N, fmt( %12.0f %12.0f %12.0f a2  %12.0f) ///
label("School FE" "Demographics" "4th grade Math" "R-Squared" "Observations")) 

}

* Table 2: Math confidence gender gap.
foreach wx of varlist w0 w1 w2 {

eststo m0: qui reghdfe math_confidence_2do $genders [pw = `wx'], ///
vce(cl codigocurso)
qui estadd local fixeds " ", replace 
qui estadd local icontrols " ", replace 
qui estadd local school4 " ", replace 
qui estadd local gpa " ", replace 

eststo m1: qui reghdfe math_confidence_2do $genders math_norm [pw = `wx'], ///
vce(cl codigocurso)
qui estadd local fixeds " ", replace 
qui estadd local icontrols " ", replace 
qui estadd local school4 " ", replace 

eststo m2: qui reghdfe math_confidence_2do $genders math_norm [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols " ", replace 
qui estadd local school4 " ", replace 

eststo m3: qui reghdfe math_confidence_2do $genders math_norm imr [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols " ", replace 
qui estadd local school4 " ", replace 

eststo m4: qui reghdfe math_confidence_2do $genders math_norm ///
${demographics} [pw = `wx'], absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 " ", replace 

eststo m5: qui reghdfe math_confidence_2do $genders math_norm ///
 ${final_controls} [pw = `wx'], absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

esttab m0 m1 m2 m3 m4 m5 using "$tables/reg2_`wx'.tex", ///
 b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) keep($genders imr math_norm) ///
mgroups("10th grade Mathematics Confidence", pattern (1 0 0 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
noobs nomtitles collabels(none) label replace nonotes nodepvar booktabs ///
s(fixeds icontrols school4 r2 N, fmt( %12.0f %12.0f %12.0f a2  %12.0f) ///
label("School FE" "Demographics" "4th grade Math" "R-Squared" "Observations")) 

}

* Table 3: Math scores gender gap by quantile.
eststo clear
mmqreg math_norm ${genders} ${final_controls}, ///
absorb(rbd) nols quantile(10 30 50 70 90 95) cluster(codigocurso)

outreg2 using "$tables/qreg1.tex", label replace dec(3) drop($final_controls)

mmqreg math_norm ${genders} ${final_controls} [aw = w2], ///
absorb(rbd) nols quantile(10 30 50 70 90 95) cluster(codigocurso)

outreg2 using "$tables/qreg1_w2.tex", label replace dec(3) drop($final_controls)


*______________________________________________________________
* Figures 
*______________________________________________________________

*----------------------------------------------------
* Quantile Regression
*----------------------------------------------------
cap gen w0 = 1

forv i = 1/9{
qui: mmqreg math_norm ${genders} ${final_controls} [aw = w0], ///
absorb(rbd) nols quantile(`i'0) cluster(codigocurso)
estimates store q`i'0 	
}

coefplot ///
	(q10, label("10th") color(midblue%30) ciopts(color(ebblue%30))) ///
	(q20, label("20th") color(midblue%38) ciopts(color(ebblue%38))) ///
	(q30, label("30th") color(midblue%46) ciopts(color(ebblue%46))) ///
	(q40, label("40th") color(midblue%54) ciopts(color(ebblue%54))) ///
	(q50, label("50th") color(midblue%62) ciopts(color(ebblue%62))) ///
	(q60, label("60th") color(midblue%70) ciopts(color(ebblue%70))) ///
	(q70, label("70th") color(midblue%78) ciopts(color(ebblue%78))) ///
	(q80, label("80th") color(midblue%86) ciopts(color(ebblue%86))) ///
	(q90, label("90th") color(midblue%100) ciopts(color(ebblue%100))), ///
    keep(${genders}) ///
    xline(0) ///
    xtitle("Gender") ///
    ytitle("Math Scores Gap compared to Cis boys") ///
    legend(position(bottom) row(1) size(small) title("") ///
           label(1 "10th" 2 "20th" 3 "30th" 4 "40th" 5 "50th" 6 "60th" 7 "70th" 8 "80th" 9 "90th")) ///
    ciopts(recast(rcap) lwidth(*0.5)) ///	
    msymbol(O) ///
    vertical ///
    swapnames ///
	xscale(range(0 10)) ///
    eqlabels(" " " " " " " " " ", labsize(tiny) labcolor(white)) ///
    xlabel(0 "." 1 "Cis girls" 3 "Trans girls" 5 "Trans boys" ///
	7 "NB AMABs" 9 "NB AFABs" 10 ".", angle(45)) ///
    xtitle("") yline(0, lpattern(dash)) ///
    ylabel(-0.3(0.1)0.3)

graph export "$figures/quantile_regression.pdf", replace
