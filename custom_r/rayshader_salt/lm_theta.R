.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
elmat <- t(raster_to_matrix(raster("data/dem_coarse_fixed.tif")))
nr<-nrow(elmat); nc<-ncol(elmat)
lm <- read.csv("data/landmarks_px.csv", stringsAsFactors=FALSE)
cols <- list(c(1,0,0),c(0,0,1),c(0,1,0),c(1,0,1),c(1,1,0))
ov <- array(0,dim=c(nr,nc,4)); d<-9
for (i in seq_len(nrow(lm))) {
  r<-lm$row[i]; c<-lm$col[i]; cc<-cols[[i]]
  rr<-max(1,r-d):min(nr,r+d); ccc<-max(1,c-d):min(nc,c+d)
  ov[rr,ccc,1]<-cc[1]; ov[rr,ccc,2]<-cc[2]; ov[rr,ccc,3]<-cc[3]; ov[rr,ccc,4]<-1
}
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
tex<-add_overlay(add_shadow(add_shadow(sphere_shade(elmat,zscale=ZSCALE,texture="imhof1"),ms,0.5),ma,0),ov,alphalayer=1)
for (th in c(180,160,200)) {
  plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=th,phi=45,windowsize=c(1200,1000),zoom=0.6,water=FALSE); Sys.sleep(0.15)
  render_camera(theta=th,phi=45,zoom=0.6,fov=0)
  render_snapshot(sprintf("images/lm_th%03d.png",th),clear=FALSE); rgl::clear3d(); cat("theta",th,"\n")
}
rgl::close3d()
