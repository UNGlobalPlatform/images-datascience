#!/bin/bash
set -e

echo "=========================================="
echo "Earth Observation Statistics Session Init"
echo "=========================================="

# Environment variables (set by Helm chart)
REPO_URL=${REPO_URL:-"https://github.com/FAO-EOSTAT/UN-Handbook.git"}
REPO_BRANCH=${REPO_BRANCH:-"main"}
CHAPTER_NAME=${CHAPTER_NAME:-"example"}

cd /home/jovyan

# Clone repository
echo "📚 Cloning repository: $REPO_URL"
if [ -d "work" ]; then
  echo "⚠️  Work directory already exists, skipping clone"
else
  git clone --depth 1 --branch $REPO_BRANCH $REPO_URL work
  cd work

  # Create convenience symlinks
  if [ -d "data/$CHAPTER_NAME" ]; then
    echo "📦 Linking chapter data: $CHAPTER_NAME"
    ln -sf data/$CHAPTER_NAME /home/jovyan/chapter-data
  fi

  if [ -f "${CHAPTER_NAME}.qmd" ]; then
    echo "📄 Linking chapter file: ${CHAPTER_NAME}.qmd"
    ln -sf ${CHAPTER_NAME}.qmd /home/jovyan/chapter.qmd
  fi

  cd /home/jovyan
fi

echo "✓ Initialization complete!"
echo "=========================================="
echo "Repository: $REPO_URL"
echo "Branch: $REPO_BRANCH"
echo "Chapter: $CHAPTER_NAME"
echo "Ready to use!"
echo "=========================================="
