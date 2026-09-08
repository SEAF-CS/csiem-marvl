.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages(library(rayshader))
f <- tryCatch(rayshader:::convert_rgl_to_raymesh, error=function(e) NULL)
if(!is.null(f)) writeLines(deparse(f), "conv_src.txt") else cat("not found\n")
