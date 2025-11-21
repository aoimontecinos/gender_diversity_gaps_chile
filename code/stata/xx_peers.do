*--------------------------------------------------------------------
* Table 4, 5 and 6: Peers and Teacher. 
*--------------------------------------------------------------------
// Manipulation 
cap drop young_teacher
gen young_teacher = 1 if edad_prof<=40
replace young_teacher = 0 if edad_prof>40 & edad_prof!=.
label var young_teacher "Young Teacher"
label var peers_sex_alu "Female Peers"
label var peers_trans "Trans or NB Peers"
label var fem_peers_math "Female peers Math Score"
label var sex_prof "Female Teacher"
label var edad_prof "Teacher's Age"


*----------------------------------------
* Differences on the variables by gender
*----------------------------------------

reghdfe sex_prof young_teacher peers_sex_alu peers_trans fem_peers_math 
gen peers_teacher_sample = e(sample)

preserve 
keep if peers_teacher_sample
eststo m1: reghdfe sex_prof $genders $final_controls, absorb(rbd)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 
eststo m2: reghdfe edad_prof $genders $final_controls, absorb(rbd)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 
eststo m3: reghdfe peers_sex_alu $genders $final_controls, absorb(rbd)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 
eststo m4: reghdfe peers_trans $genders $final_controls, absorb(rbd)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 
eststo m5: reghdfe fem_peers_math $genders $final_controls, absorb(rbd)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

esttab m1 m2 m3 m4 m5 using "$tables/first_peers_teacher.tex", ///
label replace keep($genders) b(3) se(3)  ///
star(* 0.1 ** 0.05 *** 0.01) nonotes booktabs ///
s(fixeds icontrols school4 r2 N, fmt( %12.0f %12.0f %12.0f a2  %12.0f) ///
label("School FE" "Demographics" "4th grade Math" "R-Squared" "Observations")) 
restore 


preserve 
keep if peers_teacher_sample
eststo m1: reghdfe sex_prof $genders $final_controls
qui estadd local fixeds "", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 
eststo m2: reghdfe edad_prof $genders $final_controls
qui estadd local fixeds "", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 
eststo m3: reghdfe peers_sex_alu $genders $final_controls
qui estadd local fixeds "", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 
eststo m4: reghdfe peers_trans $genders $final_controls
qui estadd local fixeds "", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 
eststo m5: reghdfe fem_peers_math $genders $final_controls
qui estadd local fixeds "", replace 
qui estadd local icontrols "$ \checkmark $", replace 
qui estadd local school4 "$ \checkmark $", replace 

esttab m1 m2 m3 m4 m5 using "$tables/first_peers_teacher_nofe.tex", ///
label replace keep($genders) b(3) se(3)  ///
star(* 0.1 ** 0.05 *** 0.01) nonotes booktabs ///
s(fixeds icontrols school4 r2 N, fmt( %12.0f %12.0f %12.0f a2  %12.0f) ///
label("School FE" "Demographics" "4th grade Math" "R-Squared" "Observations")) 
restore 



*--------------------------------------
* Mechanisms on scores 
*--------------------------------------

