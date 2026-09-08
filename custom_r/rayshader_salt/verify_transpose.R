.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4; PHI<-45; ZOOM<-0.6; W<-1100; H<-950
elmat <- t(raster_to_matrix(raster("data/dem_coarse_fixed.tif")))   # TRANSPOSE = the fix
nr<-nrow(elmat); nc<-ncol(elmat)   # 847 x 419
# north-up labels in transposed space: N=row1, S=rowNr, W=col1, E=colNc
lab <- list(N=c(1,round(nc/2)), S=c(nr,round(nc/2)), W=c(round(nr/2),1), E=c(round(nr/2),nc))
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
tex<-elmat|>sphere_shade(zscale=ZSCALE,texture="imhof1")|>add_shadow(ms,0.5)|>add_shadow(ma,0)
for (th in c(0,340,20)){
  plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=th,phi=PHI,windowsize=c(W,H),zoom=ZOOM,water=FALSE); Sys.sleep(0.15)
  for(nm in names(lab)){ p<-lab[[nm]]
    render_label(elmat,x=p[2],y=p[1],z=2500,zscale=ZSCALE,text=nm,textsize=2.4,linewidth=4,textcolor="red",linecolor="red") }
  render_camera(theta=th,phi=PHI,zoom=ZOOM,fov=0)
  render_snapshot(sprintf("images/transpose_th%03d.png",th),clear=FALSE); rgl::clear3d(); cat("theta",th,"\n")
}
rgl::close3d()
