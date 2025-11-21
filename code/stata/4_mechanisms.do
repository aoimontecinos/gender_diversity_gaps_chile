*______________________________________________________________
* Author: Francine Montecinos
* Last edition: October 27, 2025
* Action: Potential Mechanisms + Heterogeneity
*______________________________________________________________
use "$data/proc/main.dta", clear
gen w0 = 1

*___________________________________________________*
* 1. Aggressions and Discrimination 
*___________________________________________________*
label var physical "Physical" 
label var verbal "Verbal"
label var social "Social"
label var media "Social Media"

label var discr_sexo "Sex"
label var discr_orien "Sexual Orientation"
label var discr_expresion "Expression or Looks"

*------------------------
* Differences by gender 
*------------------------

reghdfe physical verbal social media discr* 
gen agg_discr_sample = e(sample)


preserve 
keep if agg_discr_sample
eststo clear
local i = 0
foreach var of varlist physical verbal social media discr* {
	local ++i
	eststo m`i': reghdfe `var' $genders $final_controls, absorb(rbd)
	qui estadd local fixeds "$ \checkmark $", replace 
	qui estadd local icontrols "$ \checkmark $", replace 
	qui estadd local school4 "$ \checkmark $", replace 
}
restore 

esttab m* using "$tables/first_agg_discr.tex", ///
label replace keep($genders) b(3) se(3)  ///
star(* 0.1 ** 0.05 *** 0.01) nonotes booktabs ///
mgroups("Aggression" "Discrimination", pattern (1 0 0 0 1 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
s(fixeds icontrols school4 r2 N, fmt( %12.0f %12.0f %12.0f a2  %12.0f) ///
label("School FE" "Demographics" "4th grade Math" "R-Squared" "Observations")) 

*-----------------------
* Mechanisms on Scores
*------------------------

preserve
foreach wx of varlist w0 w1 w2 { 
foreach var of varlist physical verbal social media discr*{	
	keep if `var'!=.
}
qui {
reg math_norm $genders 
local cismen_mean = e(b)[1,6]

eststo m0: reghdfe math_norm $genders $final_controls  [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
local cw_init =  e(b)[1,1]
local tw_init =  e(b)[1,2]
local tm_init =  e(b)[1,3]
local nbm_init =  e(b)[1,4]
local nbf_init =  e(b)[1,5]

eststo m1: reghdfe math_norm $genders $final_controls physical verbal [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m2: reghdfe math_norm $genders $final_controls social media [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m3: reghdfe math_norm $genders $final_controls discr_sexo [pw = `wx'] ///
, absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m4: reghdfe math_norm $genders $final_controls discr_orien [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 

eststo m5: reghdfe math_norm $genders $final_controls discr_expr [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 

eststo m6: reghdfe math_norm $genders $final_controls ///
physical verbal social media discr_sexo discr_orien discr_expr [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 
}
esttab m0 m1 m2 m3 m4 m5 m6 using ///
"$tables/mech_agg_discr_scores_`wx'.tex",  keep($genders *agg* discr*) ///
mgroups("10th grade Mathematics Score", pattern (1 0 0 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) mtitles("Baseline" ///
"Aggr: Visible" "Aggr: Social" "Discr: Sex" ///
 "Discr: Orien." "Discr: Expr." "All") label replace nonotes ///
stats(cm_mean cw_pc tw_pc tm_pc nbm_pc nbf_pc r2 N, ///
fmt(%9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %12.0f) ///
labels(`"Cis boys mean"' `"Cis girls gap variation"' `"Trans girls gap variation"' ///
`"Trans boys gap variation"' `"NB AMABs gap variation"' `"NB AFABs gap variation"' ///
`"R-squared"' `"Observations"' ))
}
restore 

* Small Figure about this 
coefplot (m0, offset(0) color(midblue%50)) ///
(m6, offset(0) color(red%50)), ///
keep($genders) recast(bar) vertical noci ///
legend(order(1 "Baseline" 2 "Controlling for Discrimination and Aggressions") ///
 pos(12) row(1) size(medsmall)) xtitle(,size(medsmall)) ///
ylabel(-.2(.05)0) ytitle("10th grade Mathematics Score Gap", size(medsmall))

graph export "$figures/math_norm_discr_aggr_mech.pdf", replace

*-----------------------------------------
* Mechanisms on Confidence
*------------------------------------------

preserve
foreach wx of varlist w0 w1 w2 { 
foreach var of varlist physical verbal social media discr*{	
	keep if `var'!=.
}
qui {
reg math_norm $genders 
local cismen_mean = e(b)[1,6]

eststo m0: reghdfe math_confidence_2do $genders math_norm $final_controls  [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
local cw_init =  e(b)[1,1]
local tw_init =  e(b)[1,2]
local tm_init =  e(b)[1,3]
local nbm_init =  e(b)[1,4]
local nbf_init =  e(b)[1,5]

eststo m1: reghdfe math_confidence_2do $genders math_norm $final_controls physical verbal [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m2: reghdfe math_confidence_2do $genders math_norm $final_controls social media [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m3: reghdfe math_confidence_2do $genders math_norm $final_controls discr_sexo [pw = `wx'] ///
, absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m4: reghdfe math_confidence_2do $genders math_norm $final_controls discr_orien [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 

eststo m5: reghdfe math_confidence_2do $genders math_norm $final_controls discr_expr [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 

eststo m6: reghdfe math_confidence_2do $genders math_norm $final_controls ///
physical verbal social media discr_sexo discr_orien discr_expr [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 
}
*esttab m0 m1 m2 m3 m4 m5 m6 using ///
"$tables/mech_agg_discr_confidence_`wx'.tex",  keep($genders math_norm *agg* discr*) ///
mgroups("10th grade Mathematics Confidence", pattern (1 0 0 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) mtitles("Baseline" ///
"Aggr: Visible" "Aggr: Social" "Discr: Sex" ///
 "Discr: Orien." "Discr: Expr." "All") label replace nonotes ///
stats(cm_mean cw_pc tw_pc tm_pc nbm_pc nbf_pc r2 N, ///
fmt(%9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %12.0f) ///
labels(`"Cis boys mean"' `"Cis girls gap variation"' `"Trans girls gap variation"' ///
`"Trans boys gap variation"' `"NB AMABs gap variation"' `"NB AFABs gap variation"' ///
`"R-squared"' `"Observations"' ))
}
restore 

* Small Figure about this 
qui {
cap drop math_confidence_aux
gen math_confidence_aux = - math_confidence_2do	
	
eststo m0: reghdfe math_confidence_aux $genders math_norm $final_controls  [pw = w2], ///
absorb(rbd) vce(cl codigocurso)

eststo m6: reghdfe math_confidence_aux $genders math_norm $final_controls ///
social media discr_sexo discr_orien discr_expr [pw = w2], ///
absorb(rbd) vce(cl codigocurso)
cap drop math_confidence_aux
}


coefplot (m0, offset(0) color(midblue) noci) ///
(m6, offset(0) color(cranberry*.9) noci), citop ciopts(recast(rcap)) ///
keep($genders) recast(bar)   barwidth(0.5) ///
legend(order(1 "Baseline" 2 "Controlling for Discrimination + Social and Cyber Aggressions") ///
 pos(12) row(2) size(medsmall)) xtitle(,size(medsmall)) ///
xlabel(0(.05).2) xtitle("10th grade Mathematics Confidence Gap", size(medsmall))

graph export "$figures/math_confidence_discr_aggr_mech.pdf", replace

*___________________________________________________*
* 2. Heterogeneity by School 
*___________________________________________________*


eststo m1: qui reghdfe math_norm $genders $final_controls [pw = w2] ///
if rbd_religious==0, absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

eststo m2: qui reghdfe math_norm $genders $final_controls [pw = w2] ///
if rbd_religious==1, absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

eststo m3: qui reghdfe math_confidence_2do math_norm ///
$genders $final_controls [pw = w2] if rbd_religious==0, ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

eststo m4: qui reghdfe math_confidence_2do math_norm ///
$genders $final_controls [pw = w2] if rbd_religious==1, ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 


esttab m1 m2 m3 m4 using "$tables/heterogeneity_religious_school.tex", ///
b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) keep($genders math_norm) ///
mgroups("Mathematics Score" "Mathematics Confidence", pattern (1 0 1 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
noobs collabels(none) label replace nonotes nodepvar booktabs ///
mtitles("Regular Program" "Religious Program" ///
"Regular Program" "Religious Program") ///
s(fixeds icontrols school4 r2 N, fmt( %12.0f %12.0f %12.0f a2  %12.0f) ///
label("School FE" "Demographics" "4th grade Math" "R-Squared" "Observations")) 

*___________________________________________________*
* 3. OB Decomposition
*___________________________________________________*

// Residualize outcomes 
global genders "cis_woman trans_woman trans_man nb_male nb_female"
global demographics "imr edad_alu edad_alu2 i.income_decile i.mother_education_cat immigrant_mother school_change"
global final_controls "$demographics math_norm_4to math_confidence_4to"
reghdfe math_norm $final_controls, absorb(rbd) resid
predict math_norm_res, resid

reghdfe math_confidence_2do math_norm $final_controls, absorb(rbd) resid
predict math_confidence_res, resid

// Final controls list 
global final_controls_list "edad_alu edad_alu2 income_decile mother_education immigrant_mother school_change math_norm_4to math_confidence_4to"

// Residualize mechanisms 
foreach var of varlist physical verbal social media discr_* {
qui reghdfe `var' $final_controls, absorb(rbd) resid
predict res1_`var', resid

reghdfe `var' math_norm $final_controls, absorb(rbd) resid
predict res2_`var', resid
}

* Oaxaca blinder variables  
foreach var of varlist $genders{ 
	gen `var'_oaxaca = `var' if `var'==1|cis_man==1
}

* Keep final list 
keep cis_man $genders gender $final_controls_list mother_education ///
rbd math* verbal physical social media discr* ///
w1 w2 codigocurso mrun imr res* *res *oaxaca *rel*

gen w0 = 1
svyset mrun [pw = w2]

// Math scores 
eststo clear
foreach name in $genders{
eststo: oaxaca math_norm_res ///
(Discrimination: res1*discr*) ///
(Social and Cyber Aggressions: res1*social_agg* res1*media_agg*) ///
(Physical and Verbal Aggressions: res1*physical_agg* res1*verbal_agg*), ///
by(`name'_oaxaca) svy
}
esttab, se(3) b(3) star(* 0.1 ** 0.05 *** 0.01)

esttab using "$tables/robustness_oaxaca_math_norm_within_rbd.tex", ///
b(3) se(3) nodepvar star(* 0.1 ** 0.05 *** 0.01) booktabs nonotes ///
mgroups("10th grade Mathematics Score", pattern (1 0 0 0 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
mtitles("Cis girls" "Trans girls" "Trans boys" "NB AMABs" "NB AFABs") label replace


// Math confidence

eststo clear
foreach name in $genders{
eststo: oaxaca math_confidence_res ///
(Discrimination: res2*discr*) ///
(Social and Cyber Aggressions: res2*social_agg* res2*media_agg*) ///
(Physical and Verbal Aggressions: res2*physical_agg* res2*verbal_agg*), ///
by(`name'_oaxaca) svy nodefinitions noheader 
}
esttab, se(3) b(3) star(* 0.1 ** 0.05 *** 0.01)

esttab using "$tables/robustness_oaxaca_math_confidence_within_rbd.tex", ///
b(3) se(3) nodepvar star(* 0.1 ** 0.05 *** 0.01) booktabs nonotes ///
mgroups("10th grade Mathematics Confidence", pattern (1 0 0 0 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
mtitles("Cis girls" "Trans girls" "Trans boys" "NB AMABs" "NB AFABs") label replace


*-----------------------------------------------------------------
* Collect decomposition results for math confidence
*-----------------------------------------------------------------
matrix results_conf = J(5, 4, .)
matrix colnames results_conf = "valueTotal" "valueEndowments" "valueCoefficients" "valueInteraction"  

local i = 1
foreach name in $genders {
    qui oaxaca math_confidence_res ///
    (Discrimination_Social: res2*discr* res2*social_agg* res2*media_agg*), ///
    by(`name'_oaxaca) svy
	ereturn list
    matrix b = e(b)
    matrix results_conf[`i', 1] = b[1,3]  // Total gap
    matrix results_conf[`i', 2] = b[1,4]  // Endowments
    matrix results_conf[`i', 3] = b[1,9]  // Coefficients in Constant
    matrix results_conf[`i', 4] = b[1,8]  // Interaction and Coefficients in Discr 
    local i = `i' + 1
}

preserve 
* Convert and graph math confidence results
clear
svmat results_conf, names(col)

gen gender = _n 

label define gndr 1 "Cis girls" 2 "Trans girls" 3 "Trans boys" 4 "NB AMABs" 5 "NB AFABs", replace
label values gender gndr

reshape long value, i(gender) j(component) string

drop if comp=="Total"

graph hbar (asis) value, over(comp, label(labsize(small))) over(gender) ///
    stack asyvars ///
    ytitle("Mathematics Confidence Gap (10th grade)") ///
    legend(pos(12) rows(3) col(1) ///
    label(1 "Coefficients in Constant Terms (Unexplained)") ///
    label(2 "Endowments in Discrimination + Social and Cyber Aggressions") ///
    label(3 "Coefficients in Discrimination + Social and Cyber Aggressions")) ///
    bar(1, color(cranberry*0.7)) ///
	bar(2, color(midblue*0.8)) ///
	bar(3, color(midgreen*0.8)) ///
	aspectratio(0.55) ///
	
restore 
graph export "$figures/oaxaca_confidence_decomposition.pdf", replace


