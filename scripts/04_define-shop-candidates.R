# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Define the candidates to evaluate
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# Create a data frame of candidate shops that will be evaluated using our
# models.
# = = = = = = = = = = = = = = = = = = =
# Date: February 2021


# declare libraries
library("data.table")
library("dplyr")
library("here")
library("rrMD")
library("sf")
library("stringr")
source("R/helper-02_generate-destination-data.R")

# declare data sources
source("R/helpers_data-import.R" %>% here())
load_raw_data <- get_raw_data_loaders()
load_clean_data <- get_clean_data_loaders()


# 1) Candidate (point) selection ----------------------------------------------
# The simplest method to select candidates is random from the set of
# competitors.
set.seed(123)
shop_candidates <- list(
  "random" = load_raw_data$competitors() %>% sample_n(10) %>%
    select(LON = "longitude", LAT = "latitude"))



# 2) Candidate description ----------------------------------------------------
# The candidate must be described by the same data as the list of client shops
client_shops <- load_clean_data$destination_shops()
describe_candidates <- function(shop_candidates) {
  new_ids <- seq_len(nrow(shop_candidates)) + nrow(client_shops)

  new_shops <- st_as_sf(shop_candidates,coords = c("LON","LAT")) %>%
    st_set_crs(st_crs(client_shops)) %>%
    mutate(ID_SHOP = as.character(new_ids)) %>% select(ID_SHOP)

  competing_shops <- load_raw_data$competitors() %>%
    st_as_sf(coords = c("longitude","latitude")) %>%
    `st_crs<-`(st_crs(client_shops)) %>%
    select(SIREN)

  competitor_distances <- c(.1,.5,1,2)
  competitor_counts <- competitor_distances %>%
    lapply(function(d) new_shops %>% create_buff_zone(d)) %>%
    lapply(function(z) count_points_in_zone(z,"ID_SHOP",competing_shops)[,2]) %>%
    as.data.frame() %>%
    setnames("COMPETE_DIST" %p% competitor_distances)

  cbind(new_shops,competitor_counts - 1)
}
candidate_shops <- lapply(shop_candidates,"describe_candidates")


# 3) Export the candidates ----------------------------------------------------
candidate_fits_client <- lapply(candidate_shops, "rbind", client_shops) %>%
  lapply(is.data.frame) %>%
  unlist() %>%
  all()
stopifnot(candidate_fits_client)

saveRData(candidate_shops,file_name = "candidate-shops")


