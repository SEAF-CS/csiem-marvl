# Fast rasterised preview of the BOTTOM-SALINITY DRAPE (dense water pooling on the basin
# floor = the cascade). Salinity -> pale..purple colour ramp, draped on the seabed via
# add_overlay. Shares the R lib. FRAME env = one frame; else all.
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages({ library(rayshader); library(raster); library(rgl) })

DEMC <- "data/dem_coarse_fixed.tif"; SDIR <- "data/sal_bottom"
ZSCALE <- 0.4; PHI <- 40; ZOOM <- 0.62; THETA <- 15; W <- 1500; H <- 1280
SMIN <- as.numeric(Sys.getenv("SMIN", "34.1"))     # colour-scale ends (psu), tight on CS basin
SMAX <- as.numeric(Sys.getenv("SMAX", "34.77"))
MASKTIF <- Sys.getenv("MASKTIF", "data/cs_mask.tif")   # "" to disable CS mask
OUT <- "images/drape"; dir.create(OUT, showWarnings = FALSE)

elmat <- raster_to_matrix(raster(DEMC))
nr <- nrow(elmat); nc <- ncol(elmat)
CSMASK <- if (nzchar(MASKTIF) && file.exists(MASKTIF)) raster_to_matrix(raster(MASKTIF)) else NULL
tifs <- sort(list.files(SDIR, pattern="sal_\\d+\\.tif$", full.names=TRUE))
FRAME  <- Sys.getenv("FRAME", "")          # single frame
FRAMES <- Sys.getenv("FRAMES", "")         # comma list, e.g. 0,30,59,66
idx <- if (nzchar(FRAMES)) (as.integer(strsplit(FRAMES, ",")[[1]]) + 1) else
       if (nzchar(FRAME))  (as.integer(FRAME) + 1) else seq_along(tifs)

# cool (fresher) -> purple (dense salty); no pure white so it won't blend with no-data
PAL <- colorRampPalette(c("#e0f3f8","#abd9e9","#74add1","#4575b4",
                          "#8856a7","#762a83","#40004b"))(256)

sal_overlay <- function(saltif) {
  sal <- raster_to_matrix(raster(saltif))
  if (!is.null(CSMASK)) sal[is.na(CSMASK)] <- NA       # focus on Cockburn Sound
  norm <- (sal - SMIN) / (SMAX - SMIN)
  norm[norm < 0] <- 0; norm[norm > 1] <- 1
  ci <- 1 + round(norm * 255)                       # 1..256, NA where no data
  ov <- array(0, dim = c(nr, nc, 4))
  flat <- as.vector(ci); valid <- !is.na(flat)
  rgb <- matrix(0, length(flat), 3)
  rgb[valid, ] <- t(col2rgb(PAL[flat[valid]]) / 255)
  ov[,,1] <- matrix(rgb[,1], nr, nc)
  ov[,,2] <- matrix(rgb[,2], nr, nc)
  ov[,,3] <- matrix(rgb[,3], nr, nc)
  ov[,,4] <- ifelse(is.na(sal), 0, 1)               # alpha: only over wet cells
  ov
}

ms <- ray_shade(elmat, zscale=ZSCALE, lambert=TRUE)
ma <- ambient_shade(elmat, zscale=ZSCALE)
base <- elmat |> sphere_shade(zscale=ZSCALE, texture="imhof1") |>
        add_shadow(ms,0.5) |> add_shadow(ma,0)

# Salinity is baked into the surface texture, so each frame needs its own plot_3d.
for (i in idx) {
  tex <- add_overlay(base, sal_overlay(tifs[i]), alphalayer = 0.92)
  plot_3d(tex, elmat, zscale=ZSCALE, fov=0, theta=THETA, phi=PHI,
          windowsize=c(W,H), zoom=ZOOM, water=FALSE)
  Sys.sleep(0.2)
  render_camera(theta=THETA, phi=PHI, zoom=ZOOM, fov=0)
  render_snapshot(sprintf("%s/f_%03d.png", OUT, i-1), clear=FALSE)
  rgl::clear3d()
}
rgl::close3d()
cat("done:", length(idx), "drape frame(s)  scale", SMIN, "..", SMAX, "\n")
