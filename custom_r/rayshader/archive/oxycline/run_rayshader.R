# Runner for the rayshader scripts using the ISOLATED private library.
# Usage:  Rscript run_rayshader.R <script.R> [working_dir]
# - Prepends the private lib so rayshader/sf/rgl/magick load from there,
#   while sp/raster/terra/ggplot2 are reused from the global lib (read-only).
# - Drops the (archived, unused) rgdal dependency by stubbing library(rgdal).
.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))

args <- commandArgs(trailingOnly = TRUE)
script  <- if (length(args) >= 1) args[[1]] else stop("give a script path")
workdir <- if (length(args) >= 2) args[[2]] else dirname(normalizePath(script))
setwd(workdir)
cat("libPaths[1]:", .libPaths()[1], "\n")
cat("workdir    :", getwd(), "\n")
cat("script     :", normalizePath(script), "\n\n")

# rgdal was retired from CRAN (Oct 2023) and is only library()-loaded, never called,
# in these scripts -> make library(rgdal) a no-op so old scripts run unchanged.
local({
  base_library <- base::library
  assign("library", function(package, ...) {
    pkg <- tryCatch(as.character(substitute(package)), error = function(e) as.character(package))
    if (identical(pkg, "rgdal")) { message("[run_rayshader] skipping retired 'rgdal' (unused)"); return(invisible()) }
    base_library(pkg, character.only = TRUE, ...)
  }, envir = globalenv())
})

# rgl::rgl.close() is now defunct (rgl >= 1.x) -> alias it to close3d so old scripts
# don't error on the final cleanup line.
try({
  rgl_ns <- asNamespace("rgl")
  if (exists("close3d", rgl_ns)) assignInNamespace("rgl.close", get("close3d", rgl_ns), "rgl")
}, silent = TRUE)

source(script, echo = TRUE, max.deparse.length = Inf)
cat("\n[run_rayshader] done\n")
