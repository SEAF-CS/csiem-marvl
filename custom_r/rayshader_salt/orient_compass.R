.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif")); nr<-nrow(elmat); nc<-ncol(elmat)
ov <- array(0, dim=c(nr,nc,4))
b <- 40                                  # marker block size
paint <- function(r0,r1,c0,c1,col){ rc<-col2rgb(col)/255
  ov[r0:r1,c0:c1,1]<<-rc[1]; ov[r0:r1,c0:c1,2]<<-rc[2]; ov[r0:r1,c0:c1,3]<<-rc[3]; ov[r0:r1,c0:c1,4]<<-1 }
paint(1,b,1,b,"red")            # matrix (1,1)        RED
paint(1,b,nc-b+1,nc,"green")    # matrix (1,nc)       GREEN
paint(nr-b+1,nr,1,b,"blue")     # matrix (nr,1)       BLUE
paint(nr-b+1,nr,nc-b+1,nc,"yellow") # matrix (nr,nc)  YELLOW
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
tex <- elmat|>sphere_shade(zscale=ZSCALE,texture="bw")|>add_shadow(ms,0.5)|>add_overlay(ov,alphalayer=1)
# top-down (plan)
plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(900,1500),zoom=0.9,water=FALSE)
Sys.sleep(0.2); render_camera(theta=0,phi=90,zoom=0.9,fov=0)
render_snapshot("images/compass_plan.png",clear=FALSE); rgl::clear3d()
# hero-ish oblique
plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=0,phi=45,windowsize=c(1100,950),zoom=0.62,water=FALSE)
Sys.sleep(0.2); render_camera(theta=0,phi=45,zoom=0.62,fov=0)
render_snapshot("images/compass_oblique.png",clear=FALSE); rgl::close3d()
cat("RED=mat(1,1) GREEN=mat(1,nc) BLUE=mat(nr,1) YELLOW=mat(nr,nc)\n")
