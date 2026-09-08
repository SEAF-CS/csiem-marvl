# Azimuth (theta) sweep to choose the hero angle. Builds the scene once, then
# snapshots several thetas. A green marker is dropped at the NORTH edge so we can
# see which theta looks "north from the south".
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl); library(magick) })

DEM <- "data/cockburn_swan_2.tif"; IFACE <- "data/oxy6_iface_20240123.tif"
ZSCALE <- 0.4; RESIZE_MAX <- 1000; PHI <- 40; ZOOM <- 0.6

dem <- raster(DEM); fact <- ceiling(max(dim(dem)[1:2]) / RESIZE_MAX)
dem_c <- raster::aggregate(dem, fact)
iface_c <- raster::resample(raster(IFACE), dem_c, method = "bilinear")
elmat <- raster_to_matrix(dem_c); ifacemat <- raster_to_matrix(iface_c)
ext <- raster::extent(dem_c)

add_surface_overlay <- function(em, zscale, color="#d7301f", alpha=0.85) {
  surf <- rayshader:::generate_surface(em, zscale)
  m <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
  rgl::shade3d(m, color=color, alpha=alpha, lit=FALSE, front="fill", back="fill")
}

montshadow <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
montamb    <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(montshadow,0.5) |> add_shadow(montamb,0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=0, phi=PHI, windowsize=c(1000,850),
          zoom=ZOOM, water=FALSE)
Sys.sleep(0.3)
add_surface_overlay(ifacemat, ZSCALE)
# NORTH marker (projected coords: long=easting, lat=northing), near north-centre
render_points(extent=ext, long=378000, lat=6460000, altitude=50, zscale=ZSCALE,
              heightmap=elmat, color="green", size=12)

thetas <- c(0,45,90,135,180,225,270,315)
files <- sprintf("images/_hero_t%03d.png", thetas)
for (i in seq_along(thetas)) {
  render_camera(theta=thetas[i], phi=PHI, zoom=ZOOM, fov=0)
  render_snapshot(files[i], clear=FALSE)
}
rgl::close3d()

imgs <- image_read(files)
imgs <- image_annotate(imgs, sprintf("theta=%d (green=N)", thetas), size=34,
                       color="black", boxcolor="white", gravity="northwest", location="+5+5")
mont <- image_montage(imgs, tile="4x2", geometry="x320+6+6", bg="white")
image_write(mont, "images/hero_theta_sweep.png")
cat("wrote images/hero_theta_sweep.png\n")
