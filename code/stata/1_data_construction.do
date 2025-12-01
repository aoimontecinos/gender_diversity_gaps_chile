*------------------------------------------------------------
* 0. Programs and Globals 
*------------------------------------------------------------	
* helper #1: z-score (optionally by varlist)
program drop _all
program define zscore
	/* zscore varname , gen(newvar) [by(varlist)] */
    syntax varname , GEN(str) [BY(varlist)]
    if "`by'"=="" {
        qui su `varlist' , meanonly
        gen double `gen' = (`varlist'-r(mean))/r(sd)
    }
    else {
        tempvar m s
        bys `by': egen double `m' = mean(`varlist')
        bys `by': egen double `s' = sd(`varlist')
        gen double `gen' = (`varlist'-`m')/`s'
        drop `m' `s'
    }
end

* Globals 
global simce22  "$src/Simce/Simce segundo medio 2022/Archivos DTA (Stata)"
global simce4b  "$src/Simce/Simce cuarto básico "
global rendim   "$src/rendimiento"

global years4 2012 2013 2014 2015 2016
global years2 2012/2022
	
*------------------------------------------------------------
*  1.  SIMCE 2 medio 2022: base student file
*------------------------------------------------------------
use "$simce22/simce2m2022_alu_mrun_final_SEG", clear
foreach part in cest cpad {
    merge 1:1 idalumno using "$simce22/simce2m2022_`part'_final_SEG", nogen
}
keep idalumno grado rbd dvrbd mrun cod_curso gen_alu ptje* letra_curso codigocurso serie cest* cpad*

* tag every 2º-medio var with suffix _2do except the keys we still need
foreach v of varlist * {
    rename `v' `v'_2do
}
rename (idalumno_2do mrun_2do) (idalumno mrun)

tempfile simce2m
save `simce2m'


*------------------------------------------------------------
* 2.  SIMCE 4 básico 2012–2016 
*------------------------------------------------------------
tempfile join4b
clear
save `join4b', emptyok            // empty shell to append to

foreach yr in 2012 2013 2014 2015 2016 {
    local base "$src/Simce/Simce cuarto básico `yr'/Archivos DTA (Stata)"
    local seg  = cond("`yr'"=="2016","_SEG","-SEG")   // "_SEG" only in 2016

    /*--------------------------------------------------
      1.  — ALU file —
    --------------------------------------------------*/
    local alu1 "`base'/simce4b`yr'_alu_mrun_privada_final`seg'.dta"
    local alu2 "`base'/simce4b`yr'_alu_mrun_final`seg'.dta"          // fallback
    capture confirm file "`alu1'"
    if _rc==0 {
        local alufile "`alu1'"
    }
    else {
        local alufile "`alu2'"
    }
    use "`alufile'", clear

    /*--------------------------------------------------
      2.  — CEST file —
    --------------------------------------------------*/
    local cest1 "`base'/simce4b`yr'_cest_privada_final`seg'.dta"
    local cest2 "`base'/simce4b`yr'_cest_final`seg'.dta"
    capture confirm file "`cest1'"
    if _rc==0 {
        local cestfile "`cest1'"
    }
    else {
        local cestfile "`cest2'"
    }
    merge 1:1 idalumno agno using "`cestfile'", keep(master match) nogen

    /*--------------------------------------------------
      3.  — cleaning + normalisation —
    --------------------------------------------------*/
    cap destring ptje*, replace

    egen m = mean(ptje_mate4b)
    egen s = sd(ptje_mate4b)
    gen math_norm = (ptje_mate4b-m)/s
	drop m s
    egen m = mean(ptje_lect4b)
    egen s = sd(ptje_lect4b)
    gen lect_norm = (ptje_lect4b-m)/s
    drop m s

    keep mrun idalumno agno rbd gen_alu ptje* cest* lect_norm math_norm
    foreach v of varlist agno rbd gen_alu ptje* cest* lect_norm math_norm {
        rename `v' `v'_4to
    }

    /*--------------------------------------------------
      4.  — append to running master —
    --------------------------------------------------*/
    append using `join4b'
    save   `join4b', replace
}

duplicates drop mrun, force

