# Gender Diversity Gaps in Mathematics

This repository hosts code for the paper "The Gender Diversity Gaps in Mathematics" (Francine Montecinos and Dante Contreras). Stata scripts build and analyze the dataset; an R script estimates propensity scores across gender categories.

## Layout
- `code/R/01_ps_gbm.R` � Propensity score estimation with gradient boosting (twang) and related data prep.
- `code/stata/0_makefile.do` � Entry point: sets paths, globals, logging, and runs the full Stata pipeline.
- `code/stata/1_data_construction.do` � Builds analysis-ready data from raw sources.
- `code/stata/1a_final_dataset.do` � Assembles the final dataset used downstream.
- `code/stata/2_descriptives.do` � Descriptive statistics and summarized outputs.
- `code/stata/2a_TableA1.do` � Appendix Table A1 generation.
- `code/stata/2b_Figures.do` � Placeholder for descriptive figures (currently empty).
- `code/stata/3_results.do` � Main regression results using globals defined in `0_makefile`.
- `code/stata/3a_Tables.do` / `code/stata/3b_Figures.do` � Placeholders for main tables/figures.
- `code/stata/3c_results_gpa.do` � GPA-focused results.
- `code/stata/4_mechanisms.do` � Mechanism analyses.
- `code/stata/5_robustness.do` � Robustness checks.
- `code/stata/6_selection.do` � Selection correction appendix.
- `code/stata/xx_*` � Additional experimental/auxiliary analyses (energy instrument, peers, alternate descriptives).
- `code/stata/helpers/` � Visualization scheme `scheme-bluegray_tnr.scheme`.

## Running the Stata workflow
1. Open Stata at the repository root and run `do code/stata/0_makefile.do`.
2. The makefile sets globals assuming Dropbox paths for users `aoimo` or `fam2175`:
   - Base: `~/Dropbox/Universidad/Tesis`
   - Data: `$data` -> `data/` with `src`, `tmp`, `dta` subfolders
   - Outputs: `log/`, `results/`, `figures/`, `tables/`
3. Required Stata packages (per comments): `estout`, `reghdfe`, `twang`, `rsource`, plus any dependencies noted in individual scripts.

## R propensity score script
- `code/R/01_ps_gbm.R` reads `data/proc/simce_mineduc_elsoc_2022b.dta`, constructs controls, and runs twang-based GBM propensity scores across gender categories. Paths are tied to the same Dropbox structure and user checks as the Stata code.

## Notes
- The repository currently tracks only code; raw data must live in the Dropbox `data` directories referenced above.
- Placeholder `.do` files (`2b_Figures.do`, `3a_Tables.do`, `3b_Figures.do`) are present for future outputs.
