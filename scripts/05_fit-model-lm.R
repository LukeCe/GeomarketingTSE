# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Project: Geomarketing 2021 Final Project - Estimate linear models
# Author: Lukas Dargel
# = = = = = = = = = = = = = = = = = = =
# Description:
#
# Estimate linear models to explain the market share or sales for a given store
# from all customer at given IRIS.
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


# 1) fit a model for sales ----------------------------------------------------
od_data <- load_clean_data$od_model_data()

# fit models
dont_model <-  c("ID_IRIS","ID_SHOP","MARKET_SHARE")
sales_lm <- list(
  "default" = lm(SALES ~ ., data = od_data %>% select(-dont_model)),
  "log" = lm(log(SALES) ~ ., data = od_data %>% select(-dont_model)),
  "loglog" = lm(log(SALES) ~ ., data = od_data %>% select(-dont_model) %>%
                  mutate_at(vars(-SALES), ~log(.x + 1)))
)

if_int({
  stargazer(sales_lm, type = "text", column.labels = names(sales_lm))
})

# 2) fit a model for market shares --------------------------------------------

# fit models
dont_model <-  c("ID_IRIS","ID_SHOP","SALES")
logit <- function(x) { log(x/(1-x))}
marlet_share_lm <- list(
  "logit_default" = lm(logit(MARKET_SHARE) ~ ., data = od_data %>% select(-dont_model)),
  "log_default" = lm(log(MARKET_SHARE) ~ ., data = od_data %>% select(-dont_model)),
  "logit_log" = lm(logit(MARKET_SHARE) ~ ., data = od_data %>% select(-dont_model) %>%
                  mutate_at(vars(-MARKET_SHARE), ~log(.x + 1))),
  "loglog" = lm(log(MARKET_SHARE) ~ ., data = od_data %>% select(-dont_model) %>%
                     mutate_at(vars(-MARKET_SHARE), ~log(.x + 1)))
)

if_int({
  stargazer(marlet_share_lm,
            type = "text")
})
