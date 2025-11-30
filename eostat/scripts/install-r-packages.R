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

cat("✓ R package installation complete\n")
