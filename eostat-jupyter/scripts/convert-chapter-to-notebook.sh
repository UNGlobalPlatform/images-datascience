#!/bin/bash
# Set up UN Handbook chapter environment
# Runs after git clone via init.personalInit

set -e

CHAPTER_NAME=${CHAPTER_NAME:-""}
WORK_DIR=${ROOT_PROJECT_DIRECTORY:-"/home/onyxia/work"}

echo "=========================================="
echo "Setting Up UN Handbook Chapter Environment"
echo "=========================================="

if [ -z "$CHAPTER_NAME" ]; then
  echo "⚠️  No CHAPTER_NAME specified, skipping setup"
  exit 0
fi

cd "$WORK_DIR"

# Check if UN-Handbook exists
if [ ! -d "UN-Handbook" ]; then
  echo "⚠️  UN-Handbook directory not found"
  exit 0
fi

# Check if chapter file exists
if [ ! -f "UN-Handbook/${CHAPTER_NAME}.qmd" ]; then
  echo "⚠️  Chapter file not found: UN-Handbook/${CHAPTER_NAME}.qmd"
  echo "Available .qmd files:"
  find UN-Handbook -name "*.qmd" -type f | head -10
  exit 0
fi

echo "📄 Found chapter: UN-Handbook/${CHAPTER_NAME}.qmd"

# Create a welcome README in work directory (PERSISTENT!)
cat > "${WORK_DIR}/README.md" << EOF
# UN Handbook - ${CHAPTER_NAME}

## Quick Start

### Open the Chapter (Recommended) ⭐
1. Navigate to: \`UN-Handbook/${CHAPTER_NAME}.qmd\`
2. Double-click to open in JupyterLab
3. The Quarto extension provides native .qmd editing with:
   - Syntax highlighting
   - Cell-by-cell execution
   - Visual editor mode

### Alternative: Access Data Directly
- \`data/\` - Symlink to chapter data
- \`UN-Handbook/\` - Full repository

## Files in Your Work Directory (~/work/) - PERSISTENT
- \`README.md\` - This file
- \`data/\` - Chapter data symlink
- \`UN-Handbook/\` - Full repository clone
  - \`${CHAPTER_NAME}.qmd\` - Your chapter (open this!) ⭐

## Running Code
All R packages are pre-installed:
\`\`\`r
library(sits)
library(terra)
library(sf)
\`\`\`

## Tips
- Work directly with .qmd files (no conversion needed!)
- Use Ctrl+Enter or Cmd+Enter to run cells
- Changes are saved automatically
- Your work directory (~/work/) is persistent across sessions

Happy analyzing! 🚀
EOF

echo "✓ Created README.md with instructions"

# Create symlink to chapter data in work directory (PERSISTENT!)
if [ -d "UN-Handbook/data/${CHAPTER_NAME}" ]; then
  ln -sf "${WORK_DIR}/UN-Handbook/data/${CHAPTER_NAME}" "${WORK_DIR}/data"
  echo "✓ Created symlink: ~/work/data -> chapter data"
else
  echo "⚠️  Chapter data directory not found: UN-Handbook/data/${CHAPTER_NAME}"
fi

echo "=========================================="
echo "Setup complete!"
echo "Files in work directory (PERSISTENT):"
ls -la "${WORK_DIR}/" | grep -E "README|data|UN-Handbook" || echo "No matching files found"
echo "=========================================="
echo ""
echo "📖 To get started: Open UN-Handbook/${CHAPTER_NAME}.qmd in JupyterLab"
echo ""
