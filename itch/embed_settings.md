# itch.io Embed Settings

## Recommended Configuration

### Game Settings

**Kind of project**: HTML

**Embed options**:
- ☑ Embed in page
- ☑ Mobile friendly (responsive)
- ☐ Automatically start on page load (let users click Play)
- ☑ Enable fullscreen button
- ☐ SharedArrayBuffer support (not needed - no threading)

**Viewport dimensions**:
- Width: 1280px
- Height: 720px
- (Matches Godot project resolution: 1280x720)

**Orientation**: Landscape

### Upload Files

**File structure** (zip or individual upload):
```
index.html
index.js
index.wasm
index.pck
```

**Note**: itch.io will automatically detect `index.html` as the entry point.

### Cover Image

**Dimensions**: 630x500 px (itch.io recommended)

**Placeholder**: Create a simple cover image with:
- Game title: "Political Fighting Game"
- Tagline: "Punch Through Politics!"
- Character silhouettes or sprites (if available)
- Bright, eye-catching colors

**Tool suggestions**: GIMP, Canva, or simple sprite export from Godot.

### Screenshots

**Recommended count**: 3-5 screenshots

**What to capture**:
1. Character select screen (shows available fighters)
2. In-battle action shot (mid-combo or special move)
3. HUD/UI showcase (health bars, combo counter)
4. Victory screen (optional)

**Format**: PNG, 1280x720 (native resolution)

**How to capture**: Use Godot's F12 screenshot or browser DevTools.

### Tags

**Recommended tags** (max 10):
- fighting
- local-multiplayer
- satire
- political
- 2d
- arcade
- godot
- web
- html5
- comedy

### Pricing

**Free** (MVP/early access)

**Future options**:
- Pay-what-you-want (suggested $0, optional tip)
- Paid DLC characters (if modding ecosystem grows)

### Release Status

**Early Access** (until Phase 2 complete)

**Visibility**:
- Public (once MVP stable)
- Draft (during CI/CD setup)

### Community

**Enable comments**: Yes (feedback welcome)

**Enable ratings**: Yes

**Devlog**: Optional - can post updates about new characters, features, multiplayer progress

### Cross-Origin Headers

**itch.io automatically provides** the required headers for HTML5 games:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

**No manual configuration needed** for SharedArrayBuffer (though we don't use it yet).

### Butler CLI Upload (Automated)

For GitHub Actions deployment, install butler:
```bash
curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default
unzip butler.zip
chmod +x butler
./butler -V
```

**Push command** (in CI workflow):
```bash
butler push builds/web/ username/game-name:web --userversion 0.1.0
```

**API Key**: Store as GitHub secret `BUTLER_API_KEY`

**Get key**: https://itch.io/user/settings/api-keys

### Testing Checklist

Before publishing:
- [ ] Test in Chrome (primary)
- [ ] Test in Firefox
- [ ] Test in Safari (if possible)
- [ ] Test fullscreen mode
- [ ] Verify gamepad support (if controllers connected)
- [ ] Check mobile/tablet (responsive canvas)
- [ ] Test 2-player input (verify both keyboards work)

### Launch Preparation

**Pre-launch**:
1. Upload build as **Draft**
2. Add cover image + screenshots
3. Complete description with controls
4. Test embedded game thoroughly
5. Share draft link with 2-3 testers

**Launch**:
1. Set to **Public**
2. Post in itch.io forums (fighting games, godot)
3. Share on social media / game dev communities
4. Monitor comments/feedback for bugs

**Post-launch**:
- Respond to comments
- Fix critical bugs
- Update devlog with patches
- Plan Phase 2 features based on feedback
