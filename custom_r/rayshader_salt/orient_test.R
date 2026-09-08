# Orientation diagnosis: drape a pure WATER mask (cyan where DEM<0) on the terrain.
# If cyan lands on the basin depression -> overlay orientation correct.
# Renders the as-is overlay plus flipped/transposed variants to find the right mapping.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 15; W <- 1300; H <- 1100
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
nr <- nrow(elmat); nc <- ncol(elmat)
ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
ma <- ambient_shade(elmat, zscale=ZSCALE)
base <- elmat |> sphere_shade(zscale=ZSCALE, texture="imhof1") |> add_shadow(ms,0.5) |> add_shadow(ma,0)

mk_overlay <- function(watermat) {           # cyan where TRUE
  ov <- array(0, dim=c(nrow(watermat), ncol(watermat), 4))
  ov[,,2] <- 1; ov[,,3] <- 1                  # cyan
  ov[,,4] <- ifelse(watermat, 0.7, 0)
  ov
}
water <- elmat < 0                             # TRUE on wet cells (same matrix as terrain)

variants <- list(
  asis      = water,
  flipUD    = water[nr:1, ],
  flipLR    = water[, nc:1],
  flipBOTH  = water[nr:1, nc:1]
)
for (nm in names(variants)) {
  wv <- variants[[nm]]
  if (!identical(dim(wv), dim(water))) next
  tex <- add_overlay(base, mk_overlay(wv), alphalayer=0.8)
  plot_3d(tex, elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(W,H), zoom=ZOOM, water=FALSE); Sys.sleep(0.2)
  render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)
  render_snapshot(sprintf("images/orient_%s.png", nm), clear=FALSE)
  rgl::clear3d()
  cat("rendered", nm, "\n")
}
rgl::close3d()
