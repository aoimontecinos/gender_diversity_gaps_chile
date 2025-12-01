*______________________________________________________________
* Author: Francine Montecinos
* Last edition: November 17, 2025
* Action: Descriptive Statistics and Figures 
*______________________________________________________________

* Load Data
use "$data/proc/main.dta", clear

*______________________________________________________________
* Run Table A1: Descriptives
*______________________________________________________________
do "$code/stata/2a_TableA1.do"

*______________________________________________________________
**# Descriptive Figures
*______________________________________________________________

*--------------------------------------------------------------
* Aggressions
*--------------------------------------------------------------
* Without controls 

* Bullying 
eststo clear
eststo m1: qui reghdfe physical i.gender, absorb(rbd) vce(cl codigocurso)
qui margins gender, post
eststo m2: qui reghdfe verbal i.gender, absorb(rbd) vce(cl codigocurso)
qui margins gender, post
eststo m3: qui reghdfe social i.gender, absorb(rbd) vce(cl codigocurso)
qui margins gender, post
eststo m4: qui reghdfe media i.gender, absorb(rbd) vce(cl codigocurso)
qui margins gender, post


coefplot (m1, offset(-.375) color(blue%50) ///
		ciopts(color(blue) recast(rcap))) ///
        (m2, offset(-0.125) color(midblue%50) ///
		ciopts(color(midblue) recast(rcap))) ///
		(m3, offset(.125) color(pink%50) ///
		ciopts(color(pink) recast(rcap))) ///
		(m4, offset(.375) color(red%50) ///
		ciopts(color(red) recast(rcap))), ///
        keep(*gender) ///
        recast(bar) barwidth(0.25) ///
        citop ciopt(recast(rcap)) ///
        yscale(range(0 6)) ///
		ylabel(,noticks) ///
        xlabel(-.1(0.05)0.3, format(%3.2f)) ///
        ytitle("") xline(0, lpattern(dash)) ///
		xtitle("Percent of students who reported aggressions compared to cis boys", ///
		size(medsmall)) ///
        legend(order(1 "Physical" 3 "Verbal" ///
		5 "Social" 7 "Social Media") ///
        pos(6) rows(1) size(medsmall) ///
        symxsize(*1.5) symysize(*1.5)) ///
        eqlabels("Cis girls" "Trans girls" ///
		"Trans boys" "NB AMABs" "NB AFABs")

graph export "$figures/Figure_A2b.pdf", replace

*-------------------------------------------------
* Correlation between aggressions and math score
*-------------------------------------------------
xtile math_deciles = math_norm, nq(10)

local i = 0
foreach vv of varlist physical verbal social media {
qui{
local i = `i' + 1
reghdfe `vv' i.math_deciles, absorb(rbd)
eststo m`i': margins math_deciles, post
}
}

coefplot ///
(m1, offset(-.375) color(blue%50) ///
ciopts(color(blue) recast(rcap))) ///
(m4, offset(-0.125) color(red%50) ///
ciopts(color(red) recast(rcap))) ///
(m3, offset(.125) color(pink%50) ///
ciopts(color(pink) recast(rcap))) ///
(m2, offset(.375) color(midblue%50) ///
ciopts(color(midblue) recast(rcap))), ///
vertical ///
xtitle("Math Score Decile", size(medsmall)) ///
ytitle("Percent of students who reported aggressions", size(medsmal)) ///
xlabel(1 "D1" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10") ///
legend(order(2 "Physical" 4 "Social Media" 6 "Social" 8 "Verbal") ///
pos(6) row(1) size(medsmall))

graph export "$figures/Figure_A2a.pdf", replace

*----------------------------------------------------
* Raw Math Confidence Gap by Math Score. 3 Genders
*----------------------------------------------------

gen gender_diverse = gender 
replace gender_diverse = 3 if gender>=3 & gender<=6

binsreg math_confidence_2do math_norm, by(gender_diverse) ///
ytitle("Math Confidence at 10th grade", size(medsmall))  ///
xtitle("Math Score at 10th grade", size(medsmall)) savedata("$tmp/fig_aux") nbins(15)

preserve 
use "$tmp/fig_aux.dta", clear 

tw (scatter dots_fit dots_x if gender==1, color(blue%80) msymbol(O)) ///
(scatter dots_fit dots_x if gender==2, color(ebblue%80) msymbol(D)) ///
(scatter dots_fit dots_x if gender==3, color(cranberry%80) msymbol(T)), ///
legend(order(1 "Cis boys" 2 "Cis girls" 3 "Gender Diverse Students") row(1)) ///
ytitle("Math Confidence at 10th grade", size(medsmall)) name(binsreg_raw, replace) ///
xtitle("Math Score at 10th grade", size(medsmall)) yscale(range(.35 1)) ylabel(.4(.1)1)

graph export "$figures/Figure_1.pdf", replace

rm "$tmp/fig_aux.dta"
restore 
