# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Prepare model data
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# Create data frames that can be used to fit the models following models;
# - LM (linear model)
# - MCI (Multiplicative Competitive Interaction Model)
# The model data is identified on origin-destination pairs.
# = = = = = = = = = = = = = = = = = = =
# Date: February 2021


# declare libraries
library("data.table")
library("dplyr")
library("here")
library("rrMD")
library("sf")
library("stringr")

# declare data sources
source("R/helpers_data-import.R" %>% here())
load_clean_data <- get_clean_data_loaders()

# 1) merge the orig, dest and pair data ---------------------------------------
orig_iris <- load_clean_data$origin_iris() %>% setDT()
dest_shops <- load_clean_data$destination_shops() %>% setDT()
dest_shops[,COMPETITION_RADIUS_100M :=
             COMPETE_DIST0.1]
dest_shops[,COMPETITION_RADIUS_500M :=
             COMPETE_DIST0.5 - COMPETITION_RADIUS_100M]
dest_shops[,COMPETITION_RADIUS_1000M :=
             COMPETE_DIST1 - COMPETITION_RADIUS_500M]
dest_shops[,COMPETITION_RADIUS_2000M :=
             COMPETE_DIST2 - COMPETITION_RADIUS_1000M]

od_market_shares <- load_clean_data$od_market_shares() %>% setDT()

keep_vars_orig <- c("POP","MEDIAN_INCOME","MARKET_POTENTIAL")
keep_vars_dest <- names(dest_shops) %>%
  lfilter(function(x) grepl("COMPETITION_RADIUS_*",x))
drop_vars_od <- names(od_market_shares) %>%
  lfilter(function(x) grepl(".*_(LON|LAT)",x))

od_market_shares[orig_iris,
                 (keep_vars_orig) := mget(keep_vars_orig), on = "ID_IRIS"]
od_market_shares[dest_shops,
                 (keep_vars_dest) := mget(keep_vars_dest), on = "ID_SHOP"]
od_market_shares[, (drop_vars_od):= NULL ]



# 2) treat missing data -------------------------------------------------------
# for now we remove observations that are not conform
od_market_shares <- od_market_shares[
  complete.cases(od_market_shares)
  & MARKET_SHARE > 0
  & MARKET_SHARE < 1,]

# 3) transform for MCI --------------------------------------------------------
# the MCI model requires to transform variables

# TODO find out how to make the right transformations for the MCI model
# ... 1) problem for origin variables => geometric mean loses meaning
# ... 2) we have to get an estimate of the geometric average of the market
# ...    share for all stores that sell to a given location.
# ... 3) we have to get an estimate of the geometric average of the distances
# ...    (competitor stores ? -> )
# ... 4) destination variables => impute the geometric mean?

# Export data the data that will be used for the models -----------------------
# LM model does not require transformation
out_file_LM <- "od_market_shares_lm"
saveRData(od_market_shares, file_name = out_file_LM)

# # MCI model requires transformation (look section 3)
# out_file_MCI <- "od_market_shares_mci"
# saveRData(od_market_shares, file_name = out_file_MCI)
