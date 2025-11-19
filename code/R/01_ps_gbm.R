#------------------------------------------------------------------------------
# Author: Francine Montecinos.
# Creation: May 29, 2024.
# Last edition: November 17, 2025
# Action: Propensity Score estimation among gender categories.
#------------------------------------------------------------------------------
# Importing relevant packages 
#------------------------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(tidyverse)
library(lme4)
library(merTools)
library(twang)
library(kableExtra)
library(survey)
library(parallel)

#------------------------------------------------------------------------------
# Set locals and defining the environment 
#------------------------------------------------------------------------------

if (Sys.info()["user"] == "aoimo") {
  dropbox <- "C:/Users/aoimo/Dropbox"
}

if (Sys.info()["user"] == "fam2175") {
  dropbox <- "/Users/fam2175/Dropbox/"
}

dir <- paste0(dropbox, "/PROJECT_Gender_Diversity_Gaps")
data <- paste0(dir, "/data")

src <- paste0(data, "/src")
tmp <- paste0(data, "/tmp")
proc <- paste0(data, "/proc")

tables <- paste0(dir, "/tables")
figures <- paste0(dir, "/figures")

#------------------------------------------------------------------------------
# 1. Data manipulation 
#------------------------------------------------------------------------------

# Define all variables to keep
final_controls <- c(
  # Demographics
  "edad_alu_dm", "edad_alu2_dm", "income_decile_cat_1_dm", "income_decile_cat_2_dm",
  "income_decile_cat_3_dm", "income_decile_cat_4_dm", "income_decile_cat_5_dm", 
  "income_decile_cat_6_dm", "income_decile_cat_7_dm", "income_decile_cat_8_dm", 
  "income_decile_cat_9_dm", "mother_education_cat_1_dm", "mother_education_cat_2_dm",
  "mother_education_cat_3_dm", "mother_education_cat_4_dm", "mother_education_cat_5_dm", 
  "mother_education_cat_6_dm", "mother_education_cat_7_dm", "mother_education_cat_8_dm", 
  "immigrant_parents_dm", "indigenous_parents_dm", "school_change_dm",
  
  # 4th grade controls
  "math_norm_4to", "math_confidence_4to", 
  "dependencia4_1", "dependencia4_2", "dependencia4_3", 
  "prom_gral4_norm", "asistencia4_norm",
  
  # Extra 
  "imr"
)

# Read the Stata file

base = haven::read_dta(paste0(proc,"/simce_mineduc_elsoc_2022b.dta"))

base = base %>% 
  distinct_at(vars(mrun), .keep_all = TRUE) %>% as.data.frame() %>% 
  dplyr::select(mrun,final_controls,
                math_norm,codigocurso, rbd, gender, genders) %>% 
  mutate(genders = genders %>% as.factor(),
                   gender = gender %>% as.factor()) %>% drop_na()


#------------------------------------------------------------------------------
# 2 Implementing the propensity score
#------------------------------------------------------------------------------
# Specification 
formula <- as.formula(paste("genders ~", paste(final_controls, collapse = " + ")))

mnps.base <- mnps(formula,
                    data = base,
                    estimand = "ATE",
                    verbose = 0,
                    stop.method = c("es.mean", "ks.mean"),
                    n.trees = 2000,
                    shrinkage = 0.01,
                    bag.fraction = 0.95)


# Save Data 
base$w1 <- get.weights(mnps.base, stop.method = "es.mean")
  
  base$w2 <- get.weights(mnps.base, stop.method = "ks.mean")
  
  haven::write_dta(base,paste0(tmp,"/simce_mineduc_elsoc_2022_psm.dta"))


#------------------------------------------------------------------------------
# 3.1 Descriptive Statistics about the performance of the PSM 
#------------------------------------------------------------------------------
# Note: S.E = Standardized Effect Size.
# Balance criteria as a function of the GBM iteration. 
plot(mnps.base, plots = 1, figureRows = 3)[[0]]
