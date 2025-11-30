#!/bin/bash
# Convert specified UN Handbook chapter to Jupyter notebook
# Runs after git clone via init.personalInit

set -e

CHAPTER_NAME=${CHAPTER_NAME:-""}
WORK_DIR=${ROOT_PROJECT_DIRECTORY:-"/home/onyxia/work"}
HOME_DIR=${HOME:-"/home/onyxia"}

echo "=========================================="
echo "Converting Chapter to Jupyter Notebook"
echo "=========================================="

if [ -z "$CHAPTER_NAME" ]; then
  echo "⚠️  No CHAPTER_NAME specified, skipping conversion"
  exit 0
fi

cd "$WORK_DIR"

# Check if we're in the UN-Handbook repo or if it's in a subdirectory
if [ -f "${CHAPTER_NAME}.qmd" ]; then
  CHAPTER_FILE="${CHAPTER_NAME}.qmd"
elif [ -f "UN-Handbook/${CHAPTER_NAME}.qmd" ]; then
  cd UN-Handbook
  CHAPTER_FILE="${CHAPTER_NAME}.qmd"
else
  echo "⚠️  Chapter file not found: ${CHAPTER_NAME}.qmd"
  echo "Available .qmd files:"
  find . -name "*.qmd" -type f | head -10
  exit 0
fi

echo "📄 Found chapter: $CHAPTER_FILE"
echo "📝 Converting to Jupyter notebook (preserving cells)..."

# Use quarto convert (works outside book context, preserves cell structure)
quarto convert "$CHAPTER_FILE"

if [ -f "${CHAPTER_NAME}.ipynb" ]; then
  echo "✓ Created: ${CHAPTER_NAME}.ipynb"

  # Copy to home directory for immediate visibility
  cp "${CHAPTER_NAME}.ipynb" "${HOME_DIR}/${CHAPTER_NAME}.ipynb"
  echo "✓ Copied to: ${HOME_DIR}/${CHAPTER_NAME}.ipynb"

  # Create a welcome README in home directory
  cat > "${HOME_DIR}/README.md" << EOF
# UN Handbook - ${CHAPTER_NAME}

## Quick Start

### Open the Notebook (Recommended)
- Click \`${CHAPTER_NAME}.ipynb\` in the file browser
- Ready to run immediately!

### Access Original Files
- Navigate to \`work/UN-Handbook/\` folder
- Original source: \`work/UN-Handbook/${CHAPTER_NAME}.qmd\`
- Chapter data: \`work/UN-Handbook/data/${CHAPTER_NAME}/\`

## Files in Your Home Directory (~/)
- \`${CHAPTER_NAME}.ipynb\` - Converted Jupyter notebook ⭐
- \`README.md\` - This file
- \`work/UN-Handbook/\` - Full repository clone

## Running Code
All R packages are pre-installed:
\`\`\`r
library(sits)
library(terra)
library(sf)
\`\`\`

Happy analyzing! 🚀
EOF

  echo "✓ Created README.md with instructions"

  # Create symlink to chapter data in home directory
  if [ -d "data/${CHAPTER_NAME}" ]; then
    ln -sf "${WORK_DIR}/UN-Handbook/data/${CHAPTER_NAME}" "${HOME_DIR}/data"
    echo "✓ Created symlink: ~/data -> chapter data"
  fi
else
  echo "⚠️  Conversion failed, notebook not created"
fi

echo "=========================================="
echo "Conversion complete!"
echo "Files in home directory:"
ls -la "${HOME_DIR}/" | grep -E "README|${CHAPTER_NAME}|data"
echo "=========================================="
