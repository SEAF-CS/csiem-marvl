# FAST rasterised preview: fixed DEM + red oxycline + FAINT water surface at 0 m AHD.
# Confirms plane extent/height before the slow path-traced version.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 45; W <- 1500; H <- 1280

elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
iface <- raster_to_matrix(raster("data/oxy6_series/oxy6_040.tif"))
nr <- nrow(elmat); nc <- ncol(elmat)
xext <- (nr-1)/2; zext <- (nc-1)/2

ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
ma <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(ms,0.5) |> add_shadow(ma,0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(W,H), zoom=ZOOM, water=FALSE)
Sys.sleep(0.3)

# red oxycline (below sea level)
surf <- rayshader:::generate_surface(iface, ZSCALE)
mo <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
rgl::shade3d(mo, color="#d7301f", alpha=0.9, lit=FALSE, front="fill", back="fill", tag="iface")

# faint water surface plane at elevation 0 (y=0). Land (>0) pokes through and occludes it.
rgl::quads3d(x=c(-xext, xext, xext, -xext), y=c(0,0,0,0),
             z=c(-zext, -zext, zext, zext),
             color="#5fa8e6", alpha=0.30, lit=FALSE, front="fill", back="fill", tag="water")

render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)
render_snapshot("images/verify_water_fast.png", clear=TRUE)
rgl::close3d()
cat("wrote images/verify_water_fast.png\n")
