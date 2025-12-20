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

---

## ⚖️ Comparing Branches (Side-by-Side)

The previewer allows you to compare multiple branches with synchronized cameras.

1. **Build Branch A**: In `maplibre-gl-js`, checkout `main`, build it, then run `npm run preview-sync` in `maplibre-preview`.
2. **Build Branch B**: In `maplibre-gl-js`, checkout `my-feature`, build it, then run `npm run preview-sync` in `maplibre-preview`.
3. **Compare**: Open `localhost:9966`, check both branches in the dropdown, and click **Update View**.

---

## 🌍 Remote Deployment

1. **Push code**: `git push fork your-feature-branch`
2. **Deploy**: Fork GitHub → **Actions** → **Deploy Branch Preview** → **Run workflow** (enter branch name).
3. **View**: `https://[your-username].github.io/maplibre-gl-js/`

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

- **"Address already in use"**: `lsof -ti:9966 | xargs kill -9`
- **Clean Feature Branch**: If infrastructure files appear in your feature branch, delete them (they belong in `preview-infra`).