*------------------------------------------------------------
* 3.  Combine 2 medio 2022 with 4 básico panel
*------------------------------------------------------------
merge n:n mrun using `simce2m', keep(using match) nogen
merge n:1 mrun using "$src/matricula/dta/matricula_unica_2022", keep(master match) nogen

*------------------------------------------------------------
* 4.  Quick recodes, dummies, and z scores 
*------------------------------------------------------------
* Replace all zeros / 99 to missing in cest* cpad*
foreach v of varlist cest* cpad* {
    replace `v' = . if inlist(`v',0,99)
}


* Income decile
gen ingreso_hogar = cpad_p03_2do
xtile income_decile= ingreso_hogar if gen_alu!=. | cest_p01_2do!=. , nq(10) 

* Mother & father covariates
recode cpad_p04_2do (21=.) , gen(mother_education)
recode cpad_p05_2do (21=.) , gen(father_education)

gen immigrant_father = 1 if cpad_p07_01_2do>1 & cpad_p07_01_2do!=.
replace immigrant_father = 0 if cpad_p07_01_2do==1

gen immigrant_mother = 1 if cpad_p07_02_2do>1 & cpad_p07_02_2do!=.
replace immigrant_mother = 0 if cpad_p07_02_2do==1

gen indigenous_father = 2 - cpad_p06_01_2do
gen indigenous_mother = 2 - cpad_p06_02_2do
gen indigenous_student = 2 - cpad_p06_03_2do

gen indigenous_parents = 1 if indigenous_mother==1 | indigenous_father==1
replace indigenous_parents = 0 if indigenous_father==0 | indigenous_mother==0

gen immigrant_parents = 1 if immigrant_mother==1 | immigrant_father==1
replace immigrant_parents = 0 if immigrant_mother==0 | immigrant_father==0

gen comuna_cod = cod_com_alu

gen mother_education_cat = .
replace mother_education_cat = 1 if inlist(mother_education, 1, 2, 3, 4, 5, 6, 7, 8)  // Primary incomplete
replace mother_education_cat = 2 if mother_education == 9  // Primary complete (8° básico)
replace mother_education_cat = 3 if inlist(mother_education, 10, 11, 12)  // High school incomplete
replace mother_education_cat = 4 if inlist(mother_education, 13)  // High school complete (IV medio)
replace mother_education_cat = 5 if inlist(mother_education, 14)  // High school complete (Technical)
replace mother_education_cat = 6 if inlist(mother_education, 15, 17)  // Post-secondary incomplete 
replace mother_education_cat = 7 if inlist(mother_education, 16)  // Vocational school complete 
replace mother_education_cat = 8 if inlist(mother_education, 18, 19, 20)  // Post-secondary complete 


* Reverse code all cest_p07* (1<->2) in one go
foreach v of varlist cest_p07* {
    replace `v' = cond(`v'!=., 3-`v', .)
}

* A few binary indicators via the helper
gen p05_media_incompleta = (cest_p05_2do==1) if cest_p05_2do!=.
gen p05_media_completa  = inlist(cest_p05_2do,2,3) if cest_p05_2do!=. 
gen p05_tecnico         = (cest_p05_2do==4) if cest_p05_2do!=.
gen p05_universitario   = (cest_p05_2do==5) if cest_p05_2do!=.
gen p05_posgrado        = (cest_p05_2do==6) if cest_p05_2do!=. 

* Teachers' evaluation, resilience, etc.
egen mean_val = rowmean(cest_p02_05_2do  cest_p02_06_2do)
gen  valoracion_profesores = (mean_val>=3) if mean_val  !=.
drop mean_val

egen mean_apoyo = rowmean(cest_p04_08_2do  cest_p04_09_2do)
gen  apoyo_profesores = (mean_apoyo>=3) if mean_apoyo !=.
drop mean_apoyo

egen mean_res = rowmean(cest_p48_01_2do  cest_p48_02_2do ///
                          cest_p48_03_2do  cest_p48_04_2do)
gen  resiliencia = (mean_res>=3) if mean_res!= .
drop mean_res

save "$tmp/simce_data", replace

