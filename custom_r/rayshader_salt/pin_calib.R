.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))   # confirmed-correct terrain
nr<-nrow(elmat); nc<-ncol(elmat)
# Garden Is at array[578,137]; in rtm that's [137,578]. Place that + its 3 flips, distinct colours.
R<-137; C<-578
pins <- list(none=c(R,C), UD=c(nr-R+1,C), LR=c(R,nc-C+1), R180=c(nr-R+1,nc-C+1))
pincol <- list(none=c(1,0,0), UD=c(0,0,1), LR=c(0,1,0), R180=c(1,1,0)) # red blue green yellow
ov<-array(0,dim=c(nr,nc,4)); d<-7
for (nm in names(pins)){ p<-pins[[nm]]; cc<-pincol[[nm]]
  rr<-max(1,p[1]-d):min(nr,p[1]+d); ccc<-max(1,p[2]-d):min(nc,p[2]+d)
  ov[rr,ccc,1]<-cc[1]; ov[rr,ccc,2]<-cc[2]; ov[rr,ccc,3]<-cc[3]; ov[rr,ccc,4]<-1 }
cat("Garden Is candidates: RED=none BLUE=UD GREEN=LR YELLOW=R180\n")
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE)
tex<-add_overlay(add_shadow(sphere_shade(elmat,zscale=ZSCALE,texture="bw"),ms,0.6),ov,alphalayer=1)
plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(560,1150),zoom=0.95,water=FALSE); Sys.sleep(0.2)
render_camera(theta=0,phi=90,zoom=0.95,fov=0)
render_snapshot("images/pin_calib_plan.png",clear=FALSE); rgl::close3d(); cat("done\n")
