# =====================================================================================
# FULL HQ PATH-TRACED SERIES  (Cockburn Sound PYCNOCLINE, 2021 WINTER freshwater event,
# Aug 1-5, 2-hourly, 49 frames). Port of render_hq_1991_orbit.R with SDIR/OUT swapped to
# the 2021 winter extract (sigma-t=25.40, see extract_pycnocline_2021_winter.py).
# Same locked HQ config:
#   - terrain  : data/dem_coarse_fixed.tif (land-wall repaired), built ONCE, kept warm
#   - pycnocline: diffuse violet #762a83, per-frame rayrender object (scene_elements)
#   - water    : faint blue dielectric slab @ 0 m AHD (WTHICK/WATTEN/WCOL)
#   - render   : NEE + bright 4-light wrap + samples=256/sobol_blue + denoise, clamp 8
#   - camera   : continuous slow orbit, biased NORTH-facing (SALT.md hero = theta~15)
# Reads data/pyc_2021_winter ; writes images/hq_2021_winter.  Resumable (existing PNGs skipped).
# =====================================================================================
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl); library(rayrender) })

# ---- config ----
DEM   <- "data/dem_coarse_fixed.tif"
SDIR  <- "data/pyc_2021_winter"
OUT   <- "images/hq_2021_winter"; dir.create(OUT, showWarnings = FALSE)
ZSCALE <- 0.4
SAMP  <- 256; W <- 1100; H <- 950
THETA0 <- 30; THETA1 <- 0; PHI0 <- 40; PHI1 <- 46; ZOOM0 <- 0.62; ZOOM1 <- 0.85
PYCCOL <- "#762a83"                              # violet pycnocline (SALT.md locked colour)
WTHICK <- 0.10; WATTEN <- 0.30; WCOL <- "#a9d2ef"
LDIR <- c(315,135,45,225); LALT <- c(50,45,40,55); LINT <- c(480,300,280,260)

rhq_bbox_center <- function() {
  rotmat <- rayshader:::rot_to_euler(rgl::par3d()$userMatrix)
  phi <- rotmat[1]; if (90 - abs(phi) < 0.001) phi <- -phi
  um  <- rgl::par3d()$userMatrix[, 4]
  if (0.001 > abs(abs(rotmat[3]) - 180)) {
    mv <- rgl::rotationMatrix(-rotmat[2]*pi/180,0,1,0) %*%
          rgl::rotationMatrix(-phi*pi/180,1,0,0) %*% um
  } else {
    mv <- rgl::rotationMatrix(rotmat[3]*pi/180,0,0,1) %*%
          rgl::rotationMatrix(rotmat[2]*pi/180,0,1,0) %*%
          rgl::rotationMatrix(-phi*pi/180,1,0,0) %*% um
  }
  mv <- mv[1:3]; bb <- rgl::par3d()$bbox
  c(mean(bb[1:2]), mean(bb[3:4]), mean(bb[5:6])) - mv
}

elmat <- raster_to_matrix(raster(DEM))
nr <- nrow(elmat); nc <- ncol(elmat)
tifs <- sort(list.files(SDIR, pattern = "pyc_\\d+\\.tif$", full.names = TRUE))
N <- length(tifs)
cat(sprintf("terrain %dx%d | frames %d | samples %d | CONTINUOUS ORBIT (2021 winter pycnocline)\n", nr, nc, N, SAMP))

# terrain scene built ONCE (kept warm via clear=FALSE)
ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
ma <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(ms,0.5) |> add_shadow(ma,0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA0, phi=PHI0,
          windowsize=c(1000,850), zoom=ZOOM0, water=FALSE)
Sys.sleep(0.3)

cam_for <- function(i) {                         # continuous orbit: 0 -> 1 across whole clip
  f <- if (N > 1) (i - 1) / (N - 1) else 0
  list(theta = THETA0 + (THETA1 - THETA0) * f,
       phi   = PHI0   + (PHI1   - PHI0)   * f,
       zoom  = ZOOM0  + (ZOOM1  - ZOOM0)  * f)
}

t_start <- Sys.time(); done <- 0
for (i in seq_len(N)) {
  outpng <- sprintf("%s/f_%03d.png", OUT, i-1)
  if (file.exists(outpng)) { cat(sprintf("[%2d/%d] skip (exists)\n", i, N)); next }

  cm <- cam_for(i)
  render_camera(theta=cm$theta, phi=cm$phi, zoom=cm$zoom, fov=0)
  bc <- rhq_bbox_center()

  iface <- raster_to_matrix(raster(tifs[i]))
  surf  <- rayshader:::generate_surface(iface, ZSCALE)
  mo    <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
  pyc   <- rayrender::mesh3d_model(mo, x=-bc[1], y=-bc[2], z=-bc[3],
             override_material=TRUE, material=rayrender::diffuse(color=PYCCOL))
  water <- rayrender::cube(x=-bc[1], y=(0 - WTHICK/2) - bc[2], z=-bc[3],
             xwidth=nr-1, ywidth=WTHICK, zwidth=nc-1,
             material=rayrender::dielectric(color=WCOL, refraction=1.33,
                                            attenuation_intensity=WATTEN))
  scn <- rayrender::add_object(pyc, water)

  ti <- Sys.time()
  render_highquality(outpng, samples=SAMP, light=TRUE,
                     lightdirection=LDIR, lightaltitude=LALT, lightintensity=LINT,
                     clamp_value=8, width=W, height=H, clear=FALSE,
                     scene_elements=scn, integrator_type="nee", denoise=TRUE)
  done <- done + 1
  el <- as.numeric(difftime(Sys.time(), ti, units="secs"))
  tot <- as.numeric(difftime(Sys.time(), t_start, units="mins"))
  cat(sprintf("[%2d/%d] %s  %.0fs  (elapsed %.1f min, %d rendered)\n",
              i, N, basename(outpng), el, tot, done))
}
rgl::close3d()
cat("SERIES DONE\n")
