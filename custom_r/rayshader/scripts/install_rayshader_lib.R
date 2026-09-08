# Isolated rayshader install — writes ONLY to the private lib below.
# Global/user libraries are kept on the path for REUSE (read-only), never modified.
libdir <- "G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4"
dir.create(libdir, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(libdir, .libPaths()))            # private first (install target + reuse globals)
options(repos = c(CRAN = "https://cloud.r-project.org"))

cat("Install target lib:", libdir, "\n")
cat(".libPaths():\n"); print(.libPaths())

want <- c("rayshader", "sf", "rgl", "magick", "MetBrewer")
have <- rownames(installed.packages())
need <- setdiff(want, have)
cat("\nTop-level packages still needed:", paste(need, collapse=", "), "\n\n")

if (length(need)) {
  # runtime deps only (Depends/Imports/LinkingTo) - skip the huge Suggests trees
  install.packages(need, lib = libdir, type = "binary",
                   dependencies = c("Depends", "Imports", "LinkingTo"))
}

cat("\n=== verification (load test) ===\n")
ok <- TRUE
for (p in want) {
  v <- tryCatch({ suppressWarnings(suppressMessages(library(p, character.only = TRUE, lib.loc = .libPaths())))
                  as.character(packageVersion(p)) },
                error = function(e) { ok <<- FALSE; paste("FAILED:", conditionMessage(e)) })
  cat(sprintf("%-12s %s\n", p, v))
}
cat(if (ok) "\nALL OK\n" else "\nSOME FAILED\n")
