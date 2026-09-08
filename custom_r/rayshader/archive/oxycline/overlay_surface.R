# ============================================================================
# Rayshader + interface-surface overlay (salt wedge / oxycline)
# Project working dir: G:/CSIEM/1.8.0/csiem-marvl/rayshader
#
# STEP A (this file): drop a translucent plane at z = 0 (sea level) onto the
#   Cockburn Sound terrain to validate that a custom surface aligns with the
#   rayshader scene. The plane should meet the terrain exactly at the shoreline.
# STEP B (later): replace the flat plane with the elevation of the O2 = 6 mg/L
#   surface on 2024-01-23 (a GeoTIFF on the same DEM grid).
# ============================================================================
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

# ---- params ----
DEM     <- "data/cockburn_swan_2.tif"
ZSCALE  <- 0.4
RESIZE_MAX <- 1000          # cap grid so the hillshade texture fits headless software-GL (1024)
OUTFILE <- "images/step_a_sealevel_plane.png"

# ---- load DEM -> matrix ----
elmat <- raster_to_matrix(raster(DEM))
if (max(dim(elmat)) > RESIZE_MAX) elmat <- resize_matrix(elmat, scale = RESIZE_MAX / max(dim(elmat)))
cat("render grid:", paste(dim(elmat), collapse=" x "), "\n")

# ---- reusable overlay helper -------------------------------------------------
# Draw an arbitrary single-valued surface (same grid as `elmat`) into the CURRENT
# rayshader/rgl scene, using rayshader's own coordinate transform so it aligns.
#   elevation_matrix : matrix, same dims as the plotted heightmap; metres (NA = no surface)
#   zscale           : MUST equal the plot_3d zscale
add_surface_overlay <- function(elevation_matrix, zscale,
                                color = "red", alpha = 0.45, lit = FALSE) {
  stopifnot(identical(dim(elevation_matrix), dim(elmat)))
  surf <- rayshader:::generate_surface(elevation_matrix, zscale)   # verts (n x 3), inds (3 x ntri)
  m <- rgl::tmesh3d(vertices = t(surf$verts), indices = surf$inds, homogeneous = FALSE)
  rgl::shade3d(m, color = color, alpha = alpha, lit = lit,
               front = "fill", back = "fill", tag = "interface_overlay")
  invisible(m)
}

# ---- build the terrain scene (rayshader water OFF so we test OUR plane) ------
montshadow <- ray_shade(elmat, zscale = ZSCALE, lambert = TRUE)
montamb    <- ambient_shade(elmat, zscale = ZSCALE)
elmat |>
  sphere_shade(zscale = ZSCALE, texture = "imhof1") |>
  add_shadow(montshadow, 0.5) |>
  add_shadow(montamb, 0) |>
  plot_3d(elmat, zscale = ZSCALE, fov = 0, theta = -45, phi = 45,
          windowsize = c(1000, 850), zoom = 0.75, water = FALSE)
Sys.sleep(0.3)

# ---- STEP A: flat plane at sea level (z = 0) ----
sealevel <- matrix(0, nrow = nrow(elmat), ncol = ncol(elmat))
add_surface_overlay(sealevel, ZSCALE, color = "dodgerblue", alpha = 0.45)

render_camera(theta = -45, phi = 35, zoom = 0.7, fov = 0)
render_snapshot(OUTFILE, clear = TRUE)
rgl::close3d()
cat("STEP A done ->", OUTFILE, "\n")
