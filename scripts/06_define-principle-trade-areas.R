# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Define the trade areas
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# The customer trade area (TA) is the part of the market for which each store
# tries to maximize its market share.
# We can use different heuristics to define this area.
# - based on turnover (-> rankings of IRIS)
# - based on distance (-> Voroni)
# - based on combined criteria (-> predicted turnover)
# The output is a ranking of all IRIS that should reveal the cumulative market
# share.
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
load_model <- get_model_loaders()

od_data <- load_clean_data$od_model_data()
current_shops <- load_clean_data$destination_shops()
sales_baseline_model <- load_model$sales()$base_line



# 1) distance based trade areas (TA_D) ----------------------------------------
market_zones <- load_clean_data$origin_iris() %>% select(ID_IRIS)
origin_iris <- load_clean_data$origin_iris() %>% setDT()
current_shops <- load_clean_data$destination_shops() %>%
  select(ID_SHOP)
candidate_method <- "random"
candidate_shops <- load_clean_data$candidate_shops()[[candidate_method]] %>%
  select(ID_SHOP)
shop_collections <- rbind(current_shops,candidate_shops) %>%
  st_transform(st_crs(market_zones))

shop_to_zone_distances <- st_distance(shop_collections,market_zones)
units(shop_to_zone_distances) <- "km"
units(shop_to_zone_distances) <- NULL

# Check which iris are at a given distance threshold
collect_shop_zones <- function(x) {
  collect_zones <- function(z) market_zones$ID_IRIS[z]

  apply(shop_to_zone_distances < 5, 1, collect_zones) %>%
    set_lnames(shop_collections$ID_SHOP)
  }
distance_thresholds <- c(2,5,10,20,50)
dist_ta_collection <- distance_thresholds %>%
  lookup(., "TA_D" %p% . %p% "KM") %>%
  lapply("collect_shop_zones")


# Create statistics to describe this set of IRIS
describe_zone <- function(ids){
  relevant_zone <- copy(origin_iris[ID_IRIS %in% ids, ])
  summarise_zone <- relevant_zone[
    ,list(POP = sum(POP),
          MARKET_POTENTIAL = sum(MARKET_POTENTIAL),
          DIFF_MEDIAN_INCOME = diff(range(MEDIAN_INCOME)),
          MEAN_MEDIAN_INCOME = weighted.mean(MEDIAN_INCOME,POP),
          NB_IRIS = length(ID_IRIS))]

}
describe_dist_ta_zones <- function(ta,ta_key) {
  ta %>% lapply(describe_zone) %>% lreduce("rbind") %>% setDT() %>%
    prefix_columns(ta_key %p% "_") %>%
    cbind(shop_collections %>% st_drop_geometry(),.)
}


dist_ta_stats <- dist_ta_collection %>%
  plapply(ta = ., ta_key = names(.),.f = describe_dist_ta_zones)

# export zone ids and stats
saveRData(dist_ta_stats, file_name = "distance-trade-area-stats")
saveRData(dist_ta_collection, file_name = "distance-trade-area-zones")

# 2) Turnover base trade area using a model (TA_M) ----------------------------
# The model trade based trade area uses a percentage of estimated turnover
# and a ranking.
# The trade zone contains all IRIS until the percentage of turnover is reached
# and ranking can be based only on turnover (TA_MT) or distance (TA_MD).

# TODO check the model based trade areas
# # a) from the base line model
# od_data[, FIT_SALES_BASELINE := exp(predict(sales_baseline_model,od_data))]
# od_data[, TA_ORDER_IRIS := frank(SALES,ties.method = "random"),
#         by = c("ID_SHOP")]
# od_data[order(ID_SHOP,TA_ORDER_IRIS),]
#
# define_turnover_trade_areas <- function(.data, .model, .trans){
#   .trans <- getFunction(.trans)
#   .data <- copy(.data) %>% setDT()
#   .data[,FIT_SALES := .trans(predict(.model, .data,type = "response"))]
#
#   # Ranking based on predicted turnover only
#   .data[, TTA_ORDER := frank(FIT_SALES,ties.method = "random"),
#         by = "ID_SHOP"]
#   .data[order(TTA_ORDER), TTA_PART := 1 - (cumsum(FIT_SALES) / sum(FIT_SALES)),
#         by = "ID_SHOP"]
#
#   # Ranking based on predicted turnover orderd by distance only
#   .data[, DTA_ORDER := frank(GC_DIST_KM,ties.method = "random"),
#         by = "ID_SHOP"]
#   .data[order(DTA_ORDER), DTA_PART := 1 - (cumsum(FIT_SALES) / sum(FIT_SALES)),
#         by = "ID_SHOP"]
#
#   .data$TA_PART
# }
#
# od_data[ TTA_]
# TA <- od_data %>% define_turnover_trade_areas(sales_baseline_model,"exp")
