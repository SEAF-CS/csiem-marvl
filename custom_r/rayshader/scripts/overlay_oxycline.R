# ============================================================================
# STEP B: drape the O2 = 6 mg/L isosurface (2024-01-23) over Cockburn Sound.
# Interface GeoTIFF (same grid as the DEM) is produced by extract_oxycline.py.
# ============================================================================
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

DEM     <- "data/cockburn_swan_2.tif"
IFACE   <- "data/oxy6_iface_20240123.tif"
ZSCALE  <- 0.4
RESIZE_MAX <- 1000
OUTFILE <- "images/step_b_oxycline_20240123.png"

# DEM + interface on the SAME grid; aggregate both identically for headless render
dem <- raster(DEM)
fact <- ceiling(max(dim(dem)[1:2]) / RESIZE_MAX)
dem_c   <- raster::aggregate(dem, fact)
iface_c <- raster::resample(raster(IFACE), dem_c, method = "bilinear")
elmat    <- raster_to_matrix(dem_c)
ifacemat <- raster_to_matrix(iface_c)
cat("grid:", paste(dim(elmat), collapse=" x "),
    "| interface cells:", sum(!is.na(ifacemat)), "\n")

# overlay helper (same coordinate frame as plot_3d, via rayshader::generate_surface)
add_surface_overlay <- function(elevation_matrix, zscale, color = "red", alpha = 0.55, lit = FALSE) {
  stopifnot(identical(dim(elevation_matrix), dim(elmat)))
  surf <- rayshader:::generate_surface(elevation_matrix, zscale)
  m <- rgl::tmesh3d(vertices = t(surf$verts), indices = surf$inds, homogeneous = FALSE)
  rgl::shade3d(m, color = color, alpha = alpha, lit = lit,
               front = "fill", back = "fill", tag = "interface_overlay")
  invisible(m)
}

# terrain scene
montshadow <- ray_shade(elmat, zscale = ZSCALE, lambert = TRUE)
montamb    <- ambient_shade(elmat, zscale = ZSCALE)
elmat |>
  sphere_shade(zscale = ZSCALE, texture = "imhof1") |>
  add_shadow(montshadow, 0.5) |>
  add_shadow(montamb, 0) |>
  plot_3d(elmat, zscale = ZSCALE, fov = 0, theta = -45, phi = 45,
          windowsize = c(1100, 950), zoom = 0.75, water = FALSE)  # water off: it hid the in-basin surface
Sys.sleep(0.3)

# O2 = 6 mg/L surface (depleted bottom water) - fairly opaque so it reads inside the basin
add_surface_overlay(ifacemat, ZSCALE, color = "#d7301f", alpha = 0.85)

# high-angle view that looks INTO the basin (the deep surface was occluded at low phi)
render_camera(theta = -35, phi = 65, zoom = 0.62, fov = 0)
render_snapshot(OUTFILE, clear = TRUE)
# steeper near-plan view as well
render_camera(theta = 0, phi = 78, zoom = 0.62, fov = 0)
render_snapshot("images/step_b_oxycline_20240123_high.png", clear = TRUE)
rgl::close3d()
cat("STEP B done ->", OUTFILE, "\n")
