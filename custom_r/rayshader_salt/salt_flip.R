.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4; SMIN<-33; SMAX<-35.2
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))   # correct terrain (mesh)
nr<-nrow(elmat); nc<-ncol(elmat)
PAL <- colorRampPalette(c("#e0f3f8","#abd9e9","#74add1","#4575b4","#8856a7","#762a83","#40004b"))(256)
salm <- raster_to_matrix(raster("data/sal_bottom/sal_059.tif"))
mkov <- function(v){ norm<-(v-SMIN)/(SMAX-SMIN); norm[norm<0]<-0; norm[norm>1]<-1
  ci<-1+round(norm*255); ov<-array(0,dim=c(nrow(v),ncol(v),4)); flat<-as.vector(ci); ok<-!is.na(flat)
  rgb<-matrix(0,length(flat),3); rgb[ok,]<-t(col2rgb(PAL[flat[ok]])/255)
  ov[,,1]<-matrix(rgb[,1],nrow(v),ncol(v)); ov[,,2]<-matrix(rgb[,2],nrow(v),ncol(v)); ov[,,3]<-matrix(rgb[,3],nrow(v),ncol(v))
  ov[,,4]<-ifelse(is.na(v),0,0.92); ov }
flips <- list(none=salm, UD=salm[nr:1,], LR=salm[,nc:1], R180=salm[nr:1,nc:1])
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
hill<-add_shadow(add_shadow(sphere_shade(elmat,zscale=ZSCALE,texture="imhof1"),ms,0.5),ma,0)
dir.create("images/sf",showWarnings=FALSE)
for (nm in names(flips)){ tex<-add_overlay(hill,mkov(flips[[nm]]),alphalayer=0.92)
  plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=315,phi=45,windowsize=c(1100,950),zoom=0.6,water=FALSE); Sys.sleep(0.15)
  render_camera(theta=315,phi=45,zoom=0.6,fov=0)
  render_snapshot(sprintf("images/sf/%s.png",nm),clear=FALSE); rgl::clear3d(); cat(nm,"\n") }
rgl::close3d()
