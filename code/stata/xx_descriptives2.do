set scheme stcolor

clear all
set more off

* Load Data
use "$data/proc/simce_mineduc_elsoc_2022a", clear
merge n:1 mrun using "$tmp/simce_mineduc_elsoc_2022_psm.dta", nogen ///
keepusing(w1 w2) keep(master match)

global genders "cis_woman trans_woman trans_man nb_male nb_female"
global demographics "imr edad_alu edad_alu2 i.income_decile i.mother_education immigrant_mother indigenous_mother school_change"
global mineduc_4to "asistencia4 dependencia4*"

global final_controls "$demographics $mineduc_4to math_norm_4to math_confidence_4to"

*---------------------------------------------------
* 1. Figures 
*---------------------------------------------------
// Raw gender gap in mathematics scores 
graph hbar math_norm, over(gender) aspectratio(0.45) bar(1,color(midblue)) ///
ytitle("Mean of standardized mathematics score") ylabel(-.1(.05).2)
graph export "$figures/descriptives_raw_gender_gap.pdf", replace

// Raw gender gap in mathematics confidence
graph hbar math_confidence_2do, over(gender) aspectratio(0.45) bar(1,color(midblue)) ///
ytitle("Mean of mathematics confidence") ylabel(0(.2).8) vert
// graph export "$figures/descriptives_raw_gender_gap.pdf", replace

eststo m1: reghdfe discr_sexo i.gender $final_controls, absorb(rbd)
eststo m2: reghdfe discr_orientacion i.gender $final_controls, absorb(rbd)
eststo m3: reghdfe discr_expr i.gender $final_controls, absorb(rbd)

coefplot (m1, mcolor(midblue) ciopts(color(midblue) recast(rcap))) ///
(m2, mcolor(red) ciopts(color(red) recast(rcap))) ///
(m3, mcolor(pink) ciopts(color(pink) recast(rcap))), ///
keep(*gender) ytitle(,size(medlarge)) ///
legend(order(1 "Sex" 3 "Sexual Orientation" 5 "Way of Dressing") ///
pos(6) row(1) size(medlarge)) ciopts(recast(rcap)) aspectratio(0.45)

graph export "$figures/descriptives_discrimination_gap.pdf", replace


eststo m1: reghdfe discr_sexo i.gender $final_controls, absorb(rbd)
eststo m2: reghdfe discr_orientacion i.gender $final_controls, absorb(rbd)
eststo m3: reghdfe discr_expr i.gender $final_controls, absorb(rbd)

coefplot (m1, mcolor(midblue) ciopts(color(midblue) recast(rcap))) ///
(m2, mcolor(red) ciopts(color(red) recast(rcap))) ///
(m3, mcolor(pink) ciopts(color(pink) recast(rcap))), ///
keep(*gender) ytitle(,size(medlarge)) ///
legend(order(1 "Sex" 3 "Sexual Orientation" 5 "Way of Dressing") ///
pos(6) row(1) size(medlarge)) ciopts(recast(rcap)) aspectratio(0.45)

graph export "$figures/descriptives_discrimination_gap.pdf", replace


eststo m1: reghdfe prom_gral2022 i.gender $final_controls prom_gral4, absorb(rbd)
eststo m2: reghdfe prom_gral4 i.gender $final_controls, absorb(rbd)

coefplot, keep(*gender)
 