#!/usr/bin/env Rscript

# Test that all R packages needed by UN-Handbook are installed
# Generated from actual library() calls in UN-Handbook/*.qmd

cat("Testing UN-Handbook R package dependencies...\n\n")

required_packages <- c(
  # Most critical (high usage)
  "sits",         # 12 uses - PRIMARY PACKAGE
  "sitsdata",     # 7 uses
  "sf",           # Multiple uses
  "terra",        # Multiple uses

  # Geospatial
  "stars",
  "tmap",

  # STAC and cloud data
  "rstac",
  "earthdatalogin",
  "arrow",

  # Tidyverse (should be in base)
  "tidyverse",
  "tibble",
  "dplyr",
  "tidyr",
  "ggplot2",

  # Machine learning
  "torch",
  "luz",
  "caret",
  "randomForestExplainer",
  "FNN",
  "kohonen",

  # Utilities
  "knitr",
  "kableExtra",
  "xml2",
  "reticulate",
  "downlit",
  "reshape2"
)

cat(sprintf("Checking %d packages...\n\n", length(required_packages)))

installed <- installed.packages()[, "Package"]
missing <- character(0)
found <- character(0)

for (pkg in required_packages) {
  if (pkg %in% installed) {
    cat(sprintf("✓ %s\n", pkg))
    found <- c(found, pkg)
  } else {
    cat(sprintf("✗ MISSING: %s\n", pkg))
    missing <- c(missing, pkg)
  }
}

cat("\n========================================\n")
cat(sprintf("Results: %d/%d packages available\n",
            length(found), length(required_packages)))

if (length(missing) > 0) {
  cat("\nMissing packages:\n")
  cat(paste0("  - ", missing, collapse = "\n"), "\n")
  cat("\nAdd these to requirements-r.txt\n")
  quit(status = 1)
} else {
  cat("\n✓ All UN-Handbook dependencies satisfied!\n")
  quit(status = 0)
}
