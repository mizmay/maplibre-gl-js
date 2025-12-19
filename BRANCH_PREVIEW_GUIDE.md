# Branch Preview System - Quick Start Guide

A simple system for testing and comparing MapLibre GL JS implementations across different branches.

## Table of Contents
1. [Overview](#overview)
2. [Local Testing](#local-testing)
3. [Remote Deployment](#remote-deployment)
4. [Comparing Branches](#comparing-branches)
5. [Troubleshooting](#troubleshooting)

---

## Overview

This system lets you:
- Test your changes locally before pushing
- Deploy branch previews to GitHub Pages
- Compare different implementations side-by-side with synchronized cameras

**Key principle**: Your feature branches stay clean - all infrastructure lives in `preview-infra` and `gh-pages` branches.

---

## Local Testing

### Quick Start (One Command)
```bash
npm run preview
```

This will:
1. Build your current branch
2. Deploy it to `staging/previews/`
3. Start a local server at `http://localhost:9966`

### Step-by-Step

If you prefer more control:

```bash
# 1. Build assets for current branch
npm run preview-build

# 2. Deploy to local preview folder
npm run preview-deploy

# 3. Start preview server
npm run preview-local
```

Open `http://localhost:9966` in your browser.

---

## Remote Deployment

Deploy your branch to GitHub Pages so others can test it.

### Prerequisites
1. Push your branch to your fork:
   ```bash
   git push fork your-branch-name
   ```

2. Ensure GitHub Pages is enabled:
   - Go to your fork's **Settings** → **Pages**
   - Source: **Deploy from a branch**
   - Branch: **gh-pages** / **/ (root)**

### Deploy

1. Go to your fork on GitHub
2. Click **Actions** tab
3. Select **"Deploy Branch Preview"** workflow
4. Click **"Run workflow"**
5. Enter your branch name
6. Click **"Run workflow"** button

Wait 2-3 minutes for the build to complete.

### Access

Visit: `https://[your-username].github.io/maplibre-gl-js/?branch=your-branch-name`

Your branch will also appear in the dropdown menu at the base URL.

---

## Comparing Branches

Compare your implementation against `main` or other branches side-by-side.

### Local Comparison

1. **Build main branch:**
   ```bash
   git checkout main
   npm run preview-build
   npm run preview-deploy
   ```

2. **Build your feature branch:**
   ```bash
   git checkout your-feature-branch
   npm run preview-build
   npm run preview-deploy
   ```

3. **Start the previewer:**
   ```bash
   npm run preview-local
   ```

4. **View comparison:**
   - Open `http://localhost:9966`
   - Check both branches in the dropdown
   - Click **"Update View"**
   - Both maps will render side-by-side with synchronized cameras

### Remote Comparison

1. Deploy both branches using the GitHub Action
2. Visit `https://[your-username].github.io/maplibre-gl-js/`
3. Select both branches in the dropdown
4. Click **"Update View"**

---

## Troubleshooting

### Problem: `npm run preview` fails with "dist/ not found"

**Solution**: The build step failed. Run separately to see the error:
```bash
npm run preview-build
```

### Problem: Blank page at `localhost:9966`

**Cause**: The Master Tester (`index.html`) is missing from `staging/previews/`.

**Solution**:
```bash
# Fetch it from gh-pages branch
git show gh-pages:index.html > staging/previews/index.html

# Or re-run the deploy script
npm run preview-deploy
```

### Problem: Branch doesn't appear in dropdown (locally)

**Cause**: The branch wasn't added to `staging/previews/branches.json`.

**Solution**: Re-run `npm run preview-deploy` on that branch.

### Problem: Branch doesn't appear in dropdown (remotely)

**Cause**: The GitHub Action hasn't run yet, or the branch name doesn't match.

**Solution**:
1. Check the Actions tab for workflow status
2. Ensure the branch name you entered matches exactly
3. Hard refresh the page (Cmd+Shift+R / Ctrl+Shift+R)

### Problem: "Failed to load resource: 404" in console

**Cause**: Assets for that branch haven't been built/deployed.

**Solution**:
- Locally: Run `npm run preview-build && npm run preview-deploy`
- Remotely: Run the "Deploy Branch Preview" action for that branch

### Problem: Changes not showing up

**Solution**: Rebuild and redeploy:
```bash
npm run preview-build
npm run preview-deploy
```

---

## Architecture

```
Repository Structure:
├── Feature Branches (your work)
│   └── Clean MapLibre code only
│
├── preview-infra (infrastructure)
│   ├── .github/workflows/deploy-preview.yml
│   ├── scripts/preview-local.sh
│   ├── package.json (with preview commands)
│   └── BRANCH_PREVIEW_GUIDE.md (this file)
│
├── gh-pages (deployment)
│   ├── index.html (Master Tester UI)
│   ├── branches.json (registry)
│   └── [branch-name]/dist/ (built assets)
│
└── staging/previews/ (local only, gitignored)
    ├── index.html
    ├── branches.json
    └── [branch-name]/dist/
```

---

## Summary

**Local workflow:**
```bash
npm run preview
```

**Remote workflow:**
1. `git push fork your-branch`
2. GitHub Actions → Deploy Branch Preview → your-branch

**Comparison:**
- Build multiple branches locally with `npm run preview-build && npm run preview-deploy`
- View at `localhost:9966`, select multiple branches, click "Update View"

**Your feature branch stays clean** ✓
