*______________________________________________________________
* Author: Francine Montecinos
* Last edition: November 21, 2025
* Action: Robustness Checks 
*______________________________________________________________

*______________________________________________________________
* 1. Propensity score matching with clustered bootstrap (Julia)
*______________________________________________________________

use "$data/proc/main.dta", clear

// prepare labels and settings
local ids 2 3 4 5 6

local controls ""
foreach name in $final_covs {
	local controls `controls' `name'_dm
}


local outcomes math_norm math_confidence_2do

local lab2 "Cis girls"
local lab3 "Trans girls"
local lab4 "Trans boys"
local lab5 "NB AMABs"
local lab6 "NB AFABs"

keep mrun rbd codigocurso math* gender `controls' ${genders}


*---------------------------------------
* Initialize Julia
*---------------------------------------
jl start, threads(16)
jl: using DataFrames, StatsModels, GLM, StatsBase, Random, NearestNeighbors, Statistics, Base.Threads

jl save df

jl: controls   = Symbol.(split("`controls'", " "))
jl: outcomes   = Symbol.(split("`outcomes'", " "))
jl: treatments = [2,3,4,5,6]
jl: labels = Dict( ///
    1 => "Cis boys", ///
    2 => "Cis girls", ///
    3 => "Trans girls", ///
    4 => "Trans boys", ///
    5 => "NB AMABs", ///
	6 => "NB AFABs" ///
)

jl: reps_map   = Dict(2=>50, 3=>500, 4=>500, 5=>500, 6=> 500)

cd "$code"
jl: include("julia/att_bootstrap.jl")
cd "$tmp"

// Clean controls/outcomes and drop missings
jl: ctrl_raw  = split("`controls'", " ")
jl: controls  = Symbol.(unique(filter(name -> name in names(df), ctrl_raw)))
jl: outcomes  = Symbol.(unique(split("`outcomes'", " ")))
jl: needed    = vcat([:gender, :rbd], outcomes, controls)
jl: df_clean  = dropmissing(df, needed)

// Full run
jl: results = att_boot_all(df_clean, treatments, outcomes, controls; ///
    cluster=:rbd, reps_map=reps_map, default_reps=100, ///
    nn_list=[1,2,3,4], seed=123, label_map=labels) 

// Importing in Stata
jl: using CSV
jl: CSV.write("results_psm.csv", results)

jl: results 

import delimited "results_psm.csv", clear
rm "results_psm.csv"

* Back in Stata: reshape to wide and write a combined table (both outcomes side-by-side)
tempfile res_all
save "`res_all'", replace

tempfile t_norm t_conf

foreach outcome in math_norm math_confidence_2do {
    preserve
    use "`res_all'", clear
    keep if outcome=="`outcome'"
    gen gender_num = .
    replace gender_num = 1 if treat=="Cis boys"
    replace gender_num = 2 if treat=="Cis girls"
    replace gender_num = 3 if treat=="Trans girls"
    replace gender_num = 4 if treat=="Trans boys"
    replace gender_num = 5 if treat=="NB AMABs"
    replace gender_num = 6 if treat=="NB AFABs"
    drop outcome
    reshape wide b se lb ub, i(treat gender_num) j(nn)
    sort gender_num

    // Build stars from normal approximation to bootstrap t-stats
    forvalues j = 1/4 {
        gen p`j' = 2*normal(-abs(b`j'/se`j'))
        gen star`j' = cond(missing(b`j') | missing(se`j'), "", ///
            cond(p`j'<0.01, "\sym{***}", ///
            cond(p`j'<0.05, "\sym{**}", ///
            cond(p`j'<0.1, "\sym{*}", ""))))
        gen b`j'_fmt  = string(b`j', "%6.3f") + star`j'
        gen se`j'_fmt = "(" + string(se`j', "%6.3f") + ")"
    }

    keep treat gender_num b*_fmt se*_fmt
    if "`outcome'"=="math_norm" {
        rename (b1_fmt b2_fmt b3_fmt b4_fmt) (b1_fmt_mn b2_fmt_mn b3_fmt_mn b4_fmt_mn)
        rename (se1_fmt se2_fmt se3_fmt se4_fmt) (se1_fmt_mn se2_fmt_mn se3_fmt_mn se4_fmt_mn)
        save "`t_norm'", replace
    }
    else if "`outcome'"=="math_confidence_2do" {
        rename (b1_fmt b2_fmt b3_fmt b4_fmt) (b1_fmt_mc b2_fmt_mc b3_fmt_mc b4_fmt_mc)
        rename (se1_fmt se2_fmt se3_fmt se4_fmt) (se1_fmt_mc se2_fmt_mc se3_fmt_mc se4_fmt_mc)
        save "`t_conf'", replace
    }
    restore
}

