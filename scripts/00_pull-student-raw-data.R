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
load_raw_data <- get_raw_data_loaders()
market_potential <- load_raw_data$market_potential()
client_customers <- load_raw_data$client_customers()
client_shops <- load_raw_data$client_shops()
siren_competitors <- load_raw_data$competitors()


# Export the data as input for the students -----------------------------------
# The server has an old R version that requires compression level 2
student_data_dir <- here("") %p% "../"
save_as_v2 <- function(..., file_path) save(..., file = file_path,version = 2)
file.pth <- function(nam) student_data_dir %p% nam %p% ".RData"
save_as_v2(market_potential,file_path =  file.pth("market_potential"))
save_as_v2(client_customers,file_path =  file.pth("client_customers"))
save_as_v2(client_shops,file_path =  file.pth("client_shops"))
save_as_v2(siren_competitors,file_path =  file.pth("siren_competitors"))
