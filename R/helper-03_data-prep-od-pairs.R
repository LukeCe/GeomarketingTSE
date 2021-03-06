add_pair_dist <- function(
  od_data.table,
  orig_lat_col = "ORIG_LAT",
  orig_lon_col = "ORIG_LON",
  dest_lat_col = "DEST_LAT",
  dest_lon_col = "DEST_LON"){

  od_data.table[
    , GC_DIST_KM := round(
      geosphere::distHaversine(
        matrix(c(eval(as.name(orig_lon_col)),
                 eval(as.name(orig_lat_col))), ncol = 2),
        matrix(c(eval(as.name(dest_lon_col)),
                 eval(as.name(dest_lat_col))), ncol = 2)
      )/1000,2)]
}