*------------------------------------------------------------
* 5.  MINEDUC rendimiento 2012-22 
*------------------------------------------------------------
use "$tmp/simce_data", clear
keep mrun 
save "$tmp/simce_temporal", replace

tempfile rendtmp
forv yr = $years2 {
    use "$src/rendimiento/dta/rendimiento`yr'.dta", clear
    destring mrun prom_gral*, dpcomma replace 
	duplicates tag mrun, gen(tag)
	drop if prom_gral==0 & asistencia==0 & tag>0
    keep mrun rbd cod_depe prom_gral asistencia agno gen_alu
    rename gen_alu gen_alu_mineduc
    // duplicates drop mrun, force
    merge n:n mrun using "$tmp/simce_temporal", keep(using match)
    if `yr'!=2012 append using `rendtmp'
    save `rendtmp', replace
}

keep mrun rbd cod_depe prom_gral asistencia agno gen_alu_mineduc 
drop if agno==.
duplicates drop

drop if mrun==. 
duplicates tag mrun agno, gen(tag)
drop if (prom_gral==0|asistencia==0) & tag>0
bys mrun agno: egen max_asistencia = max(asistencia)
drop if max_asistencia!=asistencia & tag>0
drop max_asistencia tag

reshape wide rbd cod_depe prom_gral asistencia gen_alu_mineduc, i(mrun) j(agno)

merge 1:m mrun using "$tmp/simce_data", nogen keep(using match)
drop if mrun==. 

duplicates tag mrun, gen(tag)
keep if (rbd_2do==rbd2022)|tag==0

drop tag 
duplicates tag mrun, gen(tag)

// One student took the math and reading classes in different classrooms.
bys mrun: ereplace ptje_lect2m_alu_2do = max(ptje_lect2m_alu_2do) if tag==1
bys mrun: egen max_math = max(ptje_mate2m_alu_2do)
keep if tag==0 | (ptje_mate2m_alu_2do==max_math)

*---------------------------------------------
* Standardise scores 
*--------------------------------------------
cap drop math_norm* lect_norm* ones
gen ones = 1

zscore ptje_mate2m , gen(math_norm) by(ones)
zscore ptje_mate2m , gen(math_norm_rbd) by(rbd)

zscore ptje_lect2m , gen(lect_norm) by(ones)
zscore ptje_lect2m , gen(lect_norm_rbd) by(rbd)


*------------------------------------------------------------
* 6.  TEACHER SURVEY, COMPLETE IDs
*------------------------------------------------------------
*– match 2022 math-teacher questionnaire to each student –*
rename cod_curso_2do codigocurso
merge n:1 codigocurso rbd using ///
    "$src/Simce/Simce segundo medio 2022/Archivos DTA (Stata)/simce2m2022_cprof_mate_final_SEG.dta", ///
    keep(master match)

foreach v of varlist cprof_* {
    replace `v' = . if cprof_p02_02!=1      // keep only the student's own teacher
}
gen byte teacher_gender = cprof_p01-1 if inrange(cprof_p01,1,2)
label define yesno 0 "No" 1 "Yes"
label values teacher_gender yesno
drop cprof*
compress

*– fill missing RBD with the 2022 value when available –*
replace rbd = rbd_2do if missing(rbd)

* Teacher's data from MINEDUC 
preserve 
import delimited "$src/docentes/Docentes_por_curso_y_subsector.csv", clear
keep if cod_grado==2 & cod_ense2>=5
keep if doc_genero!=0

gen mat_prof = 0 
replace mat_prof = 1 if regexm(nom_subsector,"MATE")==1 & obl_subsector==1

gen sex_prof = doc_genero 

gen edad_prof = int((202201-doc_fec_nac)/100)

duplicates tag rbd let_cur cod_ense if mat_prof==1, gen(duplicado)

replace mat_prof = 0 if cod_subsector!=5 & duplicado==1

keep if mat_prof==1
keep rbd let_cur cod_ense sex_prof edad_prof 
rename let_cur letra_curso

tempfile teacher_mineduc 
save `teacher_mineduc'
restore 

merge m:1 letra_curso rbd cod_ense using `teacher_mineduc', nogen keep(master match) 

