# Variant C: keep the strong key light (drama/contrast on top), add only GENTLE low
# fills to rake the vertical sides just above the MC noise floor. Goal = A's look,
# B's clean edges. Single output for quick read.
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

# Strong key (unchanged) + 2 dim low fills from the shadowed quadrants.
cat("C: key + gentle low fill...\n"); t0 <- Sys.time()
render_highquality("images/hq_lightC_tuned.png", samples=SAMP, light=TRUE,
                   lightdirection=c(315, 150, 225),
                   lightaltitude =c(45,  20,  18),
                   lightintensity=c(650, 110, 110),
                   clamp_value=10, width=1100, height=950, clear=TRUE,
                   scene_elements=oxy)
cat(sprintf("  %.0fs done\n", as.numeric(difftime(Sys.time(),t0,units="secs"))))
