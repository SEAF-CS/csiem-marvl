.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
nr<-nrow(elmat); nc<-ncol(elmat)
lm <- read.csv("data/landmarks_px.csv", stringsAsFactors=FALSE)
cols <- list(c(1,0,0),c(0,0,1),c(0,1,0),c(1,0,1),c(1,1,0))  # Garden Fremantle Woodman CapePeron Carnac
ov<-array(0,dim=c(nr,nc,4)); d<-9
for (i in seq_len(nrow(lm))){
  # swapped coords (row=col, col=row) THEN R180 (nr-..+1, nc-..+1)
  r <- nr - lm$col[i] + 1
  c <- nc - lm$row[i] + 1
  cc<-cols[[i]]
  rr<-max(1,r-d):min(nr,r+d); ccc<-max(1,c-d):min(nc,c+d)
  ov[rr,ccc,1]<-cc[1]; ov[rr,ccc,2]<-cc[2]; ov[rr,ccc,3]<-cc[3]; ov[rr,ccc,4]<-1
}
tex<-add_overlay(height_shade(elmat),ov,alphalayer=1)
plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(560,1150),zoom=0.95,water=FALSE); Sys.sleep(0.2)
render_camera(theta=0,phi=90,zoom=0.95,fov=0)
render_snapshot("images/pin_verify.png",clear=FALSE); rgl::close3d(); cat("done\n")
