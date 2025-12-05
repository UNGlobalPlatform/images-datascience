#!/bin/bash
set -e

echo "=========================================="
echo "Earth Observation Statistics Session Init"
echo "=========================================="

export RENV_CONFIG_AUTOLOADER_ENABLED=FALSE

# S3-cached R packages optimization
# Mount point configured via Helm: /mnt/eostat-cache
EOSTAT_CACHE_MOUNT=${EOSTAT_CACHE_MOUNT:-"/mnt/eostat-cache"}
R_CACHE_DIR="${EOSTAT_CACHE_MOUNT}/r-packages"

if [ -d "$R_CACHE_DIR" ] && [ -d "$R_CACHE_DIR/sitsdata" ]; then
  echo "Using S3-cached R packages from $R_CACHE_DIR"

  # Add S3 cache to R library path (checked first)
  export R_LIBS_SITE="${R_CACHE_DIR}:${R_LIBS_SITE:-/usr/local/lib/R/site-library}"

  # Persist for RStudio sessions
  echo "R_LIBS_SITE=${R_LIBS_SITE}" >> /usr/local/lib/R/etc/Renviron.site 2>/dev/null || true

  # Symlink torch backend if available
  TORCH_CACHE="${EOSTAT_CACHE_MOUNT}/r-packages/torch-backend"
  if [ -d "$TORCH_CACHE" ] && [ ! -d "${HOME}/.local/share/torch" ]; then
    mkdir -p "${HOME}/.local/share"
    ln -sf "$TORCH_CACHE" "${HOME}/.local/share/torch"
    echo "Linked torch backend from S3 cache"
  fi
else
  echo "S3 cache not available, using packages from Docker image"
fi

# Environment variables (set by Helm chart)
REPO_URL=${REPO_URL:-"https://github.com/FAO-EOSTAT/UN-Handbook.git"}
REPO_BRANCH=${REPO_BRANCH:-"main"}
CHAPTER_NAME=${CHAPTER_NAME:-"example"}

cd /home/onyxia

# Clone repository
echo "Cloning repository: $REPO_URL"
if [ -d "work" ]; then
  echo "Work directory already exists, skipping clone"
else
  git clone --depth 1 --branch $REPO_BRANCH $REPO_URL work
  cd work

    # This prevents .Rprofile from activating renv
  if [ -f ".Rprofile" ]; then
    echo "Disabling renv auto-activation..."
    mv .Rprofile .Rprofile.disabled
  fi

  # Create convenience symlinks
  if [ -d "data/$CHAPTER_NAME" ]; then
    echo "Linking chapter data: $CHAPTER_NAME"
    ln -sf data/$CHAPTER_NAME /home/onyxia/chapter-data
  fi

  if [ -f "${CHAPTER_NAME}.qmd" ]; then
    echo "Linking chapter file: ${CHAPTER_NAME}.qmd"
    ln -sf ${CHAPTER_NAME}.qmd /home/onyxia/chapter.qmd
  fi

  cd /home/onyxia
fi

echo "Initialization complete!"
echo "=========================================="
echo "Repository: $REPO_URL"
echo "Branch: $REPO_BRANCH"
echo "Chapter: $CHAPTER_NAME"
echo "Ready to use!"
echo "=========================================="