use "`t_norm'", clear
merge 1:1 gender_num treat using "`t_conf'"
drop _merge
sort gender_num

file open fh using "$tables/psm_robustness_combined.tex", write text replace
file write fh "{ \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n
file write fh "\begin{tabular}{lcccccccc}" _n
file write fh "\toprule" _n
file write fh "& \multicolumn{4}{c}{10th grade Mathematics Score} & \multicolumn{4}{c}{10th grade Mathematics Confidence} \\" _n
file write fh "& \multicolumn{4}{c}{Number of Nearest Neighbors} & \multicolumn{4}{c}{Number of Nearest Neighbors} \\" _n
file write fh "Treatment & NN=1 & NN=2 & NN=3 & NN=4 & NN=1 & NN=2 & NN=3 & NN=4 \\" _n
file write fh "\midrule" _n

quietly forvalues r = 1/`=_N' {
    file write fh "`=treat[`r']'" " & " ///
        "`=b1_fmt_mn[`r']'" " & " "`=b2_fmt_mn[`r']'" " & " "`=b3_fmt_mn[`r']'" " & " "`=b4_fmt_mn[`r']'" " & " ///
        "`=b1_fmt_mc[`r']'" " & " "`=b2_fmt_mc[`r']'" " & " "`=b3_fmt_mc[`r']'" " & " "`=b4_fmt_mc[`r']'" " \\" _n

    file write fh " & " ///
        "`=se1_fmt_mn[`r']'" " & " "`=se2_fmt_mn[`r']'" " & " "`=se3_fmt_mn[`r']'" " & " "`=se4_fmt_mn[`r']'" " & " ///
        "`=se1_fmt_mc[`r']'" " & " "`=se2_fmt_mc[`r']'" " & " "`=se3_fmt_mc[`r']'" " & " "`=se4_fmt_mc[`r']'" " \\ [0.5em]" _n
}
file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file write fh "}" _n
file close fh

*______________________________________________________________
* 2. Changing Trans Samples
*______________________________________________________________
use "$data/proc/main.dta", clear

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
label define r_gender_2 1 "Boy" 2 "Girl" 3 "Other"
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
qui ologit categorical_confidence i.gender math_norm $final_controls ///
[aw = w2], cluster(codigocurso)
eststo ologit
foreach o in 1 2 3 4 {
qui margins, dydx(gender) predict(outcome(`o')) post
eststo, title(Confidence `o')
qui estadd local fixeds "$ $", replace 
qui estadd local controls "$ \checkmark $", replace 

estimates restore ologit
}
eststo drop ologit

esttab using "$tables/ologit_confidence.tex", label replace ///
b(%5.3f) se(%5.3f) ty star(* 0.1 ** 0.05 *** 0.01) nobaselevels nonotes ///
mtitles("Not Capable" "Slightly Capable" "Fairly Capable" "Highly Capable") mgroups("10th grade Mathematics Confidence: Categorical Levels",  pattern (1 0 0 0 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
nogaps nonotes booktabs s(fixeds controls N, fmt( %12.0f %12.0f %12.0f) ///
label("School FE" "Controls" "Observations"))


*------------------------------------------------------------
* Aggression (Categorical). Focus on social aggressions.
*------------------------------------------------------------
gen categorical_social = cest_p14_03_2do 
gen categorical_media = cest_p14_04_2do 

keep if categorical_media!=.| categorical_social!=.

eststo clear
qui ologit categorical_social i.gender $final_controls [aw = w2], cluster(codigocurso)
eststo ologit
foreach o in 1 2 3 4 5 {
qui margins, dydx(gender) predict(outcome(`o')) post
eststo, title(Aggression `o')
estimates restore ologit
}
eststo drop ologit

qui ologit categorical_media i.gender $final_controls [aw = w2], cluster(codigocurso)
eststo ologit
foreach o in 1 2 3 4 5 {
qui margins, dydx(gender) predict(outcome(`o')) post
eststo, title(Aggression `o')
estimates restore ologit
}
eststo drop ologit


esttab using "$tables/ologit_aggression.tex", label replace ///
b(%5.3f) se(%5.3f) ty star(* 0.1 ** 0.05 *** 0.01) nobaselevels nonotes ///
mtitles("Never" "CT a year" "CT a month" "CT a week" "Every day" /// 
"Never" "CT a year" "CT a month" "CT a week" "Every day") ///
mgroups("Social Aggression" "Social Media Aggression",  pattern (1 0 0 0 0 1) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
nogaps nonotes booktabs s(fixeds controls N, fmt( %12.0f %12.0f %12.0f) ///
label("School FE" "Controls" "Observations"))