preserve
foreach wx of varlist w0 w1 w2 { 
keep if peers_teacher_sample
qui {
reg math_norm $genders 
local cismen_mean = e(b)[1,6]

eststo m0: reghdfe math_norm $genders $final_controls  [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
local cw_init =  e(b)[1,1]
local tw_init =  e(b)[1,2]
local tm_init =  e(b)[1,3]
local nbm_init =  e(b)[1,4]
local nbf_init =  e(b)[1,5]

eststo m1: reghdfe math_norm $genders $final_controls peers_se [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m2: reghdfe math_norm $genders $final_controls peers_tr [pw = `wx'], ///
absorb(rbd) vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m3: reghdfe math_norm $genders $final_controls fem*math* [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m4: reghdfe math_norm $genders $final_controls edad_prof [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 

eststo m5: reghdfe math_norm $genders $final_controls sex_prof [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 

eststo m6: reghdfe math_norm $genders $final_controls ///
peers_se* peers_tr fem*math* edad_prof sex_prof [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 
}
esttab m0 m1 m2 m3 m4 m5 m6 using ///
"$tables/mech_peers_teacher_scores_`wx'.tex", keep($genders ///
peers_se* peers_tr* fem*math* edad_prof sex_prof) booktabs ///
b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) nonotes ///
mgroups("10th grade Mathematics Score", pattern (1 0 0 0 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
mtitles("Baseline" "Women Peers" "Trans or NB Peers" "Female Peers Math Score" ///
 "Teacher Age" "Teacher Sex" "All") label replace ///
stats(cm_mean cw_pc tw_pc tm_pc nbm_pc nbf_pc r2 N, ///
fmt(%9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %12.0f) ///
labels(`"Cis boys mean"' `"Cis girls gap variation"' `"Trans girls gap variation"' ///
`"Trans boys gap variation"' `"NB AMABs gap variation"' `"NB AFABs gap variation"' ///
`"R-squared"' `"Observations"' ))
}
restore 

*-------------------------------------------------
* Mechanisms on Math Confidence 
*-------------------------------------------------

preserve
foreach wx of varlist w0 w1 w2 { 
keep if peers_teacher_sample
qui {
reg math_confidence_2do $genders 
local cismen_mean = e(b)[1,6]

eststo m0: reghdfe math_confidence_2do  $genders math_norm $final_controls  [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
local cw_init =  e(b)[1,1]
local tw_init =  e(b)[1,2]
local tm_init =  e(b)[1,3]
local nbm_init =  e(b)[1,4]
local nbf_init =  e(b)[1,5]

eststo m1: reghdfe math_confidence_2do  $genders math_norm $final_controls peers_se [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m2: reghdfe math_confidence_2do  $genders math_norm $final_controls peers_tr [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m3: reghdfe math_confidence_2do  $genders math_norm $final_controls fem*math* [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 


eststo m4: reghdfe math_confidence_2do  $genders math_norm $final_controls edad_prof [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 

eststo m5: reghdfe math_confidence_2do  $genders math_norm $final_controls sex_prof [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 

eststo m6: reghdfe math_confidence_2do  $genders math_norm $final_controls ///
peers_se* peers_tr fem*math* edad_prof sex_prof [pw = `wx'], ///
vce(cl codigocurso)
estadd scalar cm_mean = `cismen_mean'
estadd scalar cw_pc = e(b)[1,1] - `cw_init'
estadd scalar tw_pc = e(b)[1,2]-`tw_init' 
estadd scalar tm_pc = e(b)[1,3]-`tm_init' 
estadd scalar nbm_pc = e(b)[1,4]-`nbm_init'
estadd scalar nbf_pc = e(b)[1,5]-`nbf_init' 
}
esttab m0 m1 m2 m3 m4 m5 m6 using ///
"$tables/mech_peers_teacher_confidence_`wx'.tex", keep($genders ///
peers_se* peers_tr* fem*math* edad_prof sex_prof math_norm) booktabs ///
b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) nonotes ///
mgroups("10th grade Mathematics Confidence", pattern (1 0 0 0 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
mtitles("Baseline" "Women Peers" "Trans or NB Peers" "Female Peers Math Score" ///
 "Teacher Age" "Teacher Sex" "All") label replace ///
stats(cm_mean cw_pc tw_pc tm_pc nbm_pc nbf_pc r2 N, ///
fmt(%9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %12.0f) ///
labels(`"Cis boys mean"' `"Cis girls gap variation"' `"Trans girls gap variation"' ///
`"Trans boys gap variation"' `"NB AMABs gap variation"' `"NB AFABs gap variation"' ///
`"R-squared"' `"Observations"' ))
}
restore 

