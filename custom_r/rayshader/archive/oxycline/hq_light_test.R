# Noise diagnosis: smooth top (baked texture) vs grainy sides (block faces lit only
# by noisy indirect GI under a single directional light). Fix = wrap the scene in
# fill lights so every face gets DIRECT light -> far less variance per sample.
# Renders two variants at moderate samples for a quick A/B.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl); library(rayrender) })

ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 45; SAMP <- 64
elmat  <- raster_to_matrix(raster("data/dem_coarse.tif"))
iface  <- raster_to_matrix(raster("data/oxy6_series/oxy6_040.tif"))

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

montshadow <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
montamb    <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(montshadow, 0.5) |> add_shadow(montamb, 0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(1000,850), zoom=ZOOM, water=FALSE)
render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)

bc  <- rhq_bbox_center()
surf <- rayshader:::generate_surface(iface, ZSCALE)
m    <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
oxy  <- rayrender::mesh3d_model(m, x=-bc[1], y=-bc[2], z=-bc[3],
          override_material=TRUE, material=rayrender::diffuse(color="#d7301f"))

# Variant A: single key light (current config) -- baseline at SAMP samples
cat("A: single light...\n"); t0 <- Sys.time()
render_highquality("images/hq_lightA_single.png", samples=SAMP, light=TRUE,
                   lightdirection=315, lightaltitude=45, lightintensity=650,
                   clamp_value=10, width=1100, height=950, clear=FALSE,
                   scene_elements=oxy)
cat(sprintf("  %.0fs\n", as.numeric(difftime(Sys.time(),t0,units="secs"))))

# Variant B: key + wrap fill lights (4 azimuths). Key stays brightest; fills are
# dimmer and higher so every block face sees direct light -> low variance.
cat("B: key + wrap fill...\n"); t0 <- Sys.time()
render_highquality("images/hq_lightB_wrap.png", samples=SAMP, light=TRUE,
                   lightdirection=c(315, 135, 45, 225),
                   lightaltitude =c(45,  60,  35, 50),
                   lightintensity=c(650, 220, 220, 200),
                   clamp_value=10, width=1100, height=950, clear=TRUE,
                   scene_elements=oxy)
cat(sprintf("  %.0fs\n", as.numeric(difftime(Sys.time(),t0,units="secs"))))
cat("done\n")
