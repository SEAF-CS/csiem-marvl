# Find the camera azimuth (theta) that orients geography correctly (Swan NE, sound opens
# north). Salt is already glued to terrain; only the view rotates. Frame 59, base built once.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4; PHI <- 45; ZOOM <- 0.62; W <- 1000; H <- 850
SMIN <- 34.1; SMAX <- 34.77
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif")); nr<-nrow(elmat); nc<-ncol(elmat)
CSMASK <- raster_to_matrix(raster("data/cs_mask.tif"))
PAL <- colorRampPalette(c("#e0f3f8","#abd9e9","#74add1","#4575b4","#8856a7","#762a83","#40004b"))(256)
v <- raster_to_matrix(raster("data/sal_bottom/sal_059.tif")); v[is.na(CSMASK)]<-NA
norm <- (v-SMIN)/(SMAX-SMIN); norm[norm<0]<-0; norm[norm>1]<-1
ci <- 1+round(norm*255); ov<-array(0,dim=c(nr,nc,4)); flat<-as.vector(ci); ok<-!is.na(flat)
rgbm<-matrix(0,length(flat),3); rgbm[ok,]<-t(col2rgb(PAL[flat[ok]])/255)
ov[,,1]<-matrix(rgbm[,1],nr,nc);ov[,,2]<-matrix(rgbm[,2],nr,nc);ov[,,3]<-matrix(rgbm[,3],nr,nc)
ov[,,4]<-ifelse(is.na(v),0,1)
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
tex <- elmat|>sphere_shade(zscale=ZSCALE,texture="imhof1")|>add_shadow(ms,0.5)|>add_shadow(ma,0)|>
       add_overlay(ov,alphalayer=0.92)
dir.create("images/sweep",showWarnings=FALSE)
for (th in seq(0,315,by=45)) {
  plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=th,phi=PHI,windowsize=c(W,H),zoom=ZOOM,water=FALSE)
  Sys.sleep(0.15); render_camera(theta=th,phi=PHI,zoom=ZOOM,fov=0)
  render_snapshot(sprintf("images/sweep/theta_%03d.png",th),clear=FALSE); rgl::clear3d()
  cat("theta",th,"\n")
}
rgl::close3d()
