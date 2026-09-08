# Fast rasterised PREVIEW of the 2021 pycnocline windows (3 frames x 3 windows) to lock
# window choice / sigma-t threshold BEFORE the multi-hour HQ path-trace. Port of
# preview_1991.R; per-vertex MESH (never add_overlay) + render_snapshot.
# Frames per window (see extract_pycnocline_2021_preview.py): stratified / transitional / mixed.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

DEM <- "data/dem_coarse_fixed.tif"; BASE <- "data/pyc_2021_preview"
ZSCALE <- 0.4; THETA <- 15; PHI <- 42; ZOOM <- 0.62     # north-facing hero (SALT.md)
PYCCOL <- "#762a83"
OUT <- "images/preview_2021"; dir.create(OUT, showWarnings = FALSE)
WINDOWS <- c("summer", "autumn", "winter")

elmat <- raster_to_matrix(raster(DEM))
cat("terrain", paste(dim(elmat), collapse="x"), "\n")

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

for (w in WINDOWS) {
  tifs <- sort(list.files(file.path(BASE, w), pattern = "pyc_\\d+\\.tif$", full.names = TRUE))
  for (i in seq_along(tifs)) {
    add_iface(raster_to_matrix(raster(tifs[i])))
    render_camera(theta = THETA, phi = PHI, zoom = ZOOM, fov = 0)
    render_snapshot(sprintf("%s/preview_%s_f%03d.png", OUT, w, i - 1), clear = FALSE)
    cat("wrote preview_", w, "_f", sprintf("%03d", i - 1), "\n", sep = "")
  }
}
rgl::close3d()
cat("preview done\n")
