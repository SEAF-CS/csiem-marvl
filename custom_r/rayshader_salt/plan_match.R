.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
m  <- t(raster_to_matrix(raster("data/dem_coarse_fixed.tif")))
tm <- t(m)
cand <- list(E_t=tm, F_tUD=tm[nrow(tm):1,], G_tLR=tm[,ncol(tm):1], H_t180=tm[nrow(tm):1,ncol(tm):1])
dir.create("images/pm",showWarnings=FALSE)
for (nm in names(cand)){ e<-cand[[nm]]
  tex<-height_shade(e)
  plot_3d(tex,e,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(560,1150),zoom=0.95,water=FALSE); Sys.sleep(0.12)
  render_camera(theta=0,phi=90,zoom=0.95,fov=0)
  render_snapshot(sprintf("images/pm/%s.png",nm),clear=FALSE); rgl::clear3d(); cat(nm,"\n") }
rgl::close3d()
