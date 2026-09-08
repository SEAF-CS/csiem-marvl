# Time-series animation frames:
#  Phase 1 - FIXED hero view, oxycline surface morphs 13->23 Jan (66 frames, 4-hourly)
#  Phase 2 - hold last surface, zoom in + gentle anti-clockwise orbit (camera move)
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

DEMC <- "data/dem_coarse.tif"; SDIR <- "data/oxy6_series"
ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 45      # hero ("7 o'clock", looking N)
OUT <- "images/ts"; dir.create(OUT, showWarnings = FALSE)

elmat <- raster_to_matrix(raster(DEMC))
tifs  <- sort(list.files(SDIR, pattern = "oxy6_\\d+\\.tif$", full.names = TRUE))
cat("terrain", paste(dim(elmat), collapse="x"), "| frames", length(tifs), "\n")

add_overlay <- function(em) {
  rgl::pop3d(tag = "iface")
  surf <- rayshader:::generate_surface(em, ZSCALE)
  m <- rgl::tmesh3d(vertices = t(surf$verts), indices = surf$inds, homogeneous = FALSE)
  rgl::shade3d(m, color = "#d7301f", alpha = 0.9, lit = FALSE,
               front = "fill", back = "fill", tag = "iface")
}

montshadow <- ray_shade(elmat, zscale = ZSCALE, lambert = TRUE)
montamb    <- ambient_shade(elmat, zscale = ZSCALE)
elmat |>
  sphere_shade(zscale = ZSCALE, texture = "imhof1") |>
  add_shadow(montshadow, 0.5) |> add_shadow(montamb, 0) |>
  plot_3d(elmat, zscale = ZSCALE, fov = 0, theta = THETA, phi = PHI,
          windowsize = c(1000, 850), zoom = ZOOM, water = FALSE)
Sys.sleep(0.3)

# ---- Single continuous timeline: time advances every frame.
#      Camera holds the hero view for the first N_FIX frames, then orbits +
#      zooms over the remaining frames WHILE time keeps moving. ----
N    <- length(tifs)
N_FIX <- 28                              # establishing frames at the fixed hero view
for (i in seq_len(N)) {
  add_overlay(raster_to_matrix(raster(tifs[i])))
  if (i <= N_FIX) {
    render_camera(theta = THETA, phi = PHI, zoom = ZOOM, fov = 0)
  } else {
    f  <- (i - N_FIX) / (N - N_FIX)      # 0 -> 1 across the orbit portion
    render_camera(theta = THETA - 40 * f,           # gentle anti-clockwise swing
                  phi   = PHI  + 6  * f,            # slight lift
                  zoom  = ZOOM + (1.0 - ZOOM) * f,  # zoom in
                  fov   = 0)
  }
  render_snapshot(sprintf("%s/f_%03d.png", OUT, i-1), clear = FALSE)
}
rgl::close3d()
cat("done:", N, "frames (fixed for first", N_FIX, ", then orbit+zoom with time advancing)\n")
