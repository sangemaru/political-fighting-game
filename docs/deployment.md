# Deployment Guide

## Overview
This document describes the automated deployment pipeline for the Political Fighting Game.

## Platforms

### 1. Web (HTML5) - Primary Target

**Status**: ✅ Configured

**Hosting Options**:
- **GitHub Pages** (Free, automatic via CI)
- **itch.io** (Primary distribution, game hosting platform)

**CI/CD**: GitHub Actions workflow (`.github/workflows/build.yml`)

**Triggers**:
- Push to `main` or `master` branch
- Manual dispatch via GitHub UI

**Artifacts**: Uploaded for every build (PR or push)

**Deployment**: Automatic to GitHub Pages and itch.io (after configuration)

### 2. Windows Desktop

**Status**: ✅ CI Configured

**Export**: Automated in GitHub Actions

**Distribution**: Manual download from GitHub Releases OR itch.io upload

**Artifact**: `political-fighting-game.exe` + data files

### 3. Linux Desktop

**Status**: ✅ CI Configured

**Export**: Automated in GitHub Actions

**Distribution**: Manual download from GitHub Releases OR itch.io upload

**Artifact**: `political-fighting-game.x86_64` binary

### 4. macOS Desktop

**Status**: ⏳ Not yet configured (F78)

**Blocker**: Requires macOS export template and potentially code signing

### 5. Android

**Status**: ⏳ Not yet configured (F79)

**Blocker**: Requires Android SDK setup in CI

### 6. iOS

**Status**: ⏳ Not yet configured (F80)

**Blocker**: Requires macOS runner, iOS export template, provisioning profiles

## GitHub Actions Workflow

**File**: `.github/workflows/build.yml`

### Jobs

#### 1. `export-web`
- **Container**: `barichello/godot-ci:4.3` (pre-installed Godot + templates)
- **Steps**:
  1. Checkout code
  2. Setup export templates
  3. Export to `builds/web/index.html`
  4. Upload artifact
  5. Deploy to GitHub Pages (if push to main/master)

#### 2. `export-windows`
- Same container, exports Windows .exe

#### 3. `export-linux`
- Same container, exports Linux binary

#### 4. `deploy-itch`
- **Depends on**: `export-web`
- **Condition**: Only runs on push to main/master
- **Steps**:
  1. Download web artifact
  2. Install Butler (itch.io CLI)
  3. Push to itch.io (requires `BUTLER_API_KEY` secret)

### Secrets Required

**GitHub Repository Secrets** (Settings → Secrets and variables → Actions):

1. `BUTLER_API_KEY` - itch.io API key
   - **Get from**: https://itch.io/user/settings/api-keys
   - **Purpose**: Automated itch.io uploads via Butler

**GitHub Pages** (if using):
- No secrets needed (uses `GITHUB_TOKEN` automatically)
- Enable GitHub Pages in repository settings: Settings → Pages → Source: `gh-pages` branch

## itch.io Setup

### Prerequisites
1. Create itch.io account
2. Create new project: https://itch.io/game/new
3. Set project to **Draft** initially
4. Note project URL: `https://username.itch.io/game-name`

### Butler Configuration

**In GitHub Actions workflow**, update the Butler push command:
```yaml
./butler push builds/web/ username/game-name:web --userversion ${{ github.sha }}
```

**Replace**:
- `username` → Your itch.io username
- `game-name` → Your game's slug (from project URL)

### First Deployment

**Manual first upload** (recommended):
1. Export locally: `godot --headless --export-release "Web" builds/web/index.html`
2. Zip `builds/web/` contents
3. Upload to itch.io via web interface
4. Configure embed settings (see `itch/embed_settings.md`)
5. Test thoroughly before making public

**Then enable automated deployments**:
1. Add `BUTLER_API_KEY` to GitHub secrets
2. Update workflow with correct itch.io project path
3. Push to main/master → CI will auto-deploy

## GitHub Pages Setup

**Enable GitHub Pages**:
1. Go to repository Settings → Pages
2. Source: Deploy from a branch
3. Branch: `gh-pages` / `root`
4. Save

**After first CI run**, your game will be at:
```
https://[username].github.io/[repository-name]/
```

**Example**: `https://blackthorne.github.io/political-fighting-game/`

## Local Testing Before Deployment

**Build locally**:
```bash
cd game
godot --headless --export-release "Web" ../builds/web/index.html
```

**Test locally**:
```bash
cd builds/web
python3 -m http.server 8000
# Open http://localhost:8000 in browser
```

**Checklist**:
- [ ] Game loads without errors (check browser console)
- [ ] Both players can control characters
- [ ] Audio plays correctly
- [ ] Fullscreen works
- [ ] No CORS errors (all assets load)

## Deployment Checklist

**Before first public release**:
- [ ] Export presets configured (F71) ✅
- [ ] Web optimization settings reviewed (F72) ✅
- [ ] itch.io page description ready (F73) ✅
- [ ] GitHub Actions workflow tested (F74) ✅
- [ ] Deployment secrets configured (F75) ⏳ (requires user setup)
- [ ] Local build tested successfully
- [ ] Cover image + screenshots created
- [ ] Playtested by 2+ people
- [ ] Known bugs documented

**Release Process**:
1. Create git tag: `git tag v0.1.0 && git push --tags`
2. Merge to main/master → CI auto-deploys
3. Verify GitHub Pages deployment
4. Verify itch.io deployment (if configured)
5. Make itch.io project **Public**
6. Announce in communities (itch.io forums, /r/godot, etc.)

## Troubleshooting

### CI Workflow Fails

**Check**:
- Godot version in workflow matches export template version
- Export preset name "Web" matches exactly (case-sensitive)
- Export path in `export_presets.cfg` is correct

**Debug**:
- Check GitHub Actions logs for error messages
- Test local export first to verify configuration

### itch.io Upload Fails

**Common issues**:
- `BUTLER_API_KEY` not set in GitHub secrets
- Project path in workflow doesn't match itch.io URL
- itch.io project doesn't exist or is inaccessible

**Fix**:
- Verify API key: `./butler login` locally
- Check itch.io project settings (must be created first)

### GitHub Pages 404

**Possible causes**:
- `gh-pages` branch not created yet (wait for first CI run)
- GitHub Pages not enabled in repository settings
- Wrong branch selected in Pages settings

**Fix**:
- Enable GitHub Pages after first successful CI run
- Select `gh-pages` branch in Settings → Pages

### Game Doesn't Load in Browser

**Check**:
- Browser console for errors
- MIME types (`.wasm` must be served as `application/wasm`)
- File sizes (too large? split assets)
- CORS errors (missing headers? use itch.io embed for SharedArrayBuffer)

**itch.io**: Automatically handles CORS headers

**GitHub Pages**: No SharedArrayBuffer support by default (not needed for current build)

## Monitoring

**GitHub Actions**:
- Check Actions tab for build status
- Review logs for warnings/errors

**itch.io Analytics** (after public release):
- Views, downloads, plays
- Page views vs game plays (conversion rate)
- Geographic distribution

**Feedback Channels**:
- itch.io comments
- GitHub Issues
- Community forums

## Future Improvements (Phase 2+)

- [ ] Automated version numbering (F81)
- [ ] Changelog generation (F82)
- [ ] Automated testing in CI (GDUnit4)
- [ ] Multi-platform releases (Windows/Linux zips)
- [ ] Steam deployment pipeline
- [ ] Mobile app store deployments (Android/iOS)

## Contact

For deployment issues, check:
1. GitHub Actions logs
2. itch.io documentation: https://itch.io/docs/butler/
3. Godot CI documentation: https://github.com/abarichello/godot-ci
