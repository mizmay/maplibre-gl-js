# Branch Preview Deployment System - Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [How the Workflow Triggering Works](#how-the-workflow-triggering-works)
4. [One-Time Setup Instructions](#one-time-setup-instructions)
5. [The Vetted Flow: Local -> Stage -> Promote](#the-vetted-flow-local---stage---promote)
6. [Security Features](#security-features)
7. [Troubleshooting](#troubleshooting)
8. [Local Development & Testing](#local-development--testing)

---

## Overview

This system allows you to test different MapLibre GL JS implementations across multiple branches without adding any testing infrastructure code to your feature branches.

**Key Design Principle**: Your feature branches remain completely clean. All testing infrastructure lives in dedicated branches.

---

## System Architecture

The system uses three separate branches:

```
Repository Structure:
├── Feature Branches (e.g., align-button-keyboard-zoom)
│   └── Contains ONLY your MapLibre code changes
│
├── preview-infra (Infrastructure Branch)
│   └── .github/workflows/manual-deploy.yml (Build & Upload Only)
│   └── .github/workflows/promote-branch.yml (Add to Registry)
│   └── scripts/deploy-local.sh (Local Deployment)
│
└── gh-pages (Deployment Branch)
    ├── index.html (Master Tester - UI for testing)
    ├── branches.json (Production Registry - controls the dropdown)
    ├── main/dist/ (Assets for main)
    └── [branch-name]/dist/ (Assets for other branches)
```

---

## The Vetted Flow: Local -> Stage -> Promote

To ensure the master loader dropdown only contains verified and working branches, we follow a three-step promotion process.

### Step 1: Local Test (Baseline)
Before pushing to GitHub, verify your changes locally.

1.  **Deploy Locally**: 
    ```bash
    ./scripts/deploy-local.sh
    ```
    *This script will build your current branch and 'main' (if missing), then start a local server.*
2.  **Verify**: Open `http://localhost:9966` and ensure your changes work as expected.

### Step 2: Stage (Remote Upload)
Upload your assets to GitHub Pages without adding them to the dropdown yet.

1.  **Push Branch**: `git push fork your-feature-branch`
2.  **Trigger Upload**: 
    - Go to **Actions** → **Manual Branch Preview Deploy**.
    - Run workflow for your branch.
3.  **Verify Staging**: Open the direct URL:
    `https://mizmay.github.io/maplibre-gl-js/?branch=your-branch-name`
    *(Note: The branch will NOT appear in the dropdown yet).*

### Step 3: Promote (Production Registry)
Add the branch to the Master Loader dropdown for everyone to see.

1.  **Trigger Promotion**:
    - Go to **Actions** → **Promote Branch to Registry**.
    - Run workflow with your branch name.
2.  **Verify Production**: Visit the base URL:
    `https://mizmay.github.io/maplibre-gl-js/`
    *Your branch should now appear in the dropdown.*

---

## Local Development & Testing

The local environment mirrors GitHub Pages exactly.

### 1. The Deploy Script (`scripts/deploy-local.sh`)
This script is your primary tool for local development. It:
- Ensures `local-previews/` is set up.
- Fetches the Master Tester from `gh-pages`.
- Builds your current branch.
- Offers to build `main` as a baseline for side-by-side comparison.

### 2. The Preview Server
Run `npm run preview-local` to serve the `local-previews/` folder.

---

## Troubleshooting

### Problem: 404 Not Found in Browser Console
**Cause**: The assets for that specific branch haven't been built or deployed to the correct folder.
**Solution**: 
- Locally: Run `./scripts/deploy-local.sh`.
- Remotely: Run the **Manual Branch Preview Deploy** action.

### Problem: "index.html" preventing branch switches locally
**Solution**: `rm index.html` (it will be re-fetched by the deploy script when needed).

---

## Summary
- **Feature Branches**: Clean MapLibre code.
- **preview-infra**: Workflows and scripts.
- **gh-pages**: Deployed assets and the Master Tester.