*------------------------------------------------------------
* 7.  CONSISTENT GENDER VARIABLES
*------------------------------------------------------------
* detect sex changes in admin records *
forval y = 2013/2022 {
    local p = `y'-1
    gen byte same_sex_`y' = (gen_alu_mineduc`p'==gen_alu_mineduc`y') if ///
        !missing(gen_alu_mineduc`p',gen_alu_mineduc`y')
}

* first non-missing sex across years → sex_alu *
gen byte sex_alu = .
foreach y of numlist 2012/2022 {
    replace sex_alu = gen_alu_mineduc`y' if missing(sex_alu)
}

* combine survey gender with admin sex *
gen byte gender = sex_alu                                 // default = cis
replace gender = 3 if sex_alu==1 & cest_p01_2do==2        // trans woman
replace gender = 4 if sex_alu==2 & cest_p01_2do==1        // trans man
replace gender = 5 if sex_alu==1 & cest_p01_2do==3        // NB male
replace gender = 6 if sex_alu==2 & cest_p01_2do==3        // NB female
label define gendr 1 "Cis boys" 2 "Cis girls" 3 "Trans girls" ///
                  4 "Trans boys" 5 "NB AMABs" 6 "NB AFABs"
label values gender gendr

* dummies *
foreach g in cis_man cis_woman trans_woman trans_man trans_nb nb_male nb_female {
    gen byte `g' = 0
}
replace cis_man     = 1 if gender==1
replace cis_woman   = 1 if gender==2
replace trans_woman = 1 if gender==3
replace trans_man   = 1 if gender==4
replace trans_nb    = 1 if inlist(gender,5,6)
replace nb_male     = 1 if gender==5
replace nb_female   = 1 if gender==6

gen byte gender_diversity = cond(inlist(gender,1,2),0,cond(inlist(gender,3,4),1,2))
gen byte trans = inlist(gender,3,4,5,6)


*------------------------------------------------------------
* 8.  4º-BÁSICO SCHOOL VARIABLES (PROM, ATTENDANCE, DEPENDENCY)
*------------------------------------------------------------
gen cod_depe10 = cod_depe2022
gen cod_depe4  = cod_depe2016
gen prom_gral4 = prom_gral2016
gen asistencia4 = asistencia2016
gen rbd4 = rbd2016
forvalues i = 2/5 {
    replace cod_depe4   = cod_depe201`i' if agno_4to==201`i'
    replace prom_gral4  = prom_gral201`i' if agno_4to==201`i'
    replace asistencia4 = asistencia201`i' if agno_4to==201`i'
    replace rbd4        = rbd201`i'      if agno_4to==201`i'
}

replace asistencia4 = 50 if asistencia4<50
replace prom_gral4 = 4 if prom_gral4<4 

