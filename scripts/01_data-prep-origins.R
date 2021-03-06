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

# declare libraries
library("data.table")
library("dplyr")
library("here")
library("rrMD")
library("sf")

# declare data sources
source("R/helpers_data-import.R" %>% here())
load_raw_data <- get_raw_data_loaders()


# 1) start from the demography at the origin_iris -----------------------------
# we do not need overseas departments
dom_codes <- "97" %p% 1:6
iris_pop <- load_raw_data$iris_pop() %>%
  filter(!DEP %in% dom_codes)
origin_iris <- iris_pop %>%
  transmute(ID_IRIS = IRIS,
            NAME_IRIS = LIBIRIS,
            ID_MUN = COM,
            POP = P17_POP) %>%
  setDT()

# 2) add income information (from IRIS if available from MUN if not) ----------
iris_income <- load_raw_data$iris_income() %>% setDT()
mun_income <- load_raw_data$mun_income() %>% setDT()

origin_iris[iris_income, INC1 := DISP_MED17, on = c(ID_IRIS = "IRIS")]
origin_iris[mun_income, INC2 := Q217, on = c(ID_MUN = "CODGEO")]
origin_iris[is.na(INC1), MEDIAN_INCOME := INC2]
origin_iris[!is.na(INC1), MEDIAN_INCOME := INC1]
origin_iris[, c("INC1","INC2","ID_MUN") := NULL]

# 3) add the geographies ------------------------------------------------------
# the census data is based on 2019 geographies
iris_poly19 <- load_raw_data$iris_poly19() %>%
  select(ID_IRIS = CODE_IRIS) %>%
  setDT()
origin_iris[iris_poly19 , geometry := geometry, on = "ID_IRIS"]

# 4) add market potentials ----------------------------------------------------
# the market potential is defined on an old and unknown definition of the
# geography we collect the coordinates from multiple files and fill the
# remaining unknowns by hand.
# Based on the coordinates we merge it with the 2019 polygons.

# ... add by ID what can be connected
market_potential <- load_raw_data$market_potential() %>%
  rename(ID_IRIS_OLD = IRIS) %>%
  setDT()
market_potential[origin_iris, ID_IRIS := ID_IRIS,
                 on = c("ID_IRIS_OLD" = "ID_IRIS")]


# ... conect coordinates to lost potentials
lost_potential <- market_potential[is.na(ID_IRIS),]
lost_iris <- lost_potential$ID_IRIS_OLD

# ... fill from 2015
iris_poly15 <- load_raw_data$iris_poly15() %>%
  rename(ID_IRIS_OLD = CODE_IRIS) %>%
  filter(ID_IRIS_OLD %in% lost_iris)

suppressWarnings({
  lost_potential_coords <-
    st_point_on_surface(st_geometry(iris_poly15)) %>%
    st_as_sf() %>%
    mutate(ID_IRIS_OLD = iris_poly15$ID_IRIS_OLD)
  })
lost_iris <- lost_iris %>% setdiff(lost_potential_coords$ID_IRIS_OLD)

# ... fill from 2014
iris_poly14 <- load_raw_data$iris_poly14() %>%
  rename(ID_IRIS_OLD = DCOMIRIS) %>%
  filter(ID_IRIS_OLD %in% lost_iris)

suppressWarnings({
  lost_potential_coords <-
    st_point_on_surface(st_geometry(iris_poly14)) %>%
    st_as_sf() %>%
    mutate(ID_IRIS_OLD = iris_poly14$ID_IRIS_OLD) %>%
    rbind(lost_potential_coords)
})
lost_iris <- lost_iris %>% setdiff(lost_potential_coords$ID_IRIS_OLD)

# ... fill the last 4 IRIS coordinates by hand following the IRIS redefinition
# ... ... 1) 76108XXXX -> 76095 (rename)
new_commune1 <- origin_iris$ID_IRIS[grep("76095",origin_iris$ID_IRIS)]
# ... ... 2)  52379XXX -> 52187 (fusion)
new_commune2 <- origin_iris$ID_IRIS[grep("52187",origin_iris$ID_IRIS)]
renamed_iris <- lookup(lost_iris,c(new_commune2, new_commune1))

suppressWarnings({
  lost_potential_coords <-
    iris_poly19 %>% filter(ID_IRIS %in% names(renamed_iris)) %>%
    st_as_sf() %>%
    st_geometry(.) %>%
    st_point_on_surface(.) %>%
    st_as_sf() %>%
    mutate(ID_IRIS_OLD = renamed_iris) %>%
    rbind(lost_potential_coords)
})

# ... for the lost potential grep ids using spatial join with existing geometry
lost_potential_coords <- lost_potential_coords %>%
  st_join(origin_iris %>% st_as_sf() %>% select(ID_IRIS)) %>%
  st_drop_geometry() %>% filter(complete.cases(.))

# proceed by aggregating the market potential on the new IRIS
# then add it to the origin data
market_potential[lost_potential_coords, ID_IRIS := ID_IRIS,
                 on = "ID_IRIS_OLD"]
market_potential_new <- market_potential[,.(MARKET_POTENTIAL = sum(mp)), by = ID_IRIS]
lost_potential <- (
  sum(market_potential_new$MARKET_POTENTIA)
  / sum(market_potential$mp)
  - 1)
stopifnot(lost_potential == 0)

origin_iris[market_potential_new,MARKET_POTENTIAL := MARKET_POTENTIAL,
            on = "ID_IRIS"]
origin_iris[is.na(MARKET_POTENTIAL), MARKET_POTENTIAL := 0]
origin_iris <- origin_iris %>% st_as_sf()

# Export origin data ----------------------------------------------------------
saveRData(origin_iris,file_name = "origin_iris")
