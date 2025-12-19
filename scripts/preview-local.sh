#!/bin/bash

set -e

# Configuration
MAIN_REPO_DIR="../maplibre-gl-js"
PREVIEW_DIR="staging/previews"

mkdir -p "$PREVIEW_DIR"

echo "=========================================="
echo "  MapLibre Branch Preview - Sync Tool"
echo "=========================================="

# 1. Detect Branch from Sibling Directory (Worktree Mode)
if [ -d "$MAIN_REPO_DIR" ]; then
    echo "Detecting branch from: $MAIN_REPO_DIR"
    CURRENT_BRANCH=$(cd "$MAIN_REPO_DIR" && git rev-parse --abbrev-ref HEAD)
    SOURCE_DIST="$MAIN_REPO_DIR/dist"
else
    echo "Working in standalone mode (no sibling maplibre-gl-js found)"
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    SOURCE_DIST="dist"
fi

CLEAN_NAME=$(echo "$CURRENT_BRANCH" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]')

echo "Target Branch: $CURRENT_BRANCH (sanitized: $CLEAN_NAME)"

# 2. Check for build in source directory
if [ ! -d "$SOURCE_DIST" ] || [ ! -f "$SOURCE_DIST/maplibre-gl-dev.js" ]; then
    echo "❌ Error: Could not find build in $SOURCE_DIST"
    echo "   Please run 'npm run build-dev' in $MAIN_REPO_DIR first."
    exit 1
fi

# 3. Copy to preview directory
echo "Copying assets to $PREVIEW_DIR/$CLEAN_NAME/dist/..."
mkdir -p "$PREVIEW_DIR/$CLEAN_NAME/dist"
cp -r "$SOURCE_DIST"/* "$PREVIEW_DIR/$CLEAN_NAME/dist/"

# 4. Fetch index.html if missing
if [ ! -f "$PREVIEW_DIR/index.html" ]; then
    echo "Fetching Master Tester from gh-pages..."
    if git show gh-pages:index.html > "$PREVIEW_DIR/index.html" 2>/dev/null; then
        echo "✓ Master Tester fetched"
    else
        # If git show fails, try to copy it from our own checkout if it exists
        if [ -f "index.html" ]; then
            cp index.html "$PREVIEW_DIR/index.html"
            echo "✓ Master Tester copied from local"
        else
            echo "⚠ Warning: Could not find index.html. The previewer UI will be missing."
        fi
    fi
fi

# 5. Update branches.json
BRANCHES_FILE="$PREVIEW_DIR/branches.json"
[ ! -f "$BRANCHES_FILE" ] && echo "[]" > "$BRANCHES_FILE"

node -e "
const fs = require('fs');
const file = '$BRANCHES_FILE';
let branches = [];
try { branches = JSON.parse(fs.readFileSync(file, 'utf8')); } catch(e) {}
if (!branches.includes('$CLEAN_NAME')) {
    branches.push('$CLEAN_NAME');
    fs.writeFileSync(file, JSON.stringify(branches, null, 2));
    console.log('✓ Added $CLEAN_NAME to registry');
} else {
    console.log('✓ $CLEAN_NAME already in registry');
}
"

echo "=========================================="
echo "SUCCESS!"
echo "Preview ready for: $CLEAN_NAME"
echo ""
echo "To view: npm run preview-local"
echo "Then open: http://localhost:9966"
echo "=========================================="
