.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
nr<-nrow(elmat); nc<-ncol(elmat)
# Swan/Fremantle at array[230,274] -> raster_to_matrix index [274,230] (rtm[i,j]=array[j,i])
sr<-274; sc<-230
# place 4 candidate pins for the SAME feature: none, UD, LR, 180 of that index
pins<-list(none=c(sr,sc), UD=c(nr-sr+1,sc), LR=c(sr,nc-sc+1), R180=c(nr-sr+1,nc-sc+1))
pcol<-list(none=c(1,0,0),UD=c(0,0,1),LR=c(0,1,0),R180=c(1,1,0))
ov<-array(0,dim=c(nr,nc,4)); d<-6
for(nm in names(pins)){p<-pins[[nm]];cc<-pcol[[nm]]
  rr<-max(1,p[1]-d):min(nr,p[1]+d); ccc<-max(1,p[2]-d):min(nc,p[2]+d)
  ov[rr,ccc,1]<-cc[1];ov[rr,ccc,2]<-cc[2];ov[rr,ccc,3]<-cc[3];ov[rr,ccc,4]<-1}
cat("Swan candidates: RED=none BLUE=UD GREEN=LR YELLOW=R180  (Swan channel is the meander)\n")
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE)
tex<-add_overlay(add_shadow(sphere_shade(elmat,zscale=ZSCALE,texture="imhof1"),ms,0.5),ov,alphalayer=1)
plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(560,1150),zoom=0.95,water=FALSE);Sys.sleep(0.2)
render_camera(theta=0,phi=90,zoom=0.95,fov=0)
render_snapshot("images/addov_test.png",clear=FALSE);rgl::close3d();cat("done\n")
