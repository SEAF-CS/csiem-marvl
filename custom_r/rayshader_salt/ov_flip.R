.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))   # correct terrain
nr<-nrow(elmat); nc<-ncol(elmat)
lm <- read.csv("data/landmarks_px.csv", stringsAsFactors=FALSE)
cols <- list(c(1,0,0),c(0,0,1),c(0,1,0),c(1,0,1),c(1,1,0))
base_ov <- function(){ ov<-array(0,dim=c(nr,nc,4)); d<-10
  for (i in seq_len(nrow(lm))){ r<-lm$col[i]; c<-lm$row[i]; cc<-cols[[i]]  # array(R,C)->rtm(C,R)
    rr<-max(1,r-d):min(nr,r+d); ccc<-max(1,c-d):min(nc,c+d)
    ov[rr,ccc,1]<-cc[1]; ov[rr,ccc,2]<-cc[2]; ov[rr,ccc,3]<-cc[3]; ov[rr,ccc,4]<-1 }
  ov }
flips <- list(none=function(o)o, UD=function(o)o[nr:1,,], LR=function(o)o[,nc:1,], both=function(o)o[nr:1,nc:1,])
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE)
hill<-add_shadow(sphere_shade(elmat,zscale=ZSCALE,texture="imhof1"),ms,0.5)
dir.create("images/ovf",showWarnings=FALSE)
for (nm in names(flips)){ ov<-flips[[nm]](base_ov())
  tex<-add_overlay(hill,ov,alphalayer=1)
  plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(560,1150),zoom=0.95,water=FALSE); Sys.sleep(0.12)
  render_camera(theta=0,phi=90,zoom=0.95,fov=0)
  render_snapshot(sprintf("images/ovf/%s.png",nm),clear=FALSE); rgl::clear3d(); cat(nm,"\n") }
rgl::close3d()
