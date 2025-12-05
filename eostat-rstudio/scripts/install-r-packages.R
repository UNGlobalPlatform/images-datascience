#!/usr/bin/env Rscript

# Install R packages for Earth Observation Statistics
# Reads package list from /tmp/requirements-r.txt

cat("Installing R packages for Earth Observation Statistics...\n")

# Use Posit Package Manager with binary support for much faster builds
# Ubuntu 24.04 (Noble) binaries
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))

# Configure HTTP user agent for binary package detection
options(HTTPUserAgent = sprintf(
  "R/%s R (%s)",
  getRversion(),
  paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
))

# Read package list
packages <- readLines("/tmp/requirements-r.txt")

# Remove comments and empty lines
packages <- packages[!grepl("^#", packages) & nchar(trimws(packages)) > 0]

# Trim whitespace
packages <- trimws(packages)

cat(sprintf("Installing %d packages: %s\n",
            length(packages),
            paste(packages, collapse=", ")))

# Install packages with dependencies
for (pkg in packages) {
  cat(sprintf("Installing %s...\n", pkg))
  tryCatch({
    install.packages(pkg, dependencies = TRUE, quiet = FALSE)
    cat(sprintf("✓ %s installed successfully\n", pkg))
  }, error = function(e) {
    cat(sprintf("✗ Failed to install %s: %s\n", pkg, e$message))
  })
}

# Install torch backend (LibTorch C++ library)
cat("\nInstalling torch backend...\n")
tryCatch({
  if (require("torch", quietly = TRUE)) {
    torch::install_torch()
    cat("✓ torch backend installed successfully\n")
  } else {
    cat("⚠ torch package not available, skipping backend installation\n")
  }
}, error = function(e) {
  cat(sprintf("✗ Failed to install torch backend: %s\n", e$message))
})

# Install GitHub-only packages
cat("\nInstalling GitHub-only packages...\n")

# Install remotes if not available
if (!require("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# sitsdata - example datasets for sits package (large download, needs extended timeout)
tryCatch({
  cat("Installing sitsdata from GitHub...\n")
  options(timeout = 1200)  # 20 minutes for large data package
  remotes::install_github("e-sensing/sitsdata", quiet = FALSE, upgrade = "never")
  cat("✓ sitsdata installed successfully\n")
}, error = function(e) {
  cat(sprintf("✗ Failed to install sitsdata: %s\n", e$message))
})

cat("\n✓ R package installation complete\n")
