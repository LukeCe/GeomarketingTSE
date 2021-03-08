# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Fit the market share model
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# Estimate models to explain the market share.
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
trade_area_data <- load_clean_data$trade_area_dist_stats()$TA_D10KM %>% setDT()

model_data <- od_data
all_cols <- names(trade_area_data) %>% setdiff("ID_SHOP")
model_data[trade_area_data, (all_cols) := mget("i." %p% all_cols),on = "ID_SHOP"]

# 1) fit the baseline model for market share ----------------------------------
base_line_formula <-
  logit(MARKET_SHARE) ~
  log(GC_DIST_KM) + log(POP + 1) + log(MARKET_POTENTIAL) + MEDIAN_INCOME +
     COMPETITION_RADIUS_100M + COMPETITION_RADIUS_500M + COMPETITION_RADIUS_1000M +
     COMPETITION_RADIUS_2000M + TA_D10KM_POP + TA_D10KM_MARKET_POTENTIAL +
     TA_D10KM_DIFF_MEDIAN_INCOME + TA_D10KM_MEAN_MEDIAN_INCOME +
     TA_D10KM_NB_IRIS

logit <- function(x) log(x/(1-x))

base_line_sales_model <-
  lm(base_line_formula, data = model_data %>% select(-starts_with("ID_")),weights = MARKET_POTENTIAL)
if_int(base_line_sales_model %>% summary())


# 2) export the market share model --------------------------------------------
market_share_model <- list(
  "base_line" = base_line_sales_model)

saveRData(market_share_model,file_name = "model-market-share")
