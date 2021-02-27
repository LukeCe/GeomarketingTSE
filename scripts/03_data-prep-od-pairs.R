# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Prepare od-pair data
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# Create the pair data for the retail gravitation model.
# This comes down to generating the distances and the market share by pair of
# shop and IRIS
# = = = = = = = = = = = = = = = = = = =
# Date: February 2021

library("data.table")
library("dplyr")
library("here")
library("sf")
library("rrMD")


# Load data -------------------------------------------------------------------
source("R/helpers_data-import.R" %>% here())
load_raw_data <- get_raw_data_loaders()
load_raw_data$market_potential()
load_raw_data$client_customers()

load_clean_data <- get_clean_data_loaders()
load_clean_data$origin_iris()
load_clean_data$destination_shops()

# Generate od-pair-data -------------------------------------------------------
# customer data needs to be aggregated on iris level and we have to add
# distances as well as market shares

# 1) aggregate on OD pair level (O = IRIS; D = SHOP)
od_customer_flows <- as.data.table(client_customers) %>%
  setnames("pos_id", "ID_SHOP")
od_customer_flows[,.(SALES = sum(sales)),by = c("IRIS","ID_SHOP")]

# 2) add distance information
destination_shops$geometry
od_customer_flows[market_potential, ]