foreach var of varlist asistencia4 prom_gral4 {
	bys rbd_4to: egen mean_var = mean(`var')
	bys rbd_4to: egen sd_var = sd(`var')
	gen `var'_norm = (`var' - mean_var)/sd_var
	drop mean_var sd_var
}

* collapse some dependency codes *
replace cod_depe4 = 1 if inlist(cod_depe4,1,2,5)
tab cod_depe4, gen(dependencia4_)

* school change between 2020-2022 *
gen byte school_change = (rbd2020!=. & rbd2022!=rbd2020 & rbd!=rbd2020)
label var school_change "School change 2020-22"

*----------------------------------------------------------------
* 9. Confidence and bullying variables 
*----------------------------------------------------------------
gen math_confidence_2do = 1 if cest_p03_09_2do>=3 & cest_p03_09_2do!=.
replace math_confidence_2do = 0 if cest_p03_09_2do<3

gen lect_confidence_2do = 1 if cest_p03_08_2do>=3 & cest_p03_08_2do!=.
replace lect_confidence_2do = 0 if cest_p03_08_2do<3

gen math_confidence_4to = 1 if cest_p05_07_4to>=3 & cest_p05_07_4to!=. & agno_4to==2016
replace math_confidence_4to = 0 if cest_p05_07_4to<3 & agno_4to==2016

replace math_confidence_4to = 1 if cest_p05_09_4to>=3 & cest_p05_09_4to!=. & agno_4to==2015
replace math_confidence_4to = 0 if cest_p05_09_4to<3 & agno_4to==2015

replace math_confidence_4to = 1 if cest_p05_10_4to>=3 & cest_p05_10_4to!=. & agno_4to==2014
replace math_confidence_4to = 0 if cest_p05_10_4to<3 & agno_4to==2014

gen lect_confidence_4to = 1 if cest_p05_06_4to>=3 & cest_p05_06_4to!=. & agno_4to==2016
replace lect_confidence_4to = 0 if cest_p05_06_4to<3 & agno_4to==2016

replace lect_confidence_4to = 1 if cest_p05_04_4to>=3 & cest_p05_04_4to!=. & agno_4to==2015
replace lect_confidence_4to = 0 if cest_p05_04_4to<3 & agno_4to==2015

replace lect_confidence_4to = 1 if cest_p05_05_4to>=3 & cest_p05_05_4to!=. & agno_4to==2014
replace lect_confidence_4to = 0 if cest_p05_05_4to<3 & agno_4to==2014


gen intelligence_limitations = cest_p45_01_2do + cest_p45_02_2do + cest_p45_03_2do
egen limitations_mean = mean(intelligence_limitations)
egen limitations_sd = sd(intelligence_limitations)
gen limitations_norm = (intelligence_limitations - limitations_mean)/limitations_sd

*----------------------------------------------------
* Bullying and aggressions 
*----------------------------------------------------
gen physical_aggression = 1 if cest_p14_01_2do>=2 & cest_p14_01_2do!=.
	replace physical_aggression = 0 if cest_p14_01_2do==1
gen verbal_aggression = 1 if cest_p14_02_2do>=2 & cest_p14_02_2do!=.
	replace verbal_aggression = 0 if cest_p14_02_2do==1
gen social_aggression = 1 if cest_p14_03_2do>=2 & cest_p14_03_2do!=.
	replace social_aggression = 0 if cest_p14_03_2do==1
gen media_aggression = 1 if cest_p14_04_2do>=2 & cest_p14_04_2do!=.
	replace media_aggression = 0 if cest_p14_04_2do==1
gen any_aggression = 1 if (physical + verbal + social + media)>0 & ///
	(physical + verbal + social + media)!=.
	replace any_aggression = 0 if (physical + verbal + social + media)==0

gen bullying = 0 if any_aggression!=.
	replace bullying = 1 if cest_p14_01_2do==2 | cest_p14_02_2do==2| ///
	cest_p14_03_2do==2 | cest_p14_04_2do==2
	replace bullying = 2 if (cest_p14_01_2do>=3 & cest_p14_01_2do!=.) | ///
	(cest_p14_02_2do>=3 & cest_p14_02_2do!=.) | ///
	(cest_p14_03_2do>=3 & cest_p14_03_2do!=.) | ///
	(cest_p14_04_2do>=3 & cest_p14_04_2do!=.) 

gen bullying_social = 0 if any_aggression!=.
	replace bullying_social = 1 if cest_p14_03_2do==4 | cest_p14_03_2do==5 | ///
	cest_p14_04_2do==4 | cest_p14_04_2do==5

*---------------------------------------------------
* Discrimination 
*---------------------------------------------------	
gen discr_sexo = cest_p07_01_2do
gen discr_orientacion= cest_p07_04_2do
gen discr_expresion = cest_p07_05_2do
	
* Extra
destring edad_alu, replace
gen double edad_alu2 = edad_alu^2
	
*------------------------------------------------------------
* 10.  PEER AND SCHOOL-LEVEL AGGREGATES
*------------------------------------------------------------
* lists *
global student_controls edad_alu income_decile mother_education_cat ///
                        immigrant_mother school_change ///
                        sex_alu asistencia4 prom_gral4

local gradevars math_norm_4to math_confidence_4to
local aggvars  physical_aggression verbal_aggression social_aggression ///
               media_aggression discr_sexo discr_orientacion discr_expresion
local peerlist $student_controls trans `gradevars' `aggvars'

gen __isF = cest_p01_2do==2|sex_alu==2

* peers in the same classroom *

foreach v of varlist `peerlist' {
    bys codigocurso: egen __n = count(`v') if !missing(`v')
    bys codigocurso: egen __s = total(`v')
    gen double peers_`v' = (__s-`v')/(__n-1)
    drop __n __s
}

