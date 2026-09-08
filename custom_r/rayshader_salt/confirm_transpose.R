.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
elmat <- t(raster_to_matrix(raster("data/dem_coarse_fixed.tif")))  # transpose
nr<-nrow(elmat); nc<-ncol(elmat); b<-45
ov<-array(0,dim=c(nr,nc,4))
paint<-function(r0,r1,c0,c1,col){rc<-col2rgb(col)/255
  ov[r0:r1,c0:c1,1]<<-rc[1];ov[r0:r1,c0:c1,2]<<-rc[2];ov[r0:r1,c0:c1,3]<<-rc[3];ov[r0:r1,c0:c1,4]<<-1}
paint(1,b,1,b,"red")               # (1,1)=NW
paint(1,b,nc-b+1,nc,"green")       # (1,nc)=NE  <- Swan corner
paint(nr-b+1,nr,1,b,"blue")        # (nr,1)=SW
paint(nr-b+1,nr,nc-b+1,nc,"yellow")# (nr,nc)=SE
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
tex<-elmat|>sphere_shade(zscale=ZSCALE,texture="imhof1")|>add_shadow(ms,0.5)|>add_overlay(ov,alphalayer=1)
plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=0,phi=42,windowsize=c(1100,950),zoom=0.62,water=FALSE)
Sys.sleep(0.2); render_camera(theta=0,phi=42,zoom=0.62,fov=0)
render_snapshot("images/confirm_transpose.png",clear=FALSE); rgl::close3d()
cat("RED=NW GREEN=NE(Swan) BLUE=SW YELLOW=SE\n")
