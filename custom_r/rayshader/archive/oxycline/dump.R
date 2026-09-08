.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages(library(rayshader))
writeLines(deparse(rayshader:::render_highquality), "rhq_src.txt")
