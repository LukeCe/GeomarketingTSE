# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Prepare destination data
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# This script creates the dataset used to describe the destinations in our
# retail gravity model.
# The destinations correspond to the shops of our client.
# - - - - - - - - - - - - - - - - - - -
# Date: February 2021

library("data.table")
library("geosphere")
library("dplyr")
library("here")
library("sf")
library("rrMD")
source('R/helper-02_generate-destination-data.R' %>% here())

# Load data -------------------------------------------------------------------
source("R/helpers_data-import.R" %>% here())
load_raw_data <- get_raw_data_loaders()
client_shops <- load_raw_data$client_shops()
client_customers <- load_raw_data$client_customers()
sirene_competitors <- load_raw_data$competitors()


# Generate the origin data ----------------------------------------------------
# the destination list is the complete set of shops of our customer
client_shops <- st_as_sf(client_shops) %>%
  rename(ID_SHOP = "pos_id")

# 1) add the number of competitors
competing_shops <- sirene_competitors %>%
  st_as_sf(coords = c("longitude","latitude")) %>%
  `st_crs<-`(st_crs(client_shops)) %>%
  select(SIREN)

shops_0.5km_zone <- client_shops %>% create_buff_zone(.5)
shops_1km_zone <- client_shops %>% create_buff_zone(1)
shops_5km_zone <- client_shops %>% create_buff_zone(5)
shops_10km_zone <- client_shops %>% create_buff_zone(10)

competitor_distances <- c(.1,.5,1,2)
competitor_counts <- competitor_distances %>%
  lapply(function(d) client_shops %>% create_buff_zone(d)) %>%
  lapply(function(z) count_points_in_zone(z,"ID_SHOP",competing_shops)[,2]) %>%
  as.data.frame() %>%
  setnames("COMPETE_DIST" %p% competitor_distances)

destination_shops <- client_shops %>%
  select(-pos_lon, -pos_lat) %>%
  cbind(competitor_counts)

# Export destination data -----------------------------------------------------
out_file <- "destination_shops"
save(destination_shops, file = dir_out_data() %p% out_file)
