# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Political Fighting Game** - A satirical multiplayer fighting game featuring controversial politicians and historical figures. Designed for humor and political commentary.

### Core Requirements
- **Players**: Up to 4 players per match
- **Platforms**: Web, PC, Mobile (iOS/Android) - all cross-play compatible
- **Multiplayer**: Local play (MVP priority), then network play
- **Philosophy**: Easy to implement, low system/network requirements over fancy graphics
- **Monetization**: Commercial-friendly license required
- **Community**: Modding/extensibility system for characters, landscapes, mechanics, moves

## Technology Stack (Recommended)

### Game Engine
**Godot 4.x** (MIT License - commercial friendly)
- Native exports: Web (HTML5/WebGL), Windows, Linux, macOS, Android, iOS
- GDScript for rapid prototyping, C# or GDExtension for performance-critical code
- Built-in multiplayer with ENet (local) and WebRTC (cross-platform network)
- Small binary sizes, low system requirements
- Active modding community with established patterns

### Alternative Considerations
- **Defold** (custom license, also suitable) - Lua-based, tiny builds
- **LÖVE + Lua** - If 2D only, extremely lightweight

## Architecture

### Directory Structure (Planned)
```
/
├── game/                    # Godot project root
│   ├── scenes/             # Scene files (.tscn)
│   │   ├── characters/     # Character scenes
│   │   ├── stages/         # Arena/landscape scenes
│   │   └── ui/             # Menu and HUD scenes
│   ├── scripts/            # GDScript files
│   │   ├── characters/     # Character controllers
│   │   ├── combat/         # Fighting mechanics
│   │   ├── network/        # Multiplayer logic
│   │   └── core/           # Game state, input handling
│   ├── resources/          # Shared resources (.tres)
│   │   ├── moves/          # Move definitions (moddable)
│   │   └── stats/          # Character stats (moddable)
│   └── mods/               # User mod directory
├── assets/                  # Raw assets (sprites, audio)
├── docs/                    # Design documents
└── tools/                   # Build scripts, mod tools
```

### Modding System Design
- **Data-driven characters**: JSON/Resource files for stats, moves, hitboxes
- **Hot-loadable content**: Characters and stages as scene packs
- **Mod manifest format**: Standardized metadata for mod discovery
- **Workshop integration**: Plan for Steam Workshop / itch.io mods

### Multiplayer Architecture
1. **Local Play (MVP)**
   - Single-device with split input (keyboards, gamepads)
   - State managed locally, no network code

2. **Network Play (Phase 2)**
   - Rollback netcode for responsiveness (GGPO-style)
   - Peer-to-peer for LAN, relay server for WAN
   - WebRTC for web browser compatibility

## Build Commands

```bash
# Export for Web (HTML5)
godot --headless --export-release "Web" builds/web/index.html

# Export for Windows
godot --headless --export-release "Windows Desktop" builds/windows/game.exe

# Export for Linux
godot --headless --export-release "Linux" builds/linux/game.x86_64

# Export for Android
godot --headless --export-release "Android" builds/android/game.apk

# Run game in editor
godot --path game/

# Run specific scene
godot --path game/ scenes/main_menu.tscn
```

## Development Phases

### Phase 1: MVP (Local Multiplayer)
- [ ] Basic character controller (movement, jump, attack)
- [ ] 2 playable characters with distinct movesets
- [ ] 1 stage/arena
- [ ] Local 2-player support
- [ ] Basic UI (character select, health bars)

### Phase 2: Core Game
- [ ] Expand to 4-player local
- [ ] 4+ characters
- [ ] Multiple stages
- [ ] Special moves system
- [ ] Sound effects and music

### Phase 3: Network Play
- [ ] Rollback netcode implementation
- [ ] Matchmaking (basic)
- [ ] Cross-platform play testing

### Phase 4: Community & Polish
- [ ] Mod loading system
- [ ] Mod creation documentation
- [ ] Monetization integration

## Character Design Guidelines

Characters should be immediately recognizable caricatures with:
- **Signature visual element** (hair, accessory, pose)
- **Catchphrase voice lines** (satirical quotes)
- **Moves reflecting persona** (e.g., a banker's "bailout" attack)
- **Fair use considerations**: Parody/satire protected, but avoid defamation

## Code Style

- GDScript: Follow official Godot style guide
- Prefer composition over inheritance for game objects
- Use signals for loose coupling between systems
- Document public APIs with docstrings
- Keep scenes small and composable

## License

Project should use a license compatible with:
- Commercial distribution
- Mod creation and sharing
- Asset sales (character packs, etc.)

Recommended: **MIT** or **Apache 2.0** for code, **CC BY** for community-created content guidelines
