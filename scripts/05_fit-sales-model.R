# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Estimate a model for sales
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# Estimate linear models to explain the sales.
# This model is used to define the customer trade area.
# = = = = = = = = = = = = = = = = = = =
# Date: March 2021

# declare libraries
library("data.table")
library("dplyr")
library("here")
library("rrMD")
library("sf")
library("stringr")
library("stargazer")

# declare data sources
source("R/helpers_data-import.R" %>% here())
load_clean_data <- get_clean_data_loaders()
od_data <- load_clean_data$od_model_data()

# 1) fit the baseline model for sales -----------------------------------------
base_line_variables <-
  c("SALES","GC_DIST_KM","POP","MEDIAN_INCOME","MARKET_POTENTIAL")
base_line_formula <-
  log(SALES) ~
  log(GC_DIST_KM) + log(POP + 1) + log(MARKET_POTENTIAL) +
  MEDIAN_INCOME

base_line_sales_model <-
  lm(base_line_formula,
     data = od_data %>% select(base_line_variables),)
if_int(base_line_sales_model %>% summary())


# 2) export the sales model
sales_model <- list(
  "base_line" = base_line_sales_model)

saveRData(sales_model,file_name = "model-sales")
