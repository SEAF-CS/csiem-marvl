.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4; THETA<-0; PHI<-45; ZOOM<-0.62; W<-1300; H<-1100
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif")); nr<-nrow(elmat); nc<-ncol(elmat)
salt  <- raster_to_matrix(raster("data/sal_bottom/sal_059.tif"))
halo  <- raster_to_matrix(raster("data/halo_series/halo_059.tif"))
PAL <- colorRampPalette(c("#abd9e9","#74add1","#4575b4","#8856a7","#762a83","#40004b"))(256)
SMIN<-34.3; SMAX<-34.9
mkbase <- function(){
  ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
  elmat|>sphere_shade(zscale=ZSCALE,texture="imhof1")|>add_shadow(ms,0.5)|>add_shadow(ma,0)|>
    plot_3d(elmat,zscale=ZSCALE,fov=0,theta=THETA,phi=PHI,windowsize=c(W,H),zoom=ZOOM,water=FALSE)
  Sys.sleep(0.3)
}
saltmesh <- function(v, raise, alpha){
  sh<-elmat+raise; sh[is.na(v)]<-NA
  surf<-rayshader:::generate_surface(sh,ZSCALE)
  m<-rgl::tmesh3d(t(surf$verts),surf$inds,homogeneous=FALSE)
  norm<-pmin(pmax((c(v)-SMIN)/(SMAX-SMIN),0),1); ci<-1+round(norm*255); ci[is.na(ci)]<-1
  rgl::shade3d(m,col=PAL[ci],meshColor="vertices",lit=FALSE,alpha=alpha,front="fill",back="fill",tag="s")
}
# A: clipped dense-water footprint on the floor
mkbase(); v<-salt; v[v<34.55]<-NA; saltmesh(v,1.5,1)
render_camera(theta=THETA,phi=PHI,zoom=ZOOM,fov=0); render_snapshot("images/optA_clip.png",clear=FALSE); rgl::close3d()
# B: translucent full drape
mkbase(); saltmesh(salt,1.5,0.45)
render_camera(theta=THETA,phi=PHI,zoom=ZOOM,fov=0); render_snapshot("images/optB_translucent.png",clear=FALSE); rgl::close3d()
# C: halocline isosurface at its true elevation (translucent body)
mkbase()
sh<-halo; surf<-rayshader:::generate_surface(sh,ZSCALE)
m<-rgl::tmesh3d(t(surf$verts),surf$inds,homogeneous=FALSE)
rgl::shade3d(m,col="#762a83",lit=FALSE,alpha=0.6,front="fill",back="fill",tag="iso")
render_camera(theta=THETA,phi=PHI,zoom=ZOOM,fov=0); render_snapshot("images/optC_isosurface.png",clear=FALSE); rgl::close3d()
cat("done\n")
