# Drape the model mesh (faint edges) over the terrain to inspect channel resolution.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4; THETA<-0; PHI<-45; ZOOM<-0.62; W<-1600; H<-1350
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
seg <- as.matrix(read.csv("data/mesh_seg.csv", header=FALSE))
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
elmat|>sphere_shade(zscale=ZSCALE,texture="imhof1")|>add_shadow(ms,0.5)|>add_shadow(ma,0)|>
  plot_3d(elmat,zscale=ZSCALE,fov=0,theta=THETA,phi=PHI,windowsize=c(W,H),zoom=ZOOM,water=FALSE)
Sys.sleep(0.3)
rgl::segments3d(seg[,1], seg[,2], seg[,3], color="#222222", alpha=0.28, lwd=0.4)
render_camera(theta=THETA,phi=PHI,zoom=ZOOM,fov=0)
render_snapshot("images/mesh_overlay.png", clear=FALSE)
# also a near-top view to read channel resolution clearly
render_camera(theta=THETA,phi=88,zoom=0.9,fov=0)
render_snapshot("images/mesh_overlay_plan.png", clear=FALSE)
rgl::close3d(); cat("done\n")
