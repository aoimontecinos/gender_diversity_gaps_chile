use "$data/proc/simce_mineduc_elsoc_2022a", clear 
merge 1:m mrun using "$src/matricula_superior/20250729_Matricula_Ed_Superior_2025_PUBL_MRUN.dta", nogen keep(1 3)

tab area_conocimiento
replace area_conocimiento = "Outside Option" if area_conocimiento==""

tab area_conocimiento
cap drop stem
gen stem = inlist(area_conocimiento,"Ciencias Básicas", "Tecnología", "Agropecuaria")
gen outside = area_conocimiento=="Outside Option"

reg stem i.gender $final_controls , absorb(rbd)

graph hbar stem, over(gender) aspectratio(0.55) bar(1,color(midblue)) ///
ytitle("STEM Enrollment") ylabel(0(.1).4) vert

graph hbar outside stem, over(gender) aspectratio(0.55) bar(1,color(midblue)) ///
ytitle("Share of Students") ylabel(0(.1).5) vert ///
legend(order(1 "Outside of Higher Education" 2 "STEM Enrollment"))



























use "$data/proc/simce_mineduc_elsoc_2022a", clear 
tostring rbd, replace
merge 1:1 mrun using "$data/src/DEMRE/A_ADM25.dta", gen(match_A) keep(1 3)

gen take_test = mate1_max!=0 if mate1_max!=.
replace mate1_max = . if mate1_max==0

egen mean = mean(mate1_max)
egen sd = sd(mate1_max)
gen psu_math_norm = (mate1_max - mean)/sd 
drop mean sd 

global final_controls "edad_alu edad_alu2 i.income_decile i.mother_education_cat* immigrant_mother school_change"

eststo m1: reghdfe math_norm_4to i.gender $final_controls if psu_math_norm!=., abs(rbd)
eststo m2: reghdfe math_norm i.gender $final_controls if psu_math_norm!=., abs(rbd)
eststo m3: reghdfe psu_math_norm i.gender $final_controls if psu_math_norm!=., abs(rbd)

esttab m1 m2 m3, keep(*gender*)

coefplot m1 m2 m3, keep(*gender*) vert ///
legend(order(2 "4th grade" 4 "10th grade" 6 "12th grade") row(1)) ciopts(recast(rcap)) ///
yline(0, lpattern(dash))



use "$data/proc/simce_mineduc_elsoc_2022a", clear 

forv i=2013/2022 {
	drop if prom_gral`i'<4
	bys rbd: egen r_mean = mean(prom_gral`i')
	bys rbd: egen r_sd = sd(prom_gral`i')
	gen gpa_norm`i' = (prom_gral`i' - r_mean)/r_sd
	cap drop r_mean r_sd
}

keep mrun gender gpa_* prom_gral*
drop prom_gral2012 prom_gral4 

reshape long gpa_norm prom_gral, i(mrun) j(year)

collapse prom_gral gpa_norm, by(gender year)

gen aux = prom_gral if year==2013
bys gender: egen prom_gral_baseline = mean(aux)
gen prom_gral_norm = prom_gral/prom_gral_baseline 

cap drop aux
gen aux = gpa_norm if year==2013
bys gender: egen gpa_baseline= mean(aux)

gen gpa_norm_norm = gpa_norm - gpa_baseline
gen grade = year - 2012

local var "prom_gral_norm"
tw (connect `var' grade if gender==1) (connect `var' grade if gender==2) ///
(connect `var' grade if gender==3) (connect `var' grade if gender==4) ///
(connect `var' grade if gender==5) (connect `var' grade if gender==6), ///
legend(order(1 "Cis boys" 2 "Cis girls" 3 "Trans girls" ///
4 "Trans boys" 5 "NB AMABs" 6 "NB AFABs")) xtitle("Academic grade") ///
ytitle("GPA") 

, by(gender)