* same-sex peers' scores *
foreach v in math_norm lect_norm {
    bys codigocurso sex_alu: egen __n = count(`v') if !missing(`v')
    bys codigocurso sex_alu: egen __s = total(`v')
    gen double same_sex_peers_`v' = (__s-`v')/(__n-1)
    drop __n __s
}

* women peers' scores (fill missing with class mean) *
foreach v in math_norm lect_norm {
    bys codigocurso: egen __n = count(`v') if !missing(`v') & __isF==1
    bys codigocurso: egen __s = total(`v') if __isF==1
    gen double fem_peers_`v' = (__s-`v')/(__n-1) if __isF==1
    bys codigocurso: egen __m = mean(fem_peers_`v')
    bys codigocurso: replace fem_peers_`v' = __m if missing(fem_peers_`v')
    drop __n __s __m
}

drop __isF

* RBD-level aggregates for several grades *
local grades 2do 4to 
foreach v of varlist $student_controls math_confidence_4to math_norm_4to {
    foreach g of local grades {
        bys rbd_`g': egen __n = count(`v') if !missing(`v')
        bys rbd_`g': egen __s = total(`v')
		cap drop rbd_`g'_`v' 
        gen double rbd_`g'_`v' = (__s-`v')/(__n-1)
		bys rbd_`g': egen __m = mean(rbd_`g'_`v')
        bys rbd_`g': replace rbd_`g'_`v' = __m if missing(rbd_`g'_`v')
        drop __n __s __m
    }
}

* basic repeat flag *
gen byte repitente = (agno_4to!=2016)

*------------------------------------------------------------
* 10.  FINAL SAMPLE, IPW & MILLS RATIO
*------------------------------------------------------------
* Leave one out instrument: We'll take all the "not in sample" from schools, and remove the student's value. Then we obtain the average for all students without our student i. 
gen imr = 1 
reghdfe math_norm i.gender $final_controls, absorb(rbd) vce(cluster codigocurso)
drop imr 

gen byte final_sample = e(sample)
gen byte not_sample = final_sample==0

bys rbd_4to: egen tot_rbd_4to = count(mrun)
bys rbd_4to: egen tot_rbd_4to_rep = sum(not_sample)
gen rbd_4to_not_sample_out = (tot_rbd_4to_rep - not_sample)/(tot_rbd_4to - 1) 

bys rbd_2do: egen tot_rbd_2do = count(mrun)
bys rbd_2do: egen tot_rbd_2do_rep = sum(not_sample)
gen rbd_2do_not_sample_out = (tot_rbd_2do_rep - not_sample)/(tot_rbd_2do - 1) 

gen rbd_not_sample_out = (rbd_4to_not_sample_out + rbd_2do_not_sample_out)/2 if rbd_4to!=.

cap drop phat ipw imr 
probit final_sample rbd_not_sample_out ///
					rbd_2do_math_norm_4to rbd_2do_math_confidence_4to ///
					rbd_2do_income_decile rbd_2do_mother_education_cat
	  
predict double phat, pr
gen double ipw = final_sample/phat
gen double imr = normalden(invnorm(phat))/phat
label var imr "Inverse Mills ratio"

*------------------------------------------------------------
* 11.  GENDER LABEL AS STRING
*------------------------------------------------------------
gen str12 genders = ""
replace genders = "Cis boys"      if gender==1
replace genders = "Cis girls"     if gender==2
replace genders = "Trans girls"   if gender==3
replace genders = "Trans boys"    if gender==4
replace genders = "NB AMABs"      if gender==5
replace genders = "NB AFABs"      if gender==6

label values gender gendr

label var cis_woman "Cis girls"
label var trans_woman "Trans girls"
label var trans_man "Trans boys"
label var nb_male "NB AMABs"
label var nb_female "NB AFABs"

label var math_norm "10th grade math score"

