.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))
suppressMessages(library(rayshader))
fm <- formals(rayshader:::render_highquality)
for (n in c("samples","sample_method","min_variance","light","lightdirection",
            "lightaltitude","lightsize","lightintensity","lightcolor","clamp_value",
            "ground_material","ground_size"))
  cat(sprintf("%-16s = %s\n", n, paste(deparse(fm[[n]]), collapse="")))
