.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 45
elmat <- raster_to_matrix(raster("data/dem_coarse.tif"))
iface <- raster_to_matrix(raster("data/oxy6_series/oxy6_040.tif"))   # ~peak coverage

surf <- rayshader:::generate_surface(iface, ZSCALE)
montshadow <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
montamb    <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(montshadow,0.5) |> add_shadow(montamb,0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(1000,850), zoom=ZOOM, water=FALSE)
m <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
rgl::shade3d(m, color="#d7301f", alpha=0.9, lit=FALSE, front="fill", back="fill", tag="iface")
render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)

cat("starting render_highquality...\n")
t0 <- Sys.time()
render_highquality("images/hq_test.png", samples=128, light=TRUE,
                   lightdirection=315, lightaltitude=45, lightintensity=650,
                   clamp_value=10, width=1100, height=950, clear=TRUE)
cat(sprintf("render_highquality took %.1f s\n", as.numeric(difftime(Sys.time(), t0, units="secs"))))
