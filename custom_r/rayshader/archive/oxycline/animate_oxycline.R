# Hero still (theta=45, "7 o'clock" looking north) + 360-deg orbit frames.
# GIF is assembled separately (PIL) so frame order / direction is controllable.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

DEM <- "data/cockburn_swan_2.tif"; IFACE <- "data/oxy6_iface_20240123.tif"
ZSCALE <- 0.4; RESIZE_MAX <- 1000; PHI <- 40; ZOOM <- 0.62
HERO_THETA <- 45

dem <- raster(DEM); fact <- ceiling(max(dim(dem)[1:2]) / RESIZE_MAX)
dem_c <- raster::aggregate(dem, fact)
iface_c <- raster::resample(raster(IFACE), dem_c, method = "bilinear")
elmat <- raster_to_matrix(dem_c); ifacemat <- raster_to_matrix(iface_c)

add_surface_overlay <- function(em, zscale, color="#d7301f", alpha=0.9) {
  surf <- rayshader:::generate_surface(em, zscale)
  m <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
  rgl::shade3d(m, color=color, alpha=alpha, lit=FALSE, front="fill", back="fill")
}

montshadow <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
montamb    <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(montshadow,0.5) |> add_shadow(montamb,0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=HERO_THETA, phi=PHI,
          windowsize=c(1000,850), zoom=ZOOM, water=FALSE)
Sys.sleep(0.3)
add_surface_overlay(ifacemat, ZSCALE)

# hero still
render_camera(theta=HERO_THETA, phi=PHI, zoom=ZOOM, fov=0)
render_snapshot("images/hero_oxycline_20240123.png", clear=FALSE)

# orbit frames every 10 deg
thetas <- seq(0, 350, by=10)
dir.create("images/orbit", showWarnings=FALSE)
for (i in seq_along(thetas)) {
  render_camera(theta=thetas[i], phi=PHI, zoom=ZOOM, fov=0)
  render_snapshot(sprintf("images/orbit/f_%03d.png", thetas[i]), clear=FALSE)
}
rgl::close3d()
cat("HERO + ", length(thetas), " orbit frames done\n")
