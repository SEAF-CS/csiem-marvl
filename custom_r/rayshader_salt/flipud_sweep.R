# Lock GLOBAL orientation. Full water mask (cyan, Swan estuary visible, NO CS crop),
# data flipped UP-DOWN (per user), swept over theta. Pick the view matching the real coast.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4; PHI <- 45; ZOOM <- 0.60; W <- 1000; H <- 850
FLIP <- Sys.getenv("FLIP", "ud")            # ud | none | lr | both

elmat0 <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
flipmat <- function(m) switch(FLIP,
  none = m, ud = m[nrow(m):1, ], lr = m[, ncol(m):1], both = m[nrow(m):1, ncol(m):1])
elmat <- flipmat(elmat0); nr <- nrow(elmat); nc <- ncol(elmat)
water <- elmat < 0
ov <- array(0, dim=c(nr,nc,4)); ov[,,2]<-1; ov[,,3]<-1; ov[,,4]<-ifelse(water,0.65,0)
ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE); ma <- ambient_shade(elmat, zscale=ZSCALE)
tex <- elmat |> sphere_shade(zscale=ZSCALE, texture="imhof1") |>
       add_shadow(ms,0.5) |> add_shadow(ma,0) |> add_overlay(ov, alphalayer=0.7)
dir.create("images/osweep", showWarnings=FALSE)
for (th in seq(0,315,by=45)) {
  plot_3d(tex, elmat, zscale=ZSCALE, fov=0, theta=th, phi=PHI, windowsize=c(W,H), zoom=ZOOM, water=FALSE)
  Sys.sleep(0.15); render_camera(theta=th, phi=PHI, zoom=ZOOM, fov=0)
  render_snapshot(sprintf("images/osweep/%s_%03d.png", FLIP, th), clear=FALSE); rgl::clear3d()
  cat(FLIP, "theta", th, "\n")
}
rgl::close3d()
