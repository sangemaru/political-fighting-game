# Web Build Export Options

## Overview
This document describes the HTML5/Web export configuration for the Political Fighting Game.

## Export Preset Configuration

**Location**: `game/export_presets.cfg`

**Platform**: Web (HTML5/WebGL)

**Output**: `builds/web/index.html`

## Key Settings

### VRAM Texture Compression
- **Desktop**: Enabled (S3TC compression for web browsers)
- **Mobile**: Disabled (reduces build size, web-first target)

### Canvas Settings
- **Resize Policy**: 2 (Scale to fill, keeping aspect ratio)
- **Focus on Start**: Enabled (immediate input capture)

### Progressive Web App
- **Enabled**: False (simple web game, no offline requirements)
- Keep disabled to avoid COOP/COEP header complexity on simple hosting

## Build Optimization (F72)

### Texture Import Settings
**Recommendation**: Review all textures in `game/assets/` and ensure:
- Import as Compress, Lossy (default for web)
- Maximum size: 2048x2048 for characters/backgrounds
- Use SVG or low-res sprites where possible

**Action**: In Godot Editor, select textures → Import tab → Set:
```
Compress: Lossy
Mipmaps: Generate (for scaling quality)
Max Size: 2048
```

### Memory Optimization
Godot's HTML5 export automatically handles:
- WebAssembly memory allocation
- Streaming texture loading
- Audio buffer management

**Target**: Keep initial WASM download under 10MB for fast load times.

### JavaScript Compression
Godot automatically generates:
- `index.js` (game logic, compressed)
- `index.wasm` (engine + game code)
- `index.pck` (game assets, compressed)

**Production checklist**:
- [ ] Export with "Optimize" enabled (Godot export dialog)
- [ ] Test in Chrome, Firefox, Safari
- [ ] Verify WASM loads successfully (check browser console)

## Export Template Installation

### First-time Setup (if templates missing)
```bash
# Godot will prompt to download templates on first export
# OR manually install:
# Editor → Manage Export Templates → Download and Install
```

**Version**: Must match your Godot version (4.x)

## Testing Locally

### Python HTTP Server
```bash
cd builds/web
python3 -m http.server 8000
# Open http://localhost:8000
```

### Cross-Origin Headers (for SharedArrayBuffer)
If using threading (currently disabled), serve with:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

**Note**: itch.io handles these headers automatically for HTML5 games.

## Troubleshooting

### "Failed to load wasm binary"
- Check file size (too large? split assets)
- Verify MIME types on server (`.wasm` → `application/wasm`)

### "Out of memory" in browser
- Reduce texture sizes
- Lower audio bitrates
- Disable unused features in export

### Black screen on load
- Check browser console for errors
- Verify `project.godot` main scene is set
- Test export with minimal scene first

## File Size Targets

**Uncompressed**:
- index.html: < 100KB
- index.js: ~2MB (Godot engine wrapper)
- index.wasm: ~10MB (engine + game code)
- index.pck: ~5MB (game assets)

**Total**: ~17MB initial download (acceptable for web game)

**With gzip compression** (server-side): ~8-10MB actual download.

## CI/CD Integration
See GitHub Actions workflow in `.github/workflows/build.yml` for automated builds.
