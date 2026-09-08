# Fast rasterised check that the cleaned DEM removed the spurious land wall.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 45; W <- 1500; H <- 1280

render_one <- function(dem_path, out) {
  elmat <- raster_to_matrix(raster(dem_path))
  iface <- raster_to_matrix(raster("data/oxy6_series/oxy6_040.tif"))
  ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
  ma <- ambient_shade(elmat, zscale=ZSCALE)
  elmat |>
    sphere_shade(zscale=ZSCALE, texture="imhof1") |>
    add_shadow(ms,0.5) |> add_shadow(ma,0) |>
    plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
            windowsize=c(W,H), zoom=ZOOM, water=FALSE)
  Sys.sleep(0.3)
  surf <- rayshader:::generate_surface(iface, ZSCALE)
  m <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
  rgl::shade3d(m, color="#d7301f", alpha=0.9, lit=FALSE, front="fill", back="fill", tag="iface")
  render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)
  render_snapshot(out, clear=TRUE)
  rgl::close3d()
  cat("wrote", out, "\n")
}

render_one("data/dem_coarse.tif",       "images/dem_before_wall.png")
render_one("data/dem_coarse_fixed.tif", "images/dem_after_fixed.png")
