# MapLibre Branch Preview System

A decoupled system for testing and comparing MapLibre GL JS implementations across different branches without polluting feature branches.

## 🏗️ Architecture Overview

The preview system uses a clean two-file architecture:

- **`index.html`**: Main container with side-by-side layout and controls (Align, Synchronize, Zoom)
- **`viewer.html`**: Individual map viewer loaded in iframes, one per branch
- **Asset structure**: Built assets stored in `previews/{branch}/dist/`

### How It Works

1. Each branch's build artifacts are synced to `previews/{branch}/dist/`
2. `index.html` loads two instances of `viewer.html` in iframes, passing branch names via URL parameters
3. Each `viewer.html` loads its branch's MapLibre assets and renders a map
4. The iframes communicate with the parent via `postMessage` for synchronization

### Features

- **Align Button**: One-time sync of right map to match left map's camera position
- **Synchronize Checkbox**: Toggle continuous bidirectional pan/zoom syncing between maps
- **Shared Zoom Controls**: `+` and `−` buttons zoom both maps simultaneously (auto-disables sync mode)
- **Native Zoom Logic**: Uses MapLibre's internal `zoomIn()`/`zoomOut()` methods for consistent behavior
- **Real-time Zoom Display**: Each map shows its actual zoom level from `map.getZoom()`

---

## 🚀 Quick Start (Local Testing)

### 1. One-Time Setup
Create a parallel directory (worktree) for the preview infrastructure:

```bash
# From maplibre-gl-js directory:
git worktree add ../maplibre-preview preview-infra
cd ../maplibre-preview && npm install
```
Defined under `scripts` in `package.json`:
```bash
    "preview-local": "st --no-cache -H localhost --port 9966 staging/previews",
    "preview-sync": "bash scripts/preview-local.sh",
    "preview": "npm run preview-sync && npm run preview-local"
```

### 2. The Development Loop (Switch & Sync)

**Terminal 1: Working in `maplibre-gl-js` directory**
1. Checkout the branch you want to test: `git checkout my-feature`
2. Build your changes: `npm run build-dev && npm run build-css`

**Terminal 2: Sync in `maplibre-preview`**
1. Switch to the preview directory: `cd ../maplibre-preview`
2. Ensure you are on the infra branch: `git checkout preview-infra`
3. Sync the build: `npm run preview-sync`
4. Start server: `npm run preview-local`

**View at: http://localhost:9966**

The server serves from the project root, with:
- HTML files at root: `index.html`, `viewer.html`
- Branch assets in: `previews/{branch}/dist/`
- Branch registry: `previews/branches.json`

---

## ⚖️ Comparing Branches (Side-by-Side)

The previewer allows you to compare multiple branches with synchronized cameras.

### Building Multiple Branches

1. **Build Branch A**: In `maplibre-gl-js`, checkout `main`, build it, then run `npm run preview-sync` in `maplibre-preview`.
2. **Build Branch B**: In `maplibre-gl-js`, checkout `my-feature`, build it, then run `npm run preview-sync` in `maplibre-preview`.

### Viewing Comparisons

Open the preview with URL parameters to specify which branches to compare:
- Default: `http://localhost:9966` (shows main on left, first non-main branch on right)
- Custom: `http://localhost:9966?left=main&right=my-feature`

### Using Comparison Controls

- **Align**: Click to make the right map jump to the left map's current view (one-time sync)
- **Synchronize**: Check to enable continuous syncing - pan or zoom either map and the other follows
- **Zoom Buttons**: Use `+`/`−` to zoom both maps together (automatically unchecks Synchronize)

---

## 🌍 Remote Deployment (GitHub Pages)

### Overview

The deployment system uses GitHub Actions to deploy the `preview-infra` branch to `gh-pages`. The `deploy-preview.yml` workflow is **automatically triggered** whenever you push to the `preview-infra` branch.

**The workflow**:
1. Checks out the `preview-infra` branch
2. Copies `index.html` and `viewer.html` to the deployment folder
3. Copies the entire `previews/` directory (which contains all synced branches)
4. Deploys everything to the `gh-pages` branch

**Important**: The workflow does NOT build branches. You must build and sync branches locally using `npm run preview-sync` before pushing.

### Workflow: Build → Sync → Push → View

1. **Build branches locally** (in `maplibre-gl-js`):
   ```bash
   # Build main
   git checkout main
   npm run build-dev && npm run build-css
   
   # Build your feature
   git checkout my-feature
   npm run build-dev && npm run build-css
   ```

2. **Sync to preview-infra** (in `maplibre-preview`):
   ```bash
   cd ../maplibre-preview
   git checkout preview-infra
   
   # Sync main
   npm run preview-sync  # while main is checked out in maplibre-gl-js
   
   # Switch to feature branch in maplibre-gl-js, then:
   npm run preview-sync  # syncs the feature branch
   ```

3. **Commit and push** (in `maplibre-preview`):
   ```bash
   git add staging/
   git commit -m "Add preview for my-feature branch"
   git push fork preview-infra
   ```

4. **Automatic Deployment**: GitHub Actions will detect the push to `preview-infra` and automatically deploy the updated previews to `gh-pages`. You can track progress in the **Actions** tab.

5. **View**: Visit `https://[your-username].github.io/maplibre-gl-js/`

### Updating the Deployment System

If you need to update the HTML files or deployment logic:

1. **Make changes** in the `preview-infra` branch:
   ```bash
   cd ../maplibre-preview
   git checkout preview-infra
   # Edit index.html, viewer.html, or .github/workflows/deploy-preview.yml
   git add -A
   git commit -m "Update preview system"
   git push origin preview-infra
   ```

2. **Deploy**: Run the **Deploy Branch Preview** workflow to push the updates to `gh-pages`.

---

## 🌳 Git Worktree Troubleshooting

Run `git branch` to see branch status symbols:
- `*` (**Asterisk**): Active in current folder.
- `+` (**Plus**): Active in a different folder.

**Correct state**:
- `maplibre-gl-js` folder: `* my-feature`, `+ preview-infra`
- `maplibre-preview` folder: `+ my-feature`, `* preview-infra`

---

## 🛠 Troubleshooting

### Port Issues
- **"Address already in use"**: `lsof -ti:9966 | xargs kill -9`

### Branch Pollution
- **Clean Feature Branch**: If infrastructure files appear in your feature branch, delete them (they belong in `preview-infra`).

### Asset Loading Issues
- **Local**: Ensure `npm run preview-local` is serving from the project root
- **Remote**: Check that the workflow deployed to `previews/{branch}/dist/`
- **Paths**: Both `index.html` and `viewer.html` use relative paths starting with `./previews/`

### Sync Not Working
- **Refresh the page**: The iframes need to be fully loaded before sync works
- **Check Console**: Open browser DevTools to see any postMessage errors
- **Branch Mismatch**: Ensure both branches have been built and synced

---

## 📋 npm Scripts Reference

Defined in `package.json`:

```bash
# Sync the current branch's build to staging/previews/
npm run preview-sync

# Start the local preview server at http://localhost:9966
npm run preview-local
```

