# Fast rasterised PREVIEW of the 1991 pycnocline surface (3 representative frames) to lock
# colour / orientation / camera BEFORE the multi-hour HQ path-trace. Uses the per-vertex MESH
# (never add_overlay) + render_snapshot. Frames chosen from the extract log:
#   00 = pre-storm stratified (broad surface), 25 = storm collapse (surface ~gone),
#   52 = post-storm cascade (surface rebuilt).
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

DEM <- "data/dem_coarse_fixed.tif"; SDIR <- "data/pyc_1991"
ZSCALE <- 0.4; THETA <- 15; PHI <- 42; ZOOM <- 0.62     # north-facing hero (SALT.md)
PYCCOL <- "#762a83"
OUT <- "images/preview_1991"; dir.create(OUT, showWarnings = FALSE)
SHOW <- c(3, 34, 44)     # pre-storm strong / storm-thinned / cascade (22 Aug, cf. Fig 6.22)

elmat <- raster_to_matrix(raster(DEM))
tifs  <- sort(list.files(SDIR, pattern = "pyc_\\d+\\.tif$", full.names = TRUE))
cat("terrain", paste(dim(elmat), collapse="x"), "| frames", length(tifs), "\n")

add_iface <- function(em) {
  rgl::pop3d(tag = "iface")
  surf <- rayshader:::generate_surface(em, ZSCALE)
  m <- rgl::tmesh3d(vertices = t(surf$verts), indices = surf$inds, homogeneous = FALSE)
  rgl::shade3d(m, color = PYCCOL, alpha = 0.9, lit = FALSE,
               front = "fill", back = "fill", tag = "iface")
}

ms <- ray_shade(elmat, zscale = ZSCALE, lambert = TRUE)
ma <- ambient_shade(elmat, zscale = ZSCALE)
elmat |>
  sphere_shade(zscale = ZSCALE, texture = "imhof1") |>
  add_shadow(ms, 0.5) |> add_shadow(ma, 0) |>
  plot_3d(elmat, zscale = ZSCALE, fov = 0, theta = THETA, phi = PHI,
          windowsize = c(1000, 850), zoom = ZOOM, water = FALSE)
Sys.sleep(0.3)

for (i in SHOW) {
  add_iface(raster_to_matrix(raster(tifs[i + 1])))
  render_camera(theta = THETA, phi = PHI, zoom = ZOOM, fov = 0)
  render_snapshot(sprintf("%s/preview_f%03d.png", OUT, i), clear = FALSE)
  cat("wrote preview_f", sprintf("%03d", i), "\n", sep = "")
}
rgl::close3d()
cat("preview done\n")