// Variable labels for regression output
label variable edad_alu "Age"
label variable edad_alu2 "Age$^2$"
label variable immigrant_mother "Immigrant mother"
label variable school_change "Changed schools"
label variable math_norm_4to "4th grade math score"
label variable math_confidence_4to "4th grade math confidence"
label variable math_norm_4to "4th grade math score"
label variable math_confidence_4to "4th grade math confidence"
label variable rbd_not_sample_out "Leave-one-out non response rate"

// Income decile labels
label var income_decile "Income decile"
cap label drop income_decile_lbl
label define income_decile_lbl ///
    1 "Income Declile: D1 (ref)" ///
    2 "Income Declile: D2" ///
    3 "Income Declile: D3" ///
    4 "Income Declile: D4" ///
    5 "Income Declile: D5" ///
    6 "Income Declile: D6" ///
    7 "Income Declile: D7" ///
    8 "Income Declile: D8" ///
    9 "Income Declile: D9" ///
    10 "Income Declile: D10"

label values income_decile income_decile_lbl


// Collapse mother education into broader categories for cleaner results
cap label drop mother_ed_collapsed_lbl
label define mother_ed_collapsed_lbl ///
    1 "Mother's Education: Primary incomplete or less" ///
    2 "Mother's Education: Primary complete (8th grade)" ///
    3 "Mother's Education: High school incomplete" ///
    4 "Mother's Education: High school complete, Regular" ///
    5 "Mother's Education: High school complete, Technical" ///
    6 "Mother's Education: Post-secondary incomplete" ///
    7 "Mother's Education: Vocational's degree complete" ///
	8 "Mother's Education: Bachelor's degree complete"

label var asistencia4 "4th grade attendance"
label var prom_gral4 "4th grade GPA"
		
label values mother_education_cat mother_ed_collapsed_lbl
label variable mother_education_cat "Mother's education"

save "$data/proc/simce_mineduc_elsoc_2022_full", replace

*------------------------------------------------------------
* 12.  RE-STANDARDISE SCORES WITHIN FINAL SAMPLE
*------------------------------------------------------------
keep if final_sample==1

cap drop ones 
gen ones = 1 
foreach v in math_norm math_norm_4to lect_norm lect_norm_4to {
    zscore `v' , gen(__z) by(ones)
    replace `v' = __z
    drop __z
}

*------------------------------------------------------------
* 13. Heterogeneity by religious school 
*------------------------------------------------------------
preserve 
import delimited ///
"$src/planes/20230307_Planes_y_programas_de_estudios_2022_20220131_PUBL.csv", clear

keep if cod_ense>=300 
cap drop total_cursos
bys rbd: egen total_cursos = nvals(let_cur cod_grado)

gen per_religion = rel_subsector==1 & per_subsector==1 
bys rbd let_cur cod_grado: egen religious_cur = max(per_religion)

duplicates drop rbd let_cur cod_grado, force
bys rbd: egen religious_tot = total(religious_cur)
gen religious_ratio = religious_tot/total_cursos

// School with all their classes with religion in the study program
gen rbd_religious = religious_ratio==1
duplicates drop rbd, force

keep rbd rbd_religious
tempfile religion
save `religion' 
restore 

merge m:1 rbd using `religion', nogen keep(master match)

compress
save "$data/proc/simce_mineduc_elsoc_2022a", replace

*------------------------------------------------------------
* 14. PROPENSITY SCORE CALCULATION. WE NEED TO DEMEAN COVS.
*------------------------------------------------------------
tab mother_education_cat, gen(mother_education_cat_)
tab income_decile, gen(income_decile_cat_)

foreach var of varlist $final_covs {
bys rbd: egen aux_mean = mean(`var')
bys rbd: egen aux_sd = sd(`var')
egen global_sd = sd(`var')
replace aux_sd = global_sd if aux_sd==0
gen `var'_dm = (`var' - aux_mean)/aux_sd
cap drop aux_mean aux_sd global_sd
}

save "$data/proc/simce_mineduc_elsoc_2022b", replace

cap rm "$tmp/simce_data.dta"
cap rm "$tmp/simce_temporal.dta"
