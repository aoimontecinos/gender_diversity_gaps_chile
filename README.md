# Gender Diversity Gaps in Mathematics - Replication Package

Replication materials for "The Gender Diversity Gaps in Mathematics" (Francine Montecinos and Dante Contreras). The package contains Stata code for data construction, analysis, and outputs, plus an R script for propensity-score estimation.

## Data availability
- Agencia de la Calidad de la Educacion (SIMCE microdata, 10th grade 2022 and linked 4th grade 2012-2016): confidential; access requires a data request to the Agencia. These files are **not redistributed** here; place approved files in `Dropbox/Universidad/Tesis/data/src`.
- Ministerio de Educacion (MINEDUC) administrative data (teacher assignment records, GPA/attendance, study plans): open-access from MINEDUC; not redistributed here. Place downloads in `data/src` alongside SIMCE files.
- The pipeline writes intermediate data to `data/tmp` and `data/dta` and the merged analysis file `data/proc/simce_mineduc_elsoc_2022b.dta` used by the R script.

## Rights and permissions
- I certify that the authors have legitimate access to and permission to use all datasets employed in the manuscript.
- I certify that redistribution/publication of data in this replication package is permitted only for derived outputs; confidential SIMCE microdata are **not** redistributed. See `LICENSE` for code licensing.

## Repository layout
- `code/stata/0_makefile.do` - Entry point: sets globals/paths, logging, and runs the full Stata pipeline.
- `code/stata/1_data_construction.do` - Builds analysis-ready data from raw sources.
- `code/stata/1a_final_dataset.do` - Assembles the final dataset and calls the R propensity-score script via `rsource`.
- `code/stata/2_descriptives.do`, `2a_TableA1.do`, `2b_Figures.do` - Descriptive statistics and appendix table; `2b` is a placeholder.
- `code/stata/3_results.do`, `3a_Tables.do`, `3b_Figures.do`, `3c_results_gpa.do` - Main and GPA-focused results; `3a`/`3b` are placeholders.
- `code/stata/4_mechanisms.do` - Mechanism analyses.
- `code/stata/5_robustness.do` - Robustness checks (exact matching, heterogeneity, oaxaca).
- `code/stata/6_selection.do` - Selection correction appendix.
- `code/stata/xx_*` - Auxiliary/experimental analyses (e.g., peers, alternate descriptives, instruments).
- `code/stata/helpers/scheme-bluegray_tnr.scheme` - Custom Stata graph scheme.
- `code/R/01_ps_gbm.R` - Gradient-boosting propensity scores (twang) using the merged Stata data.

## Software and hardware used
- OS: Windows 11 Pro
- Hardware: AMD Ryzen 7 7730U with Radeon Graphics, 40 GB RAM, 2 TB SSD
- Stata 19.5 (code compatible with Stata 17+)
- R 4.5.1

## Required packages
**Stata (install from SSC unless noted)**
- `ftools` 
- `gtools` 
- `reghdfe`
- `estout` 
- `outreg2`
- `psmatch2`
- `oaxaca`

Install example:
```
ssc install ftools, replace
ssc install gtools, replace
ssc install reghdfe, replace
ssc install estout, replace
ssc install outreg2, replace
ssc install psmatch2, replace
ssc install oaxaca, replace
ssc install rsource, replace
```

**R (CRAN)**
`dplyr`, `ggplot2`, `tidyverse`, `lme4`, `merTools`, `twang`, `kableExtra`, `survey`, `parallel`, `haven` (explicitly used). Install with:
```
install.packages(c(
  "dplyr","ggplot2","tidyverse","lme4","merTools",
  "twang","kableExtra","survey","parallel","haven"
))
```

## How to run
1. Set the Dropbox root expected by the scripts. Edit `code/stata/0_makefile.do` to set `global dropbox "<your Dropbox path>"` before running. 
2. Place the SIMCE (confidential) and MINEDUC (open) raw files in `data/src` under that Dropbox path. The workflow writes intermediate files to `data/tmp` and `data/dta`.
3. Open Stata in the repository root and run:
   ```
   do code/stata/0_makefile.do
   ```
   This script sets globals, builds data, and executes `1_data_construction.do` -> `1a_final_dataset.do` (which calls the R script) -> `2_descriptives.do` -> `3_results.do` -> `4_mechanisms.do` -> `5_robustness.do` -> `6_selection.do`.

## Outputs
- Logs: `log/`
- Tables: `tables/` 
- Figures: `figures/`

## Expected runtime
- End-to-end pipeline (Stata + R) runs in about 1 hour on the hardware listed above.

## Data citations (for paper and README)
- Ministerio de Educacion de Chile (2024). Docentes por curso y subsector [open dataset]. Datos Abiertos, Ministerio de Educacion de Chile. From the "Docentes y Asistentes de la Educacion" section. Retrieved from https://datosabiertos.mineduc.cl (accessed August 2024).
- Ministerio de Educacion de Chile (2024). Rendimiento por estudiante [open dataset]. Datos Abiertos, Ministerio de Educacion de Chile. From the "Estudiantes y Parvulos" section. Retrieved from https://datosabiertos.mineduc.cl (accessed August 2024).
- Ministerio de Educacion de Chile (2024). Planes y programas de estudio [open dataset]. Datos Abiertos, Ministerio de Educacion de Chile. From the "Establecimientos educacionales" section. Retrieved from https://datosabiertos.mineduc.cl (accessed August 2024).
- Agencia de la Calidad de la Educacion (2024). Simce segundo medio dataset (2022). Dataset from Agencia de la Calidad de la Educacion, Chile. Includes Segundo Medio data for year 2022; retrieved from https://www.agenciaeducacion.cl (accessed August 2024). Confidential; available upon request.
- Agencia de la Calidad de la Educacion (2024). Simce cuarto basico dataset (2012-2016). Dataset from Agencia de la Calidad de la Educacion, Chile. Includes Cuarto Basico data for years 2012-2016; retrieved from https://www.agenciaeducacion.cl (accessed August 2024). Confidential; available upon request.

## Used datasets and replication status
- Empirical analysis with confidential SIMCE microdata (not redistributed). MINEDUC administrative data are open-access but not included here. Cleaning and analysis code for all tables/figures is included; no synthetic data are used.
