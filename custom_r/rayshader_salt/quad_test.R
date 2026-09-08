.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
nr<-nrow(elmat); nc<-ncol(elmat); hr<-nr%/%2; hc<-nc%/%2
ov<-array(0,dim=c(nr,nc,4)); ov[,,4]<-0.45
ov[1:hr,1:hc,1]<-1                       # overlay TL-index = RED
ov[1:hr,(hc+1):nc,2]<-1                   # overlay TR-index = GREEN
ov[(hr+1):nr,1:hc,3]<-1                    # overlay BL-index = BLUE
ov[(hr+1):nr,(hc+1):nc,1]<-1; ov[(hr+1):nr,(hc+1):nc,2]<-1  # overlay BR-index = YELLOW
cat("overlay index quadrants: TL=RED TR=GREEN BL=BLUE BR=YELLOW\n")
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE)
tex<-add_overlay(add_shadow(sphere_shade(elmat,zscale=ZSCALE,texture="imhof1"),ms,0.5),ov,alphalayer=0.45)
plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(560,1150),zoom=0.95,water=FALSE);Sys.sleep(0.2)
render_camera(theta=0,phi=90,zoom=0.95,fov=0)
render_snapshot("images/quad_test.png",clear=FALSE);rgl::close3d();cat("done\n")
