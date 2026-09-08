# Path-traced verification frame: FIXED DEM + red oxycline + faint water surface (0 m
# AHD) under the locked look (NEE + bright 4-light wrap + sobol_blue + denoise).
# SAMPLES env: start 48 (quick, check water material) then 256 (final look).
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl); library(rayrender) })

ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 45
SAMP <- as.integer(Sys.getenv("SAMPLES", "48"))
W <- 1100; H <- 950
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
iface <- raster_to_matrix(raster("data/oxy6_series/oxy6_040.tif"))
nr <- nrow(elmat); nc <- ncol(elmat)

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

ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
ma <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(ms,0.5) |> add_shadow(ma,0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(1000,850), zoom=ZOOM, water=FALSE)
render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)
bc <- rhq_bbox_center()

# red oxycline mesh -> rayrender object (shifted into HQ world coords)
surf <- rayshader:::generate_surface(iface, ZSCALE)
mo  <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
oxy <- rayrender::mesh3d_model(mo, x=-bc[1], y=-bc[2], z=-bc[3],
         override_material=TRUE, material=rayrender::diffuse(color="#d7301f"))

# faint water surface: thin blue dielectric SLAB at 0 m AHD. Keep it FAINT (thin +
# low attenuation + light colour) so the red oxycline reads clearly beneath it.
THICK <- as.numeric(Sys.getenv("WTHICK", "0.15"))
ATTEN <- as.numeric(Sys.getenv("WATTEN", "0.5"))
WCOL  <- Sys.getenv("WCOL", "#7fb6df")
water <- rayrender::cube(x=-bc[1], y=(0 - THICK/2) - bc[2], z=-bc[3],
           xwidth=nr-1, ywidth=THICK, zwidth=nc-1,
           material=rayrender::dielectric(color=WCOL, refraction=1.33,
                                          attenuation_intensity=ATTEN))

scn <- rayrender::add_object(oxy, water)

cat(sprintf("path-trace water frame, SAMPLES=%d ...\n", SAMP)); t0 <- Sys.time()
render_highquality(sprintf("images/hq_water_s%d.png", SAMP), samples=SAMP, light=TRUE,
                   lightdirection=c(315, 135,  45, 225),
                   lightaltitude =c( 50,  45,  40,  55),
                   lightintensity=c(480, 300, 280, 260),
                   clamp_value=8, width=W, height=H, clear=TRUE,
                   scene_elements=scn,
                   integrator_type="nee", denoise=TRUE)
cat(sprintf("  %.0fs done -> images/hq_water_s%d.png\n",
            as.numeric(difftime(Sys.time(),t0,units="secs")), SAMP))
