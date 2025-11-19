preserve 

* Load Data
use "$tmp/simce_mineduc_elsoc_2022b", clear

qui: reghdfe math_confidence_2do i.gender $final_controls [aw = w2], absorb(rbd) 
keep if e(sample)

cap drop ones
gen ones = 1
bys gender: egen n_total = total(ones) 

gen public_school_4 = inlist(cod_depe4,1,2,5) if cod_depe4!=.
gen public_school_10 = inlist(cod_depe10,1,2,5,6) if cod_depe10!=.
gen private_school_4 = cod_depe4==4 if cod_depe4!=.
gen private_school_10 = cod_depe10==4 if cod_depe10!=.

gen Mother_Education_Primary = inlist(mother_education_cat,2,3)*100
gen Mother_Education_Secondary = inlist(mother_education_cat,4,5,6)*100
gen Mother_Education_Vocational = inlist(mother_education_cat,7)*100
gen Mother_Education_College = inlist(mother_education_cat,8)*100

gen agg_physical = physical
gen agg_verbal = verbal 
gen agg_social = social
gen agg_media = media

gen disc_sexo = discr_sexo-1
gen disc_orientacion = discr_orientacion-1
gen disc_expresion = discr_expresion-1

su disc* 

foreach cov of varlist public_school* private_school* immigrant* ///
indigenous* math_norm* math_confidence* agg* disc* {
	replace `cov' = `cov'*100
}

compress 

rename edad_alu Age
rename income_decile Income_Decile
rename immigrant_mother Immigrant_Mother
rename indigenous_mother Indigenous_Mother

rename prom_gral4 GPA_4th 
rename asistencia4 Attendance_4th
rename public_school_4 Public_School_4th 
rename private_school_4 Private_School_4th 
rename math_norm_4to Math_Score_4th
rename math_confidence_4to Math_Confidence_4th

rename prom_gral2022 GPA_10th 
rename asistencia2022 Attendance_10th
rename public_school_10 Public_School_10th 
rename private_school_10 Private_School_10th 
rename math_norm Math_Score_10th
rename math_confidence_2do Math_Confidence_10th

rename n_total N

* Define variable types AND groups in the desired order
local demographics_continuous Age Income_Decile
local demographics_binary Immigrant_Mother Indigenous_Mother Mother_Education_Primary ///
    Mother_Education_Secondary Mother_Education_Vocational Mother_Education_College

local fourth_grade_continuous GPA_4th Math_Score_4th 
local fourth_grade_binary Math_Confidence_4th Attendance_4th Public_School_4th Private_School_4th

local tenth_grade_continuous GPA_10th Math_Score_10th 
local tenth_grade_binary Math_Confidence_10th Attendance_10th Public_School_10th Private_School_10th agg_physical agg_verbal agg_social agg_media disc_sexo disc_orientacion disc_expresion

local count_vars N

* Create a temporary file to store results
tempfile results
tempname memhold
postfile `memhold' str32 variable str16 cis_man str16 cis_woman str16 trans_woman ///
    str16 trans_man str16 nb_male str16 nb_female using `results'

	
