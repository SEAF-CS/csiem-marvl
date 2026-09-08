# ============================================================================
# Salt-cascade DRAPE renderer (rasterised). Salt = per-vertex-coloured MESH on the
# seabed (the oxycline mechanism) — NOT add_overlay (which transposes vs the mesh on
# non-square grids). elmat = raster_to_matrix AS-IS (rtm); verified geography-correct.
# Terrain built once; salt mesh swapped per frame (tag="salt"); resumable.
#
# Env: SDIR/PREFIX (series), SMIN/SMAX (psu scale), MASKTIF ("none"=full domain),
#      THETA/PHI/ZOOM, RAISE (m above seabed), OUT, FRAME/FRAMES, FORCE.
# ============================================================================
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })
g  <- function(k,d){ v<-Sys.getenv(k); if(nzchar(v)) v else d }
gn <- function(k,d) as.numeric(g(k,as.character(d)))

DEMC   <- "data/dem_coarse_fixed.tif"
SDIR   <- g("SDIR","data/sal_bottom"); PREFIX <- g("PREFIX","sal")
SMIN   <- gn("SMIN",33); SMAX <- gn("SMAX",35.2)
MASKTIF<- g("MASKTIF","data/cs_mask.tif")          # "none" -> full domain
THETA  <- gn("THETA",0); PHI <- gn("PHI",45); ZOOM <- gn("ZOOM",0.62)
ZSCALE <- gn("ZSCALE",0.4); W <- gn("W",1500); H <- gn("H",1280)
RAISE  <- gn("RAISE",2); OUT <- g("OUT","images/drape"); dir.create(OUT,showWarnings=FALSE)
ALPHA  <- gn("ALPHA",1)                              # <1 = translucent (basin relief reads through)
FORCE  <- g("FORCE","")=="1"
PAL <- colorRampPalette(c("#abd9e9","#74add1","#4575b4","#8856a7","#762a83","#40004b"))(256)

elmat  <- raster_to_matrix(raster(DEMC)); nr<-nrow(elmat); nc<-ncol(elmat)
CSMASK <- if (nzchar(MASKTIF) && file.exists(MASKTIF)) raster_to_matrix(raster(MASKTIF)) else NULL
tifs <- sort(list.files(SDIR, pattern=sprintf("%s_\\d+\\.tif$",PREFIX), full.names=TRUE))
if (!length(tifs)) stop("no tifs in ",SDIR)
FRAME<-g("FRAME",""); FRAMES<-g("FRAMES","")
idx <- if(nzchar(FRAMES)) (as.integer(strsplit(FRAMES,",")[[1]])+1) else
       if(nzchar(FRAME)) (as.integer(FRAME)+1) else seq_along(tifs)

ms<-ray_shade(elmat,zscale=ZSCALE,lambert=TRUE); ma<-ambient_shade(elmat,zscale=ZSCALE)
elmat |> sphere_shade(zscale=ZSCALE,texture="imhof1") |> add_shadow(ms,0.5) |> add_shadow(ma,0) |>
  plot_3d(elmat,zscale=ZSCALE,fov=0,theta=THETA,phi=PHI,windowsize=c(W,H),zoom=ZOOM,water=FALSE)
Sys.sleep(0.3)

add_salt <- function(saltmat){
  rgl::pop3d(tag="salt")
  if (!is.null(CSMASK)) saltmat[is.na(CSMASK)] <- NA
  salt_h <- elmat + RAISE; salt_h[is.na(saltmat)] <- NA
  surf <- rayshader:::generate_surface(salt_h, ZSCALE)
  m <- rgl::tmesh3d(vertices=t(surf$verts), indices=surf$inds, homogeneous=FALSE)
  norm <- pmin(pmax((c(saltmat)-SMIN)/(SMAX-SMIN),0),1)
  ci <- 1+round(norm*255); ci[is.na(ci)]<-1
  rgl::shade3d(m, col=PAL[ci], meshColor="vertices", lit=FALSE, alpha=ALPHA,
               front="fill", back="fill", tag="salt")
}

cat(sprintf("DRAPE(mesh) %s scale %.2f..%.2f mask=%s theta=%g phi=%g | %d frame(s)\n",
            SDIR,SMIN,SMAX,!is.null(CSMASK),THETA,PHI,length(idx)))
done<-0
for (i in idx){
  out<-sprintf("%s/f_%03d.png",OUT,i-1)
  if(!FORCE && file.exists(out)) next
  add_salt(raster_to_matrix(raster(tifs[i])))
  render_camera(theta=THETA,phi=PHI,zoom=ZOOM,fov=0)
  render_snapshot(out,clear=FALSE); done<-done+1
}
rgl::close3d()
cat(sprintf("done: %d rendered (%d requested)\n",done,length(idx)))
