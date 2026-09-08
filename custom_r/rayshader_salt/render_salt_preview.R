# Fast rasterised preview of the halocline (SAL=34.6) cascade, new hero angle, purple.
# Shares the R library from the oxycline folder. FRAME env = single frame; else all -> gif.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

DEMC <- "data/dem_coarse_fixed.tif"; SDIR <- "data/halo_series"
ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 15        # hero: closer to north-facing
SCOL <- "#762a83"                                          # dense salty water = purple/violet
W <- 1500; H <- 1280
OUT <- "images/preview"; dir.create(OUT, showWarnings = FALSE)

elmat <- raster_to_matrix(raster(DEMC))
tifs  <- sort(list.files(SDIR, pattern="halo_\\d+\\.tif$", full.names=TRUE))
FRAME <- Sys.getenv("FRAME", "")
idx   <- if (nzchar(FRAME)) (as.integer(FRAME)+1) else seq_along(tifs)

ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
ma <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(ms,0.5) |> add_shadow(ma,0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(W,H), zoom=ZOOM, water=FALSE)
Sys.sleep(0.3)

add_halo <- function(em) {
  rgl::pop3d(tag="halo")
  surf <- rayshader:::generate_surface(em, ZSCALE)
  m <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
  rgl::shade3d(m, color=SCOL, alpha=0.9, lit=FALSE, front="fill", back="fill", tag="halo")
}

for (i in idx) {
  add_halo(raster_to_matrix(raster(tifs[i])))
  render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)
  render_snapshot(sprintf("%s/f_%03d.png", OUT, i-1), clear=FALSE)
}
rgl::close3d()
cat("done:", length(idx), "preview frame(s)\n")
