#!/bin/bash

# Exit on error
set -e

PREVIEW_DIR="local-previews"
mkdir -p "$PREVIEW_DIR"

echo "------------------------------------------------"
echo "  MapLibre Branch Preview - Local Deployer"
echo "------------------------------------------------"

# Function to build a branch
build_branch() {
    local branch=$1
    local clean=$2
    echo ">>> Building assets for branch: $branch (target: $clean)..."
    
    # Store current branch to return later
    local current=$(git rev-parse --abbrev-ref HEAD)
    
    if [ "$branch" != "$current" ]; then
        echo "Stashing changes and switching to $branch..."
        git stash push -m "Auto-stash for local preview build"
        git checkout "$branch"
    fi

    # Build process
    npm run build-dev
    npm run build-css

    mkdir -p "$PREVIEW_DIR/$clean/dist"
    cp -r dist/* "$PREVIEW_DIR/$clean/dist/"

    # Return to original branch if needed
    if [ "$branch" != "$current" ]; then
        git checkout "$current"
        git stash pop || echo "No stash to pop or conflict occurred."
    fi
}

# 1. Check for index.html (Master Tester)
if [ ! -f "$PREVIEW_DIR/index.html" ]; then
    echo "(!) Master Tester index.html missing in $PREVIEW_DIR."
    echo "Attempting to fetch from gh-pages branch..."
    git show gh-pages:index.html > "$PREVIEW_DIR/index.html" || {
        echo "Error: Could not find index.html on gh-pages branch."
        echo "Please ensure you have run the infrastructure setup or have a local gh-pages branch."
        exit 1
    }
fi

# 2. Check for main branch build (baseline)
if [ ! -d "$PREVIEW_DIR/main/dist" ]; then
    echo "(!) baseline 'main' build missing."
    read -p "Would you like to build 'main' as a baseline now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        build_branch "main" "main"
        
        # Add to registry
        node -e "
            const fs = require('fs');
            const file = '$PREVIEW_DIR/branches.json';
            let b = []; try { b = JSON.parse(fs.readFileSync(file)); } catch(e) {}
            if (!b.includes('main')) { b.push('main'); fs.writeFileSync(file, JSON.stringify(b, null, 2)); }
        "
    fi
fi

# 3. Build current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CLEAN_NAME=$(echo "$CURRENT_BRANCH" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]')

build_branch "$CURRENT_BRANCH" "$CLEAN_NAME"

# 4. Update registry
BRANCHES_FILE="$PREVIEW_DIR/branches.json"
[ ! -f "$BRANCHES_FILE" ] && echo "[]" > "$BRANCHES_FILE"

node -e "
    const fs = require('fs');
    const file = '$BRANCHES_FILE';
    let b = []; try { b = JSON.parse(fs.readFileSync(file)); } catch(e) {}
    if (!b.includes('$CLEAN_NAME')) { 
        b.push('$CLEAN_NAME'); 
        fs.writeFileSync(file, JSON.stringify(b, null, 2));
        console.log('>>> Added $CLEAN_NAME to local registry.');
    }
"

echo "------------------------------------------------"
echo "SUCCESS: Branch '$CURRENT_BRANCH' is ready."
echo "Local Registry: $(cat $BRANCHES_FILE)"
echo "------------------------------------------------"

# 5. Auto-start option
read -p "Start the local preview server now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting server at http://localhost:9966 ..."
    npm run preview-local
fi
