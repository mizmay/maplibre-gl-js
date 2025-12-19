# MapLibre Branch Preview System

A decoupled system for testing and comparing MapLibre GL JS implementations across different branches without polluting feature branches.

## 🚀 Quick Start (Local Testing)

### 1. One-Time Setup
Create a parallel directory (worktree) for the preview infrastructure:

```bash
# From maplibre-gl-js directory:
git worktree add ../maplibre-preview preview-infra
cd ../maplibre-preview && npm install
```

### 2. The Development Loop
Whenever you want to test your current work:

```bash
# Step A: Build your feature (in your main work directory)
cd ~/Repos/maplibre/maplibre-gl-js
npm run build-dev && npm run build-css

# Step B: Sync and View (in the preview worktree)
cd ../maplibre-preview
npm run preview
```
View at: **http://localhost:9966**

---

## 🌍 Remote Deployment

Deploy your branch to GitHub Pages for others to review.

1. **Push your code**: `git push fork your-branch-name`
2. **Deploy**: Go to your fork's **Actions** tab → **Deploy Branch Preview** → **Run workflow** (enter your branch name).
3. **View**: `https://[your-username].github.io/maplibre-gl-js/?branch=your-branch-name`

---

## ⚖️ Comparing Branches

1. Build and Sync **main**:
   ```bash
   cd ~/Repos/maplibre/maplibre-gl-js
   git checkout main && npm run build-dev && npm run build-css
   cd ../maplibre-preview && npm run preview-sync
   ```

2. Build and Sync **your feature**:
   ```bash
   cd ~/Repos/maplibre/maplibre-gl-js
   git checkout your-branch && npm run build-dev && npm run build-css
   cd ../maplibre-preview && npm run preview-sync
   ```

3. **Compare**: Run `npm run preview-local` in `maplibre-preview`. Open the browser, select both branches in the dropdown, and click **Update View**.

---

## 🛠 Troubleshooting

- **"Address already in use"**: Kill the old process: `lsof -ti:9966 | xargs kill -9`
- **Missing UI**: Run `npm run preview-sync` to fetch the latest `index.html` and registry.
- **Clean Feature Branch**: If you see preview files in your feature branch, delete them: `rm -rf scripts/ .github/workflows/deploy-preview.yml` (they should only live in `preview-infra`).

**Note**: All local test files are stored in `staging/previews/` which is already ignored by MapLibre's `.gitignore`.
