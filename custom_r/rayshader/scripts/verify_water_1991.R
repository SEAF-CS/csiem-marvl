# Two-frame HQ check of the DYNAMIC water level before the full flood render:
# renders the flood-high (frame 07, +0.27 m) and ebb-low (frame 17, -0.36 m) frames so the
# dielectric slab is visible (render_snapshot can't show it) and the waterline shift is confirmed.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl); library(rayrender) })

DEM <- "data/dem_coarse_fixed.tif"; SDIR <- "data/pyc_1991_flood"
WLCSV <- "data/pyc_1991_flood/water_level.csv"
OUT <- "images/verify_flood"; dir.create(OUT, showWarnings = FALSE)
ZSCALE <- 0.4; SAMP <- 160; W <- 1100; H <- 950          # slightly fewer samples = faster check
THETA <- 15; PHI <- 42; ZOOM <- 0.62
PYCCOL <- "#762a83"; WTHICK <- 0.10; WATTEN <- 0.30; WCOL <- "#a9d2ef"
LDIR <- c(315,135,45,225); LALT <- c(50,45,40,55); LINT <- c(480,300,280,260)
CHECK <- c(7, 17)                                         # flood-high, ebb-low (0-based)

rhq_bbox_center <- function() {
  rotmat <- rayshader:::rot_to_euler(rgl::par3d()$userMatrix)
  phi <- rotmat[1]; if (90 - abs(phi) < 0.001) phi <- -phi
  um  <- rgl::par3d()$userMatrix[, 4]
  if (0.001 > abs(abs(rotmat[3]) - 180)) {
    mv <- rgl::rotationMatrix(-rotmat[2]*pi/180,0,1,0) %*% rgl::rotationMatrix(-phi*pi/180,1,0,0) %*% um
  } else {
    mv <- rgl::rotationMatrix(rotmat[3]*pi/180,0,0,1) %*% rgl::rotationMatrix(rotmat[2]*pi/180,0,1,0) %*%
          rgl::rotationMatrix(-phi*pi/180,1,0,0) %*% um
  }
  mv <- mv[1:3]; bb <- rgl::par3d()$bbox
  c(mean(bb[1:2]), mean(bb[3:4]), mean(bb[5:6])) - mv
}

elmat <- raster_to_matrix(raster(DEM)); nr <- nrow(elmat); nc <- ncol(elmat)
tifs <- sort(list.files(SDIR, pattern = "pyc_\\d+\\.tif$", full.names = TRUE))
wl <- read.csv(WLCSV)

ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE); ma <- ambient_shade(elmat, zscale=ZSCALE)
elmat |> sphere_shade(zscale=ZSCALE, texture="imhof1") |> add_shadow(ms,0.5) |> add_shadow(ma,0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI, windowsize=c(1000,850), zoom=ZOOM, water=FALSE)
Sys.sleep(0.3)

for (i in CHECK) {
  render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)
  bc <- rhq_bbox_center()
  iface <- raster_to_matrix(raster(tifs[i+1]))
  surf  <- rayshader:::generate_surface(iface, ZSCALE)
  mo    <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
  pyc   <- rayrender::mesh3d_model(mo, x=-bc[1], y=-bc[2], z=-bc[3],
             override_material=TRUE, material=rayrender::diffuse(color=PYCCOL))
  wy    <- wl$elev_m[i+1] / ZSCALE
  water <- rayrender::cube(x=-bc[1], y=(wy - WTHICK/2) - bc[2], z=-bc[3],
             xwidth=nr-1, ywidth=WTHICK, zwidth=nc-1,
             material=rayrender::dielectric(color=WCOL, refraction=1.33, attenuation_intensity=WATTEN))
  scn <- rayrender::add_object(pyc, water)
  render_highquality(sprintf("%s/verify_f%03d_wl%+.2f.png", OUT, i, wl$elev_m[i+1]),
                     samples=SAMP, light=TRUE, lightdirection=LDIR, lightaltitude=LALT,
                     lightintensity=LINT, clamp_value=8, width=W, height=H, clear=FALSE,
                     scene_elements=scn, integrator_type="nee", denoise=TRUE)
  cat(sprintf("verify frame %d  wlev %+.3f m done\n", i, wl$elev_m[i+1]))
}
rgl::close3d(); cat("VERIFY DONE\n")
