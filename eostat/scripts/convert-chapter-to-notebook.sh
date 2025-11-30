#!/bin/bash
# Convert specified UN Handbook chapter to Jupyter notebook
# Runs after git clone via init.personalInit

set -e

CHAPTER_NAME=${CHAPTER_NAME:-""}
WORK_DIR=${ROOT_PROJECT_DIRECTORY:-"/home/jovyan/work"}

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
echo "📝 Converting to Jupyter notebook..."

# Convert to notebook format
quarto convert "$CHAPTER_FILE" --output "${CHAPTER_NAME}.ipynb"

if [ -f "${CHAPTER_NAME}.ipynb" ]; then
  echo "✓ Created: ${CHAPTER_NAME}.ipynb"

  # Create a copy in the parent directory for easy access
  cp "${CHAPTER_NAME}.ipynb" "../${CHAPTER_NAME}.ipynb" 2>/dev/null || true

  # Create a welcome README
  cat > ../README.md << EOF
# UN Handbook - ${CHAPTER_NAME}

## Quick Start

### Option 1: Open Converted Notebook
- Open \`${CHAPTER_NAME}.ipynb\` (ready to run!)

### Option 2: Work with Full Repository
- Navigate to \`UN-Handbook/\` folder
- Open \`${CHAPTER_NAME}.qmd\` (original source)

## Files
- \`${CHAPTER_NAME}.ipynb\` - Converted Jupyter notebook (this directory)
- \`UN-Handbook/${CHAPTER_NAME}.qmd\` - Original Quarto source
- \`UN-Handbook/data/${CHAPTER_NAME}/\` - Chapter data

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
else
  echo "⚠️  Conversion failed, notebook not created"
fi

echo "=========================================="
echo "Conversion complete!"
echo "=========================================="