* Program for continuous variables (mean and SD)
cap program drop format_continuous
program define format_continuous
    args varname gender
    quietly summ `varname' if gender == `gender'
    
    if r(N) == 0 {
        c_local result "."
    }
    else {
        local mean = r(mean)
        local sd = r(sd)
        
        // Determine the format based on the mean value
        if abs(`mean') < 1 {
            local mean_str = string(`mean', "%6.3f")
            local sd_str = string(`sd', "%6.3f")
        }
        else if abs(`mean') < 10 {
            local mean_str = string(`mean', "%6.2f")
            local sd_str = string(`sd', "%6.2f")
        }
        else if abs(`mean') < 100 {
            local mean_str = string(`mean', "%6.1f")
            local sd_str = string(`sd', "%6.1f")
        }
        else {
            local mean_str = string(`mean', "%6.0f")
            local sd_str = string(`sd', "%6.0f")
        }
        c_local result "`mean_str' (`sd_str')"
    }
end

* Program for binary variables (percentage only)
cap program drop format_binary
program define format_binary
    args varname gender
    quietly summ `varname' if gender == `gender'
    
    if r(N) == 0 {
        c_local result "."
    }
    else {
        local mean = r(mean)
        
        // Format as percentage with one decimal place
        local perc_str = string(`mean', "%6.1f")
        c_local result "`perc_str'"
    }
end

* Program for count variables (integer only)
cap program drop format_count
program define format_count
    args varname gender
    quietly summ `varname' if gender == `gender'
    
    if r(N) == 0 {
        c_local result "."
    }
    else {
        local mean = r(mean)
        local count_str = string(`mean', "%6.0f")
        c_local result "`count_str'"
    }
end

* Calculate statistics in the desired group order

* 1. Demographics - Continuous
foreach var of local demographics_continuous {
    forvalues g = 1/6 {
        format_continuous `var' `g'
        local result_`g' "`result'"
    }
    post `memhold' ("`var'") ("`result_1'") ("`result_2'") ("`result_3'") ///
        ("`result_4'") ("`result_5'") ("`result_6'")
}

* 2. Demographics - Binary (Mother Education variables now included here)
foreach var of local demographics_binary {
    forvalues g = 1/6 {
        format_binary `var' `g'
        local result_`g' "`result'"
    }
    post `memhold' ("`var'") ("`result_1'") ("`result_2'") ("`result_3'") ///
        ("`result_4'") ("`result_5'") ("`result_6'")
}

* 3. 4th Grade - Continuous
foreach var of local fourth_grade_continuous {
    forvalues g = 1/6 {
        format_continuous `var' `g'
        local result_`g' "`result'"
    }
    post `memhold' ("`var'") ("`result_1'") ("`result_2'") ("`result_3'") ///
        ("`result_4'") ("`result_5'") ("`result_6'")
}

* 4. 4th Grade - Binary
foreach var of local fourth_grade_binary {
    forvalues g = 1/6 {
        format_binary `var' `g'
        local result_`g' "`result'"
    }
    post `memhold' ("`var'") ("`result_1'") ("`result_2'") ("`result_3'") ///
        ("`result_4'") ("`result_5'") ("`result_6'")
}

* 5. 10th Grade - Continuous
foreach var of local tenth_grade_continuous {
    forvalues g = 1/6 {
        format_continuous `var' `g'
        local result_`g' "`result'"
    }
    post `memhold' ("`var'") ("`result_1'") ("`result_2'") ("`result_3'") ///
        ("`result_4'") ("`result_5'") ("`result_6'")
}

* 6. 10th Grade - Binary
foreach var of local tenth_grade_binary {
    forvalues g = 1/6 {
        format_binary `var' `g'
        local result_`g' "`result'"
    }
    post `memhold' ("`var'") ("`result_1'") ("`result_2'") ("`result_3'") ///
        ("`result_4'") ("`result_5'") ("`result_6'")
}

* 7. Sample Size
foreach var of local count_vars {
    forvalues g = 1/6 {
        format_count `var' `g'
        local result_`g' "`result'"
    }
    post `memhold' ("`var'") ("`result_1'") ("`result_2'") ("`result_3'") ///
        ("`result_4'") ("`result_5'") ("`result_6'")
}

* Close postfile
postclose `memhold'

* Load results
use `results', clear

* Display results
list, sep(0) abbreviate(32)

// Define the LaTeX table file with appropriate note and group formatting
file open myfile using "$tables/descriptives.tex", write replace
// Write the LaTeX table header
file write myfile "\begin{tabular}{lcccccc}" _n
file write myfile "\hline" _n
// Write the header row
file write myfile "& \textbf{Cis Men} & \textbf{Cis Women} & \textbf{Trans Women} & \textbf{Trans Men} & \textbf{NB AMAB} & \textbf{NB AFAB} \\" _n
file write myfile "\hline" _n

* Add group headers and format variable names nicely
local row_count = 1
forvalues i = 1/`=_N' {
    local var = variable[`i']
    
    * Add group headers at appropriate points
    if `i' == 1 {
        file write myfile "\multicolumn{7}{l}{\textbf{Demographics}} \\" _n
    }
    else if `i' == 9 {  // After demographics (2 continuous + 6 binary = 8 variables)
        file write myfile "\multicolumn{7}{l}{\textbf{4th Grade}} \\" _n
    }
    else if `i' == 15 {  // After 4th grade (4 continuous + 2 binary = 6 variables)
        file write myfile "\multicolumn{7}{l}{\textbf{10th Grade}} \\" _n
    }
    else if `i' == 21 {  // After 10th grade (4 continuous + 2 binary = 6 variables)
        file write myfile "\multicolumn{7}{l}{\textbf{10th Grade: Aggressions and Discrimination}} \\" _n
    }
    else if `i' == 28 {  // After Aggressions 
        file write myfile "\multicolumn{7}{l}{\textbf{ }} \\" _n
    }
    
    * Format variable names for display
    if "`var'" == "Age" local label "Age (years)"
    else if "`var'" == "Income_Decile" local label "Income Decile"
    else if "`var'" == "Immigrant_Mother" local label "Immigrant Mother (\%)"
    else if "`var'" == "Indigenous_Mother" local label "Indigenous Mother (\%)"
    else if "`var'" == "Mother_Education_Primary" local label "Mother Education: Primary (\%)"
    else if "`var'" == "Mother_Education_Secondary" local label "Mother Education: Secondary (\%)"
    else if "`var'" == "Mother_Education_Vocational" local label "Mother Education: Vocational (\%)"
    else if "`var'" == "Mother_Education_College" local label "Mother Education: College (\%)"
    else if "`var'" == "GPA_4th" local label "GPA (4th grade, 1.0-7.0)"
    else if "`var'" == "Attendance_4th" local label "Attendance (4th grade, \%)"
    else if "`var'" == "Public_School_4th" local label "Public School (4th grade, \%)"
    else if "`var'" == "Private_School_4th" local label "Private School (4th grade, \%)"
    else if "`var'" == "Math_Score_4th" local label "Math Score (4th grade, std.)"
    else if "`var'" == "Math_Confidence_4th" local label "Math Confidence (4th grade, \%)"
    else if "`var'" == "GPA_10th" local label "GPA (10th grade, 1.0-7.0)"
    else if "`var'" == "Attendance_10th" local label "Attendance (10th grade, \%)"
    else if "`var'" == "Public_School_10th" local label "Public School (10th grade, \%)"
    else if "`var'" == "Private_School_10th" local label "Private School (10th grade, \%)"
    else if "`var'" == "Math_Score_10th" local label "Math Score (10th grade, std.)"
    else if "`var'" == "Math_Confidence_10th" local label "Math Confidence (10th grade, \%)"
	else if "`var'" == "agg_physical" local label "Aggression: Physical (\%)"
	else if "`var'" == "agg_verbal" local label "Aggression: Verbal (\%)"
	else if "`var'" == "agg_social" local label "Aggression: Social (\%)"
	else if "`var'" == "agg_media" local label "Aggression: Social Media (\%)"
	else if "`var'" == "disc_sexo" local label "Discrimination: Sex (\%)"
	else if "`var'" == "disc_orientacion" local label "Discrimination: Sexual Orientation (\%)"
	else if "`var'" == "disc_expresion" local label "Discrimination: Expression or Looks (\%)"
	
	
    else if "`var'" == "N" local label "Sample Size"
    else local label "`var'"  // fallback
    
    file write myfile "`label'"
    foreach col in cis_man cis_woman trans_woman trans_man nb_male nb_female {
        local value = `col'[`i']
        file write myfile " & `value'"
    }
    file write myfile " \\" _n
}
file write myfile "\hline" _n
// Write the LaTeX table footer with note
file write myfile "\end{tabular}" _n
// Close the file
file close myfile
restore