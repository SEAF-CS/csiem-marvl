# HQ smoke test v2 — FIX: oxycline now reaches render_highquality.
# Root cause of v1 miss: render_highquality re-path-traces via rayrender and only
# converts rgl meshes with tags it recognises (convert_rgl_to_raymesh). The overlay
# was tagged "iface" -> unrecognised -> silently dropped. Fix: don't put the overlay
# in the rgl scene at all; build it as a rayrender object and pass via scene_elements.
# scene_elements are added AFTER the terrain is shifted by -bbox_center, so we shift
# the overlay by the same vector (replicating render_highquality's own formula on the
# terrain-only scene, so the two agree exactly).
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl); library(rayrender) })

ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 45
FAST   <- as.logical(Sys.getenv("FAST", "TRUE"))   # TRUE = cheap alignment check
elmat  <- raster_to_matrix(raster("data/dem_coarse.tif"))
iface  <- raster_to_matrix(raster("data/oxy6_series/oxy6_040.tif"))  # ~peak coverage

# --- replicate render_highquality's bbox_center on the (terrain-only) rgl scene ---
rhq_bbox_center <- function() {
  rotmat <- rayshader:::rot_to_euler(rgl::par3d()$userMatrix)
  phi <- rotmat[1]; if (90 - abs(phi) < 0.001) phi <- -phi
  um  <- rgl::par3d()$userMatrix[, 4]
  if (0.001 > abs(abs(rotmat[3]) - 180)) {
    mv <- rgl::rotationMatrix(-rotmat[2]*pi/180, 0,1,0) %*%
          rgl::rotationMatrix(-phi*pi/180, 1,0,0) %*% um
  } else {
    mv <- rgl::rotationMatrix(rotmat[3]*pi/180, 0,0,1) %*%
          rgl::rotationMatrix(rotmat[2]*pi/180, 0,1,0) %*%
          rgl::rotationMatrix(-phi*pi/180, 1,0,0) %*% um
  }
  mv <- mv[1:3]
  bb <- rgl::par3d()$bbox
  c(mean(bb[1:2]), mean(bb[3:4]), mean(bb[5:6])) - mv
}

# --- terrain scene (NO rgl overlay this time) ---
montshadow <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
montamb    <- ambient_shade(elmat, zscale=ZSCALE)
elmat |>
  sphere_shade(zscale=ZSCALE, texture="imhof1") |>
  add_shadow(montshadow, 0.5) |> add_shadow(montamb, 0) |>
  plot_3d(elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(1000,850), zoom=ZOOM, water=FALSE)
render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)

bc <- rhq_bbox_center()
cat("bbox_center:", paste(round(bc, 3), collapse=", "), "\n")

# --- oxycline as a rayrender object, shifted into render_highquality world coords ---
surf <- rayshader:::generate_surface(iface, ZSCALE)
m   <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
oxy <- rayrender::mesh3d_model(m, x=-bc[1], y=-bc[2], z=-bc[3],
         override_material=TRUE,
         material=rayrender::diffuse(color="#d7301f"))

out    <- if (FAST) "images/hq_test2_fast.png" else "images/hq_test2.png"
nsamp  <- if (FAST) 16 else 128
cat(sprintf("starting render_highquality (%s, samples=%d)...\n",
            if (FAST) "FAST align-check" else "FULL", nsamp))
t0 <- Sys.time()
render_highquality(out, samples=nsamp, light=TRUE,
                   lightdirection=315, lightaltitude=45, lightintensity=650,
                   clamp_value=10, width=1100, height=950, clear=TRUE,
                   scene_elements=oxy)
cat(sprintf("render_highquality took %.1f s -> %s\n",
            as.numeric(difftime(Sys.time(), t0, units="secs")), out))
