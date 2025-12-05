#!/bin/bash
set -e

echo "=========================================="
echo "Earth Observation Statistics Session Init"
echo "=========================================="

export RENV_CONFIG_AUTOLOADER_ENABLED=FALSE

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
