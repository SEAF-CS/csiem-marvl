# Clean high-RES via the rasterizer (render_snapshot), NOT the path tracer.
# Rasterising is deterministic -> ZERO Monte Carlo noise, at any resolution.
# Overlay goes back to rgl::shade3d (works fine in render_snapshot; it was only
# render_highquality that dropped unrecognised-tag meshes). Big window = high res;
# baked ray_shade + ambient_shade still give the shadows.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 45
W <- 1900; H <- 1600                      # high-res window (vs 1000x850 prototype)
elmat  <- raster_to_matrix(raster("data/dem_coarse.tif"))
iface  <- raster_to_matrix(raster("data/oxy6_series/oxy6_040.tif"))

montshadow <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
montamb    <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(montshadow, 0.5) |> add_shadow(montamb, 0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(W,H), zoom=ZOOM, water=FALSE)
Sys.sleep(0.3)

# oxycline overlay straight into rgl (rasteriser keeps it)
surf <- rayshader:::generate_surface(iface, ZSCALE)
m <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
rgl::shade3d(m, color="#d7301f", alpha=0.9, lit=FALSE, front="fill", back="fill", tag="iface")

render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)
t0 <- Sys.time()
render_snapshot("images/hires_snapshot.png", clear=TRUE)
cat(sprintf("render_snapshot %dx%d took %.1fs\n", W, H,
            as.numeric(difftime(Sys.time(),t0,units="secs"))))
rgl::close3d()
