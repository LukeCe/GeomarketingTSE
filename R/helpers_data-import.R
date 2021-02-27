get_raw_data_loaders <- function(){
  # 1. Declare data sources
  raw_data_location <- "~/Projects/DataLake/data/"
  import_files <- list(
    competitors = "0016-1_tse-geomarketing-trade-register-competitiors_bva.RData",
    market_potential = "0014-1_tse-geomarketing-market-potential_bva.RData",
    client_shops = "0009-1_tse-geomarketing-shops_bva.RData",
    client_customers = "0010-1_tse-geomarketing-customers_bva.RData",
    iris_pop = "0002-1_iris-pop-2017_insee.RData",
    iris_income = "0004-1_iris-income-2017_insee.RData",
    mun_income = "0018-1_fr-mun-income-2017_insee.RData") %>%
    lapply(FUN = function(s) paste0(raw_data_location,s))


  # 2. Assign importers
  import_functions <- import_files %>%
    lapply(function(f) x <- function() rrMD::load_as(f))
}

get_clean_data_loaders <- function(){
  # 1. Declare data sources
  clean_data_location <- rrMD::dir_out_data()
  import_files <- list(
    origin_iris = "origin_iris",
    destination_shops = "destination_shops",
    od_customer_flows = "od_customer_flows") %>%
    lapply(FUN = function(s) paste0(clean_data_location,s))


  # 2. Assign importers
  import_functions <- import_files %>%
    lapply(function(f) x <- function() rrMD::load_as(f))

}
