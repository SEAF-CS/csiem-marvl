.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
E0 <- t(raster_to_matrix(raster("data/dem_coarse_fixed.tif")))   # north-up array
NR<-nrow(E0); NC<-ncol(E0)
lm <- read.csv("data/landmarks_px.csv", stringsAsFactors=FALSE)
cols <- list(c(1,0,0),c(0,0,1),c(0,1,0),c(1,0,1),c(1,1,0))
mkdots <- function(nr,nc,fr){ ov<-array(0,dim=c(nr,nc,4)); d<-10
  for (i in seq_len(nrow(lm))){ p<-fr(lm$row[i],lm$col[i]); r<-p[1]; c<-p[2]; cc<-cols[[i]]
    rr<-max(1,r-d):min(nr,r+d); ccc<-max(1,c-d):min(nc,c+d)
    ov[rr,ccc,1]<-cc[1]; ov[rr,ccc,2]<-cc[2]; ov[rr,ccc,3]<-cc[3]; ov[rr,ccc,4]<-1 }
  ov }
variants <- list(
  none=list(e=E0,                       fr=function(r,c) c(r,c)),
  LR  =list(e=E0[,NC:1],                fr=function(r,c) c(r, NC-c+1)),
  UD  =list(e=E0[NR:1,],                fr=function(r,c) c(NR-r+1, c)),
  both=list(e=E0[NR:1,NC:1],            fr=function(r,c) c(NR-r+1, NC-c+1))
)
for (nm in names(variants)){ v<-variants[[nm]]; e<-v$e; nr<-nrow(e); nc<-ncol(e)
  ov<-mkdots(nr,nc,v$fr)
  ms<-ray_shade(e,zscale=ZSCALE,lambert=TRUE)
  tex<-add_overlay(add_shadow(sphere_shade(e,zscale=ZSCALE,texture="imhof1"),ms,0.5),ov,alphalayer=1)
  plot_3d(tex,e,zscale=ZSCALE,fov=0,theta=0,phi=45,windowsize=c(1100,950),zoom=0.6,water=FALSE); Sys.sleep(0.15)
  render_camera(theta=0,phi=45,zoom=0.6,fov=0)
  render_snapshot(sprintf("images/flip_%s.png",nm),clear=FALSE); rgl::clear3d(); cat(nm,"\n") }
rgl::close3d()
