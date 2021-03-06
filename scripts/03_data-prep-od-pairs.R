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


# declare libraries
library("data.table")
library("dplyr")
library("geosphere")
library("here")
library("sf")
library("rrMD")
source("R/helper-03_data-prep-od-pairs.R")

# declare data sources
source("R/helpers_data-import.R" %>% here())
load_raw_data <- get_raw_data_loaders()
load_clean_data <- get_clean_data_loaders()

# 1) identify customers with current IRIS geometries --------------------------
origin_iris <- load_clean_data$origin_iris()
od_customer_flows <- load_raw_data$client_customers() %>%
  as.data.table() %>%
  setnames(c("pos_id","IRIS"), c("ID_SHOP","ID_IRIS_OLD")) %>%
  st_as_sf(coords = c("cl_lon","cl_lat")) %>%
  st_set_crs("WGS84") %>%
  st_transform(st_crs(origin_iris)) %>%
  st_join(origin_iris %>% select("ID_IRIS"))

# 2) aggregate on OD pair level (O = IRIS; D = SHOP) --------------------------
od_market_shares <-
  as.data.table(od_customer_flows
                )[,.(SALES = sum(sales)),by = c("ID_IRIS","ID_SHOP")]

# 3) add market share information ---------------------------------------------
od_market_shares[origin_iris, MARKET_SHARE := SALES/i.MARKET_POTENTIAL,
                  on = "ID_IRIS"]

# 4) add distance information -------------------------------------------------
# first get coordinates, then compute the great circle distance
suppressWarnings({
  orig_coord <- origin_iris %>%
    st_geometry() %>%
    st_point_on_surface() %>%
    st_transform("WGS84") %>%
    lreduce("rbind") %>%
    as.data.table() %>%
    setnames(c("ORIG_LON","ORIG_LAT"))
  orig_coord[, ID_IRIS := origin_iris$ID_IRIS]

  dest_coord <- destination_shops$geometry %>%
    st_geometry() %>%
    st_transform("WGS84") %>%
    lreduce("rbind") %>%
    as.data.table() %>%
    setnames(c("DEST_LON","DEST_LAT"))
  dest_coord[, ID_SHOP := destination_shops$ID_SHOP]
})
add_orig_coord <- "ORIG_" %p% c("LON","LAT")
od_market_shares[orig_coord,
                  (add_orig_coord) := mget(paste0("i.", add_orig_coord)),
                  on = "ID_IRIS"]
add_dest_coord <- "DEST_" %p% c("LON","LAT")
od_market_shares[dest_coord,
                  (add_dest_coord) := mget(paste0("i.", add_dest_coord)),
                  on = "ID_SHOP"]
od_market_shares %>% add_pair_dist()

# Export origin-destination pair data -----------------------------------------
out_file <- "od_market_shares"
saveRData(od_market_shares,file_name = out_file)
