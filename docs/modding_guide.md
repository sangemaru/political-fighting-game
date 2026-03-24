# Modding Guide - Political Fighting Game

This guide explains how to create and install mods for the Political Fighting Game.

## Overview

The game supports data-driven mods that add new characters and stages without requiring code changes. Mods are loaded automatically from the `game/mods/` directory at startup.

## Supported Mod Types

| Type | Description |
|------|-------------|
| `character` | Adds a new playable fighter with custom stats and moves |
| `stage` | Adds a new battle arena with custom boundaries and spawn points |
| `gameplay` | Reserved for future use (not yet supported) |

## Mod Structure

Each mod lives in its own subdirectory under `game/mods/`:

```
game/mods/
  my_character_mod/
    mod_manifest.json    -- Required: metadata and file references
    character.json       -- Data file (character or stage JSON)
    README.md            -- Optional: documentation for your mod
```

## Mod Manifest Format

Every mod must include a `mod_manifest.json` in its root directory:

```json
{
  "mod_id": "unique_mod_id",
  "name": "Display Name",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "What this mod adds",
  "type": "character",
  "godot_version": "4.1",
  "game_version": "0.1.0",
  "files": {
    "data": "character.json"
  }
}
```

### Manifest Fields

| Field | Required | Description |
|-------|----------|-------------|
| `mod_id` | Yes | Unique identifier (lowercase letters, numbers, underscores only) |
| `name` | Yes | Human-readable name shown in-game |
| `version` | Yes | Semantic version of your mod (e.g., `1.0.0`) |
| `author` | Yes | Creator name or team |
| `description` | Yes | Short description of the mod's content |
| `type` | Yes | One of: `character`, `stage`, `gameplay` |
| `godot_version` | No | Minimum Godot version (informational) |
| `game_version` | Yes | Minimum game version required (e.g., `0.1.0`) |
| `files.data` | Yes | Path to the JSON data file, relative to the mod directory |
| `files.scene` | No | Path to a `.tscn` scene file (reserved for future use) |
| `files.script` | No | Path to a `.gd` script file (reserved for future use) |

## Creating a Character Mod

### 1. Create the directory

```
game/mods/my_fighter/
```

### 2. Create `mod_manifest.json`

```json
{
  "mod_id": "my_fighter",
  "name": "The Spin Doctor",
  "version": "1.0.0",
  "author": "YourName",
  "description": "A media manipulator who attacks with propaganda.",
  "type": "character",
  "game_version": "0.1.0",
  "files": {
    "data": "character.json"
  }
}
```

### 3. Create `character.json`

Follow the character data schema (`game/resources/schemas/character_schema.json`):

```json
{
  "id": "spin_doctor",
  "name": "The Spin Doctor",
  "description": "Manipulates the narrative and the opponent.",
  "base_stats": {
    "health": 90,
    "speed": 200,
    "weight": 0.9,
    "attack_power": 1.0,
    "defense": 0.8
  },
  "moves": [
    {
      "id": "light_attack",
      "name": "Press Release",
      "input": "ATTACK",
      "damage": 7,
      "startup_frames": 3,
      "active_frames": 2,
      "recovery_frames": 5,
      "knockback": 45,
      "hitbox": {
        "offset_x": 25,
        "offset_y": 0,
        "width": 35,
        "height": 28
      }
    }
  ]
}
```

### Character Stats Reference

| Stat | Type | Range | Description |
|------|------|-------|-------------|
| `health` | int | 1+ | Maximum hit points |
| `speed` | float | 0.1+ | Movement speed in pixels/sec |
| `weight` | float | 0.5 - 2.0 | Knockback resistance (higher = heavier) |
| `attack_power` | float | 0.5+ | Damage multiplier |
| `defense` | float | 0.5+ | Damage reduction multiplier |

### Move Fields Reference

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | string | unique per character | Move identifier |
| `name` | string | | Display name |
| `input` | string | | Input command (e.g., `"DOWN + ATTACK"`) |
| `damage` | int | >= 0 | Base damage dealt |
| `startup_frames` | int | >= 1 | Windup frames before hit |
| `active_frames` | int | >= 1 | Frames the hitbox is live |
| `recovery_frames` | int | >= 1 | Cooldown frames after move |
| `knockback` | float | >= 0 | Push force on hit |
| `hitbox` | object | | Collision rectangle |

### Hitbox Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `offset_x` | float | | X offset from character center |
| `offset_y` | float | | Y offset from character center |
| `width` | float | >= 1 | Hitbox width in pixels |
| `height` | float | >= 1 | Hitbox height in pixels |

## Creating a Stage Mod

### 1. Create the directory and manifest

```json
{
  "mod_id": "my_stage",
  "name": "Parliament Floor",
  "version": "1.0.0",
  "author": "YourName",
  "description": "Battle in the halls of government.",
  "type": "stage",
  "game_version": "0.1.0",
  "files": {
    "data": "stage.json"
  }
}
```

### 2. Create `stage.json`

Follow the stage data schema (`game/resources/schemas/stage_schema.json`):

```json
{
  "id": "parliament_1",
  "name": "Parliament Floor",
  "description": "The marble halls where laws are made and fists fly.",
  "boundaries": {
    "left": 50,
    "right": 1230,
    "top": 0,
    "bottom": 650
  },
  "spawn_points": {
    "player_1": { "x": 320, "y": 650 },
    "player_2": { "x": 960, "y": 650 }
  },
  "camera": {
    "enabled": false,
    "limit_left": 0,
    "limit_right": 1280,
    "limit_top": 0,
    "limit_bottom": 720
  },
  "hazards": []
}
```

Note: Stage mods currently provide data only. The game uses the base arena scene for rendering. Custom stage scenes will be supported in a future update.

## Validation

The ModLoader validates all mods at startup. Invalid mods are skipped with a warning in the console. Common validation errors:

- **Missing required field**: Check your manifest and data files against the schemas.
- **Invalid mod_id**: Must be lowercase letters, numbers, and underscores only.
- **Invalid version format**: Use semantic versioning (`1.0.0`).
- **Incompatible game_version**: Your mod's `game_version` must be at or below the current game version.
- **Missing data file**: The file referenced in `files.data` must exist in the mod directory.
- **Duplicate mod_id**: Each mod must have a unique `mod_id`.

## Troubleshooting

- Check the Godot console output for `[ModLoader]` messages.
- Mods whose directory names start with `.` are ignored.
- The `_example_character` mod in `game/mods/` serves as a working reference.
- JSON syntax errors will cause the mod to be skipped entirely.

## Example Mod

See `game/mods/_example_character/` for a complete working example with inline documentation.
