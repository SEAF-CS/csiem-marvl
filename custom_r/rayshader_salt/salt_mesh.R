.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
ZSCALE<-0.4; SMIN<-33; SMAX<-35.2
elmat <- raster_to_matrix(raster("data/dem_coarse_fixed.tif"))   # rtm = correct terrain
salt  <- raster_to_matrix(raster("data/sal_bottom/sal_059.tif")) # same grid
nr<-nrow(elmat); nc<-ncol(elmat)
PAL <- colorRampPalette(c("#e0f3f8","#abd9e9","#74add1","#4575b4","#8856a7","#762a83","#40004b"))(256)
ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
elmat |> sphere_shade(zscale=ZSCALE,texture="imhof1") |> add_shadow(ms,0.5) |> add_shadow(ma,0) |>
  plot_3d(elmat,zscale=ZSCALE,fov=0,theta=0,phi=90,windowsize=c(560,1150),zoom=0.95,water=FALSE)
Sys.sleep(0.3)
# salt as a per-vertex-coloured MESH (oxycline mechanism) -> shares terrain coord frame
salt_h <- elmat + 2; salt_h[is.na(salt)] <- NA            # mesh only where salt exists
surf <- rayshader:::generate_surface(salt_h, ZSCALE)
m <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
sv <- c(salt); norm <- pmin(pmax((sv-SMIN)/(SMAX-SMIN),0),1)
ci <- 1+round(norm*255); ci[is.na(ci)] <- 1; vcol <- PAL[ci]
rgl::shade3d(m, col=vcol, meshColor="vertices", lit=FALSE, alpha=1, front="fill", back="fill")
render_camera(theta=0,phi=90,zoom=0.95,fov=0)
render_snapshot("images/salt_mesh_plan2.png",clear=FALSE); rgl::close3d(); cat("done\n")
