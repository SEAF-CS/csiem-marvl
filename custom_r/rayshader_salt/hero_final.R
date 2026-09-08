.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4; SMIN<-33; SMAX<-35.2
elmat <- t(raster_to_matrix(raster("data/dem_coarse_fixed.tif")))   # transposed (correct)
nr<-nrow(elmat); nc<-ncol(elmat)
lm <- read.csv("data/landmarks_px.csv", stringsAsFactors=FALSE)
PAL <- colorRampPalette(c("#e0f3f8","#abd9e9","#74add1","#4575b4","#8856a7","#762a83","#40004b"))(256)
salm <- t(raster_to_matrix(raster("data/sal_bottom/sal_059.tif")))
norm<-(salm-SMIN)/(SMAX-SMIN); norm[norm<0]<-0; norm[norm>1]<-1
ci<-1+round(norm*255); ov<-array(0,dim=c(nr,nc,4)); flat<-as.vector(ci); ok<-!is.na(flat)
rgb<-matrix(0,length(flat),3); rgb[ok,]<-t(col2rgb(PAL[flat[ok]])/255)
ov[,,1]<-matrix(rgb[,1],nr,nc); ov[,,2]<-matrix(rgb[,2],nr,nc); ov[,,3]<-matrix(rgb[,3],nr,nc)
ov[,,4]<-ifelse(is.na(salm),0,0.9)
pc <- list(c(1,0,0),c(0,0,1),c(0,1,0),c(1,0,1),c(1,1,0))
d<-7
for (i in seq_len(nrow(lm))){ r<-lm$row[i]; c<-lm$col[i]; cc<-pc[[i]]   # PLAIN array coords
  rr<-max(1,r-d):min(nr,r+d); ccc<-max(1,c-d):min(nc,c+d)
  ov[rr,ccc,1]<-cc[1]; ov[rr,ccc,2]<-cc[2]; ov[rr,ccc,3]<-cc[3]; ov[rr,ccc,4]<-1 }
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
tex<-add_overlay(add_shadow(add_shadow(sphere_shade(elmat,zscale=ZSCALE,texture="imhof1"),ms,0.5),ma,0),ov,alphalayer=0.92)
dir.create("images/hf",showWarnings=FALSE)
for (th in seq(0,315,by=45)){
  plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=th,phi=45,windowsize=c(1000,850),zoom=0.62,water=FALSE); Sys.sleep(0.12)
  render_camera(theta=th,phi=45,zoom=0.62,fov=0)
  render_snapshot(sprintf("images/hf/th%03d.png",th),clear=FALSE); rgl::clear3d(); cat(th,"\n") }
rgl::close3d()
