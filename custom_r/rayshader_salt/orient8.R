.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4
m  <- t(raster_to_matrix(raster("data/dem_coarse_fixed.tif")))
tm <- t(m)
trans <- list(
  A_asis = m,
  B_UD   = m[nrow(m):1, ],
  C_LR   = m[, ncol(m):1],
  D_180  = m[nrow(m):1, ncol(m):1],
  E_t    = tm,
  F_tUD  = tm[nrow(tm):1, ],
  G_tLR  = tm[, ncol(tm):1],
  H_t180 = tm[nrow(tm):1, ncol(tm):1]
)
dir.create("images/o8", showWarnings = FALSE)
for (nm in names(trans)) {
  e   <- trans[[nm]]
  ms  <- ray_shade(e, zscale = ZSCALE, lambert = TRUE)
  tex <- add_shadow(sphere_shade(e, zscale = ZSCALE, texture = "imhof1"), ms, 0.5)
  plot_3d(tex, e, zscale = ZSCALE, fov = 0, theta = 0, phi = 90,
          windowsize = c(700, 1200), zoom = 0.9, water = FALSE)
  Sys.sleep(0.12)
  render_camera(theta = 0, phi = 90, zoom = 0.9, fov = 0)
  render_snapshot(sprintf("images/o8/%s.png", nm), clear = FALSE)
  rgl::clear3d()
  cat(nm, "\n")
}
rgl::close3d()
