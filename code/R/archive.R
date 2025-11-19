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

tesis <- paste0(dropbox, "/PROJECT_Gender_Diversity_Gaps")
data <- paste0(tesis, "/data")

src <- paste0(data, "/src")
tmp <- paste0(data, "/tmp")
proc <- paste0(data, "/proc")

tables <- paste0(tesis, "/tables")
figures <- paste0(tesis, "/figures")

#------------------------------------------------------------------------------
# 1. Data manipulation 
#------------------------------------------------------------------------------

# Define all variables to keep
final_controls <- c(
  # Demographics
  "edad_alu", "edad_alu2", "income_decile_1", "income_decile_2", "income_decile_3",  
  "income_decile_4", "income_decile_5", "income_decile_6", "income_decile_7",  
  "income_decile_8",  "income_decile_9",  "income_decile_10", "mother_education_cat_1",
  "mother_education_cat_2", "mother_education_cat_3", "mother_education_cat_4",
  "mother_education_cat_5", "mother_education_cat_6", "mother_education_cat_7",
  "mother_education_cat_8", "mother_education_cat_9", "mother_education_cat_10",
  "mother_education_cat_11", "immigrant_parents", "indigenous_parents",
  "school_change",
  
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
# 2.2 Implementing the propensity score
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


#=============================================================
# OLD CODE APPENDIX
#=============================================================

#------------------------------------------------------------------------------
# 2.1 Functions and iterations to obtain the best propensity score
#------------------------------------------------------------------------------
# Specification 
formula <- as.formula(paste("genders ~", paste(final_controls, collapse = " + ")))

# Parameter grids
n_trees_grid <- c(1000)
shrinkage_grid <- c(0.001, 0.005, 0.01)
bag_fraction_grid <- c(0.9, 1.0)

# Function to evaluate model performance
evaluate_mnps <- function(n_trees, shrinkage, bag_fraction) {
  model <- mnps(formula,
                data = base,
                estimand = "ATE",
                verbose = 0,
                stop.method = c("es.mean", "ks.mean"),
                n.trees = n_trees,
                shrinkage = shrinkage,
                bag.fraction = bag_fraction)
  
  # Extract balance statistics
  balance_stats <- summary(model)$balance
  
  # Return mean of es.mean and ks.mean
  return(mean(c(balance_stats$es.mean.ATE, balance_stats$ks.mean.ATE)))
}



## Grid Search
# Create the parameter grid
results <- expand.grid(n_trees = n_trees_grid,
                       shrinkage = shrinkage_grid,
                       bag_fraction = bag_fraction_grid)

# Applying the function
results$balance_metric <- mapply(evaluate_mnps, 
                                 results$n_trees, 
                                 results$shrinkage, 
                                 results$bag_fraction)

# Best parameters
best_params <- results[which.min(results$balance_metric), ]
