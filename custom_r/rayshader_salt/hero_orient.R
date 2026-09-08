.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE <- 0.4; PHI <- 45; ZOOM <- 0.6; W<-1000; H<-850
FLIP <- Sys.getenv("FLIP","none")
e0 <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))
elmat <- switch(FLIP, none=e0, lr=e0[,ncol(e0):1], ud=e0[nrow(e0):1,], both=e0[nrow(e0):1,ncol(e0):1])
nr<-nrow(elmat); nc<-ncol(elmat)
# geographic label positions IN ORIGINAL matrix: N=col1, S=colNc, W=row1, E=rowNr
# after a flip, transform the (row,col) the same way:
pos <- list(N=c(round(nr/2),1), S=c(round(nr/2),nc), W=c(1,round(nc/2)), E=c(nr,round(nc/2)))
tf <- function(rc){ r<-rc[1]; c<-rc[2]
  if(FLIP=="lr") c<-nc-c+1; if(FLIP=="ud") r<-nr-r+1; if(FLIP=="both"){r<-nr-r+1;c<-nc-c+1}; c(r,c) }
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
tex<-elmat|>sphere_shade(zscale=ZSCALE,texture="imhof1")|>add_shadow(ms,0.5)|>add_shadow(ma,0)
dir.create("images/hsweep",showWarnings=FALSE)
for (th in seq(0,315,by=45)){
  plot_3d(tex,elmat,zscale=ZSCALE,fov=0,theta=th,phi=PHI,windowsize=c(W,H),zoom=ZOOM,water=FALSE); Sys.sleep(0.1)
  for(nm in names(pos)){ p<-tf(pos[[nm]])
    render_label(elmat,x=p[2],y=p[1],z=2500,zscale=ZSCALE,text=nm,textsize=2,linewidth=3,textcolor="red",linecolor="red") }
  render_camera(theta=th,phi=PHI,zoom=ZOOM,fov=0)
  render_snapshot(sprintf("images/hsweep/%s_%03d.png",FLIP,th),clear=FALSE); rgl::clear3d()
  cat(FLIP,th,"\n")
}
rgl::close3d()
