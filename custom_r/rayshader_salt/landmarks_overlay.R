.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
elmat <- t(raster_to_matrix(raster("data/dem_coarse_fixed.tif")))   # north-up array
nr<-nrow(elmat); nc<-ncol(elmat)
lm <- read.csv("data/landmarks_px.csv", stringsAsFactors=FALSE)
cols <- list(c(1,0,0),c(0,0,1),c(0,1,0),c(1,0,1),c(1,1,0))   # R,B,G,magenta,Y
ov <- array(0,dim=c(nr,nc,4)); d<-9
for (i in seq_len(nrow(lm))){
  r<-lm$row[i]; c<-lm$col[i]; cc<-cols[[i]]
  rr<-max(1,r-d):min(nr,r+d); ccc<-max(1,c-d):min(nc,c+d)
  ov[rr,ccc,1]<-cc[1]; ov[rr,ccc,2]<-cc[2]; ov[rr,ccc,3]<-cc[3]; ov[rr,ccc,4]<-1
}
cat("dot colours: Garden=RED Fremantle=BLUE Woodman=GREEN CapePeron=MAGENTA Carnac=YELLOW\n")
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
tex<-elmat|>sphere_shade(zscale=ZSCALE,texture="imhof1")|>add_shadow(ms,0.5)|>add_shadow(ma,0)|>add_overlay(ov,alphalayer=1)
plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=340,phi=48,windowsize=c(1300,1050),zoom=0.55,water=FALSE); Sys.sleep(0.2)
render_camera(theta=340,phi=48,zoom=0.55,fov=0)
render_snapshot("images/landmarks_overlay.png",clear=FALSE); rgl::close3d(); cat("done\n")
