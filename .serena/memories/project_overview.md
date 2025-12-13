# Political Fighting Game - Project Overview

## Project Summary
A Godot 4.x fighting game with political themes. Two-player combat focusing on fighting mechanics, character data systems, and mod support.

## Technology Stack
- **Engine**: Godot 4.x
- **Language**: GDScript
- **Target Platform**: Web (GL Compatibility renderer)
- **Viewport**: 1280x720

## Project Structure

```
political-fighting-game/
├── game/
│   ├── scenes/              # Scene files (.tscn)
│   ├── scripts/
│   │   ├── core/           # Core systems (game_manager, input_manager, etc.)
│   │   ├── combat/         # Combat system (hitboxes, damage, etc.)
│   │   └── characters/     # Character base classes and components
│   ├── resources/
│   │   └── schemas/        # JSON schemas for data validation
│   └── mods/               # Mod support directory
├── assets/
│   ├── sprites/            # Character and UI graphics
│   └── audio/              # Sound effects and music
├── docs/                   # Project documentation
├── tools/                  # Development tools and utilities
└── builds/                 # Export builds directory
```

## Core Systems

### 1. Game Manager (`game/scripts/core/game_manager.gd`)
- Handles overall game state
- Scene transitions
- Core initialization

### 2. Input Manager (`game/scripts/core/input_manager.gd`)
- Processes input for both players
- Maps keyboard input to actions

### 3. Combat System (`game/scripts/combat/combat_system.gd`)
- Fighting mechanics
- Hitbox detection
- Damage calculations

### 4. Base Fighter (`game/scripts/characters/base_fighter.gd`)
- Base class for all characters
- Movement and animation logic
- Health and state management

## Input Actions

### Player 1 (WASD)
- `p1_move_left` - A key
- `p1_move_right` - D key
- `p1_move_up` - W key
- `p1_move_down` - S key
- `p1_attack` - Spacebar
- `p1_special` - Shift

### Player 2 (Arrow Keys)
- `p2_move_left` - Left Arrow
- `p2_move_right` - Right Arrow
- `p2_move_up` - Up Arrow
- `p2_move_down` - Down Arrow
- `p2_attack` - Enter
- `p2_special` - Right Ctrl

## Character Data Schema

Located at: `game/resources/schemas/character_schema.json`

Structure includes:
- **base_stats**: health, speed, weight, attack_power, defense
- **moves**: array of moves with:
  - Input commands
  - Damage values
  - Frame data (startup, active, recovery)
  - Hitbox definitions (offset, width, height)

## Godot Configuration

**project.godot settings:**
- Project name: "Political Fighting Game"
- Renderer: GL Compatibility (web-ready)
- Physics: 60 ticks per second
- Main scene: res://game/scenes/main.tscn (to be created)

## Development Workflow

1. **Version Control**: Git with Godot-specific .gitignore
2. **Code Style**: GDScript with class_name declarations
3. **File Organization**: Functional grouping (core, combat, characters)
4. **Data Format**: JSON schemas for character data validation

## Next Steps
- Create actual scene files (.tscn)
- Implement input system
- Develop character and combat mechanics
- Create character data files using the schema
- Build mod system support
