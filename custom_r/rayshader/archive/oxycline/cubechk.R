.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages(library(rayrender))
cat("cube exists:", exists("cube", where=asNamespace("rayrender")), "\n")
print(names(formals(rayrender::cube)))
cat("\ndielectric attenuation_intensity default:",
    deparse(formals(rayrender::dielectric)$attenuation_intensity), "\n")
