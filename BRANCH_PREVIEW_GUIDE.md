# Branch Preview Deployment System - Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [How the Workflow Triggering Works](#how-the-workflow-triggering-works)
4. [One-Time Setup Instructions](#one-time-setup-instructions)
5. [Daily Usage: Testing a Feature Branch](#daily-usage-testing-a-feature-branch)
6. [Security Features](#security-features)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This system allows you to test different MapLibre GL JS implementations (zoom behavior, controls, etc.) across multiple branches without adding any testing infrastructure code to your feature branches.

**Key Design Principle**: Your feature branches remain completely clean - they contain only the code changes you intend to contribute to MapLibre. All testing infrastructure lives in dedicated branches.

---

## System Architecture

The system uses three separate branches with distinct purposes:

```
Repository Structure:
├── Feature Branches (e.g., align-button-keyboard-zoom)
│   └── Contains ONLY your MapLibre code changes
│
├── preview-infra (Infrastructure Branch)
│   └── .github/workflows/manual-deploy.yml
│       └── Workflow that builds and deploys branches
│
└── gh-pages (Deployment Branch)
    ├── index.html (Master Tester - UI for testing)
    ├── branches.json (Registry of available builds)
    ├── main/
    │   └── dist/ (Built assets from main branch)
    ├── align-button-keyboard-zoom/
    │   └── dist/ (Built assets from feature branch)
    └── [other-branches]/
        └── dist/ (Built assets from other branches)
```

**Data Flow**:
1. You manually trigger the workflow from GitHub Actions UI
2. Workflow checks out the branch you specified
3. Builds the MapLibre assets (dist/)
4. Deploys to gh-pages under a branch-specific folder
5. Updates branches.json to register the new build
6. The index.html page loads assets dynamically based on URL parameter

---

## How the Workflow Triggering Works

### Important: This is NOT Automatic

The workflow in `preview-infra` branch uses `workflow_dispatch`, which means:

- **It does NOT automatically trigger on push**
- **It does NOT monitor any branches**
- **You must manually run it via GitHub's UI**

### Why Manual Triggering?

1. **Clean Feature Branches**: The workflow file doesn't exist in your feature branches, keeping them pristine
2. **Control**: You decide when to build a preview, avoiding unnecessary CI runs
3. **Flexibility**: You can build previews from any branch, even if you're not currently working on it

### The Trigger Mechanism

In `.github/workflows/manual-deploy.yml` (located in `preview-infra` branch):

```yaml
on:
  workflow_dispatch:
    inputs:
      branch_name:
        description: 'The branch name to build and deploy'
        required: true
        default: 'main'
```

This configuration creates a form in GitHub Actions where you enter the branch name as input.

---

## One-Time Setup Instructions

### Step 1: Enable GitHub Pages

1. Navigate to your fork on GitHub: `https://github.com/mizmay/maplibre-gl-js`
2. Go to **Settings** → **Pages** (in the left sidebar under "Code and automation")
3. Under **Build and deployment**:
   - Source: Select **"Deploy from a branch"**
   - Branch: Select **`gh-pages`** and **`/ (root)`**
   - Click **Save**

**Note**: If `gh-pages` doesn't appear in the dropdown yet, that's okay - it will be created when you first deploy.

### Step 2: Push the Infrastructure Branches

You need to push two branches to your fork:

```bash
# Push the workflow infrastructure
git push fork preview-infra

# Push the Master Tester page
git push fork gh-pages
```

**Verification**: After pushing, check:
- Go to **Actions** tab on GitHub
- You should see a workflow called "Manual Branch Preview Deploy"
- Go to the **Code** tab, switch to `gh-pages` branch
- You should see `index.html` at the root

### Step 3: Verify GitHub Actions Permissions

1. Go to **Settings** → **Actions** → **General**
2. Scroll to **Workflow permissions**
3. Ensure **"Read and write permissions"** is selected
4. Click **Save** if you made changes

---

## Daily Usage: Testing a Feature Branch

### Scenario: You want to test your feature branch online

Let's say you're working on a branch called `align-button-keyboard-zoom` and want to deploy a preview.

#### Step 1: Ensure Your Feature Branch is Pushed

```bash
# Make sure your latest changes are on GitHub
git push fork align-button-keyboard-zoom
```

#### Step 2: Trigger the Deployment Workflow

1. Go to your repository on GitHub
2. Click the **Actions** tab at the top
3. In the left sidebar, click **"Manual Branch Preview Deploy"**
4. You'll see a blue button that says **"Run workflow"** - click it
5. A form will appear:
   - **Use workflow from**: Keep as `preview-infra` (this is where the workflow lives)
   - **The branch name to build and deploy**: Enter `align-button-keyboard-zoom`
6. Click the green **"Run workflow"** button

#### Step 3: Wait for the Build

1. The workflow will appear in the runs list (refresh if needed)
2. Click on the workflow run to see progress
3. It typically takes 2-3 minutes to complete
4. Wait until you see a green checkmark ✓

#### Step 4: Access Your Preview

Once complete, open your browser to:

```
https://mizmay.github.io/maplibre-gl-js/?branch=align-button-keyboard-zoom
```

**What you'll see**:
- A full-screen map with zoom controls
- A large zoom level display in the top-left corner
- A branch selector dropdown in the top-right corner

#### Step 5: Compare Branches Parallelly

To compare your implementation with `main` or other branches side-by-side:

1. Look at the **Compare Branches** panel in the top-right corner.
2. Select the branches you want to compare (e.g., check both `main` and `align-button-keyboard-zoom`).
3. Click **Update View**.
4. The page will reload in **Comparison Mode**, showing each branch in a separate, isolated window (iframe).
5. **Synchronization**: Panning or zooming in any one of the maps will automatically sync all other maps to the same location and zoom level. This makes it extremely easy to spot subtle differences in rendering or behavior.

---

## Security Features

### 1. XSS Protection via Branch Registry Validation

The `index.html` page includes security checks to prevent malicious script injection:

```javascript
// Security: Validate branch name against registry
if (branch && !branches.includes(branch)) {
    console.error('Invalid branch:', branch);
    branch = 'main';
}
```

**How it works**:
- Only branches listed in `branches.json` can be loaded
- If someone tries `?branch=//malicious-site.com/script.js`, it will fallback to `main`
- The registry is managed automatically by the CI/CD workflow

### 2. Branch Name Sanitization

The workflow sanitizes branch names to prevent path traversal attacks:

```bash
# Sanitize branch name
CLEAN_NAME=$(echo "${{ github.event.inputs.branch_name }}" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
```

**Examples**:
- `feature/zoom-fix` → `feature-zoom-fix`
- `test/../../../etc/passwd` → `test-etc-passwd`
- `My-Branch-Name` → `my-branch-name`

---

## Troubleshooting

### Problem: "Manual Branch Preview Deploy" workflow not showing in Actions

**Cause**: The workflow file doesn't exist in the `preview-infra` branch, or hasn't been pushed.

**Solution**:
```bash
git checkout preview-infra
ls .github/workflows/manual-deploy.yml  # Verify file exists
git push fork preview-infra              # Push to GitHub
```

### Problem: Workflow fails with "Permission denied" error

**Cause**: GitHub Actions doesn't have write permissions.

**Solution**:
1. Go to **Settings** → **Actions** → **General**
2. Under **Workflow permissions**, select **"Read and write permissions"**
3. Click **Save**
4. Re-run the workflow

### Problem: Preview page shows "Failed to load assets for branch"

**Cause**: The branch hasn't been deployed yet, or the build failed.

**Solutions**:
1. Check the Actions tab to see if the workflow succeeded
2. Look at the workflow logs for build errors
3. Ensure the branch name you entered matches exactly (case-insensitive after sanitization)
4. Try deploying again

### Problem: Branch doesn't appear in the dropdown

**Cause**: The `branches.json` wasn't updated, or you need to refresh the page.

**Solution**:
1. Hard refresh the page (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)
2. Check the `branches.json` file in the `gh-pages` branch on GitHub
3. If the branch is missing from the JSON, re-run the deployment

### Problem: "index.html" preventing branch switches locally

**Cause**: The `index.html` file is untracked in your working directory but exists in `gh-pages`.

**Solution**:
```bash
rm index.html                    # Remove the untracked file
git checkout [your-branch]       # Now you can switch freely
```

### Problem: I want to remove a branch from the previewer

**Solution**:
1. Go to the `gh-pages` branch on GitHub
2. Edit `branches.json` and remove the branch name from the array
3. Optionally, delete the branch folder (e.g., `align-button-keyboard-zoom/`) to clean up space

---

## Advanced: Adding Multiple Branches at Once

If you want to deploy several branches for comparison:

1. Go to **Actions** → **Manual Branch Preview Deploy**
2. Run the workflow multiple times, once for each branch:
   - Run #1: `main`
   - Run #2: `align-button-keyboard-zoom`
   - Run #3: `alternative-zoom-approach`
3. All branches will be available in the dropdown

---

## Workflow Execution Details

When you trigger the workflow with branch name `align-button-keyboard-zoom`:

1. **Checkout**: Workflow checks out your branch
2. **Install**: Runs `npm ci` to install dependencies
3. **Build**: Runs `npm run build-dev` to create `dist/` folder
4. **Sanitize**: Converts branch name to `align-button-keyboard-zoom`
5. **Package**: Creates `deploy-out/align-button-keyboard-zoom/dist/`
6. **Update Registry**: Adds branch to `branches.json` if not already present
7. **Deploy**: Pushes `deploy-out/` to `gh-pages` branch (without deleting existing deployments)
8. **Result**: Assets available at `https://mizmay.github.io/maplibre-gl-js/align-button-keyboard-zoom/dist/`

---

## Summary

**For Each New Feature Branch**:
1. Work on your feature branch (stays clean)
2. Push to GitHub
3. Go to Actions → Manual Branch Preview Deploy → Run workflow
4. Enter your branch name
5. Wait 2-3 minutes
6. Visit `https://mizmay.github.io/maplibre-gl-js/?branch=your-branch-name`

**No infrastructure code touches your feature branches** ✓

