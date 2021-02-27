create_buff_zone <- function(points,dist_km){
  suppressWarnings({
    pre_crs <- st_crs(points)
    units(dist_km) <- "km"
    points %>%
      st_transform(7801) %>%
      st_buffer(x = .,dist = dist_km) %>%
      st_transform(pre_crs)
  })
}

count_points_in_zone <- function(zone,zone_id,points){
  zone %>% st_join(competing_shops) %>%
    st_drop_geometry() %>%
    group_by( .dots = zone_id) %>%
    summarise(n_points = n())
}

