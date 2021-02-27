# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Prepare origin data
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# This script creates the dataset used to describe the origin_iris in our retail
# gravity model.
# The origin_iris are by the list of unique IRIS from where the customers of our
# are coming.
# - - - - - - - - - - - - - - - - - - -
# Date: February 2021

library("data.table")
library("dplyr")
library("here")
library("rrMD")


# Load data -------------------------------------------------------------------
source("R/helpers_data-import.R" %>% here())
iris_pop <- load_raw_data$iris_pop()
market_potential <- load_raw_data$market_potential()
iris_income <- load_raw_data$iris_income()
mun_income <- load_raw_data$mun_income()

# Generate the origin data ----------------------------------------------------
# the origin list is the complete set of iris as in the census data

# 1) start from the demography at the origin_iris
origin_iris <- iris_pop %>%
  transmute(ID_IRIS = IRIS, ID_MUN = COM, POP = P17_POP) %>%
  setDT()

# 2) add income information (from IRIS if available from MUN if not)
iris_income %>% setDT()
mun_income %>% setDT()
origin_iris[iris_income, INC1 := DISP_MED17, on = c(ID_IRIS = "IRIS")]
origin_iris[mun_income, INC2 := Q217, on = c(ID_MUN = "CODGEO")]
origin_iris[is.na(INC1), MEDIAN_INCOME := INC2]
origin_iris[!is.na(INC1), MEDIAN_INCOME := INC1]
origin_iris[, c("INC1","INC2","ID_MUN") := NULL]

# 3) add market potentials
market_potential %>% setDT()
origin_iris[market_potential, MARKET_POTENTIAL := mp, on = c(ID_IRIS = "IRIS")]

# Export origin data ----------------------------------------------------------
save(origin_iris,file = dir_out_data() %p% "origin_iris")
