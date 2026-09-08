.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster) })
r <- raster("data/dem_coarse_fixed.tif")
cat("raster nrow(N-S)=",nrow(r)," ncol(W-E)=",ncol(r),"\n")
# geographic corners in raster space: row1=NORTH, col1=WEST
r[1,1] <- 9991            # NW
r[1, ncol(r)] <- 9992     # NE
r[nrow(r), 1] <- 9993     # SW
r[nrow(r), ncol(r)] <- 9994  # SE
m <- raster_to_matrix(r)
cat("matrix dim:", nrow(m), "x", ncol(m), "  (mat row -> screen vertical, mat col -> screen horizontal)\n")
for (v in 9991:9994) {
  idx <- which(abs(m - v) < 0.5, arr.ind = TRUE)
  lbl <- c("NW","NE","SW","SE")[v-9990]
  cat(sprintf("%s  -> matrix (row=%d, col=%d)\n", lbl, idx[1,1], idx[1,2]))
}
