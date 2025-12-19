#!/bin/bash

set -e

PREVIEW_DIR="staging/previews"
mkdir -p "$PREVIEW_DIR"

echo "=========================================="
echo "  MapLibre Branch Preview - Local Setup"
echo "=========================================="

# Get current branch name and sanitize
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CLEAN_NAME=$(echo "$CURRENT_BRANCH" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]')

echo "Branch: $CURRENT_BRANCH (sanitized: $CLEAN_NAME)"

# 1. Check/build dist
if [ ! -d "dist" ] || [ ! -f "dist/maplibre-gl-dev.js" ]; then
    echo "Building assets..."
    npm run build-dev
    npm run build-css
else
    echo "Using existing dist/ (run 'npm run build-dev' to rebuild)"
fi

# 2. Copy to preview directory
echo "Deploying to $PREVIEW_DIR/$CLEAN_NAME/dist/..."
mkdir -p "$PREVIEW_DIR/$CLEAN_NAME/dist"
cp -r dist/* "$PREVIEW_DIR/$CLEAN_NAME/dist/"

# 3. Fetch index.html if missing
if [ ! -f "$PREVIEW_DIR/index.html" ]; then
    echo "Fetching Master Tester from gh-pages..."
    if git show gh-pages:index.html > "$PREVIEW_DIR/index.html" 2>/dev/null; then
        echo "✓ Master Tester fetched"
    else
        echo "⚠ Could not fetch index.html from gh-pages branch"
        echo "  The previewer will not work without it."
        echo "  Make sure you have a local gh-pages branch with index.html"
    fi
fi

# 4. Update branches.json
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
    console.log('✓ Added $CLEAN_NAME to local registry');
} else {
    console.log('✓ $CLEAN_NAME already in registry');
}
"

echo "=========================================="
echo "SUCCESS!"
echo "Preview ready at: staging/previews/$CLEAN_NAME/"
echo ""
echo "To view: npm run preview-local"
echo "Then open: http://localhost:9966"
echo "=========================================="

