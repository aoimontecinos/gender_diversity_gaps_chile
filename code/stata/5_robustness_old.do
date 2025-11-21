*______________________________________________________________
* Author: Francine Montecinos
* Last edition: November 19, 2025
* Action: Robustness Checks 
*______________________________________________________________

*______________________________________________________________
* 1. Exact Matching
*______________________________________________________________

use "$data/proc/main.dta", clear
keep mrun rbd codigocurso math* gender ${genders} $final_covs

// Create variables 
cap drop gen_dummy* pscore*
tabulate gender, gen(gen_dummy_)

// rbd fixed efffects
xtset rbd

// propensity scores (manual)
forv i = 1/6 {
	replace gen_dummy_`i' = . if gender!=`i' & gender!=1
	if `i'!=1 {
		xtlogit gen_dummy_`i' ${final_controls}
		predict pscore_`i'
	} 
}

// seed for replication
set seed 123

//labels (with spaces) and their dummy ids
local ids 2 3 4 5
local lab2 "Cis girls"
local lab3 "Trans girls"
local lab4 "Trans boys"
local lab5 "NB AMABs"
local lab6 "NB AFABs"

foreach outcome of varlist math_norm math_confidence_2do {
tempfile results
tempname pf
capture postclose `pf'
postfile `pf' str32 treat ///
    double b1 b2 b3 b4  ///
    double se1 se2 se3 se4  ///
    using "`results'", replace

	
foreach trnum of local ids {
    * init cells to missing (in case a j fails)
    forvalues j=1/4 {
        local b`j' = .
        local se`j' = .
    }

	if `trnum'==2 local reps_num = 10
	if `trnum'!=2 local reps_num = 100 

    forvalues j=1/4 {
        if `j'==1 {
            bootstrap r(att), reps(`reps_num') rseed(123) bca cluster(rbd): ///
			psmatch2 gen_dummy_`trnum', ties out(`outcome') pscore(pscore_`trnum')
        }
        else {
            bootstrap r(att), reps(`reps_num') rseed(123) bca cluster(rbd): ///
			psmatch2 gen_dummy_`trnum', n(`j') out(`outcome') pscore(pscore_`trnum')
           
        }

        * prefer BC; fallback to percentile if BC missing
        matrix ci = e(ci_bc)
        if missing(ci[1,1]) | missing(ci[2,1]) {
            matrix ci = e(ci_percentile)
        }

        scalar lb = ci[1,1]
        scalar ub = ci[2,1]
        scalar b_bc  = (lb + ub)/2
        scalar se_bc = (ub - lb)/(2*invnormal(0.975))

        local b`j'  = b_bc
        local se`j' = se_bc
		dis "`b`j'' (`se`j'')"
    }

    * get the pretty label for this trnum
    local tr = "`lab`trnum''"

    post `pf' ("`tr'") ///
        (`b1') (`b2') (`b3') (`b4') (`b5') ///
        (`se1') (`se2') (`se3') (`se4') (`se5')
}
postclose `pf'

preserve 
use "`results'", clear
list, noobs

*----- LaTeX with two rows per treatment (coef, then SEs)
if "`outcome'"=="math_norm" local var_name "Mathematics Score"
if "`outcome'"=="math_confidence_2do" local var_name "Mathematics Confidence"

file open fh using "$tables/psmatch2_robustness_`var_name'.tex", write replace text
file write fh "\begin{tabular}{lcccc}" _n
file write fh "\toprule" _n
file write fh "& \multicolumn{4}{c}{Dependent variable: 10th grade `var_name'} \\"
file write fh "& \multicolumn{4}{c}{Number of Nearest Neighbors} \\"
file write fh "Treatment & NN=1 & NN=2 & NN=3 & NN=4 \\" _n
file write fh "\midrule" _n

quietly forvalues r = 1/`=_N' {
    file write fh "`=treat[`r']'" " & " ///
        "`: display %6.3f b1[`r']'" " & " ///
        "`: display %6.3f b2[`r']'" " & " ///
        "`: display %6.3f b3[`r']'" " & " ///
        "`: display %6.3f b4[`r']'" " & " ///
        "`: display %6.3f b5[`r']'" " \\" _n

    file write fh " & " ///
        "(`: display %6.3f se1[`r']')" " & " ///
        "(`: display %6.3f se2[`r']')" " & " ///
        "(`: display %6.3f se3[`r']')" " & " ///
        "(`: display %6.3f se4[`r']')" " & " ///
        "(`: display %6.3f se5[`r']')" " \\\\" _n

    if `r' < `=_N' file write fh "\addlinespace" _n
}
file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file close fh
restore 
}

*______________________________________________________________
* 2. Changing Trans Samples
*______________________________________________________________

* Creating variables 
gen r_gender_1 = gender 
replace r_gender_1 = 5 if (cest_p01_2do==4|cest_p01_2do==5) & sex_alu==1
replace r_gender_1 = 6 if (cest_p01_2do==4|cest_p01_2do==5) & sex_alu==2
label values r_gender_1 gendr
gen r_gender_2 = cest_p01_2do if cest_p01_2do<=3
gen gender_diverse = 1 if gender==1 | gender==2
replace gender_diverse = 2 if gender>=3 & gender<=6
label define gender_diverse 1 "Cisgender" 2 "Trans or NB"
label values gender_diverse gender_diverse
gen trans_binary = 2 if gender==3 | gender==4
replace trans_binary = 1 if gender==1 | gender==2
label define trans_binary 1 "Cisgender" 2 "Binary Trans"
label values trans_binary trans_binary
label define r_gender_2 1 "Man" 2 "Woman" 3 "Other"
label values r_gender_2 r_gender_2


label var math_confidence_2do "10th Math Confidence"
label var social "Social"
label var media "Social Media"
label var discr_sex "Sex"
label var discr_orien "Sexual Orientation"
label var discr_expresion "Expression or Looks"


* NB Sample
eststo m1: qui reghdfe math_norm i.r_gender_1 $final_controls, ///
absorb(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local controls "$ \checkmark $", replace 

eststo m2: qui reghdfe math_confidence_2do i.r_gender_1 ${final_controls_confidence}, ///
abs(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local controls "$ \checkmark $", replace 

eststo m3: qui reghdfe social i.r_gender_1 ${final_controls}, ///
abs(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local controls "$ \checkmark $", replace 

eststo m4: qui reghdfe media i.r_gender_1 ${final_controls}, ///
abs(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local controls "$ \checkmark $", replace 

eststo m5: qui reghdfe discr_sex i.r_gender_1 ${final_controls}, ///
abs(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local controls "$ \checkmark $", replace 

eststo m6: qui reghdfe discr_orien i.r_gender_1 ${final_controls}, ///
abs(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local controls "$ \checkmark $", replace 

eststo m7: qui reghdfe discr_expr i.r_gender_1 ${final_controls}, ///
abs(rbd) vce(cl codigocurso)
qui estadd local fixeds "$ \checkmark $", replace 
qui estadd local controls "$ \checkmark $", replace 

mmqreg math_norm i.r_gender_1 ${final_controls}, ///
absorb(rbd) nols quantile(10 30 50 70 90 95)
outreg2 using "$tables/robust_qreg.tex", label replace

esttab m1 m2 m3 m4 m5 m6 m7 using "$tables/rob_nb_sample.tex", label replace ///
b(%5.3f) se(%5.3f) ty star(* 0.1 ** 0.05 *** 0.01) nobaselevels ///
mgroups("" "Aggression" "Discrimination", pattern (1 0 1 0 1 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
keep(*.r_gender_1) nogaps nonotes booktabs ///
s(fixeds controls N, fmt( %12.0f %12.0f %12.0f) ///
label("School FE" "Controls" "Observations"))

*------------------------------------
** Sex and gender interactions.
*------------------------------------

* Interaction model (comparing by sex, trans and nb)
eststo m1: reghdfe math_norm sex_alu##gender_diverse $final_controls, ///
absorb(rbd) vce(cl codigocurso)
eststo m1a: margins sex_alu, dydx(gender_diverse) post

* Interaction model (comparing by sex, only trans binary)
eststo m2: reghdfe math_norm sex_alu##gender_diverse $final_controls if ///
gender!=5 & gender!=6, ///
absorb(rbd) vce(cl codigocurso)
eststo m2a: margins sex_alu, dydx(gender_diverse) post

* Interaction model (comparing by sex, only non binary)
eststo m3: reghdfe math_norm sex_alu##gender_diverse $final_controls if ///
gender!=3 & gender!=4, ///
absorb(rbd) vce(cl codigocurso)
eststo m3a: margins sex_alu, dydx(gender_diverse) post

* Interaction model (comparing by sex, trans and nb)
eststo m4: reghdfe math_confidence_2do sex_alu##gender_diverse ///
$final_controls_confidence, absorb(rbd) vce(cl codigocurso)
eststo m4a: margins sex_alu, dydx(gender_diverse) post

* Interaction model (comparing by sex, only trans binary)
eststo m5: reghdfe math_confidence_2do sex_alu##gender_diverse ///
$final_controls_confidence if gender!=5 & gender!=6, ///
absorb(rbd) vce(cl codigocurso)
eststo m5a: margins sex_alu, dydx(gender_diverse) post

* Interaction model (comparing by sex, only non binary)
eststo m6: reghdfe math_confidence_2do sex_alu##gender_diverse ///
$final_controls_confidence if gender!=3 & gender!=4, ///
absorb(rbd) vce(cl codigocurso)
eststo m6a: margins sex_alu, dydx(gender_diverse) post

esttab m1 m2 m3 m4 m5 m6 m1a m2a m3a m4a m5a m6a using ///
"$tables/robust_ame.tex", label replace ///
b(%5.3f) se(%5.3f) ty star(* 0.1 ** 0.05 *** 0.01) ///
keep(2.gender_diverse:1.sex_alu 2.sex_alu 2.gender_diverse ///
2.sex_alu#2.gender_diverse) ///
mtitles("Model 1" "Model 2" "Model 3" "Model 1" "Model 2" "Model 3")

*______________________________________________________________
* 3. Categorical variables 
*______________________________________________________________
*------------------------------------------
* Math Confidence (Categorical)
*------------------------------------------
gen categorical_confidence = cest_p03_09_2do

eststo clear
qui ologit categorical_confidence i.gender $final_controls, cluster(codigocurso)
eststo ologit
foreach o in 1 2 3 4 {
qui margins, dydx(gender) predict(outcome(`o')) post
eststo, title(Confidence `o')
estimates restore ologit
}
eststo drop ologit

esttab using "$tables/ologit_confidence.tex", label replace ///
b(%5.3f) se(%5.3f) ty star(* 0.1 ** 0.05 *** 0.01) nobaselevels

*------------------------------------------------------------
* Aggression (Categorical). Focus on social aggressions.
*------------------------------------------------------------
gen categorical_social = 1 if cest_p14_03_2do==1 | cest_p14_04_2do==1
forv i = 2/5{
replace categorical_social = `i' if cest_p14_03_2do==`i' | cest_p14_04_2do==`i'
}

eststo clear
qui ologit categorical_social i.gender $final_controls, cluster(codigocurso)
eststo ologit
foreach o in 1 2 3 4 5 {
qui margins, dydx(gender) predict(outcome(`o')) post
eststo, title(Aggression `o')
estimates restore ologit
}
eststo drop ologit

esttab using "$tables/ologit_aggression.tex", label replace ///
b(%5.3f) se(%5.3f) ty star(* 0.1 ** 0.05 *** 0.01) nobaselevels

