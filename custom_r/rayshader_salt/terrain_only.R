.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
mk <- function(e,nm){ ms<-ray_shade(e,zscale=ZSCALE,lambert=TRUE)
  tex<-add_shadow(height_shade(e),ms,0.4)
  plot_3d(tex,e,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(560,1150),zoom=0.95,water=FALSE); Sys.sleep(0.15)
  render_camera(theta=0,phi=90,zoom=0.95,fov=0)
  render_snapshot(sprintf("images/terr_%s.png",nm),clear=FALSE); rgl::clear3d(); cat(nm,"\n") }
rtm <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
mk(rtm,"rtm")
mk(t(rtm),"trtm")
rgl::close3d()
